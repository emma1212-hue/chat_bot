import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart'; 
import 'database/database_helper.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final AudioPlayer _audioPlayer = AudioPlayer(); 
  List<ChatMessage> _messages = [];
  List<FAQCategory> _categories = [];
  List<FAQQuestion> _questions = [];
  int? _selectedCategoryId;
  bool _isLoading = true;
  bool _hasError = false;
  int _activeSessionId = 0;
  bool _isClearingChat = false;

  @override
  void initState() {
    super.initState();
    _checkDatabaseAndInitialize();
    _initializeAudio(); 
  }

  @override
  void dispose() {
    _audioPlayer.dispose(); 
    super.dispose();
  }

  // Método para inicializar el audio
  void _initializeAudio() {
    
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
    print(' Reproductor de audio inicializado');
  }

  // Método para reproducir sonido de respuesta del bot
  Future<void> _playBotSound() async {
    try {

      _playSimpleBeep();
      
    } catch (e) {
      print(' Error reproduciendo sonido: $e');
      
    }
  }

  // Método alternativo para reproducir un beep simple
  void _playSimpleBeep() {
    
    try {
    
    } catch (e) {
      print(' No se pudo reproducir sonido: $e');
    }
  }

  // Método para reproducir sonido de mensaje enviado (opcional)
  Future<void> _playUserSound() async {
    try {
 
    } catch (e) {
      print(' Error reproduciendo sonido de usuario: $e');
    }
  }

  Future<void> _checkDatabaseAndInitialize() async {
    print(' Chatbot: Iniciando verificación de base de datos...');
    
    try {
      await _dbHelper.checkDatabaseStatus();
      
      // Obtener o crear sesión activa
      _activeSessionId = await _dbHelper.getOrCreateActiveSession();
      
      // Cargar mensajes previos
      await _loadPreviousMessages();
      
      // Inicializar categorías
      await _initializeApp();
      
    } catch (e) {
      print(' Error crítico en inicialización: $e');
      _showErrorMessage('Error grave al inicializar. Reinicia la aplicación.');
    }
  }

  Future<void> _loadPreviousMessages() async {
    try {
      if (_activeSessionId > 0) {
        final previousMessages = await _dbHelper.getChatMessages(_activeSessionId);
        
        setState(() {
          _messages = previousMessages.map((msg) => ChatMessage(
            text: msg.text,
            isUser: msg.isUser,
            timestamp: msg.timestamp,
          )).toList();
        });
        
        print('📨 Mensajes anteriores cargados: ${_messages.length}');
      }
    } catch (e) {
      print(' Error cargando mensajes anteriores: $e');
    }
  }

  Future<void> _initializeApp() async {
    try {
      print(' Chatbot: Inicializando aplicación...');
      
      // Cargar categorías
      _categories = await _dbHelper.getFAQCategories();
      
      print(' Categorías cargadas: ${_categories.length}');
      for (var cat in _categories) {
        print('  - ${cat.name} (ID: ${cat.id})');
      }
      
      if (_categories.isEmpty) {
        print(' No se encontraron categorías. Forzando recreación...');
        await _dbHelper.forceRecreateDatabase();
        _categories = await _dbHelper.getFAQCategories();
      }
      
      setState(() {
        _isLoading = false;
        _hasError = false;
      });
      
      // Si no hay mensajes, agregar mensaje de bienvenida
      if (_messages.isEmpty) {
        _addBotMessage('¡Hola! Soy P.E.K.K.A BOT 🤖\n¿En qué puedo ayudarte?');
      }
      
    } catch (e) {
      print(' Error en _initializeApp: $e');
      _showErrorMessage('Error al cargar las preguntas frecuentes.');
    }
  }

  void _showErrorMessage(String message) {
    _addBotMessage(message);
    setState(() {
      _isLoading = false;
      _hasError = true;
    });
  }

  void _addBotMessage(String text) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final message = ChatMessage(
        text: text,
        isUser: false,
        timestamp: DateTime.now(),
      );
      
      setState(() {
        _messages.add(message);
      });
      
      // Guardar en base de datos
      if (_activeSessionId > 0) {
        _dbHelper.saveChatMessage(
          sessionId: _activeSessionId,
          text: text,
          isUser: false,
          timestamp: DateTime.now(),
        );
      }
      
      
      _playBotSound(); 
    });
  }

  void _addUserMessage(String text) {
    final message = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.add(message);
    });
    
    // Guardar en base de datos
    if (_activeSessionId > 0) {
      _dbHelper.saveChatMessage(
        sessionId: _activeSessionId,
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      );
    }
    
  
  }

  void _onCategorySelected(FAQCategory category) async {
    print(' Categoría seleccionada: ${category.name} (ID: ${category.id})');
    
    _addUserMessage(category.name);
    _selectedCategoryId = category.id;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      _questions = await _dbHelper.getQuestionsByCategory(category.id);
      
      print(' Preguntas encontradas para ${category.name}: ${_questions.length}');
      
      if (_questions.isEmpty) {
        print(' No hay preguntas para esta categoría');
        _addBotMessage('No hay preguntas disponibles en esta categoría.');
        
        // Regresar al menú principal
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _selectedCategoryId = null;
              _isLoading = false;
            });
          }
        });
        return;
      }
      
      setState(() {
        _isLoading = false;
      });
      
    } catch (e) {
      print(' Error cargando preguntas: $e');
      _addBotMessage('Error al cargar las preguntas. Intenta nuevamente.');
      setState(() {
        _isLoading = false;
        _selectedCategoryId = null;
      });
    }
  }

  void _onQuestionSelected(FAQQuestion question) {
    print(' Pregunta seleccionada: ${question.question}');
    
    _addUserMessage(question.question);
    _addBotMessage(question.answer); 
    

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _selectedCategoryId = null;
        });
      }
    });
  }

  void _onBackToCategories() {
    setState(() {
      _selectedCategoryId = null;
    });
  }

  void _retryInitialization() {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _messages.clear();
    });
    _checkDatabaseAndInitialize();
  }

  Future<void> _clearChatHistory() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar chat'),
        content: const Text('¿Estás seguro de que quieres limpiar todo el historial del chat? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              setState(() {
                _isClearingChat = true;
              });
              
              try {
                // 1. Limpiar mensajes de la sesión actual en la base de datos
                final activeSession = await _dbHelper.getLastActiveSession();
                if (activeSession != null) {
                  await _dbHelper.deleteChatSession(activeSession.id);
                  print(' Sesión de chat eliminada de la base de datos');
                }
                
                // 2. Crear una nueva sesión
                _activeSessionId = await _dbHelper.createChatSession();
                print(' Nueva sesión creada: ID $_activeSessionId');
                
                // 3. Limpiar mensajes en pantalla
                setState(() {
                  _messages.clear();
                });
                
                // 4. Agregar mensaje de bienvenida
                _addBotMessage('¡Hola! Soy P.E.K.K.A BOT 🤖\n¿En qué puedo ayudarte?');
                
                // 5. Regresar al menú principal si estaba en preguntas
                if (_selectedCategoryId != null) {
                  setState(() {
                    _selectedCategoryId = null;
                    _questions.clear();
                  });
                }
                
                // Mostrar mensaje de éxito
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(' Historial del chat limpiado exitosamente'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
                
              } catch (e) {
                print(' Error limpiando chat: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(' Error al limpiar el historial'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 2),
                  ),
                );
              } finally {
                setState(() {
                  _isClearingChat = false;
                });
              }
            },
            child: const Text('Limpiar todo', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _clearLocalChatOnly() async {
    setState(() {
      _messages.clear();
      _selectedCategoryId = null;
      _questions.clear();
    });
    
    // Agregar mensaje de bienvenida (con sonido)
    _addBotMessage('¡Hola! Soy P.E.K.K.A BOT 🤖\n¿En qué puedo ayudarte?');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chat local limpiado'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'P.E.K.K.A BOT',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF6B2E9C),
        leading: _selectedCategoryId != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _onBackToCategories,
              )
            : null,
        actions: [
          if (_messages.isNotEmpty && !_isClearingChat)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear_chat',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Limpiar chat', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear_local',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Reiniciar chat local'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'clear_chat') {
                  _clearChatHistory();
                } else if (value == 'clear_local') {
                  _clearLocalChatOnly();
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Header con imagen y texto P.E.K.K.A BOT
          Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            color: const Color(0xFFF5F5F5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/minipekka.png',
                  height: 50,
                  width: 50,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.android, color: Color(0xFF6B2E9C), size: 40);
                  },
                ),
                const SizedBox(width: 15),
                const Text(
                  'P.E.K.K.A BOT',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B2E9C),
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          
          // Historial del chat
          Expanded(
            child: Container(
              color: Colors.grey.shade50,
              child: _isClearingChat
                  ? _buildClearingIndicator()
                  : _hasError && _messages.isEmpty
                      ? _buildErrorScreen()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          reverse: false, // Mantener orden cronológico
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            return ChatBubble(
                              message: message.text,
                              isUser: message.isUser,
                              timestamp: message.timestamp,
                            );
                          },
                        ),
            ),
          ),
          
          // Sección de preguntas frecuentes
          if (!_hasError || _messages.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoading)
                    _buildLoadingIndicator()
                  else if (_selectedCategoryId == null)
                    _buildMainMenu()
                  else
                    _buildQuestionsSection(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClearingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF6B2E9C),
          ),
          const SizedBox(height: 16),
          const Text(
            'Limpiando chat...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Creando nueva sesión...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar el chatbot',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No se pudieron cargar las preguntas frecuentes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _retryInitialization,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B2E9C),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              child: const Text(
                'Reintentar',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () async {
                print(' Forzando recreación de base de datos...');
                try {
                  await _dbHelper.forceRecreateDatabase();
                  _retryInitialization();
                } catch (e) {
                  print(' Error forzando recreación: $e');
                }
              },
              child: const Text(
                'Recrear base de datos',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            CircularProgressIndicator(
              color: Color(0xFF6B2E9C),
            ),
            SizedBox(height: 12),
            Text(
              'Cargando preguntas frecuentes...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainMenu() {
    final categoryMap = {
      'Recuperar cuenta': 'Recuperar cuenta',
      'Eliminar cuenta': 'Eliminar cuenta', 
      'Cambiar usuario': 'Cambiar usuario',
      'Reportar jugador': 'Reportar jugador',
    };
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preguntas frecuentes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        
        // Tabla de categorías como en la imagen
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              // Primera fila
              Row(
                children: [
                  _buildCategoryCard(
                    'Recuperar cuenta',
                    Icons.restore,
                    const Color(0xFF4285F4),
                    categoryMap['Recuperar cuenta']!,
                  ),
                  Container(
                    width: 1,
                    height: 80,
                    color: Colors.grey.shade300,
                  ),
                  _buildCategoryCard(
                    'Eliminar cuenta',
                    Icons.delete,
                    const Color(0xFFEA4335),
                    categoryMap['Eliminar cuenta']!,
                  ),
                ],
              ),
              Container(
                height: 1,
                color: Colors.grey.shade300,
              ),
              // Segunda fila
              Row(
                children: [
                  _buildCategoryCard(
                    'Cambiar usuario',
                    Icons.person,
                    const Color(0xFFFBBC05),
                    categoryMap['Cambiar usuario']!,
                  ),
                  Container(
                    width: 1,
                    height: 80,
                    color: Colors.grey.shade300,
                  ),
                  _buildCategoryCard(
                    'Reportar jugador',
                    Icons.flag,
                    const Color(0xFF34A853),
                    categoryMap['Reportar jugador']!,
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildCategoryCard(String title, IconData icon, Color color, String dbCategoryName) {
    return Expanded(
      child: InkWell(
        onTap: () {
          // Buscar la categoría en la lista cargada
          final category = _categories.firstWhere(
            (cat) => cat.name == dbCategoryName,
            orElse: () {
              print(' Categoría "$dbCategoryName" no encontrada en la base de datos');
              print('   Categorías disponibles: ${_categories.map((c) => c.name).toList()}');
              
              // Crear una categoría temporal
              return FAQCategory(
                id: 999,
                name: dbCategoryName,
                icon: 'custom',
                color: color.value.toRadixString(16),
              );
            },
          );
          
          _onCategorySelected(category);
        },
        child: Container(
          height: 80,
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecciona una pregunta:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        
        if (_isLoading)
          _buildLoadingIndicator()
        else if (_questions.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey.shade400, size: 48),
                  const SizedBox(height: 10),
                  const Text(
                    'No hay preguntas disponibles en esta categoría',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedCategoryId = null;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B2E9C),
                    ),
                    child: const Text(
                      'Volver a categorías',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ..._questions.map((question) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 3,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B2E9C).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '${_questions.indexOf(question) + 1}',
                      style: const TextStyle(
                        color: Color(0xFF6B2E9C),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  question.question,
                  style: const TextStyle(fontSize: 14),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () => _onQuestionSelected(question),
              ),
            );
          }).toList(),
      ],
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final DateTime timestamp;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isUser,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) 
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.transparent,
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/minipekka.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B2E9C),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.android, color: Colors.white, size: 22),
                      );
                    },
                  ),
                ),
              ),
            ),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF6B2E9C) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: isUser ? null : Border.all(color: Colors.grey.shade300),
                boxShadow: isUser
                    ? [
                        BoxShadow(
                          color: const Color(0xFF6B2E9C).withOpacity(0.2),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 2,
                          spreadRadius: 1,
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: isUser ? Colors.white70 : Colors.grey.shade500,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) 
            Container(
              margin: const EdgeInsets.only(left: 8),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.transparent,
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/usuario.png', 
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.person, color: Colors.white, size: 22),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}