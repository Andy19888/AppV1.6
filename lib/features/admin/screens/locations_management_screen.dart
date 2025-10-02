import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/models/location_model.dart';
import '../../../core/theme/app_theme.dart';

class LocationsManagementScreen extends ConsumerStatefulWidget {
  const LocationsManagementScreen({super.key});

  @override
  ConsumerState<LocationsManagementScreen> createState() => _LocationsManagementScreenState();
}

class _LocationsManagementScreenState extends ConsumerState<LocationsManagementScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(allLocationsProvider);
    
    return Column(
      children: [
        // Search bar and add button
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Buscar ubicaciones...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              const SizedBox(width: 12),
              FloatingActionButton(
                onPressed: () => _showAddLocationDialog(context),
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        
        // Locations list
        Expanded(
          child: locationsAsync.when(
            data: (locations) {
              final filteredLocations = locations.where((location) {
                final searchLower = _searchQuery.toLowerCase();
                return (location.provincia ?? '').toLowerCase().contains(searchLower) ||
                       (location.localidad ?? '').toLowerCase().contains(searchLower) ||
                       (location.cadena ?? '').toLowerCase().contains(searchLower) ||
                       (location.sucursal ?? '').toLowerCase().contains(searchLower);
              }).toList();
              
              if (filteredLocations.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No se encontraron ubicaciones',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredLocations.length,
                itemBuilder: (context, index) {
                  final location = filteredLocations[index];
                  return _LocationCard(location: location);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          ),
        ),
      ],
    );
  }

  void _showAddLocationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _AddLocationDialog(),
    );
  }
}

class _LocationCard extends ConsumerWidget {
  final LocationModel location;
  
  const _LocationCard({required this.location});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    location.sucursal ?? location.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: AppTheme.errorColor),
                          SizedBox(width: 8),
                          Text('Eliminar'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditLocationDialog(context, location);
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(context, ref, location);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Location details
            _DetailRow(icon: Icons.map, label: 'Provincia', value: location.provincia ?? ''),
            _DetailRow(icon: Icons.location_city, label: 'Localidad', value: location.localidad ?? ''),
            _DetailRow(icon: Icons.store, label: 'Cadena', value: location.cadena ?? ''),
          ],
        ),
      ),
    );
  }

  void _showEditLocationDialog(BuildContext context, LocationModel location) {
    showDialog(
      context: context,
      builder: (context) => _EditLocationDialog(location: location),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, LocationModel location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Ubicación'),
        content: Text('¿Estás seguro de que quieres eliminar ${location.sucursal ?? location.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final adminService = ref.read(adminServiceProvider);
                await adminService.deleteLocation(location.sucursalId ?? '');
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ubicación eliminada')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _AddLocationDialog extends ConsumerStatefulWidget {
  const _AddLocationDialog();

  @override
  ConsumerState<_AddLocationDialog> createState() => _AddLocationDialogState();
}

class _AddLocationDialogState extends ConsumerState<_AddLocationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _provinciaController = TextEditingController();
  final _localidadController = TextEditingController();
  final _cadenaController = TextEditingController();
  final _sucursalController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _provinciaController.dispose();
    _localidadController.dispose();
    _cadenaController.dispose();
    _sucursalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar Ubicación'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _provinciaController,
              decoration: const InputDecoration(labelText: 'Provincia'),
              validator: (value) => value?.isEmpty == true ? 'Campo requerido' : null,
            ),
            TextFormField(
              controller: _localidadController,
              decoration: const InputDecoration(labelText: 'Localidad'),
              validator: (value) => value?.isEmpty == true ? 'Campo requerido' : null,
            ),
            TextFormField(
              controller: _cadenaController,
              decoration: const InputDecoration(labelText: 'Cadena'),
              validator: (value) => value?.isEmpty == true ? 'Campo requerido' : null,
            ),
            TextFormField(
              controller: _sucursalController,
              decoration: const InputDecoration(labelText: 'Sucursal'),
              validator: (value) => value?.isEmpty == true ? 'Campo requerido' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addLocation,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Agregar'),
        ),
      ],
    );
  }

  Future<void> _addLocation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final location = LocationModel(
        id: '', // Will be set by Firestore
        name: _sucursalController.text,
        provincia: _provinciaController.text,
        localidad: _localidadController.text,
        cadena: _cadenaController.text,
        sucursal: _sucursalController.text,
        sucursalId: '', // Will be set by Firestore
      );

      final adminService = ref.read(adminServiceProvider);
      await adminService.addLocation(location);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ubicación agregada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _EditLocationDialog extends ConsumerStatefulWidget {
  final LocationModel location;
  
  const _EditLocationDialog({required this.location});

  @override
  ConsumerState<_EditLocationDialog> createState() => _EditLocationDialogState();
}

class _EditLocationDialogState extends ConsumerState<_EditLocationDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _provinciaController;
  late final TextEditingController _localidadController;
  late final TextEditingController _cadenaController;
  late final TextEditingController _sucursalController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _provinciaController = TextEditingController(text: widget.location.provincia ?? '');
    _localidadController = TextEditingController(text: widget.location.localidad ?? '');
    _cadenaController = TextEditingController(text: widget.location.cadena ?? '');
    _sucursalController = TextEditingController(text: widget.location.sucursal ?? widget.location.name);
  }

  @override
  void dispose() {
    _provinciaController.dispose();
    _localidadController.dispose();
    _cadenaController.dispose();
    _sucursalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Ubicación'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _provinciaController,
              decoration: const InputDecoration(labelText: 'Provincia'),
              validator: (value) => value?.isEmpty == true ? 'Campo requerido' : null,
            ),
            TextFormField(
              controller: _localidadController,
              decoration: const InputDecoration(labelText: 'Localidad'),
              validator: (value) => value?.isEmpty == true ? 'Campo requerido' : null,
            ),
            TextFormField(
              controller: _cadenaController,
              decoration: const InputDecoration(labelText: 'Cadena'),
              validator: (value) => value?.isEmpty == true ? 'Campo requerido' : null,
            ),
            TextFormField(
              controller: _sucursalController,
              decoration: const InputDecoration(labelText: 'Sucursal'),
              validator: (value) => value?.isEmpty == true ? 'Campo requerido' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateLocation,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }

  Future<void> _updateLocation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedLocation = LocationModel(
        id: widget.location.id,
        name: _sucursalController.text,
        provincia: _provinciaController.text,
        localidad: _localidadController.text,
        cadena: _cadenaController.text,
        sucursal: _sucursalController.text,
        sucursalId: widget.location.sucursalId,
      );

      final adminService = ref.read(adminServiceProvider);
      await adminService.updateLocation(updatedLocation);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ubicación actualizada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
