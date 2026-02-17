import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/menu_provider.dart';
import '../../models/comanda.dart';
import '../../models/table_model.dart';
import '../../utils/constants.dart';
import '../waiter/table_order_screen.dart';
import '../../widgets/order_card.dart';
import '../../models/menu_item.dart';
import '../../services/image_storage_service.dart';
import '../../widgets/menu_item_image.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final menuProvider = context.watch<MenuProvider>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Administração',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                auth.currentUser?.name ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                auth.logout();
              },
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            tabs: [
              Tab(text: 'Resumo'),
              Tab(text: 'Histórico Pedidos'),
              Tab(text: 'Mesas Finalizadas'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildDashboardTab(context, auth, orderProvider, menuProvider),
            _buildOrdersHistoryTab(context, orderProvider),
            _buildTablesFinalizedHistoryTab(context, orderProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardTab(
    BuildContext context,
    AuthProvider auth,
    OrderProvider orderProvider,
    MenuProvider menuProvider,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Total de Pedidos',
                  orderProvider.orders.length.toString(),
                  Icons.receipt_long,
                  AppColors.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Itens no Cardápio',
                  menuProvider.menuItems.length.toString(),
                  Icons.restaurant_menu,
                  AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Usuários',
                  auth.users.length.toString(),
                  Icons.people,
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Mesas',
                  orderProvider.tables.length.toString(),
                  Icons.table_bar,
                  AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Ações Rápidas',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            context,
            'Fazer Pedido para uma Mesa',
            'Selecione a mesa e crie um novo pedido',
            Icons.add_shopping_cart,
            AppColors.secondary,
            () => _openCreateOrderFlow(context, orderProvider),
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            context,
            'Pedidos Prontos na Cozinha',
            'Visualize e entregue pedidos finalizados',
            Icons.outbox,
            AppColors.success,
            () => _showReadyOrders(context, orderProvider),
          ),
          const SizedBox(height: 24),
          Text(
            'Pedidos por Status',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: PieChart(
              PieChartData(
                sections: _buildPieChartSections(orderProvider),
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildFeatureCard(
            context,
            'Gerenciar Cardápio',
            'Adicionar, editar e remover pratos',
            Icons.restaurant_menu,
            AppColors.warning,
            () => _showAddMenuItemDialog(context),
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            context,
            'Gerenciar Usuários',
            'Adicionar garçons, cozinheiros e administradores',
            Icons.people,
            AppColors.success,
            () => _showComingSoon(context, 'Gerenciamento de Usuários'),
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            context,
            'Relatórios Detalhados',
            'Pratos mais pedidos, tempo médio e estatísticas',
            Icons.analytics,
            AppColors.info,
            () => _showComingSoon(context, 'Relatórios Detalhados'),
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            context,
            'Configurações',
            'Gerenciar mesas, integrações e configurações gerais',
            Icons.settings,
            AppColors.accent,
            () => _showComingSoon(context, 'Configurações'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersHistoryTab(
    BuildContext context,
    OrderProvider orderProvider,
  ) {
    final orders = [...orderProvider.orders]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (orders.isEmpty) {
      return Center(
        child: Text(
          'Nenhum pedido no histórico',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    final createdFormat = DateFormat('dd/MM/yyyy HH:mm');
    final shortFormat = DateFormat('dd/MM HH:mm');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final started = order.startedAt != null
            ? shortFormat.format(order.startedAt!)
            : '—';
        final finished = order.finishedAt != null
            ? shortFormat.format(order.finishedAt!)
            : '—';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: OrderStatusHelper.getColor(order.status),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        OrderStatusHelper.getLabel(order.status),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      createdFormat.format(order.createdAt),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Mesa ${order.tableNumber}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Garçom: ${order.waiterName}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Cozinha: em preparo $started • finalizado $finished',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTablesFinalizedHistoryTab(
    BuildContext context,
    OrderProvider orderProvider,
  ) {
    final events = [...orderProvider.tableFinalizationHistory]
      ..sort((a, b) => b.finalizedAt.compareTo(a.finalizedAt));

    if (events.isEmpty) {
      return Center(
        child: Text(
          'Nenhuma mesa finalizada no histórico',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.table_bar, color: AppColors.secondary),
            title: Text('Mesa ${event.tableNumber} finalizada'),
            subtitle: Text(dateFormat.format(event.finalizedAt)),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(
    OrderProvider orderProvider,
  ) {
    final received = orderProvider.orders
        .where((o) => o.status == OrderStatus.received)
        .length;
    final preparing = orderProvider.orders
        .where((o) => o.status == OrderStatus.preparing)
        .length;
    final finished = orderProvider.orders
        .where((o) => o.status == OrderStatus.finished)
        .length;
    final delivered = orderProvider.orders
        .where((o) => o.status == OrderStatus.delivered)
        .length;

    final total = received + preparing + finished + delivered;
    if (total == 0) {
      return [
        PieChartSectionData(
          color: AppColors.textSecondary.withValues(alpha: 0.3),
          value: 1,
          title: 'Sem dados',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ];
    }

    return [
      if (received > 0)
        PieChartSectionData(
          color: AppColors.info,
          value: received.toDouble(),
          title: received.toString(),
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      if (preparing > 0)
        PieChartSectionData(
          color: AppColors.warning,
          value: preparing.toDouble(),
          title: preparing.toString(),
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      if (finished > 0)
        PieChartSectionData(
          color: AppColors.success,
          value: finished.toDouble(),
          title: finished.toString(),
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      if (delivered > 0)
        PieChartSectionData(
          color: AppColors.accent,
          value: delivered.toDouble(),
          title: delivered.toString(),
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
    ];
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.rocket_launch, color: AppColors.secondary),
            const SizedBox(width: 12),
            const Text('Em Desenvolvimento'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              feature,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Esta funcionalidade está em desenvolvimento e estará disponível em breve!',
                style: TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAddMenuItemDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _AddMenuItemDialog(),
    );
  }

  void _openCreateOrderFlow(BuildContext context, OrderProvider orderProvider) {
    final outerContext = context;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SizedBox(
          height: 420,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Selecione a Mesa',
                  style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: orderProvider.tables.length,
                  itemBuilder: (context, index) {
                    final table = orderProvider.tables[index];
                    final isOccupied = table.status == TableStatus.occupied;
                    return InkWell(
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        await Future<void>.delayed(Duration.zero);
                        if (!outerContext.mounted) return;
                        await _openTableWithComandasIfNeeded(
                          outerContext,
                          table,
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: isOccupied
                                ? AppColors.warning
                                : AppColors.success,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.table_bar,
                                color: isOccupied
                                    ? AppColors.warning
                                    : AppColors.success,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Mesa ${table.number}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openTableWithComandasIfNeeded(
    BuildContext context,
    TableModel table,
  ) async {
    final orderProvider = context.read<OrderProvider>();

    if (table.status == TableStatus.available) {
      final List<Comanda>? comandas = await showDialog<List<Comanda>>(
        context: context,
        builder: (_) => _ComandasDialog(tableNumber: table.number),
      );

      if (comandas == null || !context.mounted) return;
      await orderProvider.occupyTableWithComandas(table.number, comandas);
    }

    if (!context.mounted) return;
    final updatedTable = orderProvider.getTable(table.number);
    if (updatedTable == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TableOrderScreen(table: updatedTable)),
    );
  }

  void _showReadyOrders(BuildContext context, OrderProvider orderProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Consumer<OrderProvider>(
              builder: (context, provider, _) {
                final ready = provider.activeOrders
                    .where((o) => o.status == OrderStatus.finished)
                    .toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pedidos Prontos',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ready.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.outbox,
                                    size: 48,
                                    color: AppColors.textSecondary.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text('Nenhum pedido pronto no momento'),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: ready.length,
                              itemBuilder: (context, index) {
                                final order = ready[index];
                                return OrderCard(
                                  order: order,
                                  showDeliverActionWhenFinished: true,
                                  onStatusChange: (newStatus) async {
                                    await provider.updateOrderStatus(
                                      order.id,
                                      newStatus,
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Pedido marcado como entregue',
                                          ),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ComandasDialog extends StatefulWidget {
  final int tableNumber;
  const _ComandasDialog({required this.tableNumber});

  @override
  State<_ComandasDialog> createState() => _ComandasDialogState();
}

class _ComandasDialogState extends State<_ComandasDialog> {
  int numComandas = 1;
  late List<TextEditingController> controllers;

  @override
  void initState() {
    super.initState();
    controllers = [TextEditingController()];
  }

  @override
  void dispose() {
    for (final c in controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Ocupar Mesa ${widget.tableNumber}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quantas comandas serão usadas?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: numComandas > 1
                      ? () {
                          setState(() {
                            numComandas--;
                            controllers.removeLast();
                          });
                        }
                      : null,
                ),
                Text(
                  '$numComandas',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: numComandas < 10
                      ? () {
                          setState(() {
                            numComandas++;
                            controllers.add(TextEditingController());
                          });
                        }
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Nome das comandas:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            ...List.generate(
              numComandas,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: controllers[index],
                  decoration: InputDecoration(
                    labelText: 'Comanda ${index + 1}',
                    hintText: 'Ex: João, Maria, Comanda 1...',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.receipt),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final nowMs = DateTime.now().millisecondsSinceEpoch;
            final comandas = controllers
                .asMap()
                .entries
                .map(
                  (entry) => Comanda(
                    id: '${widget.tableNumber}-comanda-${entry.key + 1}-$nowMs',
                    tableNumber: widget.tableNumber,
                    name: entry.value.text.trim().isEmpty
                        ? 'Comanda ${entry.key + 1}'
                        : entry.value.text.trim(),
                    createdAt: DateTime.now(),
                  ),
                )
                .toList();
            Navigator.pop(context, comandas);
          },
          child: const Text('Ocupar Mesa'),
        ),
      ],
    );
  }
}

class _AddMenuItemDialog extends StatefulWidget {
  const _AddMenuItemDialog();

  @override
  State<_AddMenuItemDialog> createState() => _AddMenuItemDialogState();
}

class _AddMenuItemDialogState extends State<_AddMenuItemDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();
  final _imageUrlController = TextEditingController();

  final _imagePicker = ImagePicker();

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menuProvider = context.watch<MenuProvider>();
    final categories = [...menuProvider.categories]..sort();
    final screenWidth = MediaQuery.sizeOf(context).width;
    final availableWidth = screenWidth - 96; // dialog padding/margins (aprox.)
    final previewWidth = availableWidth < 200
        ? 200.0
        : (availableWidth > 320 ? 320.0 : availableWidth);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.add_circle_outline, color: AppColors.warning),
          const SizedBox(width: 12),
          const Expanded(child: Text('Adicionar produto')),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Informe o nome';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Descrição'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Informe a descrição';
                  }
                  return null;
                },
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                textInputAction: TextInputAction.next,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Preço (ex: 12.90)',
                ),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return 'Informe o preço';
                  final normalized = value.replaceAll(',', '.');
                  final parsed = double.tryParse(normalized);
                  if (parsed == null || parsed < 0) return 'Preço inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              if (categories.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: null,
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    _categoryController.text = value;
                    setState(() {});
                  },
                  decoration: const InputDecoration(
                    labelText: 'Categoria (selecionar)',
                  ),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Categoria'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Informe a categoria';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Imagem',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSaving ? null : _pickImageFromGallery,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(
                        _imageUrlController.text.trim().isEmpty
                            ? 'Selecionar da galeria'
                            : 'Trocar imagem',
                      ),
                    ),
                  ),
                  if (_imageUrlController.text.trim().isNotEmpty) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Remover imagem',
                      onPressed: _isSaving
                          ? null
                          : () => setState(() => _imageUrlController.clear()),
                      icon: const Icon(Icons.delete_outline),
                      color: AppColors.error,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              if (_imageUrlController.text.trim().isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: MenuItemImage(
                    imageUrl: _imageUrlController.text.trim(),
                    height: 140,
                    width: previewWidth,
                    fit: BoxFit.cover,
                    placeholder: Container(
                      height: 140,
                      color: AppColors.background,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: Container(
                      height: 140,
                      color: AppColors.background,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        size: 42,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : () => _save(context),
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Adicionar'),
        ),
      ],
    );
  }

  Future<void> _save(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    if (_imageUrlController.text.trim().isEmpty) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        const SnackBar(
          content: Text('Selecione uma imagem da galeria'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final priceText = _priceController.text.trim().replaceAll(',', '.');
      final price = double.parse(priceText);

      final item = MenuItem(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: price,
        category: _categoryController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
      );

      await context.read<MenuProvider>().addMenuItem(item);

      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      Navigator.pop(context);
      messenger?.showSnackBar(
        const SnackBar(
          content: Text('Produto adicionado ao cardápio'),
          backgroundColor: AppColors.success,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (picked == null) return;

      final persisted = await ImageStorageService.persistPickedImage(picked);
      if (!mounted) return;
      setState(() => _imageUrlController.text = persisted);
    } catch (_) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        const SnackBar(
          content: Text('Não foi possível selecionar a imagem'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
