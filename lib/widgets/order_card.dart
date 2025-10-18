import 'package:flutter/material.dart';
import '../models/order.dart';
import '../utils/constants.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final Function(OrderStatus) onStatusChange;
  final bool showDeliverActionWhenFinished;

  const OrderCard({
    super.key,
    required this.order,
    required this.onStatusChange,
    this.showDeliverActionWhenFinished = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = OrderStatusHelper.getColor(order.status);
    final timeSinceOrder = DateTime.now().difference(order.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: statusColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.table_bar,
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mesa ${order.tableNumber}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Garçom: ${order.waiterName}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        OrderStatusHelper.getLabel(order.status),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDuration(timeSinceOrder),
                      style: TextStyle(
                        fontSize: 11,
                        color: timeSinceOrder.inMinutes > 15
                            ? AppColors.error
                            : AppColors.textSecondary,
                        fontWeight: timeSinceOrder.inMinutes > 15
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            ...order.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${item.quantity}x',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (item.specialInstructions != null)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  size: 14,
                                  color: AppColors.warning,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    item.specialInstructions!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.warning,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    'R\$ ${item.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            )),
            if (order.generalNotes != null) ...[
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.note,
                      size: 16,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.generalNotes!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Divider(height: 24),
            Row(
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'R\$ ${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    switch (order.status) {
      case OrderStatus.received:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => onStatusChange(OrderStatus.preparing),
            icon: const Icon(Icons.restaurant),
            label: const Text('Iniciar Preparo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        );
      case OrderStatus.preparing:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => onStatusChange(OrderStatus.finished),
            icon: const Icon(Icons.check_circle),
            label: const Text('Marcar como Finalizado'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        );
      case OrderStatus.finished:
        if (showDeliverActionWhenFinished) {
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => onStatusChange(OrderStatus.delivered),
              icon: const Icon(Icons.delivery_dining),
              label: const Text('Marcar como Entregue'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          );
        }
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: AppColors.success),
              SizedBox(width: 8),
              Text(
                'Aguardando entrega pelo garçom',
                style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      case OrderStatus.delivered:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.done_all, color: AppColors.accent),
              SizedBox(width: 8),
              Text(
                'Pedido entregue',
                style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes < 1) {
      return 'Agora';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes} min atrás';
    } else {
      return '${duration.inHours}h ${duration.inMinutes % 60}m atrás';
    }
  }
}
