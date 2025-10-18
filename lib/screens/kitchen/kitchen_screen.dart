import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/order_card.dart';
import '../../widgets/chat_widget.dart';

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  OrderStatus _selectedStatus = OrderStatus.received;
  bool _showChat = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final chatProvider = context.watch<ChatProvider>();
    
    final filteredOrders = orderProvider.activeOrders
        .where((order) => order.status == _selectedStatus)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cozinha',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
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
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: () {
                  setState(() => _showChat = !_showChat);
                  if (_showChat) {
                    chatProvider.markAsRead();
                  }
                },
              ),
              if (chatProvider.unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${chatProvider.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              auth.logout();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.primary.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Recebidos',
                        orderProvider.activeOrders
                            .where((o) => o.status == OrderStatus.received)
                            .length
                            .toString(),
                        AppColors.info,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Em Preparo',
                        orderProvider.activeOrders
                            .where((o) => o.status == OrderStatus.preparing)
                            .length
                            .toString(),
                        AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Finalizados',
                        orderProvider.activeOrders
                            .where((o) => o.status == OrderStatus.finished)
                            .length
                            .toString(),
                        AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildStatusChip(OrderStatus.received),
                    const SizedBox(width: 8),
                    _buildStatusChip(OrderStatus.preparing),
                    const SizedBox(width: 8),
                    _buildStatusChip(OrderStatus.finished),
                  ],
                ),
              ),
              Expanded(
                child: filteredOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              OrderStatusHelper.getIcon(_selectedStatus),
                              size: 64,
                              color: AppColors.textSecondary.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhum pedido ${OrderStatusHelper.getLabel(_selectedStatus).toLowerCase()}',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          return OrderCard(
                            order: order,
                            onStatusChange: (newStatus) {
                              orderProvider.updateOrderStatus(order.id, newStatus);
                            },
                          ).animate().fadeIn(
                            delay: (index * 50).ms,
                            duration: 300.ms,
                          ).slideX(
                            begin: -0.2,
                            end: 0,
                          );
                        },
                      ),
              ),
            ],
          ),
          if (_showChat)
            ChatWidget(
              onClose: () => setState(() => _showChat = false),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
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
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    final isSelected = status == _selectedStatus;
    return FilterChip(
      label: Text(OrderStatusHelper.getLabel(status)),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedStatus = status);
      },
      backgroundColor: Colors.white,
      selectedColor: OrderStatusHelper.getColor(status),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      avatar: Icon(
        OrderStatusHelper.getIcon(status),
        size: 18,
        color: isSelected ? Colors.white : OrderStatusHelper.getColor(status),
      ),
    );
  }
}
