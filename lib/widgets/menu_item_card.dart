import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/menu_item.dart';
import '../utils/constants.dart';

class MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback? onLongPress;

  const MenuItemCard({
    super.key,
    required this.item,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        clipBehavior: Clip.antiAlias,
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
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.background,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.background,
                      child: const Icon(
                        Icons.restaurant,
                        size: 48,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                if (quantity > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        quantity.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      'R\$ ${item.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (quantity == 0)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onAdd,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(36),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Adicionar',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: IconButton(
                              onPressed: onRemove,
                              icon: const Icon(Icons.remove_circle),
                              color: AppColors.error,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              quantity.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: IconButton(
                              onPressed: onAdd,
                              icon: const Icon(Icons.add_circle),
                              color: AppColors.success,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
