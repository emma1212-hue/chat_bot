import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database/database_helper.dart';
import 'home_screen.dart'; 

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  
  const ProfileScreen({super.key, required this.userData});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  
  bool _notificationsEnabled = true;
  bool _languageEnabled = true;
  String _language = 'Español (Único disponible)';
  bool _themeEnabled = false;
  String _theme = 'Light mode';
  bool _isSaving = false;
  String? _selectedImagePath;
  
  // Claves para SharedPreferences
  static const String _profileNotificationsKey = 'profile_notifications_enabled';
  static const String _profileLanguageEnabledKey = 'profile_language_enabled';
  static const String _profileLanguageKey = 'profile_language';
  static const String _profileThemeEnabledKey = 'profile_theme_enabled';
  static const String _profileThemeKey = 'profile_theme';
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSettings();
  }
  
  void _loadUserData() {
    _nameController.text = widget.userData['name'] ?? 'Usuario';
    _emailController.text = widget.userData['email'] ?? '';
    _usernameController.text = widget.userData['username'] ?? 'usuario';
    _selectedImagePath = widget.userData['profile_image'] ?? 'assets/images/demon.png';
  }
  
  
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _notificationsEnabled = prefs.getBool(_profileNotificationsKey) ?? true;
        _languageEnabled = prefs.getBool(_profileLanguageEnabledKey) ?? true;
        _language = prefs.getString(_profileLanguageKey) ?? 'Español (Único disponible)';
        _themeEnabled = prefs.getBool(_profileThemeEnabledKey) ?? false;
        _theme = prefs.getString(_profileThemeKey) ?? 'Light mode';
      });
      
      print(' Preferencias de perfil cargadas:');
      print('   Notificaciones: $_notificationsEnabled');
      print('   Idioma habilitado: $_languageEnabled');
      print('   Idioma: $_language');
      print('   Tema habilitado: $_themeEnabled');
      print('   Tema: $_theme');
    } catch (e) {
      print(' Error cargando preferencias de perfil: $e');
    }
  }
  
  // Guardar configuración individual
  Future<void> _savePreference(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      }
      
      print(' Preferencia guardada: $key = $value');
    } catch (e) {
      print(' Error guardando preferencia: $e');
    }
  }
  
  // Guardar todas las preferencias
  Future<void> _saveAllPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool(_profileNotificationsKey, _notificationsEnabled);
      await prefs.setBool(_profileLanguageEnabledKey, _languageEnabled);
      await prefs.setString(_profileLanguageKey, _language);
      await prefs.setBool(_profileThemeEnabledKey, _themeEnabled);
      await prefs.setString(_profileThemeKey, _theme);
      
      print(' Todas las preferencias guardadas');
    } catch (e) {
      print(' Error guardando todas las preferencias: $e');
    }
  }
  
  // Restablecer preferencias a valores por defecto
  Future<void> _resetPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.remove(_profileNotificationsKey);
      await prefs.remove(_profileLanguageEnabledKey);
      await prefs.remove(_profileLanguageKey);
      await prefs.remove(_profileThemeEnabledKey);
      await prefs.remove(_profileThemeKey);
      
      setState(() {
        _notificationsEnabled = true;
        _languageEnabled = true;
        _language = 'Español (Único disponible)';
        _themeEnabled = false;
        _theme = 'Light mode';
      });
      
      print(' Preferencias restablecidas a valores predeterminados');
    } catch (e) {
      print(' Error restableciendo preferencias: $e');
    }
  }
  
  Future<void> _updateName() async {
    if (_nameController.text.isEmpty) {
      _showSnackbar('El nombre no puede estar vacío');
      return;
    }
    
    final userId = widget.userData['id'] as int;
    final success = await _dbHelper.updateUserName(userId, _nameController.text);
    
    if (success) {
      _showSnackbar(' Nombre actualizado');
    } else {
      _showSnackbar(' Error al actualizar el nombre');
    }
  }
  
  Future<void> _updateEmail() async {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      _showSnackbar('Ingresa un email válido');
      return;
    }
    
    final existingUser = await _dbHelper.getUserByEmail(_emailController.text);
    if (existingUser != null && existingUser['id'] != widget.userData['id']) {
      _showSnackbar(' Este email ya está registrado');
      return;
    }
    
    final userId = widget.userData['id'] as int;
    final success = await _dbHelper.updateUserEmail(userId, _emailController.text);
    
    if (success) {
      _showSnackbar(' Email actualizado');
    } else {
      _showSnackbar(' Error al actualizar el email');
    }
  }
  
  Future<void> _updateUsername() async {
    if (_usernameController.text.isEmpty) {
      _showSnackbar('El nombre de usuario no puede estar vacío');
      return;
    }
    
    if (_usernameController.text.length < 3) {
      _showSnackbar('El nombre de usuario debe tener al menos 3 caracteres');
      return;
    }
    
    final userId = widget.userData['id'] as int;
    
    try {
      // Verificar si el username ya está en uso por otro usuario
      final existingUser = await _dbHelper.getUserByUsername(_usernameController.text);
      if (existingUser != null && existingUser['id'] != userId) {
        _showSnackbar(' Este nombre de usuario ya está en uso');
        return;
      }
      
      final db = await _dbHelper.database;
      await db.update(
        'users',
        {'username': _usernameController.text},
        where: 'id = ?',
        whereArgs: [userId],
      );
      
      _showSnackbar(' Nombre de usuario actualizado');
    } catch (e) {
      print(' Error actualizando username: $e');
      _showSnackbar(' Error al actualizar el nombre de usuario');
    }
  }
  
  Future<void> _updateProfileImage() async {
    if (_selectedImagePath == null) return;
    
    final userId = widget.userData['id'] as int;
    try {
      final db = await _dbHelper.database;
      await db.update(
        'users',
        {'profile_image': _selectedImagePath},
        where: 'id = ?',
        whereArgs: [userId],
      );
      
      _showSnackbar(' Imagen de perfil actualizada');
    } catch (e) {
      print(' Error actualizando imagen de perfil: $e');
      _showSnackbar(' Error al actualizar la imagen de perfil');
    }
  }
  
  void _showImageSelectionDialog() {
    final List<String> availableImages = [
      'assets/images/demon.png',
      'assets/images/icon.png',
      'assets/images/kit.png',
      'assets/images/rico.png',
      'assets/images/bibi.png',
      'assets/images/max.png',
      'assets/images/toy.png',
      'assets/images/gus.png',
      'assets/images/ricoc.png',
      'assets/images/amarillo.png',
      
    ];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar imagen de perfil'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: availableImages.length,
            itemBuilder: (context, index) {
              final imagePath = availableImages[index];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedImagePath = imagePath;
                  });
                  Navigator.pop(context);
                  _updateProfileImage();
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedImagePath == imagePath 
                          ? const Color(0xFF6B2E9C) 
                          : Colors.transparent,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.person, size: 30),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Perfil',
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF6B2E9C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _goBackWithData(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con imagen de perfil
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _showImageSelectionDialog,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF6B2E9C),
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child: _buildProfileImage(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _showImageSelectionDialog,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Cambiar imagen'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF6B2E9C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.userData['name'] ?? 'Usuario',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '@${_usernameController.text}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    widget.userData['email'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            const Divider(thickness: 1),
            const SizedBox(height: 20),
            
            const Text(
              'Información Personal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B2E9C),
              ),
            ),
            const SizedBox(height: 16),
            
            _buildEditableField(
              title: 'Nombre',
              value: _nameController,
              onSave: _updateName,
              icon: Icons.person_outline,
            ),
            
            const SizedBox(height: 12),
            
            _buildEditableField(
              title: 'Nombre de usuario',
              value: _usernameController,
              onSave: _updateUsername,
              icon: Icons.alternate_email,
            ),
            
            const SizedBox(height: 12),
            
            _buildEditableField(
              title: 'Correo electrónico',
              value: _emailController,
              onSave: _updateEmail,
              icon: Icons.email_outlined,
            ),
            
            const SizedBox(height: 30),
            const Divider(thickness: 1),
            const SizedBox(height: 20),
            
            const Text(
              'Preferencias',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B2E9C),
              ),
            ),
            const SizedBox(height: 16),
            
            _buildPreferenceOption(
              title: 'Notificaciones',
              value: _notificationsEnabled,
              onChanged: (value) async {
                setState(() {
                  _notificationsEnabled = value;
                });
                await _savePreference(_profileNotificationsKey, value);
                _showSnackbar('Notificaciones ${value ? 'activadas' : 'desactivadas'}');
              },
              icon: Icons.notifications_outlined,
            ),
            
            const SizedBox(height: 12),
            
            _buildPreferenceOption(
              title: 'Idioma',
              value: _languageEnabled,
              onChanged: (value) async {
                setState(() {
                  _languageEnabled = value;
                });
                await _savePreference(_profileLanguageEnabledKey, value);
                _showSnackbar('Idioma ${value ? 'activado' : 'desactivado'}');
              },
              icon: Icons.language_outlined,
            ),
            
            if (_languageEnabled) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 40),
                    Expanded(
                      child: Text(
                        _language,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18, color: Color(0xFF6B2E9C)),
                      onPressed: () => _showLanguageDialog(),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            
            _buildPreferenceOption(
              title: 'Tema',
              value: _themeEnabled,
              onChanged: (value) async {
                setState(() {
                  _themeEnabled = value;
                });
                await _savePreference(_profileThemeEnabledKey, value);
                _showSnackbar('Tema ${value ? 'activado' : 'desactivado'}');
              },
              icon: Icons.brightness_6_outlined,
            ),
            
            if (_themeEnabled) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 40),
                    Expanded(
                      child: Text(
                        _theme,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18, color: Color(0xFF6B2E9C)),
                      onPressed: () => _showThemeDialog(),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 30),
            const Divider(thickness: 1),
            const SizedBox(height: 20),
            
            // Botón para restablecer preferencias
            Center(
              child: TextButton(
                onPressed: _resetSettings,
                child: const Text(
                  'Restablecer preferencias',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 10),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : () async {
                  await _saveAllChangesAndReturn();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B2E9C),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'GUARDAR CAMBIOS Y VOLVER',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : () async {
                  await _saveAllChanges();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black87,
                        ),
                      )
                    : const Text(
                        'GUARDAR CAMBIOS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
      
    );
  }

  // Diálogo para seleccionar idioma
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar idioma'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildLanguageOption('Español (Único disponible)'),
              _buildLanguageOption('English (Not available)'),
              _buildLanguageOption('Français (Non disponible)'),
              _buildLanguageOption('Deutsch (Nicht verfügbar)'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String language) {
    return ListTile(
      title: Text(language),
      trailing: _language == language 
          ? const Icon(Icons.check, color: Color(0xFF6B2E9C))
          : null,
      onTap: () async {
        setState(() {
          _language = language;
        });
        await _savePreference(_profileLanguageKey, language);
        Navigator.pop(context);
        _showSnackbar('Idioma cambiado a: $language');
      },
    );
  }

  
  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar tema'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildThemeOption('Light mode'),
              _buildThemeOption('Dark mode'),
              _buildThemeOption('System default'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(String theme) {
    return ListTile(
      title: Text(theme),
      trailing: _theme == theme 
          ? const Icon(Icons.check, color: Color(0xFF6B2E9C))
          : null,
      onTap: () async {
        setState(() {
          _theme = theme;
        });
        await _savePreference(_profileThemeKey, theme);
        Navigator.pop(context);
        _showSnackbar('Tema cambiado a: $theme');
      },
    );
  }

  // Restablecer configuraciones
  Future<void> _resetSettings() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restablecer preferencias'),
        content: const Text('¿Estás seguro de que quieres restablecer todas las preferencias a sus valores predeterminados?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _resetPreferences();
              _showSnackbar(' Preferencias restablecidas');
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

  // Método para construir la imagen de perfil
  Widget _buildProfileImage() {
    return Image.asset(
      _selectedImagePath ?? 'assets/images/demon.png',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: const Color(0xFF6B2E9C),
          child: const Icon(
            Icons.person,
            color: Colors.white,
            size: 50,
          ),
        );
      },
    );
  }

  Widget _buildEditableField({
    required String title,
    required TextEditingController value,
    required VoidCallback onSave,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
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
                    TextField(
                      controller: value,
                      decoration: InputDecoration(
                        hintText: title,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.save, color: Color(0xFF6B2E9C)),
                onPressed: onSave,
                tooltip: 'Guardar cambios',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceOption({
    required String title,
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
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF6B2E9C),
          ),
        ],
      )
    );
  }

  Map<String, dynamic> _getUpdatedUserData() {
    return {
      'id': widget.userData['id'],
      'name': _nameController.text,
      'username': _usernameController.text,
      'email': _emailController.text,
      'profile_image': _selectedImagePath ?? 'assets/images/demon.png',
      'role': widget.userData['role'] ?? 'user', // Añadir el rol si existe
      'created_at': widget.userData['created_at'],
    };
  }

  Future<void> _saveAllChanges() async {
    if (_isSaving) return;
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      if (_nameController.text != widget.userData['name']) {
        await _updateName();
      }
      
      if (_usernameController.text != widget.userData['username']) {
        await _updateUsername();
      }
      
      if (_emailController.text != widget.userData['email']) {
        await _updateEmail();
      }
      
      if (_selectedImagePath != widget.userData['profile_image']) {
        await _updateProfileImage();
      }
      
      await _saveAllPreferences();
      
      _showSnackbar(' Todos los cambios guardados');
    } catch (e) {
      _showSnackbar(' Error al guardar: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _saveAllChangesAndReturn() async {
    await _saveAllChanges();
    if (!_isSaving) {
      _navigateToHomeScreen();
    }
  }

  void _goBackWithData() {
    final updatedData = _getUpdatedUserData();
    Navigator.pop(context, updatedData);
  }

 
  void _navigateToHomeScreen() {
    final updatedData = _getUpdatedUserData();
    
    
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(userData: updatedData),
      ),
      (route) => false, 
    );
    
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    super.dispose();
  }
}