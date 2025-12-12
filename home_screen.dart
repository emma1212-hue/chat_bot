import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart'; 
import 'ChatbotScreen.dart';
import 'chatbot_settings_screen.dart';
import 'profile_screen.dart';
import 'database/database_helper.dart';
import 'crearCuenta.dart'; 
import 'iniciarSesion.dart';
import 'admin_video_manager.dart';
import 'administrar_preguntas.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  
  const HomeScreen({super.key, this.userData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;
  bool _showUpdates = false;
  Map<String, dynamic>? _currentUserData;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  List<Map<String, dynamic>> _videoContent = [];
  List<Map<String, dynamic>> _updateContent = [];
  bool _isContentLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadVideoContent();
  }

  Future<void> _loadCurrentUser() async {
    try {
      print(' Cargando usuario actual...');
      
      if (widget.userData != null && widget.userData!.isNotEmpty) {
        print(' Usando usuario del parámetro: ${widget.userData!['name']} - Rol: ${widget.userData!['role']}');
        setState(() {
          _currentUserData = widget.userData;
        });
        return;
      }
      
      final allUsers = await _dbHelper.getAllUsers();
      print(' Usuarios encontrados: ${allUsers.length}');
      
      if (allUsers.isEmpty) {
        print(' No hay usuarios en la base de datos');
        setState(() {
          _currentUserData = {
            'id': 1,
            'name': 'Nuevo Usuario',
            'email': 'usuario@ejemplo.com',
            'username': 'usuario',
            'role': 'user',
            'profile_image': 'assets/images/demon.png',
          };
        });
        return;
      }
      
      allUsers.sort((a, b) {
        final idA = a['id'] as int? ?? 0;
        final idB = b['id'] as int? ?? 0;
        return idB.compareTo(idA);
      });
      
      final latestUser = allUsers.first;
      
      final isDefaultUser = latestUser['email']?.toString().contains('emmaadev@gmail.com') ?? false;
      if (isDefaultUser && allUsers.length > 1) {
        print(' Usuario por defecto detectado, usando el segundo más reciente');
        setState(() {
          _currentUserData = allUsers[1];
        });
      } else {
        setState(() {
          _currentUserData = latestUser;
        });
      }
      
      print(' Usuario cargado exitosamente: ${_currentUserData?['name']} - Rol: ${_currentUserData?['role']}');
      
    } catch (e) {
      print(' Error crítico cargando usuario: $e');
      
      setState(() {
        _currentUserData = {
          'id': 1,
          'name': 'Usuario',
          'email': 'error@ejemplo.com',
          'username': 'usuario_error',
          'role': 'user',
          'profile_image': 'assets/images/demon.png',
        };
      });
    }
  }

  Future<void> _loadVideoContent() async {
    try {
      setState(() {
        _isContentLoading = true;
      });
      
      print(' Cargando contenido de videos...');
      
      _videoContent = await _dbHelper.getVideoContent(category: 'todo');
      print(' Videos en "Todo": ${_videoContent.length}');
      
      _updateContent = await _dbHelper.getVideoContent(category: 'updates');
      print(' Videos en "Actualizaciones": ${_updateContent.length}');
      
      setState(() {
        _isContentLoading = false;
      });
    } catch (e) {
      print(' Error cargando contenido: $e');
      setState(() {
        _isContentLoading = false;
      });
    }
  }

  void _showYouTubeVideo(BuildContext context, String videoUrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.black,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Video',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.fullscreen, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Scaffold(
                              appBar: AppBar(
                                title: const Text('Video'),
                                backgroundColor: Colors.black,
                              ),
                              body: WebViewWidget(
                                controller: WebViewController()
                                  ..setJavaScriptMode(JavaScriptMode.unrestricted)
                                  ..setBackgroundColor(Colors.black)
                                  ..loadRequest(Uri.parse(videoUrl)),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: WebViewWidget(
                  controller: WebViewController()
                    ..setJavaScriptMode(JavaScriptMode.unrestricted)
                    ..setBackgroundColor(Colors.black)
                    ..loadRequest(Uri.parse(videoUrl)),
                ),
              ),
            ],
          ),
        );
      },
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
    final userName = _currentUserData?['name'] ?? 'Usuario';
    final userEmail = _currentUserData?['email'] ?? '';
    final userRole = _currentUserData?['role'] ?? 'user';
    final profileImage = _currentUserData?['profile_image'] ?? 'assets/images/demon.png';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '¡Hola, $userName!',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (userRole == 'admin')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.purple[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'ADMIN',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.purple[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '¿Qué te gustaría hacer hoy?',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        _showUserMenu(context);
                      },
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundImage: _buildProfileImage(profileImage),
                          ),
                          if (userRole == 'admin')
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                  color: Colors.purple,
                                  shape: BoxShape.circle,
                                  border: Border.fromBorderSide(
                                    BorderSide(color: Colors.white, width: 2),
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.star,
                                    size: 8,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChatbotScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6B2E9C), Color(0xFF9B59B6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: 10,
                          top: 0,
                          bottom: 0,
                          child: Image.asset(
                            'assets/images/minipekka.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.android,
                                size: 60,
                                color: Colors.white,
                              );
                            },
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'P.E.K.K.A BOT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'SOPORTE TÉCNICO',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Contenido',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    _buildTab('Todo', 0),
                    const SizedBox(width: 12),
                    _buildTab('Actualizaciones', 1),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (_showUpdates) ...[
                _buildUpdatesSection(),
              ] else ...[
                _buildTodoSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodoSection() {
    return _isContentLoading
        ? const Padding(
            padding: EdgeInsets.all(40.0),
            child: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF6B2E9C),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Cargando contenido...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        : _videoContent.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(40.0),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.video_library,
                        size: 60,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No hay videos disponibles',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentUserData?['role'] == 'admin'
                            ? 'Ve a "Gestión de Videos" para agregar contenido'
                            : 'El administrador agregará contenido pronto',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                children: _videoContent.map((video) {
                  return _buildVideoItem(video);
                }).toList(),
              );
  }

  Widget _buildUpdatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Últimas Actualizaciones',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 16),

        _isContentLoading
            ? const Padding(
                padding: EdgeInsets.all(40.0),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        color: Color(0xFF6B2E9C),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Cargando actualizaciones...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            : _updateContent.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.update,
                            size: 60,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No hay actualizaciones',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currentUserData?['role'] == 'admin'
                                ? 'Ve a "Gestión de Videos" para agregar actualizaciones'
                                : 'Próximamente más actualizaciones',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: _updateContent.map((video) {
                      return _buildUpdateItem(video);
                    }).toList(),
                  ),
      ],
    );
  }

  Widget _buildVideoItem(Map<String, dynamic> video) {
    final imagePath = video['image_path'] ?? 'assets/images/demon.png';
    final title = video['title'] ?? 'Sin título';
    final videoUrl = video['video_url'] ?? '';

    return GestureDetector(
      onTap: () {
        if (videoUrl.isNotEmpty) {
          _showYouTubeVideo(context, videoUrl);
        } else {
          _showSnackbar('Video no disponible');
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFF6B2E9C),
                            child: const Icon(
                              Icons.image,
                              color: Colors.white,
                              size: 30,
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      color: Colors.black.withOpacity(0.3),
                      child: const Center(
                        child: Icon(
                          Icons.play_circle_filled,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateItem(Map<String, dynamic> video) {
    final imagePath = video['image_path'] ?? 'assets/images/demon.png';
    final title = video['title'] ?? 'Sin título';
    final description = video['description'] ?? '';
    final videoUrl = video['video_url'] ?? '';
    final time = 'Hace 2 días';

    return GestureDetector(
      onTap: () {
        if (videoUrl.isNotEmpty) {
          _showYouTubeVideo(context, videoUrl);
        } else {
          _showSnackbar('Video no disponible');
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  image: DecorationImage(
                    image: AssetImage(imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B2E9C),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'VIDEO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B2E9C).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.video_library, size: 14, color: Color(0xFF6B2E9C)),
                              SizedBox(width: 6),
                              Text(
                                'Ver video',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF6B2E9C),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToProfile() async {
    if (_currentUserData != null && _currentUserData!.isNotEmpty) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(userData: _currentUserData!),
        ),
      );
      
      if (result != null && result is Map<String, dynamic>) {
        setState(() {
          _currentUserData = result;
        });
        print(' Datos del usuario actualizados desde Perfil');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cargando datos del usuario...'),
          duration: Duration(seconds: 2),
        ),
      );
      
      await _loadCurrentUser();
      
      if (_currentUserData != null) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(userData: _currentUserData!),
          ),
        );
        
        if (result != null && result is Map<String, dynamic>) {
          setState(() {
            _currentUserData = result;
          });
        }
      }
    }
  }

  void _navigateToChatbotSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChatbotSettingsScreen(),
      ),
    );
  }

  void _navigateToVideoManager() {
    if (_currentUserData != null && _currentUserData!['role'] == 'admin') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdminVideoManager(userData: _currentUserData!),
        ),
      ).then((_) {
        _loadVideoContent();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acceso denegado. Solo administradores pueden acceder.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToAdminQuestions() {
    if (_currentUserData != null && _currentUserData!['role'] == 'admin') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AdministrarPreguntasScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acceso denegado. Solo administradores pueden acceder.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showUserMenu(BuildContext context) {
    final userName = _currentUserData?['name'] ?? 'Usuario';
    final userEmail = _currentUserData?['email'] ?? '';
    final userRole = _currentUserData?['role'] ?? 'user';
    final profileImage = _currentUserData?['profile_image'] ?? 'assets/images/demon.png';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: _buildProfileImage(profileImage),
                        ),
                        if (userRole == 'admin')
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.purple,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.star,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      userEmail,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (userRole == 'admin')
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'ADMINISTRADOR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    
                    _buildMenuOption(
                      icon: Icons.person,
                      color: const Color(0xFF6B2E9C),
                      title: 'Mi Perfil',
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToProfile();
                      },
                    ),
                    
                    if (userRole == 'admin')
                      _buildMenuOption(
                        icon: Icons.video_library,
                        color: Colors.purple,
                        title: 'Gestión de Videos',
                        subtitle: 'Agregar/editar contenido de video',
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToVideoManager();
                        },
                      ),
                    
                    if (userRole == 'admin')
                      _buildMenuOption(
                        icon: Icons.chat_bubble,
                        color: Colors.teal,
                        title: 'Administrar Preguntas',
                        subtitle: 'Gestionar preguntas del chatbot',
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToAdminQuestions();
                        },
                      ),
                    
                    _buildMenuOption(
                      icon: Icons.settings,
                      color: const Color(0xFF6B2E9C),
                      title: 'Configuración del ChatBot',
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToChatbotSettings();
                      },
                    ),
                    
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      height: 1,
                      color: Colors.grey[200],
                    ),
                    
                    _buildMenuOption(
                      icon: Icons.refresh,
                      color: Colors.blue,
                      title: 'Recargar Contenido',
                      onTap: () {
                        Navigator.pop(context);
                        _loadVideoContent();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Contenido recargado'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
                    
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      height: 1,
                      color: Colors.grey[200],
                    ),
                    
                    _buildMenuOption(
                      icon: Icons.logout,
                      color: Colors.red,
                      title: 'Cerrar Sesión',
                      onTap: () {
                        Navigator.pop(context);
                        _showLogoutDialog(context);
                      },
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              )
            : null,
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
                
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Login(),
                  ),
                  (route) => false,
                );
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(' Sesión cerrada exitosamente'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text(
                'Cerrar sesión',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTab(String text, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
          _showUpdates = (text == 'Actualizaciones');
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6B2E9C) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (text == 'Todo')
              Icon(
                Icons.video_library,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            if (text == 'Actualizaciones')
              Icon(
                Icons.update,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider _buildProfileImage(String imagePath) {
    if (imagePath.isNotEmpty && imagePath.startsWith('assets/')) {
      return AssetImage(imagePath);
    }
    return const AssetImage('assets/images/demon.png');
  }
}