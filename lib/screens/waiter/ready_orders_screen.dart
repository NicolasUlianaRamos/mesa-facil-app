import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/order_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/order_card.dart';

class ReadyOrdersScreen extends StatelessWidget {
  const ReadyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final ready =
        orderProvider.orders
            .where((o) => o.status == OrderStatus.finished)
            .toList()
          ..sort(
            (a, b) => (a.finishedAt ?? a.createdAt).compareTo(
              b.finishedAt ?? b.createdAt,
            ),
          );

    return Scaffold(
      appBar: AppBar(title: const Text('Pedidos Prontos')),
      body: ready.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.outbox, size: 64, color: AppColors.textSecondary),
                  SizedBox(height: 12),
                  Text(
                    'Nenhum pedido pronto no momento',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : ListView.builder(
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
            ),
    );
  }
}
