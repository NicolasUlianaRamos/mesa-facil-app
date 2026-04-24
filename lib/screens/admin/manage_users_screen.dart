import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/admin_users_service.dart';
import '../../utils/constants.dart';
import '../../widgets/require_admin_auth.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final _service = AdminUsersService();

  bool _loading = false;
  bool _saving = false;
  String? _error;

  final List<_ManagedUser> _users = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      final token = auth.token;
      if (token == null || token.isEmpty) {
        throw Exception('Token inválido. Faça login novamente.');
      }

      final res = await _service.listUsers(token: token);
      if (!mounted) return;

      setState(() {
        _users
          ..clear()
          ..addAll(res.map(_ManagedUser.fromUser));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openCreateDialog() async {
    if (_saving) return;

    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    UserRole role = UserRole.waiter;

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Criar usuário'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<UserRole>(
                  initialValue: role,
                  decoration: const InputDecoration(
                    labelText: 'Perfil',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: UserRole.waiter,
                      child: Text('Garçom'),
                    ),
                    DropdownMenuItem(
                      value: UserRole.kitchen,
                      child: Text('Cozinha'),
                    ),
                    DropdownMenuItem(
                      value: UserRole.admin,
                      child: Text('Admin'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setLocalState(() => role = v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Criar'),
            ),
          ],
        ),
      ),
    );

    if (created != true || !mounted) return;

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (name.isEmpty || email.isEmpty || password.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha nome, email e senha'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final token = context.read<AuthProvider>().token;
      if (token == null || token.isEmpty) {
        throw Exception('Token inválido. Faça login novamente.');
      }

      await _service.createUser(
        token: token,
        name: name,
        email: email,
        password: password,
        role: role,
      );

      if (!mounted) return;
      await _refresh();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário criado com sucesso')),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg.isEmpty ? 'Erro ao criar usuário' : msg),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openEditDialog(_ManagedUser u) async {
    if (_saving) return;

    final nameController = TextEditingController(text: u.name);
    UserRole role = u.role;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Editar usuário'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  enabled: false,
                  controller: TextEditingController(text: u.email),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<UserRole>(
                  initialValue: role,
                  decoration: const InputDecoration(
                    labelText: 'Perfil',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: UserRole.waiter,
                      child: Text('Garçom'),
                    ),
                    DropdownMenuItem(
                      value: UserRole.kitchen,
                      child: Text('Cozinha'),
                    ),
                    DropdownMenuItem(
                      value: UserRole.admin,
                      child: Text('Admin'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setLocalState(() => role = v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    final newName = nameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nome não pode ficar vazio'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final token = context.read<AuthProvider>().token;
      if (token == null || token.isEmpty) {
        throw Exception('Token inválido. Faça login novamente.');
      }

      await _service.updateUser(
        token: token,
        userId: u.id,
        name: newName,
        role: role,
      );

      if (!mounted) return;
      await _refresh();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário atualizado com sucesso')),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg.isEmpty ? 'Erro ao atualizar usuário' : msg),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteUser(_ManagedUser u) async {
    if (_saving) return;

    final currentUserId = context.read<AuthProvider>().currentUser?.id;
    if (currentUserId != null && currentUserId == u.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você não pode deletar seu próprio usuário'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Deletar usuário'),
        content: Text('Deseja deletar "${u.name}"?'),
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

    setState(() => _saving = true);
    try {
      final token = context.read<AuthProvider>().token;
      if (token == null || token.isEmpty) {
        throw Exception('Token inválido. Faça login novamente.');
      }

      await _service.deleteUser(token: token, userId: u.id);

      if (!mounted) return;
      await _refresh();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário deletado com sucesso')),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg.isEmpty ? 'Erro ao deletar usuário' : msg),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final createdFormat = DateFormat('dd/MM/yyyy HH:mm');

    return RequireAdminAuth(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gerenciar Usuários'),
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
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : (_error != null)
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          _error!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar novamente'),
                        ),
                      ],
                    )
                  : (_users.isEmpty)
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 80),
                            Center(
                              child: Text(
                                'Nenhum usuário encontrado',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            final u = _users[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                leading: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: _roleColor(u.role)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _roleIcon(u.role),
                                    color: _roleColor(u.role),
                                  ),
                                ),
                                title: Text(
                                  u.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 2),
                                    Text(
                                      u.email,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Criado em ${createdFormat.format(u.createdAt)}',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Editar',
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed:
                                          _saving ? null : () => _openEditDialog(u),
                                    ),
                                    IconButton(
                                      tooltip: 'Deletar',
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: AppColors.error,
                                      ),
                                      onPressed: _saving ? null : () => _deleteUser(u),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _saving ? null : _openCreateDialog,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add),
        ),
      ),
    );
  }

  static IconData _roleIcon(UserRole role) {
    return switch (role) {
      UserRole.waiter => Icons.person_outline,
      UserRole.kitchen => Icons.restaurant,
      UserRole.admin => Icons.admin_panel_settings_outlined,
    };
  }

  static Color _roleColor(UserRole role) {
    return switch (role) {
      UserRole.waiter => AppColors.info,
      UserRole.kitchen => AppColors.warning,
      UserRole.admin => AppColors.success,
    };
  }
}

class _ManagedUser {
  _ManagedUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final DateTime createdAt;

  factory _ManagedUser.fromUser(dynamic u) {
    // `User` from app models
    return _ManagedUser(
      id: u.id as String,
      name: u.name as String,
      email: u.username as String,
      role: u.role as UserRole,
      createdAt: u.createdAt as DateTime,
    );
  }
}
