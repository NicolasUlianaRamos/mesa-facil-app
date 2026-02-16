import 'package:flutter/material.dart';
import '../models/table_model.dart';
import '../utils/constants.dart';

class TableCard extends StatelessWidget {
  final TableModel table;
  final VoidCallback onTap;

  const TableCard({super.key, required this.table, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = TableStatusHelper.getColor(table.status);
    final statusLabel = TableStatusHelper.getLabel(table.status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: statusColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.table_bar, size: 32, color: statusColor),
            ),
            const SizedBox(height: 12),
            Text(
              'Mesa ${table.number}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            if (table.currentTotal > 0) ...[
              const SizedBox(height: 8),
              Text(
                'R\$ ${table.currentTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
