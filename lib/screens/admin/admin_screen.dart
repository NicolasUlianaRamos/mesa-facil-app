import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/menu_provider.dart';
import '../../utils/constants.dart';
import '../waiter/table_order_screen.dart';
import '../../widgets/order_card.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final menuProvider = context.watch<MenuProvider>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Administração',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                auth.logout();
              },
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            tabs: [
              Tab(text: 'Resumo'),
              Tab(text: 'Histórico Pedidos'),
              Tab(text: 'Mesas Finalizadas'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildDashboardTab(context, auth, orderProvider, menuProvider),
            _buildOrdersHistoryTab(context, orderProvider),
            _buildTablesFinalizedHistoryTab(context, orderProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardTab(
    BuildContext context,
    AuthProvider auth,
    OrderProvider orderProvider,
    MenuProvider menuProvider,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Total de Pedidos',
                  orderProvider.orders.length.toString(),
                  Icons.receipt_long,
                  AppColors.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Itens no Cardápio',
                  menuProvider.menuItems.length.toString(),
                  Icons.restaurant_menu,
                  AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Usuários',
                  auth.users.length.toString(),
                  Icons.people,
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Mesas',
                  orderProvider.tables.length.toString(),
                  Icons.table_bar,
                  AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Ações Rápidas',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            context,
            'Fazer Pedido para uma Mesa',
            'Selecione a mesa e crie um novo pedido',
            Icons.add_shopping_cart,
            AppColors.secondary,
            () => _openCreateOrderFlow(context, orderProvider),
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            context,
            'Pedidos Prontos na Cozinha',
            'Visualize e entregue pedidos finalizados',
            Icons.outbox,
            AppColors.success,
            () => _showReadyOrders(context, orderProvider),
          ),
          const SizedBox(height: 24),
          Text(
            'Pedidos por Status',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
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
            child: PieChart(
              PieChartData(
                sections: _buildPieChartSections(orderProvider),
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildFeatureCard(
            context,
            'Gerenciar Cardápio',
            'Adicionar, editar e remover pratos',
            Icons.restaurant_menu,
            AppColors.warning,
            () => _showComingSoon(context, 'Gerenciamento de Cardápio'),
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            context,
            'Gerenciar Usuários',
            'Adicionar garçons, cozinheiros e administradores',
            Icons.people,
            AppColors.success,
            () => _showComingSoon(context, 'Gerenciamento de Usuários'),
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            context,
            'Relatórios Detalhados',
            'Pratos mais pedidos, tempo médio e estatísticas',
            Icons.analytics,
            AppColors.info,
            () => _showComingSoon(context, 'Relatórios Detalhados'),
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            context,
            'Configurações',
            'Gerenciar mesas, integrações e configurações gerais',
            Icons.settings,
            AppColors.accent,
            () => _showComingSoon(context, 'Configurações'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersHistoryTab(
    BuildContext context,
    OrderProvider orderProvider,
  ) {
    final orders = [...orderProvider.orders]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (orders.isEmpty) {
      return Center(
        child: Text(
          'Nenhum pedido no histórico',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    final createdFormat = DateFormat('dd/MM/yyyy HH:mm');
    final shortFormat = DateFormat('dd/MM HH:mm');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final started = order.startedAt != null
            ? shortFormat.format(order.startedAt!)
            : '—';
        final finished = order.finishedAt != null
            ? shortFormat.format(order.finishedAt!)
            : '—';

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
                        borderRadius: BorderRadius.circular(6),
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
                      createdFormat.format(order.createdAt),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Mesa ${order.tableNumber}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Garçom: ${order.waiterName}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Cozinha: em preparo $started • finalizado $finished',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTablesFinalizedHistoryTab(
    BuildContext context,
    OrderProvider orderProvider,
  ) {
    final events = [...orderProvider.tableFinalizationHistory]
      ..sort((a, b) => b.finalizedAt.compareTo(a.finalizedAt));

    if (events.isEmpty) {
      return Center(
        child: Text(
          'Nenhuma mesa finalizada no histórico',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.table_bar, color: AppColors.secondary),
            title: Text('Mesa ${event.tableNumber} finalizada'),
            subtitle: Text(dateFormat.format(event.finalizedAt)),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(
    OrderProvider orderProvider,
  ) {
    final received = orderProvider.orders
        .where((o) => o.status == OrderStatus.received)
        .length;
    final preparing = orderProvider.orders
        .where((o) => o.status == OrderStatus.preparing)
        .length;
    final finished = orderProvider.orders
        .where((o) => o.status == OrderStatus.finished)
        .length;
    final delivered = orderProvider.orders
        .where((o) => o.status == OrderStatus.delivered)
        .length;

    final total = received + preparing + finished + delivered;
    if (total == 0) {
      return [
        PieChartSectionData(
          color: AppColors.textSecondary.withValues(alpha: 0.3),
          value: 1,
          title: 'Sem dados',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ];
    }

    return [
      if (received > 0)
        PieChartSectionData(
          color: AppColors.info,
          value: received.toDouble(),
          title: received.toString(),
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      if (preparing > 0)
        PieChartSectionData(
          color: AppColors.warning,
          value: preparing.toDouble(),
          title: preparing.toString(),
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      if (finished > 0)
        PieChartSectionData(
          color: AppColors.success,
          value: finished.toDouble(),
          title: finished.toString(),
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      if (delivered > 0)
        PieChartSectionData(
          color: AppColors.accent,
          value: delivered.toDouble(),
          title: delivered.toString(),
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
    ];
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.rocket_launch, color: AppColors.secondary),
            const SizedBox(width: 12),
            const Text('Em Desenvolvimento'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              feature,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Esta funcionalidade está em desenvolvimento e estará disponível em breve!',
                style: TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _openCreateOrderFlow(BuildContext context, OrderProvider orderProvider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SizedBox(
          height: 420,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Selecione a Mesa',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: orderProvider.tables.length,
                  itemBuilder: (context, index) {
                    final table = orderProvider.tables[index];
                    final isOccupied = table.status == TableStatus.occupied;
                    return InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TableOrderScreen(table: table),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
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
                          border: Border.all(
                            color: isOccupied
                                ? AppColors.warning
                                : AppColors.success,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.table_bar,
                                color: isOccupied
                                    ? AppColors.warning
                                    : AppColors.success,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Mesa ${table.number}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReadyOrders(BuildContext context, OrderProvider orderProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Consumer<OrderProvider>(
              builder: (context, provider, _) {
                final ready = provider.activeOrders
                    .where((o) => o.status == OrderStatus.finished)
                    .toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pedidos Prontos',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ready.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.outbox,
                                    size: 48,
                                    color: AppColors.textSecondary.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text('Nenhum pedido pronto no momento'),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: ready.length,
                              itemBuilder: (context, index) {
                                final order = ready[index];
                                return OrderCard(
                                  order: order,
                                  showDeliverActionWhenFinished: true,
                                  onStatusChange: (newStatus) async {
                                    await provider.updateOrderStatus(
                                      order.id,
                                      newStatus,
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Pedido marcado como entregue',
                                          ),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
