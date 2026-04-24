import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../models/order.dart';
import '../models/table_model.dart';
import '../models/comanda.dart';
import '../models/table_finalization_event.dart';
import '../services/storage_service.dart';
import '../services/table_service.dart';
import '../services/order_service.dart';
import '../services/api_config.dart';
import '../utils/constants.dart';

class OrderProvider with ChangeNotifier {
  List<Order> _orders = [];
  List<Order> _ordersHistory = [];
  List<TableModel> _tables = [];
  List<TableFinalizationEvent> _tableFinalizations = [];

  bool _ordersHistoryLoading = false;
  bool _ordersHistoryHasMore = true;
  int _ordersHistoryPage = 1;
  final int _ordersHistoryLimit = 20;
  bool _ordersHistoryInitialized = false;
  String? _ordersHistoryError;

  final TableService _tableService = TableService();
  final OrderService _orderService = OrderService();

  io.Socket? _ordersSocket;

  bool get isOrdersRealtimeConnected => _ordersSocket?.connected ?? false;

  TableStatus _parseBackendTableStatus(dynamic raw) {
    final s = (raw ?? '').toString();
    return switch (s) {
      'available' => TableStatus.available,
      'occupied' => TableStatus.occupied,
      'needsBill' => TableStatus.needsBill,
      _ => TableStatus.available,
    };
  }

  TableModel _mapBackendTableFromRealtime(Map<String, dynamic> map) {
    final numberRaw = map['number'];
    final number = numberRaw is num
        ? numberRaw.toInt()
        : int.tryParse(numberRaw.toString()) ?? 0;

    final rawComandas = map['comandas'];
    final comandas = rawComandas is List
        ? rawComandas.whereType<Map>().map((c) {
            final cm = c.map((k, v) => MapEntry(k.toString(), v));
            final createdAtRaw = cm['createdAt'];
            final createdAt = createdAtRaw is String
                ? (DateTime.tryParse(createdAtRaw) ?? DateTime.now())
                : DateTime.now();
            return Comanda(
              id: (cm['id'] ?? '').toString(),
              tableNumber: number,
              name: (cm['name'] ?? '').toString(),
              createdAt: createdAt,
            );
          }).toList()
        : <Comanda>[];

    final occupiedSinceRaw = map['occupiedSince'];
    final occupiedSince = occupiedSinceRaw is String
        ? DateTime.tryParse(occupiedSinceRaw)
        : null;

    return TableModel(
      number: number,
      status: _parseBackendTableStatus(map['status']),
      occupiedSince: occupiedSince,
      comandas: comandas,
    );
  }

  OrderProvider() {
    _loadData();
    unawaited(_bootstrapTables());
    unawaited(refreshOrdersFromBackend());
    _connectOrdersRealtime();
  }

  @override
  void dispose() {
    _ordersSocket?.dispose();
    super.dispose();
  }

  List<Order> get orders => _orders;
  List<Order> get ordersHistory => List.unmodifiable(_ordersHistory);
  bool get ordersHistoryLoading => _ordersHistoryLoading;
  bool get ordersHistoryHasMore => _ordersHistoryHasMore;
  bool get ordersHistoryInitialized => _ordersHistoryInitialized;
  String? get ordersHistoryError => _ordersHistoryError;
  List<TableModel> get tables => _tables;
  List<TableFinalizationEvent> get tableFinalizationHistory =>
      List.unmodifiable(_tableFinalizations);

  List<Order> get activeOrders {
    return _orders
        .where((order) => order.status != OrderStatus.delivered)
        .toList();
  }

  List<Order> getOrdersByTable(int tableNumber) {
    // Show only orders for the current occupancy/session
    final table = getTable(tableNumber);
    if (table == null) return [];
    if (table.status == TableStatus.available) return [];

    final since = table.occupiedSince;
    return _orders.where((order) {
      if (order.tableNumber != tableNumber) return false;
      if (since == null) return true; // fallback if not set
      return order.createdAt.isAtSameMomentAs(since) ||
          order.createdAt.isAfter(since);
    }).toList();
  }

