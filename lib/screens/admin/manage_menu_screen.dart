import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/menu_provider.dart';
import '../../services/menu_foods_service.dart';
import '../../services/storage_service.dart';
import '../../utils/constants.dart';
import '../../widgets/menu_item_image.dart';
import 'add_menu_food_screen.dart';

class ManageMenuScreen extends StatefulWidget {
  const ManageMenuScreen({super.key, this.isAdmin = true});

  final bool isAdmin;

  @override
  State<ManageMenuScreen> createState() => _ManageMenuScreenState();
}

class _ManageMenuScreenState extends State<ManageMenuScreen> {
  bool _loading = false;
  String _selectedCategory = 'Todos';
  bool _deleting = false;
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      await context.read<MenuProvider>().refreshMenuFromBackend();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteItem(String id, String name) async {
    if (_deleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Deletar item'),
        content: Text('Deseja deletar "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      final token = StorageService.getAuthToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token inválido. Faça login novamente.');
      }

      await MenuFoodsService().deleteMenuFood(token: token, menuFoodId: id);
      if (!mounted) return;
      await _refresh();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item deletado com sucesso')),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '').trim();

      // Even if backend says not found, refresh to avoid showing stale items.
      try {
        await _refresh();
      } catch (_) {
        // ignore refresh errors here; we'll show the original error below
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg.isEmpty ? 'Erro ao deletar item' : msg),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _toggleActive(String id) async {
    if (_toggling) return;
    setState(() => _toggling = true);
    try {
      await context.read<MenuProvider>().toggleItemActive(id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '').trim()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Widget _imageFor(String url) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: MenuItemImage(
        imageUrl: url,
        height: 110,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: Container(
          color: AppColors.background,
          child: const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: Container(
          color: AppColors.background,
          child: const Center(
            child: Icon(
              Icons.restaurant,
              size: 48,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuProvider = context.watch<MenuProvider>();
    final items = [...menuProvider.menuItems]
      ..sort((a, b) => a.category.compareTo(b.category));

    final categories = items
        .map((e) => e.category)
        .where((c) => c.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final effectiveSelected = (_selectedCategory != 'Todos' && categories.contains(_selectedCategory))
        ? _selectedCategory
        : 'Todos';
    final filteredItems = effectiveSelected == 'Todos'
        ? items
        : items.where((e) => e.category == effectiveSelected).toList();

    final isAdmin = widget.isAdmin;

    return Scaffold(
        appBar: AppBar(
          title: const Text('Gerenciar Cardápio'),
          actions: [
            IconButton(
              tooltip: 'Atualizar',
              onPressed: _loading ? null : _refresh,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.refresh),
            ),
          ],
        ),
        body: items.isEmpty
            ? Center(
                child: Text(
                  'Nenhum item no cardápio',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              )
            : Column(
                children: [
                  if (categories.isNotEmpty)
                    Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: categories.length + 1,
                        itemBuilder: (context, index) {
                          final category = index == 0 ? 'Todos' : categories[index - 1];
                          final isSelected = category == effectiveSelected;
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
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.72,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        final statusColor = item.available
                            ? AppColors.success
                            : AppColors.textSecondary;
                        final statusLabel = item.available ? 'Ativo' : 'Inativo';

                        return InkWell(
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
                                    _imageFor(item.imageUrl),
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          statusLabel,
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (isAdmin)
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: IconButton(
                                          tooltip: 'Deletar',
                                          onPressed: (_loading || _deleting)
                                              ? null
                                              : () => _deleteItem(item.id, item.name),
                                          icon: const Icon(Icons.delete_outline),
                                          color: AppColors.error,
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
                                        const SizedBox(height: 4),
                                        Text(
                                          item.category,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const Spacer(),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'R\$ ${item.price.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.success,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              height: 24,
                                              child: Switch(
                                                value: item.available,
                                                activeThumbColor: AppColors.success,
                                                onChanged: (_loading || _toggling)
                                                    ? null
                                                    : (_) => _toggleActive(item.id),
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
                      },
                    ),
                  ),
                ],
              ),
        floatingActionButton: isAdmin
            ? FloatingActionButton(
                onPressed: () async {
                  final created = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => const AddMenuFoodScreen()),
                  );
                  if (created == true && context.mounted) {
                    await _refresh();
                  }
                },
                child: const Icon(Icons.add),
              )
            : null,
    );
  }
}
