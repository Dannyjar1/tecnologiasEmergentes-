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
  
  String _selectedType = DeviceTypes.temperature;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Dispositivo'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header card with instructions
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
                          'Completa la información del dispositivo que deseas agregar al sistema',
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
              decoration: InputDecoration(
                labelText: 'ID del Dispositivo *',
                hintText: 'lab-01-temp',
                helperText: 'Identificador único para el dispositivo',
                prefixIcon: const Icon(Icons.fingerprint),
                suffixIcon: Tooltip(
                  message: 'Usa letras, números y guiones. Ejemplo: lab-01-temp',
                  child: Icon(Icons.help_outline, color: Colors.grey[400]),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El ID es obligatorio';
                }
                if (value.length < 3) {
                  return 'Mínimo 3 caracteres';
                }
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
              decoration: InputDecoration(
                labelText: 'Nombre del Dispositivo *',
                hintText: 'Sensor Temperatura Laboratorio 01',
                helperText: 'Nombre descriptivo para identificar el dispositivo',
                prefixIcon: const Icon(Icons.label),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El nombre es obligatorio';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Type Dropdown
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: 'Tipo de Dispositivo *',
                helperText: 'Selecciona qué medirá este dispositivo',
                prefixIcon: const Icon(Icons.category),
              ),
              items: DeviceTypes.all.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(_getTypeIcon(type), size: 20),
                      const SizedBox(width: 12),
                      Text(DeviceTypes.getDisplayName(type)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Location
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Ubicación (Opcional)',
                hintText: 'Laboratorio de Física',
                helperText: 'Lugar específico donde está el dispositivo',
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Building
            TextFormField(
              controller: _buildingController,
              decoration: const InputDecoration(
                labelText: 'Edificio (Opcional)',
                hintText: 'Edificio A',
                helperText: 'Nombre o código del edificio',
                prefixIcon: Icon(Icons.business),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Floor
            TextFormField(
              controller: _floorController,
              decoration: const InputDecoration(
                labelText: 'Piso (Opcional)',
                hintText: '2',
                helperText: 'Número del piso',
                prefixIcon: Icon(Icons.stairs),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final floor = int.tryParse(value);
                  if (floor == null) {
                    return 'Ingresa solo números';
                  }
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Protocol Dropdown
            DropdownButtonFormField<String>(
              value: _selectedProtocol,
              decoration: const InputDecoration(
                labelText: 'Protocolo de Comunicación *',
                helperText: 'Cómo se comunica el dispositivo',
                prefixIcon: Icon(Icons.settings_input_antenna),
              ),
              items: Protocols.all.map((protocol) {
                return DropdownMenuItem(
                  value: protocol,
                  child: Row(
                    children: [
                      Icon(_getProtocolIcon(protocol), size: 20),
                      const SizedBox(width: 12),
                      Text(protocol),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedProtocol = value!;
                });
              },
            ),
            
            const SizedBox(height: 32),
            
            // Info box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!, width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.amber[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Los campos marcados con * son obligatorios',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Submit Button
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
    
    setState(() {
      _isLoading = true;
    });
    
    final device = Device(
      deviceId: _deviceIdController.text.trim(),
      name: _nameController.text.trim(),
      type: _selectedType,
      location: _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : null,
      building: _buildingController.text.trim().isNotEmpty
          ? _buildingController.text.trim()
          : null,
      floor: _floorController.text.trim().isNotEmpty
          ? int.tryParse(_floorController.text.trim())
          : null,
      protocol: _selectedProtocol,
      status: 'active',
    );
    
    try {
      final success = await context.read<DeviceProvider>().createDevice(device);
      
      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dispositivo agregado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.read<DeviceProvider>().error ?? 
                'Error al agregar dispositivo'
              ),
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
        return Icons.thermostat;
      case DeviceTypes.occupancy:
        return Icons.people;
      case DeviceTypes.humidity:
        return Icons.water_drop;
      case DeviceTypes.light:
        return Icons.lightbulb;
      case DeviceTypes.energy:
        return Icons.bolt;
      default:
        return Icons.device_unknown;
    }
  }
  
  IconData _getProtocolIcon(String protocol) {
    switch (protocol.toLowerCase()) {
      case 'mqtt':
        return Icons.cloud_queue;
      case 'http':
        return Icons.http;
      default:
        return Icons.settings_input_antenna;
    }
  }
}