  TableModel? getTable(int number) {
    try {
      return _tables.firstWhere((table) => table.number == number);
    } catch (e) {
      return null;
    }
  }

  void _loadData() {
    _orders = StorageService.getOrders();
    _tables = StorageService.getTables();
    _tableFinalizations = StorageService.getTableFinalizationEvents();
  }

  Future<void> _syncPendingOrdersToBackend(String token) async {
    // Sync local orders created offline / pre-backend.
    final pending = _orders.where((o) => o.synced == false).take(200).toList();
    if (pending.isEmpty) return;

    for (final o in pending) {
      try {
        final created = await _orderService.createOrder(token: token, order: o);
        final synced = Order(
          id: created.id,
          tableNumber: created.tableNumber,
          comandaId: created.comandaId,
          items: created.items,
          status: created.status,
          waiterId: created.waiterId,
          waiterName: created.waiterName,
          createdAt: created.createdAt,
          startedAt: created.startedAt,
          finishedAt: created.finishedAt,
          deliveredAt: created.deliveredAt,
          generalNotes: created.generalNotes,
          synced: true,
        );
        await StorageService.saveOrder(synced);
      } catch (e) {
        final msg = e.toString();
        // If backend already has it (duplicate key), mark as synced locally.
        if (msg.contains('E11000') || msg.toLowerCase().contains('duplicate')) {
          final synced = Order(
            id: o.id,
            tableNumber: o.tableNumber,
            comandaId: o.comandaId,
            items: o.items,
            status: o.status,
            waiterId: o.waiterId,
            waiterName: o.waiterName,
            createdAt: o.createdAt,
            startedAt: o.startedAt,
            finishedAt: o.finishedAt,
            deliveredAt: o.deliveredAt,
            generalNotes: o.generalNotes,
            synced: true,
          );
          await StorageService.saveOrder(synced);
        }
      }
    }

    _loadData();
  }

