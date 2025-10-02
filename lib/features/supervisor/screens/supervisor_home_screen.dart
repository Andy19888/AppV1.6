import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/task_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/models/task_model.dart';
import '../../../core/models/authorization_request_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../location/screens/authorization_requests_screen.dart';
import '../widgets/task_review_card.dart';
import '../widgets/stats_card.dart';
import '../screens/task_review_detail_screen.dart';

class SupervisorHomeScreen extends ConsumerStatefulWidget {
  const SupervisorHomeScreen({super.key});

  @override
  ConsumerState<SupervisorHomeScreen> createState() => _SupervisorHomeScreenState();
}

class _SupervisorHomeScreenState extends ConsumerState<SupervisorHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);
    
    return currentUserAsync.when(
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('RepoCheck - Supervisor'),
            actions: [
              // Authorization requests badge
              StreamBuilder<List<AuthorizationRequestModel>>(
                stream: ref.read(locationServiceProvider).getPendingRequests(),
                builder: (context, snapshot) {
                  final pendingCount = snapshot.data?.length ?? 0;
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.person_add),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AuthorizationRequestsScreen(),
                            ),
                          );
                        },
                      ),
                      if (pendingCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: AppTheme.errorColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '$pendingCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  final authService = ref.read(authServiceProvider);
                  await authService.signOut();
                },
              ),
            ],
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              _DashboardTab(user: user, onNavigate: (index) => setState(() => _selectedIndex = index)),
              _TasksTab(user: user),
              _ReportsTab(user: user),
              _ProfileTab(user: user),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment),
                label: 'Tareas',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.analytics),
                label: 'Reportes',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Perfil',
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _DashboardTab extends ConsumerWidget {
  final user;
  final ValueChanged<int> onNavigate;
  
  const _DashboardTab({required this.user, required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome message
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 25,
                    backgroundColor: AppTheme.primaryColor,
                    child: Icon(
                      Icons.supervisor_account,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hola, ${user.name}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Supervisor',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Stats cards
          const Text(
            'Resumen de Actividad',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          const Row(
            children: [
              Expanded(
                child: StatsCard(
                  title: 'Tareas Pendientes',
                  value: '12',
                  icon: Icons.pending_actions,
                  color: AppTheme.warningColor,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: StatsCard(
                  title: 'Completadas Hoy',
                  value: '8',
                  icon: Icons.check_circle,
                  color: AppTheme.secondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          const Row(
            children: [
              Expanded(
                child: StatsCard(
                  title: 'En Revisión',
                  value: '5',
                  icon: Icons.rate_review,
                  color: Colors.orange,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: StatsCard(
                  title: 'Repositores Activos',
                  value: '15',
                  icon: Icons.people,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recent activity
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Actividad Reciente',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => onNavigate(1),
                child: const Text('Ver todas'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Recent tasks list
          _RecentTasksList(),
        ],
      ),
    );
  }
}

class _TasksTab extends ConsumerStatefulWidget {
  final user;
  
  const _TasksTab({required this.user});

  @override
  ConsumerState<_TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends ConsumerState<_TasksTab> {
  String _selectedFilter = 'all';
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter chips
        Container(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Todas',
                  value: 'all',
                  selectedValue: _selectedFilter,
                  onSelected: (value) => setState(() => _selectedFilter = value),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Pendientes',
                  value: 'pending',
                  selectedValue: _selectedFilter,
                  onSelected: (value) => setState(() => _selectedFilter = value),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'En Progreso',
                  value: 'inProgress',
                  selectedValue: _selectedFilter,
                  onSelected: (value) => setState(() => _selectedFilter = value),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Completadas',
                  value: 'completed',
                  selectedValue: _selectedFilter,
                  onSelected: (value) => setState(() => _selectedFilter = value),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Para Revisar',
                  value: 'review',
                  selectedValue: _selectedFilter,
                  onSelected: (value) => setState(() => _selectedFilter = value),
                ),
              ],
            ),
          ),
        ),
        
        // Tasks list
        Expanded(
          child: _TasksList(filter: _selectedFilter),
        ),
      ],
    );
  }
}

class _ReportsTab extends ConsumerWidget {
  final user;
  
  const _ReportsTab({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reportes y Análisis',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Report cards
          _ReportCard(
            title: 'Reporte Diario',
            subtitle: 'Actividad del día actual',
            icon: Icons.today,
            onTap: () => _generateDailyReport(context),
          ),
          const SizedBox(height: 12),
          
          _ReportCard(
            title: 'Reporte Semanal',
            subtitle: 'Resumen de la semana',
            icon: Icons.date_range,
            onTap: () => _generateWeeklyReport(context),
          ),
          const SizedBox(height: 12),
          
          _ReportCard(
            title: 'Reporte Mensual',
            subtitle: 'Análisis mensual completo',
            icon: Icons.calendar_month,
            onTap: () => _generateMonthlyReport(context),
          ),
          const SizedBox(height: 12),
          
          _ReportCard(
            title: 'Rendimiento por Repositor',
            subtitle: 'Estadísticas individuales',
            icon: Icons.person_search,
            onTap: () => _showRepositorPerformance(context),
          ),
          const SizedBox(height: 12),
          
          _ReportCard(
            title: 'Análisis por Ubicación',
            subtitle: 'Rendimiento por sucursal',
            icon: Icons.location_on,
            onTap: () => _showLocationAnalysis(context),
          ),
          const SizedBox(height: 24),

          // Export options
          const Text(
            'Exportar Datos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _exportToExcel(context),
                  icon: const Icon(Icons.table_chart),
                  label: const Text('Exportar a Excel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _exportToPDF(context),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Exportar a PDF'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _generateDailyReport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generando reporte diario...')),
    );
  }

  void _generateWeeklyReport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generando reporte semanal...')),
    );
  }

  void _generateMonthlyReport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generando reporte mensual...')),
    );
  }

  void _showRepositorPerformance(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mostrando rendimiento por repositor...')),
    );
  }

  void _showLocationAnalysis(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mostrando análisis por ubicación...')),
    );
  }

  void _exportToExcel(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exportando a Excel...')),
    );
  }

  void _exportToPDF(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exportando a PDF...')),
    );
  }
}

