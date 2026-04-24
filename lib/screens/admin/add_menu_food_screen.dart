import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/menu_category.dart';
import '../../providers/menu_provider.dart';
import '../../services/menu_foods_service.dart';
import '../../services/storage_service.dart';
import '../../utils/constants.dart';
import '../../widgets/require_admin_auth.dart';

class AddMenuFoodScreen extends StatefulWidget {
  const AddMenuFoodScreen({super.key});

  @override
  State<AddMenuFoodScreen> createState() => _AddMenuFoodScreenState();
}

class _AddMenuFoodScreenState extends State<AddMenuFoodScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _newCategoryController = TextEditingController();

  final _picker = ImagePicker();

  List<MenuCategory> _categories = const [];
  MenuCategory? _selectedCategory;
  XFile? _image;

  bool _loadingCategories = false;

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    if (_loadingCategories) return;
    final token = StorageService.getAuthToken();
    if (token == null || token.isEmpty) return;

    setState(() => _loadingCategories = true);

    try {
      final svc = MenuFoodsService();
      final cats = await svc.listMenuCategories(token: token);
      if (!mounted) return;

      setState(() {
        _categories = cats;
        if (_selectedCategory != null) {
          _selectedCategory = cats.where((c) => c.id == _selectedCategory!.id).firstOrNull;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (!mounted) return;
    if (picked == null) return;
    setState(() => _image = picked);
  }

  Future<void> _addCategory() async {
    final token = StorageService.getAuthToken();
    if (token == null || token.isEmpty) return;

    _newCategoryController.clear();

    final created = await showDialog<MenuCategory?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nova categoria'),
          content: TextField(
            controller: _newCategoryController,
            decoration: const InputDecoration(hintText: 'Nome da categoria'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = _newCategoryController.text.trim();
                if (name.isEmpty) return;
                try {
                  final svc = MenuFoodsService();
                  final cat = await svc.createMenuCategory(token: token, name: name);
                  if (context.mounted) Navigator.pop(context, cat);
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    if (created == null) return;

    await _loadCategories();
    if (!mounted) return;
    setState(() => _selectedCategory = _categories.where((c) => c.id == created.id).firstOrNull ?? created);
  }

  Future<void> _deleteSelectedCategory() async {
    final selected = _selectedCategory;
    if (selected == null) return;

    final token = StorageService.getAuthToken();
    if (token == null || token.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir categoria'),
          content: Text('Excluir a categoria "${selected.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final svc = MenuFoodsService();
      await svc.deleteMenuCategory(token: token, categoryId: selected.id);
      if (!mounted) return;
      setState(() => _selectedCategory = null);
      await _loadCategories();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma categoria'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma imagem'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final token = StorageService.getAuthToken();
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sessão inválida. Faça login novamente.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final price = double.tryParse(
      _priceController.text.trim().replaceAll(',', '.'),
    );

    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preço inválido'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _busy = true);

    try {
      final svc = MenuFoodsService();
      await svc.createMenuFoodWithImage(
        token: token,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: price,
        category: _selectedCategory!.name,
        image: _image!,
      );

      if (!mounted) return;
      await context.read<MenuProvider>().refreshMenuFromBackend();

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final msg = _friendlyErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendlyErrorMessage(Object e) {
    var s = e.toString().trim();
    if (s.startsWith('Exception:')) {
      s = s.replaceFirst('Exception:', '').trim();
    }
    if (s.isEmpty || s == 'null') return 'Erro ao criar item do cardápio';
    return s;
  }

  InputDecoration _dec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: AppColors.background,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RequireAdminAuth(
      child: Scaffold(
        appBar: AppBar(title: const Text('Adicionar item')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: _dec('Nome', Icons.restaurant_menu),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Informe o nome'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: _dec('Descrição', Icons.notes),
                  minLines: 2,
                  maxLines: 4,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Informe a descrição'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceController,
                  decoration: _dec('Preço', Icons.attach_money),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Informe o preço'
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedCategory?.id,
                        decoration: _dec('Categoria', Icons.category).copyWith(
                          suffixIcon: _selectedCategory == null
                              ? null
                              : IconButton(
                                  tooltip: 'Excluir categoria',
                                  onPressed: (_busy || _loadingCategories)
                                      ? null
                                      : _deleteSelectedCategory,
                                  icon: const Icon(Icons.delete),
                                ),
                        ),
                        items: _categories
                            .map(
                              (c) => DropdownMenuItem<String>(
                                value: c.id,
                                child: Text(c.name),
                              ),
                            )
                            .toList(),
                        onChanged: (_busy || _loadingCategories)
                            ? null
                            : (id) {
                                final cat = _categories.where((c) => c.id == id).firstOrNull;
                                setState(() => _selectedCategory = cat);
                              },
                        validator: (_) => _selectedCategory == null
                            ? 'Selecione uma categoria'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Adicionar categoria',
                      onPressed: (_busy || _loadingCategories) ? null : _addCategory,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _busy ? null : _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 170,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.textSecondary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: _image == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image, color: AppColors.textSecondary),
                              SizedBox(height: 8),
                              Text(
                                'Selecionar imagem',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: FutureBuilder<Uint8List>(
                              future: _image!.readAsBytes(),
                              builder: (context, snapshot) {
                                final data = snapshot.data;
                                if (data == null) {
                                  return const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  );
                                }
                                return Image.memory(data, fit: BoxFit.cover);
                              },
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Salvar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
