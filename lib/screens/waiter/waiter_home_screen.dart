import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/table_card.dart';
import '../../widgets/chat_widget.dart';
import '../../widgets/order_card.dart';
import 'table_order_screen.dart';
// import 'ready_orders_screen.dart';

class WaiterHomeScreen extends StatefulWidget {
  const WaiterHomeScreen({super.key});

  @override
  State<WaiterHomeScreen> createState() => _WaiterHomeScreenState();
}

class _WaiterHomeScreenState extends State<WaiterHomeScreen> {
  bool _showChat = false;
  int _currentIndex = 0; // 0 = Mesas, 1 = Prontos

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final chatProvider = context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mesa Fácil',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Garçom: ${auth.currentUser?.name}',
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
          _currentIndex == 0
              ? _buildTablesView(orderProvider)
              : _buildReadyOrdersView(orderProvider),
          if (_showChat)
            ChatWidget(
              onClose: () => setState(() => _showChat = false),
            ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text('Escaneamento QR Code'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.qr_code_scanner,
                          size: 64,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Função de escaneamento de QR Code',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Em breve: Escaneie o QR Code da mesa para abrir o pedido automaticamente',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Fechar'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Escanear QR'),
              backgroundColor: AppColors.secondary,
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.table_bar),
            label: 'Mesas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.outbox),
            label: 'Prontos',
          ),
        ],
      ),
    );
  }

  Widget _buildTablesView(OrderProvider orderProvider) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.primary.withValues(alpha: 0.1),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Mesas Ocupadas',
                  orderProvider.tables
                      .where((t) => t.status == TableStatus.occupied)
                      .length
                      .toString(),
                  Icons.table_bar,
                  AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Pedidos Ativos',
                  orderProvider.activeOrders.length.toString(),
                  Icons.receipt_long,
                  AppColors.info,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: orderProvider.tables.length,
            itemBuilder: (context, index) {
              final table = orderProvider.tables[index];
              return TableCard(
                table: table,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TableOrderScreen(table: table),
                    ),
                  );
                },
              ).animate().fadeIn(
                delay: (index * 50).ms,
                duration: 300.ms,
              ).scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.0, 1.0),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReadyOrdersView(OrderProvider orderProvider) {
    final ready = orderProvider.orders
        .where((o) => o.status == OrderStatus.finished)
        .toList()
      ..sort((a, b) => (a.finishedAt ?? a.createdAt)
          .compareTo(b.finishedAt ?? b.createdAt));

    if (ready.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.outbox, size: 64, color: AppColors.textSecondary),
            SizedBox(height: 12),
            Text('Nenhum pedido pronto no momento',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ready.length,
      itemBuilder: (context, index) {
        final order = ready[index];
        return OrderCard(
          order: order,
          showDeliverActionWhenFinished: true,
          onStatusChange: (newStatus) async {
            await orderProvider.updateOrderStatus(order.id, newStatus);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pedido marcado como entregue!'),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