class _ProfileTab extends ConsumerWidget {
  final user;
  
  const _ProfileTab({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.primaryColor,
                    child: Icon(
                      Icons.supervisor_account,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          user.email,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Supervisor',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Menu options
          _MenuOption(
            icon: Icons.person_add,
            title: 'Solicitudes de autorización',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AuthorizationRequestsScreen(),
                ),
              );
            },
          ),
          _MenuOption(
            icon: Icons.notifications,
            title: 'Notificaciones',
            onTap: () => _showNotificationsDialog(context),
          ),
          _MenuOption(
            icon: Icons.settings,
            title: 'Configuración',
            onTap: () => _showSettingsDialog(context),
          ),
          _MenuOption(
            icon: Icons.help_outline,
            title: 'Ayuda',
            onTap: () => _showHelpDialog(context),
          ),
          _MenuOption(
            icon: Icons.info_outline,
            title: 'Acerca de',
            onTap: () => _showAboutDialog(context),
          ),
          const SizedBox(height: 32),
          
          // Logout button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final authService = ref.read(authServiceProvider);
                await authService.signOut();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
                side: const BorderSide(color: AppTheme.errorColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notificaciones'),
        content: const Text('Configuración de notificaciones no implementada aún.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuración'),
        content: const Text('Panel de configuración no implementado aún.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ayuda'),
        content: const Text(
          'Como supervisor puedes:\n\n'
          '• Autorizar repositores para trabajar en sucursales\n'
          '• Revisar y aprobar tareas completadas\n'
          '• Generar reportes de actividad\n'
          '• Monitorear el rendimiento del equipo\n\n'
          'Si necesitas ayuda adicional, contacta al administrador.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'RepoCheck',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.inventory_2_outlined,
        size: 48,
        color: AppTheme.primaryColor,
      ),
      children: const [
        Text('Control de reposición tercerizada'),
      ],
    );
  }
}

class _RecentTasksList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This would normally fetch recent tasks from the service
    // For now, showing placeholder
    return Column(
      children: [
        _RecentTaskItem(
          title: 'Reposición Coca-Cola',
          repositor: 'Juan Pérez',
          status: TaskStatus.completed,
          time: '2 horas',
        ),
        _RecentTaskItem(
          title: 'Reposición Pepsi',
          repositor: 'María García',
          status: TaskStatus.inProgress,
          time: '30 min',
        ),
        _RecentTaskItem(
          title: 'Reposición Snacks',
          repositor: 'Carlos López',
          status: TaskStatus.approved,
          time: '1 hora',
        ),
      ],
    );
  }
}

class _RecentTaskItem extends StatelessWidget {
  final String title;
  final String repositor;
  final TaskStatus status;
  final String time;
  
  const _RecentTaskItem({
    required this.title,
    required this.repositor,
    required this.status,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(status).withOpacity(0.1),
          child: Icon(
            _getStatusIcon(status),
            color: _getStatusColor(status),
            size: 20,
          ),
        ),
        title: Text(title),
        subtitle: Text('Por $repositor • hace $time'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getStatusText(status),
            style: TextStyle(
              color: _getStatusColor(status),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return AppTheme.warningColor;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.completed:
        return Colors.orange;
      case TaskStatus.approved:
        return AppTheme.secondaryColor;
      case TaskStatus.rejected:
        return AppTheme.errorColor;
    }
  }

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Icons.pending;
      case TaskStatus.inProgress:
        return Icons.play_arrow;
      case TaskStatus.completed:
        return Icons.done;
      case TaskStatus.approved:
        return Icons.check_circle;
      case TaskStatus.rejected:
        return Icons.cancel;
    }
  }

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'Pendiente';
      case TaskStatus.inProgress:
        return 'En progreso';
      case TaskStatus.completed:
        return 'Completada';
      case TaskStatus.approved:
        return 'Aprobada';
      case TaskStatus.rejected:
        return 'Rechazada';
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String selectedValue;
  final ValueChanged<String> onSelected;
  
  const _FilterChip({
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selectedValue;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
      backgroundColor: isSelected ? AppTheme.primaryColor : null,
      selectedColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : null,
      ),
    );
  }
}

class _TasksList extends ConsumerWidget {
  final String filter;
  
  const _TasksList({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This would normally filter tasks based on the selected filter
    // For now, showing placeholder tasks
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 10,
      itemBuilder: (context, index) {
        // Placeholder task data
        final task = TaskModel(
          id: 'task_$index',
          sucursalId: 'sucursal_1',
          title: 'Reposición ${index % 3 == 0 ? 'Coca-Cola' : index % 3 == 1 ? 'Pepsi' : 'Snacks'}',
          description: 'Descripción de la tarea $index',
          status: TaskStatus.values[index % TaskStatus.values.length],
          createdAt: DateTime.now().subtract(Duration(hours: index)),
          repositorId: 'repositor_${index % 3}',
        );
        
        return TaskReviewCard(
          task: task,
          onTap: () => _navigateToTaskDetail(context, task),
        );
      },
    );
  }

  void _navigateToTaskDetail(BuildContext context, TaskModel task) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TaskReviewDetailScreen(task: task),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  
  const _ReportCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
          ),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _MenuOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  
  const _MenuOption({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
