import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_iot_app/models/device.dart';
import 'package:campus_iot_app/providers/device_provider.dart';
import 'package:campus_iot_app/config/constants.dart';
import 'package:campus_iot_app/config/theme.dart'; // Ensure this is imported for AppColors

class EditDeviceScreen extends StatefulWidget {
  final Device device;

  const EditDeviceScreen({Key? key, required this.device}) : super(key: key);

  @override
  State<EditDeviceScreen> createState() => _EditDeviceScreenState();
}

class _EditDeviceScreenState extends State<EditDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _buildingController;
  late TextEditingController _floorController;

  late String _selectedStatus;

  // Multi-select support for editing
  final List<String> _selectedTypes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.device.name);
    _locationController =
        TextEditingController(text: widget.device.location ?? '');
    _buildingController =
        TextEditingController(text: widget.device.building ?? '');
    _floorController =
        TextEditingController(text: widget.device.floor?.toString() ?? '');
    _selectedStatus = widget.device.status;

    // Initialize selected sensors safely
    print('DEBUG: Init Edit - Metadata: ${widget.device.metadata}');
    try {
      if (widget.device.metadata != null &&
          widget.device.metadata!.containsKey('sensors')) {
        final sensorsList = widget.device.metadata!['sensors'];
        if (sensorsList is List) {
          _selectedTypes.addAll(sensorsList.map((e) => e.toString()).toList());
        }
      } else {
        // Fallback
        if (widget.device.type != DeviceTypes.multi) {
          _selectedTypes.add(widget.device.type);
        }
      }
    } catch (e) {
      print('DEBUG: Error initializing sensors: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _buildingController.dispose();
    _floorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filter out 'multi-sensor' from selection options
    final availableTypes =
        DeviceTypes.all.where((t) => t != DeviceTypes.multi).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Dispositivo'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header Info
            Card(
              color: Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.fingerprint, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text('ID: ${widget.device.deviceId}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Dispositivo *',
                prefixIcon: Icon(Icons.label),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El nombre es obligatorio';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Sensor Types (Editable now!)
            const Text(
              'Sensores Activos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: availableTypes.map((type) {
                  return CheckboxListTile(
                    title: Row(
                      children: [
                        Icon(_getTypeIcon(type),
                            size: 20, color: Colors.grey[700]),
                        const SizedBox(width: 12),
                        Text(DeviceTypes.getDisplayName(type)),
                      ],
                    ),
                    value: _selectedTypes.contains(type),
                    onChanged: (bool? checked) {
                      setState(() {
                        if (checked == true) {
                          _selectedTypes.add(type);
                        } else {
                          _selectedTypes.remove(type);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            if (_selectedTypes.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                child: Text(
                  '⚠ Advertencia: Sin sensores, el dispositivo no generará datos.',
                  style: TextStyle(color: Colors.orange[800], fontSize: 12),
                ),
              ),

            const SizedBox(height: 16),

            // Status Toggle
            const Text('Estado', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ToggleButtons(
                borderRadius: BorderRadius.circular(8),
                fillColor: _selectedStatus == 'active'
                    ? AppColors.success.withOpacity(0.1)
                    : Colors.grey[200],
                selectedColor: _selectedStatus == 'active'
                    ? AppColors.success
                    : Colors.grey[800],
                color: Colors.grey[600],
                constraints: const BoxConstraints(minHeight: 48),
                isSelected: [
                  _selectedStatus == 'active',
                  _selectedStatus == 'inactive'
                ],
                onPressed: (index) {
                  setState(() {
                    _selectedStatus = index == 0 ? 'active' : 'inactive';
                  });
                },
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: const [
                        Icon(Icons.check_circle_outline, size: 20),
                        SizedBox(width: 8),
                        Text('ACTIVO'),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: const [
                        Icon(Icons.pause_circle_outline, size: 20),
                        SizedBox(width: 8),
                        Text('INACTIVO'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Location
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Ubicación',
                prefixIcon: Icon(Icons.location_on),
              ),
            ),

            const SizedBox(height: 16),

            // Building
            TextFormField(
              controller: _buildingController,
              decoration: const InputDecoration(
                labelText: 'Edificio',
                prefixIcon: Icon(Icons.business),
              ),
            ),

            const SizedBox(height: 16),

            // Floor
            TextFormField(
              controller: _floorController,
              decoration: const InputDecoration(
                labelText: 'Piso',
                prefixIcon: Icon(Icons.stairs),
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar Cambios'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Determine type: specific if 1, multi if > 1 (or 0)
    final String primaryType =
        _selectedTypes.length == 1 ? _selectedTypes.first : DeviceTypes.multi;

    // Explicitly construct metadata map
    Map<String, dynamic> newMetadata = {};
    if (widget.device.metadata != null) {
      newMetadata.addAll(widget.device.metadata!);
    }
    // Update sensors specifically
    newMetadata['sensors'] = _selectedTypes;

    print(
        'DEBUG: Submitting updates: Type=$primaryType, Metadata=$newMetadata');

    final updates = {
      'name': _nameController.text.trim(),
      'status': _selectedStatus,
      'type': primaryType,
      'location': _locationController.text.trim(),
      'building': _buildingController.text.trim(),
      'floor': _floorController.text.trim().isNotEmpty
          ? int.tryParse(_floorController.text.trim())
          : null,
      'metadata': newMetadata,
    };

    try {
      final success = await context
          .read<DeviceProvider>()
          .updateDevice(widget.device.deviceId, updates);

      if (mounted) {
        if (success) {
          Navigator.pop(context); // Close Update Screen
          // No need to double pop as DetailScreen handles reload

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dispositivo actualizado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al actualizar dispositivo'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case DeviceTypes.temperature:
        return Icons.thermostat_outlined;
      case DeviceTypes.occupancy:
        return Icons.people_alt;
      case DeviceTypes.humidity:
        return Icons.water_drop;
      case DeviceTypes.light:
        return Icons.wb_incandescent;
      case DeviceTypes.energy:
        return Icons.flash_on;
      default:
        return Icons.device_unknown;
    }
  }
}
