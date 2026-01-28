import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_iot_app/models/device.dart';
import 'package:campus_iot_app/providers/device_provider.dart';
import 'package:campus_iot_app/config/constants.dart';

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({Key? key}) : super(key: key);

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _deviceIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _buildingController = TextEditingController();
  final _floorController = TextEditingController();
  
  // Multi-select support
  final List<String> _selectedTypes = [];
  String _selectedProtocol = Protocols.mqtt;
  bool _isLoading = false;
  
  @override
  void dispose() {
    _deviceIdController.dispose();
    _nameController.dispose();
    _locationController.dispose();
    _buildingController.dispose();
    _floorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filter out 'multi-sensor' from selection options, we construct it dynamically
    final availableTypes = DeviceTypes.all.where((t) => t != DeviceTypes.multi).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Dispositivo'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!, width: 1),
              ),
              child: Row(
                children: [
                   Icon(Icons.info_outline, color: Colors.blue[700], size: 28),
                   const SizedBox(width: 12),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           'Nuevo Dispositivo IoT',
                           style: TextStyle(
                             fontWeight: FontWeight.bold,
                             fontSize: 16,
                             color: Colors.blue[900],
                           ),
                         ),
                         const SizedBox(height: 4),
                         Text(
                           'Selecciona uno o varios sensores para este dispositivo.',
                           style: TextStyle(
                             fontSize: 13,
                             color: Colors.blue[700],
                             height: 1.3,
                           ),
                         ),
                       ],
                     ),
                   ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Device ID
            TextFormField(
              controller: _deviceIdController,
              decoration: const InputDecoration(
                labelText: 'ID del Dispositivo *',
                hintText: 'lab-01-multi',
                helperText: 'Identificador único',
                prefixIcon: Icon(Icons.fingerprint),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'El ID es obligatorio';
                if (value.length < 3) return 'Mínimo 3 caracteres';
                if (!RegExp(r'^[a-zA-Z0-9-]+$').hasMatch(value)) {
                  return 'Solo letras, números y guiones';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Dispositivo *',
                hintText: 'Sensor Ambiental Lab 1',
                prefixIcon: Icon(Icons.label),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'El nombre es obligatorio';
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Sensor Types Selection (Multi-Select)
            const Text(
              'Sensores Integrados *',
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
                        Icon(_getTypeIcon(type), size: 20, color: Colors.grey[700]),
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
                  'Selecciona al menos un tipo de sensor',
                  style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Location
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Ubicación (Opcional)',
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Building
            TextFormField(
              controller: _buildingController,
              decoration: const InputDecoration(
                labelText: 'Edificio (Opcional)',
                prefixIcon: Icon(Icons.business),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Floor
            TextFormField(
              controller: _floorController,
              decoration: const InputDecoration(
                labelText: 'Piso (Opcional)',
                prefixIcon: Icon(Icons.stairs),
              ),
              keyboardType: TextInputType.number,
            ),
            
            const SizedBox(height: 16),
            
            // Protocol
            DropdownButtonFormField<String>(
              value: _selectedProtocol,
              decoration: const InputDecoration(
                labelText: 'Protocolo *',
                prefixIcon: Icon(Icons.settings_input_antenna),
              ),
              items: Protocols.all.map((protocol) {
                return DropdownMenuItem(
                  value: protocol,
                  child: Text(protocol),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedProtocol = value!;
                });
              },
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
                  : const Text('Agregar Dispositivo'),
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
    
    if (_selectedTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes seleccionar al menos un sensor'), backgroundColor: Colors.red),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    // Determine type: specific if 1, multi if > 1
    final String primaryType = _selectedTypes.length == 1 
        ? _selectedTypes.first 
        : DeviceTypes.multi;
        
    final device = Device(
      deviceId: _deviceIdController.text.trim(),
      name: _nameController.text.trim(),
      type: primaryType,
      location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
      building: _buildingController.text.trim().isNotEmpty ? _buildingController.text.trim() : null,
      floor: _floorController.text.trim().isNotEmpty ? int.tryParse(_floorController.text.trim()) : null,
      protocol: _selectedProtocol,
      status: 'active',
      metadata: {
        'sensors': _selectedTypes // Store all selected sensors here
      },
    );
    
    try {
      final success = await context.read<DeviceProvider>().createDevice(device);
      
      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dispositivo agregado exitosamente'), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.read<DeviceProvider>().error ?? 'Error al agregar dispositivo'),
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
      case DeviceTypes.temperature: return Icons.thermostat_outlined;
      case DeviceTypes.occupancy: return Icons.people_alt;
      case DeviceTypes.humidity: return Icons.water_drop;
      case DeviceTypes.light: return Icons.wb_incandescent;
      case DeviceTypes.energy: return Icons.flash_on;
      default: return Icons.device_unknown;
    }
  }
}
