import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatbotSettingsScreen extends StatefulWidget {
  const ChatbotSettingsScreen({super.key});

  @override
  State<ChatbotSettingsScreen> createState() => _ChatbotSettingsScreenState();
}

class _ChatbotSettingsScreenState extends State<ChatbotSettingsScreen> {
  // Variables para las configuraciones
  bool _notificationsEnabled = true;
  bool _soundsEnabled = true;
  bool _vibrationEnabled = true;

  // Clave para SharedPreferences
  static const String _notificationsKey = 'chatbot_notifications_enabled';
  static const String _soundsKey = 'chatbot_sounds_enabled';
  static const String _vibrationKey = 'chatbot_vibration_enabled';

  @override
  void initState() {
    super.initState();
    // Cargar configuraciones guardadas al iniciar
    _loadSettings();
  }

  // Cargar configuraciones desde SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
        _soundsEnabled = prefs.getBool(_soundsKey) ?? true;
        _vibrationEnabled = prefs.getBool(_vibrationKey) ?? true;
      });
      
      print(' Configuraciones cargadas:');
      print('   Notificaciones: $_notificationsEnabled');
      print('   Sonidos: $_soundsEnabled');
      print('   Vibración: $_vibrationEnabled');
    } catch (e) {
      print(' Error cargando configuraciones: $e');
    }
  }

  // Guardar configuración individual
  Future<void> _saveSetting(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
      print(' Configuración guardada: $key = $value');
    } catch (e) {
      print(' Error guardando configuración: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Configuración del ChatBot',
          style: TextStyle(
            fontSize: 20,
            color: Color.fromARGB(255, 255, 255, 255),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF6B2E9C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            const Text(
              '',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),

            // Sección 1: Notificaciones
            _buildSectionTitle('Notificaciones'),
            const SizedBox(height: 16),
            
            _buildToggleOption(
              title: 'Enviar notificaciones',
              subtitle: 'Recibe notificaciones de nuevas respuestas',
              value: _notificationsEnabled,
              onChanged: (value) async {
                setState(() {
                  _notificationsEnabled = value;
                });
                await _saveSetting(_notificationsKey, value);
                _showSnackbar('Notificaciones ${value ? 'activadas' : 'desactivadas'}');
              },
              icon: Icons.notifications,
            ),
            
            const SizedBox(height: 12),
            
            if (_notificationsEnabled) ...[
              _buildToggleOption(
                title: 'Sonidos',
                subtitle: 'Reproducir sonidos con las respuestas',
                value: _soundsEnabled,
                onChanged: (value) async {
                  setState(() {
                    _soundsEnabled = value;
                  });
                  await _saveSetting(_soundsKey, value);
                  _showSnackbar('Sonidos ${value ? 'activados' : 'desactivados'}');
                },
                icon: Icons.volume_up,
              ),
              
              const SizedBox(height: 12),
              
              _buildToggleOption(
                title: 'Vibrar con respuestas',
                subtitle: 'Vibración al recibir nuevas respuestas',
                value: _vibrationEnabled,
                onChanged: (value) async {
                  setState(() {
                    _vibrationEnabled = value;
                  });
                  await _saveSetting(_vibrationKey, value);
                  _showSnackbar('Vibración ${value ? 'activada' : 'desactivada'}');
                },
                icon: Icons.vibration,
              ),
            ],

            const Divider(height: 40, thickness: 1),
            
            
            Container(
              alignment: Alignment.center,
              margin: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(60),
                      border: Border.all(
                        color: const Color(0xFF6B2E9C).withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      child: Image.asset(
                        'assets/images/start.png',
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: const Color(0xFF6B2E9C).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(40),
                              ),
                              child: const Icon(
                                Icons.settings,
                                color: Color(0xFF6B2E9C),
                                size: 40,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Brawl Starts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B2E9C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'SUPERCELL',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Botón de guardar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B2E9C),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'GUARDAR CONFIGURACIÓN',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Versión
            Center(
              child: Text(
                'Versión 1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Botón para restablecer configuraciones
            Center(
              child: TextButton(
                onPressed: _resetSettings,
                child: const Text(
                  'Restablecer configuraciones predeterminadas',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // ELIMINADO EL MENÚ INFERIOR
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF6B2E9C),
      ),
    );
  }

  Widget _buildToggleOption({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF6B2E9C).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF6B2E9C),
              size: 24,
            ),
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
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF6B2E9C),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF6B2E9C),
      ),
    );
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationsKey, _notificationsEnabled);
      await prefs.setBool(_soundsKey, _soundsEnabled);
      await prefs.setBool(_vibrationKey, _vibrationEnabled);
      
      _showSnackbar(' Configuración guardada correctamente');
      print(' Todas las configuraciones guardadas');
    } catch (e) {
      _showSnackbar(' Error al guardar la configuración');
      print(' Error guardando todas las configuraciones: $e');
    }
  }

  Future<void> _resetSettings() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restablecer configuraciones'),
        content: const Text('¿Estás seguro de que quieres restablecer todas las configuraciones a sus valores predeterminados?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _resetToDefaults();
            },
            child: const Text(
              'Restablecer',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetToDefaults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_notificationsKey);
      await prefs.remove(_soundsKey);
      await prefs.remove(_vibrationKey);
      
      setState(() {
        _notificationsEnabled = true;
        _soundsEnabled = true;
        _vibrationEnabled = true;
      });
        
      _showSnackbar(' Configuraciones restablecidas a predeterminados');
      print(' Configuraciones restablecidas a valores predeterminados');
    } catch (e) {
      _showSnackbar(' Error al restablecer configuraciones');
      print(' Error restableciendo configuraciones: $e');
    }
  }
}