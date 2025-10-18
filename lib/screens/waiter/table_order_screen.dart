import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../models/table_model.dart';
import '../../models/order.dart';
import '../../models/order_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/menu_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/menu_item_card.dart';

class TableOrderScreen extends StatefulWidget {
  final TableModel table;

  const TableOrderScreen({super.key, required this.table});

  @override
  State<TableOrderScreen> createState() => _TableOrderScreenState();
}

class _TableOrderScreenState extends State<TableOrderScreen> {
  final Map<String, int> _cart = {};
  final Map<String, String> _specialInstructions = {};
  String _selectedCategory = '';

  @override
  void initState() {
    super.initState();
    final menuProvider = context.read<MenuProvider>();
    if (menuProvider.categories.isNotEmpty) {
      _selectedCategory = menuProvider.categories.first;
    }
  }

  void _addToCart(String itemId) {
    setState(() {
      _cart[itemId] = (_cart[itemId] ?? 0) + 1;
    });
  }

  void _removeFromCart(String itemId) {
    setState(() {
      if (_cart[itemId] != null && _cart[itemId]! > 1) {
        _cart[itemId] = _cart[itemId]! - 1;
      } else {
        _cart.remove(itemId);
        _specialInstructions.remove(itemId);
      }
    });
  }

  Future<void> _submitOrder() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione itens ao pedido'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final menuProvider = context.read<MenuProvider>();
    final orderProvider = context.read<OrderProvider>();

    final orderItems = _cart.entries.map((entry) {
      final menuItem = menuProvider.menuItems.firstWhere((item) => item.id == entry.key);
      return OrderItem(
        menuItemId: entry.key,
        name: menuItem.name,
        price: menuItem.price,
        quantity: entry.value,
        specialInstructions: _specialInstructions[entry.key],
      );
    }).toList();

    final order = Order(
      id: const Uuid().v4(),
      tableNumber: widget.table.number,
      items: orderItems,
      waiterId: auth.currentUser!.id,
      waiterName: auth.currentUser!.name,
      createdAt: DateTime.now(),
    );

    await orderProvider.addOrder(order);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pedido enviado para a cozinha!'),
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.pop(context);
  }

  double get _total {
    final menuProvider = context.read<MenuProvider>();
    return _cart.entries.fold(0.0, (sum, entry) {
      final item = menuProvider.menuItems.firstWhere((item) => item.id == entry.key);
      return sum + (item.price * entry.value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final menuProvider = context.watch<MenuProvider>();
  final orderProvider = context.watch<OrderProvider>();
  final tableOrders = orderProvider.getOrdersByTable(widget.table.number);

    return Scaffold(
      appBar: AppBar(
        title: Text('Mesa ${widget.table.number}'),
        actions: [
          IconButton(
            tooltip: 'Cliente finalizado',
            icon: const Icon(Icons.switch_account),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text('Finalizar cliente desta mesa?'),
                  content: const Text('Isso marcará os pedidos como entregues e liberará a mesa para o próximo cliente.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Finalizar Cliente'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await context.read<OrderProvider>().finalizeCustomerAtTable(widget.table.number);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mesa liberada e pedidos finalizados.'),
                    backgroundColor: AppColors.success,
                  ),
                );
                Navigator.pop(context);
              }
            },
          ),
          if (tableOrders.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () => _showOrderHistory(tableOrders),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primary.withValues(alpha: 0.1),
            child: Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    'Status',
                    TableStatusHelper.getLabel(widget.table.status),
                    TableStatusHelper.getColor(widget.table.status),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    'Total da Mesa',
                    'R\$ ${orderProvider.getTableTotal(widget.table.number).toStringAsFixed(2)}',
                    AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          // Active orders for this table
          if (tableOrders.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: const [
                  Icon(Icons.receipt_long, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Pedidos desta mesa',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 180,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: tableOrders.length,
                itemBuilder: (context, index) {
                  final order = tableOrders[index];
                  final color = OrderStatusHelper.getColor(order.status);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
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
                      border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                OrderStatusHelper.getLabel(order.status),
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'R\$ ${order.total.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          order.items.map((i) => '${i.quantity}x ${i.name}').join(', '),
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        if (order.status == OrderStatus.finished)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await orderProvider.updateOrderStatus(order.id, OrderStatus.delivered);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Pedido marcado como entregue'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.delivery_dining),
                              label: const Text('Marcar como Entregue'),
                            ),
                          )
                        else if (order.status == OrderStatus.delivered)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.done_all, color: AppColors.accent, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'Pedido entregue',
                                    style: TextStyle(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              order.status == OrderStatus.preparing
                                  ? 'Em preparo na cozinha'
                                  : 'Aguardando iniciar preparo',
                              style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: menuProvider.categories.length,
              itemBuilder: (context, index) {
                final category = menuProvider.categories[index];
                final isSelected = category == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedCategory = category);
                    },
                    backgroundColor: Colors.white,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: menuProvider.getItemsByCategory(_selectedCategory).length,
              itemBuilder: (context, index) {
                final item = menuProvider.getItemsByCategory(_selectedCategory)[index];
                final quantity = _cart[item.id] ?? 0;
                
                return MenuItemCard(
                  item: item,
                  quantity: quantity,
                  onAdd: () => _addToCart(item.id),
                  onRemove: () => _removeFromCart(item.id),
                  onLongPress: () => _showSpecialInstructions(item.id, item.name),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _cart.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_cart.values.fold(0, (a, b) => a + b)} itens',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'R\$ ${_total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submitOrder,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Enviar Pedido',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildInfoCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showSpecialInstructions(String itemId, String itemName) {
    final controller = TextEditingController(text: _specialInstructions[itemId] ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Observações - $itemName'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Ex: sem cebola, carne bem passada',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                if (controller.text.isNotEmpty) {
                  _specialInstructions[itemId] = controller.text;
                } else {
                  _specialInstructions.remove(itemId);
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _showOrderHistory(List<Order> orders) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Histórico da Mesa ${widget.table.number}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
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
                                  borderRadius: BorderRadius.circular(4),
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
                                DateFormat('HH:mm').format(order.createdAt),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...order.items.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              '${item.quantity}x ${item.name}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          )),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'R\$ ${order.total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