  Future<void> refreshOrdersHistoryFromBackend() async {
    final token = StorageService.getAuthToken();
    if (token == null || token.isEmpty) return;

    if (_ordersHistoryLoading) return;

    _ordersHistoryLoading = true;
    _ordersHistoryInitialized = true;
    _ordersHistoryError = null;
    notifyListeners();

    try {
      _ordersHistoryPage = 1;

      await _syncPendingOrdersToBackend(token);

      final items = await _orderService.listOrders(
        token: token,
        limit: _ordersHistoryLimit,
        page: _ordersHistoryPage,
      );
      _ordersHistory = items;
      _ordersHistoryHasMore = items.length == _ordersHistoryLimit;
    } catch (e) {
      _ordersHistoryError = e.toString();
    } finally {
      _ordersHistoryLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreOrdersHistoryFromBackend() async {
    final token = StorageService.getAuthToken();
    if (token == null || token.isEmpty) return;

    if (_ordersHistoryLoading || !_ordersHistoryHasMore) return;

    _ordersHistoryLoading = true;
    _ordersHistoryInitialized = true;
    _ordersHistoryError = null;
    notifyListeners();

    try {
      final nextPage = _ordersHistoryPage + 1;
      final items = await _orderService.listOrders(
        token: token,
        limit: _ordersHistoryLimit,
        page: nextPage,
      );

      if (items.isEmpty) {
        _ordersHistoryHasMore = false;
        return;
      }

      _ordersHistoryPage = nextPage;
      _ordersHistory.addAll(items);
      _ordersHistoryHasMore = items.length == _ordersHistoryLimit;
    } catch (e) {
      _ordersHistoryError = e.toString();
    } finally {
      _ordersHistoryLoading = false;
      notifyListeners();
    }
  }

  void _connectOrdersRealtime() {
    final socket = io.io(
      ApiConfig.baseUrl,
      io.OptionBuilder()
          // On Web, forcing only websocket can break in some environments.
          // Allow polling fallback so realtime works reliably in Chrome.
          .setTransports(['websocket', 'polling'])
          .enableReconnection()
          .setReconnectionAttempts(9999)
          .setReconnectionDelay(500)
          .build(),
    );

    _ordersSocket = socket;

    socket.onConnect((_) {
      socket.emit('orders:join');
      socket.emit('tables:join');
    });

    socket.on('orders:joined', (_) {
      notifyListeners();
    });

    socket.on('tables:joined', (_) {
      notifyListeners();
    });

    socket.onDisconnect((_) {
      notifyListeners();
    });

    socket.onConnectError((_) {
      notifyListeners();
    });

    socket.onError((_) {
      notifyListeners();
    });

    socket.on('order:new', (dynamic data) {
      if (data is Map) {
        final order = Order.fromJson(Map<String, dynamic>.from(data));
        unawaited(_upsertOrderFromRealtime(order));
      }
    });

    socket.on('order:updated', (dynamic data) {
      if (data is Map) {
        final order = Order.fromJson(Map<String, dynamic>.from(data));
        unawaited(_upsertOrderFromRealtime(order));
      }
    });

    Future<void> upsertTableFromRealtime(dynamic data) async {
      if (data is! Map) return;
      final incoming = _mapBackendTableFromRealtime(
        Map<String, dynamic>.from(data),
      );

      final prev = getTable(incoming.number);
      final merged = TableModel(
        number: incoming.number,
        status: incoming.status,
        occupiedSince: incoming.occupiedSince,
        comandas: incoming.comandas,
        currentOrderId: prev?.currentOrderId,
        currentTotal: prev?.currentTotal ?? 0.0,
      );

      if (merged.status == TableStatus.available) {
        merged.currentOrderId = null;
        merged.currentTotal = 0.0;
      }

      await StorageService.saveTable(merged);
      _loadData();
      _tables.sort((a, b) => a.number.compareTo(b.number));
      notifyListeners();
    }

    socket.on('table:created', (data) {
      unawaited(upsertTableFromRealtime(data));
    });

    socket.on('table:updated', (data) {
      unawaited(upsertTableFromRealtime(data));
    });

    socket.connect();
  }

  Future<void> refreshOrdersForTableFromBackend(int tableNumber) async {
    final token = StorageService.getAuthToken();
    if (token == null || token.isEmpty) return;

    try {
      final backendOrders = await _orderService.listOrders(
        token: token,
        tableNumber: tableNumber,
        limit: 500,
        page: 1,
      );

      // Preserve any local unsynced orders for this table.
      final localUnsynced = _orders
          .where((o) => o.tableNumber == tableNumber && o.synced == false)
          .toList();

      for (final o in backendOrders) {
        final synced = Order(
          id: o.id,
          tableNumber: o.tableNumber,
          comandaId: o.comandaId,
          items: o.items,
          status: o.status,
          waiterId: o.waiterId,
          waiterName: o.waiterName,
          createdAt: o.createdAt,
          startedAt: o.startedAt,
          finishedAt: o.finishedAt,
          deliveredAt: o.deliveredAt,
          generalNotes: o.generalNotes,
          synced: true,
        );
        await StorageService.saveOrder(synced);
      }

      for (final o in localUnsynced) {
        await StorageService.saveOrder(o);
      }

      _loadData();
      notifyListeners();
    } catch (_) {
      // ignore; offline fallback
    }
  }

  Future<void> _upsertOrderFromRealtime(Order incoming) async {
    final idx = _orders.indexWhere((o) => o.id == incoming.id);
    final merged = Order(
      id: incoming.id,
      tableNumber: incoming.tableNumber,
      comandaId: incoming.comandaId,
      items: incoming.items,
      status: incoming.status,
      waiterId: incoming.waiterId,
      waiterName: incoming.waiterName,
      createdAt: incoming.createdAt,
      startedAt: incoming.startedAt,
      finishedAt: incoming.finishedAt,
      deliveredAt: incoming.deliveredAt,
      generalNotes: incoming.generalNotes,
      synced: true,
    );

    if (idx >= 0) {
      _orders[idx] = merged;
    } else {
      _orders.add(merged);
    }

    await StorageService.saveOrder(merged);
    _loadData();
    notifyListeners();
  }

  Future<void> refreshOrdersFromBackend() async {
    final token = StorageService.getAuthToken();
    if (token == null || token.isEmpty) return;

    try {
      final backendOrders = await _orderService.listOrders(
        token: token,
        limit: 500,
        page: 1,
      );

      // Keep any local orders that are not synced yet.
      final localUnsynced = _orders.where((o) => o.synced == false).toList();

      for (final o in backendOrders) {
        final synced = Order(
          id: o.id,
          tableNumber: o.tableNumber,
          comandaId: o.comandaId,
          items: o.items,
          status: o.status,
          waiterId: o.waiterId,
          waiterName: o.waiterName,
          createdAt: o.createdAt,
          startedAt: o.startedAt,
          finishedAt: o.finishedAt,
          deliveredAt: o.deliveredAt,
          generalNotes: o.generalNotes,
          synced: true,
        );
        await StorageService.saveOrder(synced);
      }

      for (final o in localUnsynced) {
        await StorageService.saveOrder(o);
      }

      _loadData();
      notifyListeners();
    } catch (_) {
      // ignore; offline fallback
    }
  }

  Future<void> _recordTableFinalization(int tableNumber) async {
    final now = DateTime.now();
    final event = TableFinalizationEvent(
      id: 'table_${tableNumber}_${now.microsecondsSinceEpoch}',
      tableNumber: tableNumber,
      finalizedAt: now,
    );
    await StorageService.saveTableFinalizationEvent(event);
  }

  Future<void> _bootstrapTables() async {
    final token = StorageService.getAuthToken();
    if (token != null && token.isNotEmpty) {
      await refreshTablesFromBackend();
      return;
    }

    // Offline/demo fallback (no token yet).
    if (_tables.isEmpty) {
      for (int i = 1; i <= 20; i++) {
        await StorageService.saveTable(TableModel(number: i));
      }
      _loadData();
      notifyListeners();
    }
  }

  Future<void> refreshTablesFromBackend() async {
    final token = StorageService.getAuthToken();
    if (token == null || token.isEmpty) return;

    try {
      final backendTables = await _tableService.listTables(token: token);
      backendTables.sort((a, b) => a.number.compareTo(b.number));

      final desired = backendTables.map((t) => t.number).toSet();
      final existing = {for (final t in _tables) t.number: t};

      // Remove local tables that do not exist in backend.
      for (final t in _tables) {
        if (!desired.contains(t.number)) {
          await StorageService.deleteTable(t.number);
        }
      }

      // Sync backend tables locally (status/comandas come from backend).
      for (final bt in backendTables) {
        final prev = existing[bt.number];

        final merged = TableModel(
          number: bt.number,
          status: bt.status,
          occupiedSince: bt.occupiedSince,
          comandas: bt.comandas,
          currentOrderId: prev?.currentOrderId,
          currentTotal: prev?.currentTotal ?? 0.0,
        );

        if (merged.status == TableStatus.available) {
          merged.currentOrderId = null;
          merged.currentTotal = 0.0;
        }

        await StorageService.saveTable(merged);
      }

      _loadData();
      _tables.sort((a, b) => a.number.compareTo(b.number));
      notifyListeners();
    } catch (_) {
      // ignore; app still works offline with local tables
    }
  }

  Future<TableModel?> createTableFromBackend() async {
    final token = StorageService.getAuthToken();
    if (token == null || token.isEmpty) return null;

    try {
      final number = await _tableService.createTable(token: token);

      final existing = getTable(number);
      if (existing != null) return existing;

      final table = TableModel(number: number);
      await StorageService.saveTable(table);
      _loadData();
      notifyListeners();
      return table;
    } catch (_) {
      return null;
    }
  }

  Future<void> addOrder(Order order) async {
    Order savedOrder = order;
    final token = StorageService.getAuthToken();
    if (token != null && token.isNotEmpty) {
      final created = await _orderService.createOrder(token: token, order: order);
      final synced = Order(
        id: created.id,
        tableNumber: created.tableNumber,
        comandaId: created.comandaId,
        items: created.items,
        status: created.status,
        waiterId: created.waiterId,
        waiterName: created.waiterName,
        createdAt: created.createdAt,
        startedAt: created.startedAt,
        finishedAt: created.finishedAt,
        deliveredAt: created.deliveredAt,
        generalNotes: created.generalNotes,
        synced: true,
      );
      await StorageService.saveOrder(synced);
      savedOrder = synced;
    } else {
      await StorageService.saveOrder(order);
    }

    final table = getTable(savedOrder.tableNumber);
    if (table != null) {
      table.status = TableStatus.occupied;
      table.currentOrderId = savedOrder.id;
      // Start a new occupancy window at the time of the first order
      table.occupiedSince ??= savedOrder.createdAt;
      await StorageService.saveTable(table);
    }

    _loadData();
    notifyListeners();
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    final order = _orders.firstWhere((o) => o.id == orderId);

    final token = StorageService.getAuthToken();
    if (token != null && token.isNotEmpty) {
      try {
        final updated = await _orderService.updateOrderStatus(
          token: token,
          orderId: orderId,
          status: newStatus,
        );
        order.status = updated.status;
        order.startedAt = updated.startedAt;
        order.finishedAt = updated.finishedAt;
        order.deliveredAt = updated.deliveredAt;
        order.synced = true;
        await StorageService.saveOrder(order);
        _loadData();
        notifyListeners();
        return;
      } catch (_) {
        // fall through to local update
      }
    }

    order.status = newStatus;

    switch (newStatus) {
      case OrderStatus.preparing:
        order.startedAt = DateTime.now();
        break;
      case OrderStatus.finished:
        order.finishedAt = DateTime.now();
        break;
      case OrderStatus.delivered:
        order.deliveredAt = DateTime.now();
        break;
      default:
        break;
    }

    await StorageService.saveOrder(order);
    _loadData();
    notifyListeners();
  }

  Future<void> finalizeCustomerAtTable(int tableNumber) async {
    // Mark all orders from this table as delivered
    final tableOrders = _orders
        .where(
          (o) =>
              o.tableNumber == tableNumber && o.status != OrderStatus.delivered,
        )
        .toList();
    for (final o in tableOrders) {
      await updateOrderStatus(o.id, OrderStatus.delivered);
    }

    final table = getTable(tableNumber);

    final token = StorageService.getAuthToken();
    if (token != null && token.isNotEmpty) {
      try {
        final updated = await _tableService.freeTable(
          token: token,
          tableNumber: tableNumber,
        );
        if (table != null) {
          table.status = updated.status;
          table.occupiedSince = updated.occupiedSince;
          table.comandas = updated.comandas;
          if (table.status == TableStatus.available) {
            table.currentOrderId = null;
            table.currentTotal = 0.0;
          }
          await StorageService.saveTable(table);
        }
      } catch (_) {
        // Fallback to local update
        if (table != null) {
          table.status = TableStatus.available;
          table.currentOrderId = null;
          table.currentTotal = 0.0;
          table.occupiedSince = null;
          table.comandas.clear();
          await StorageService.saveTable(table);
        }
      }
    } else {
      // Offline/demo
      if (table != null) {
        table.status = TableStatus.available;
        table.currentOrderId = null;
        table.currentTotal = 0.0;
        table.occupiedSince = null;
        table.comandas.clear();
        await StorageService.saveTable(table);
      }
    }

    await _recordTableFinalization(tableNumber);

    _loadData();
    notifyListeners();
  }

  Future<void> addComandaToTable(int tableNumber, Comanda comanda) async {
    final table = getTable(tableNumber);
    if (table == null) return;

    final token = StorageService.getAuthToken();
    if (token != null && token.isNotEmpty) {
      try {
        final updated = await _tableService.addComanda(
          token: token,
          tableNumber: tableNumber,
          comanda: comanda,
        );
        table.status = updated.status;
        table.occupiedSince = updated.occupiedSince;
        table.comandas = updated.comandas;
      } catch (_) {
        if (table.status == TableStatus.available) {
          table.status = TableStatus.occupied;
          table.occupiedSince ??= DateTime.now();
        }
        table.comandas.add(comanda);
      }
    } else {
      if (table.status == TableStatus.available) {
        table.status = TableStatus.occupied;
        table.occupiedSince ??= DateTime.now();
      }
      table.comandas.add(comanda);
    }

    await StorageService.saveTable(table);
    _loadData();
    notifyListeners();
  }

  Future<void> occupyTableWithComandas(
    int tableNumber,
    List<Comanda> comandas,
  ) async {
    final table = getTable(tableNumber);
    if (table == null) return;

    final token = StorageService.getAuthToken();
    if (token != null && token.isNotEmpty) {
      try {
        final updated = await _tableService.occupyTable(
          token: token,
          tableNumber: tableNumber,
          comandas: comandas,
        );
        table.status = updated.status;
        table.occupiedSince = updated.occupiedSince;
        table.comandas = updated.comandas;
      } catch (_) {
        table.status = TableStatus.occupied;
        table.occupiedSince = DateTime.now();
        table.comandas = comandas;
      }
    } else {
      table.status = TableStatus.occupied;
      table.occupiedSince = DateTime.now();
      table.comandas = comandas;
    }

    await StorageService.saveTable(table);
    _loadData();
    notifyListeners();
  }

  List<Comanda> getComandasForTable(int tableNumber) {
    final table = getTable(tableNumber);
    return table?.comandas ?? [];
  }

  List<Order> getOrdersByComanda(String comandaId) {
    return _orders.where((order) => order.comandaId == comandaId).toList();
  }

  double getComandaTotal(String comandaId) {
    return getOrdersByComanda(
      comandaId,
    ).fold(0.0, (sum, order) => sum + order.total);
  }

  String getComandaName(String? comandaId) {
    if (comandaId == null) return '';
    for (final table in _tables) {
      for (final comanda in table.comandas) {
        if (comanda.id == comandaId) return comanda.name;
      }
    }
    return '';
  }

  Future<void> finalizeComanda(int tableNumber, String comandaId) async {
    // Mark all orders of this comanda as delivered
    final comandaOrders = _orders
        .where(
          (o) => o.comandaId == comandaId && o.status != OrderStatus.delivered,
        )
        .toList();
    for (final o in comandaOrders) {
      await updateOrderStatus(o.id, OrderStatus.delivered);
    }

    final table = getTable(tableNumber);
    if (table == null) return;

    final token = StorageService.getAuthToken();
    if (token != null && token.isNotEmpty) {
      try {
        final updated = await _tableService.removeComanda(
          token: token,
          tableNumber: tableNumber,
          comandaId: comandaId,
        );
        table.status = updated.status;
        table.occupiedSince = updated.occupiedSince;
        table.comandas = updated.comandas;

        if (table.status == TableStatus.available) {
          table.currentOrderId = null;
          table.currentTotal = 0.0;
          await _recordTableFinalization(tableNumber);
        }
      } catch (_) {
        table.comandas.removeWhere((c) => c.id == comandaId);

        if (table.comandas.isEmpty) {
          table.status = TableStatus.available;
          table.currentOrderId = null;
          table.currentTotal = 0.0;
          table.occupiedSince = null;
          await _recordTableFinalization(tableNumber);
        }
      }
    } else {
      table.comandas.removeWhere((c) => c.id == comandaId);

      if (table.comandas.isEmpty) {
        table.status = TableStatus.available;
        table.currentOrderId = null;
        table.currentTotal = 0.0;
        table.occupiedSince = null;
        await _recordTableFinalization(tableNumber);
      }
    }

    await StorageService.saveTable(table);

    _loadData();
    notifyListeners();
  }

  Future<void> updateTableStatus(int tableNumber, TableStatus newStatus) async {
    final table = getTable(tableNumber);
    if (table != null) {
      table.status = newStatus;

      if (newStatus == TableStatus.available) {
        table.currentOrderId = null;
        table.currentTotal = 0.0;
        table.occupiedSince = null;
      }

      await StorageService.saveTable(table);
      _loadData();
      notifyListeners();
    }
  }

  double getTableTotal(int tableNumber) {
    // Sum only orders from the current session (visible to the waiter)
    final tableOrders = getOrdersByTable(tableNumber);
    return tableOrders.fold(0.0, (sum, order) => sum + order.total);
  }
}
