import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  bool _isInitialized = false;

  // Nombres de tablas
  static const String _userTable = 'users';
  static const String _videoContentTable = 'video_content';
  static const String _faqCategoriesTable = 'faq_categories';
  static const String _faqQuestionsTable = 'faq_questions';
  static const String _chatSessionsTable = 'chat_sessions';
  static const String _chatMessagesTable = 'chat_messages';

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('users.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    print(' Inicializando base de datos...');
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 6,
      onCreate: _createDB,
      onOpen: (db) async {
        print('Base de datos abierta');
        await _verifyTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        print('Actualizando base de datos de v$oldVersion a v$newVersion');
        if (oldVersion < 2) {
          await _createChatHistoryTables(db);
        }
        if (oldVersion < 3) {
          await _addActiveColumn(db);
        }
        if (oldVersion < 4) {
          await _addProfileImageColumn(db);
        }
        if (oldVersion < 5) {
          await _addUsernameColumn(db);
        }
        if (oldVersion < 6) {
          await _addRoleColumn(db);
          await _createVideoContentTable(db);
        }
      },
    );
  }

  Future<void> _addRoleColumn(Database db) async {
    try {
      final columns = await db.rawQuery("PRAGMA table_info(users)");
      bool hasRoleColumn = false;
      for (var column in columns) {
        if (column['name'] == 'role') {
          hasRoleColumn = true;
          break;
        }
      }
      
      if (!hasRoleColumn) {
        await db.execute("ALTER TABLE users ADD COLUMN role TEXT DEFAULT 'user'");
        print(' Columna role agregada a users');
        
        await db.update(
          _userTable,
          {'role': 'admin'},
          where: 'email = ?',
          whereArgs: ['emmaadev@gmail.com'],
        );
        print(' Usuario emmaadev@gmail.com actualizado a admin');
      }
    } catch (e) {
      print(' Error agregando columna role: $e');
    }
  }

  Future<void> _createVideoContentTable(Database db) async {
    try {
      const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
      const textType = 'TEXT NOT NULL';

      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_videoContentTable (
          id $idType,
          title $textType,
          description TEXT,
          image_path $textType,
          video_url $textType,
          category TEXT DEFAULT 'todo',
          rating REAL DEFAULT 4.0,
          comments INTEGER DEFAULT 0,
          created_by INTEGER,
          created_at TEXT,
          is_active INTEGER DEFAULT 1,
          FOREIGN KEY (created_by) REFERENCES users (id)
        )
      ''');
      print(' Tabla "$_videoContentTable" creada');
    } catch (e) {
      print(' Error creando tabla video_content: $e');
    }
  }

  Future<void> _addUsernameColumn(Database db) async {
    try {
      final columns = await db.rawQuery("PRAGMA table_info(users)");
      bool hasUsernameColumn = false;
      for (var column in columns) {
        if (column['name'] == 'username') {
          hasUsernameColumn = true;
          break;
        }
      }
      
      if (!hasUsernameColumn) {
        await db.execute("ALTER TABLE users ADD COLUMN username TEXT");
        print(' Columna username agregada a users');
        
        await db.update(
          'users',
          {'username': 'usuario'},
          where: 'username IS NULL',
        );
        print(' Usuarios existentes actualizados con username por defecto');
      }
    } catch (e) {
      print(' Error agregando columna username: $e');
    }
  }

  Future<void> _addActiveColumn(Database db) async {
    try {
      final columns = await db.rawQuery("PRAGMA table_info(chat_sessions)");
      bool hasActiveColumn = false;
      for (var column in columns) {
        if (column['name'] == 'is_active') {
          hasActiveColumn = true;
          break;
        }
      }
      
      if (!hasActiveColumn) {
        await db.execute("ALTER TABLE chat_sessions ADD COLUMN is_active INTEGER DEFAULT 1");
        print(' Columna is_active agregada a chat_sessions');
      }
    } catch (e) {
      print(' Error agregando columna is_active: $e');
    }
  }

  Future<void> _addProfileImageColumn(Database db) async {
    try {
      final columns = await db.rawQuery("PRAGMA table_info(users)");
      bool hasProfileImageColumn = false;
      for (var column in columns) {
        if (column['name'] == 'profile_image') {
          hasProfileImageColumn = true;
          break;
        }
      }
      
      if (!hasProfileImageColumn) {
        await db.execute("ALTER TABLE users ADD COLUMN profile_image TEXT");
        print(' Columna profile_image agregada a users');
        
        await db.update(
          'users',
          {'profile_image': 'assets/images/demon.png'},
          where: 'profile_image IS NULL',
        );
        print(' Usuarios existentes actualizados con imagen por defecto');
      }
    } catch (e) {
      print(' Error agregando columna profile_image: $e');
    }
  }

  Future<void> _verifyTables(Database db) async {
    print(' Verificando tablas...');
    
    final requiredTables = [_userTable, _videoContentTable, _faqCategoriesTable, _faqQuestionsTable, _chatSessionsTable, _chatMessagesTable];
    
    for (var table in requiredTables) {
      try {
        final result = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='$table'");
        
        if (result.isEmpty) {
          print(' Tabla "$table" NO existe. Creándola...');
          await _createMissingTables(db);
          break;
        } else {
          print(' Tabla "$table" existe');
        }
      } catch (e) {
        print(' Error verificando tabla $table: $e');
      }
    }
    
    await _checkAndInsertData(db);
  }

  Future<void> _createMissingTables(Database db) async {
    print(' Creando tablas faltantes...');
    
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';

    // Tabla users
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_userTable (
          id $idType,
          email $textType,
          password $textType,
          name TEXT,
          username TEXT,
          profile_image TEXT,
          role TEXT DEFAULT 'user',
          created_at TEXT
        )
      ''');
      print(' Tabla "$_userTable" creada con username y role');
    } catch (e) {
      print(' Error creando tabla users: $e');
    }

    // Tabla video_content
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_videoContentTable (
          id $idType,
          title $textType,
          description TEXT,
          image_path $textType,
          video_url $textType,
          category TEXT DEFAULT 'todo',
          rating REAL DEFAULT 4.0,
          comments INTEGER DEFAULT 0,
          created_by INTEGER,
          created_at TEXT,
          is_active INTEGER DEFAULT 1,
          FOREIGN KEY (created_by) REFERENCES users (id)
        )
      ''');
      print(' Tabla "$_videoContentTable" creada');
    } catch (e) {
      print(' Error creando tabla video_content: $e');
    }

    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS faq_categories (
          id $idType,
          name $textType,
          icon TEXT,
          color TEXT
        )
      ''');
      print(' Tabla "faq_categories" creada');
    } catch (e) {
      print(' Error creando tabla faq_categories: $e');
    }

    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS faq_questions (
          id $idType,
          category_id INTEGER,
          question $textType,
          answer $textType,
          FOREIGN KEY (category_id) REFERENCES faq_categories (id)
        )
      ''');
      print(' Tabla "faq_questions" creada');
    } catch (e) {
      print(' Error creando tabla faq_questions: $e');
    }

    await _createChatHistoryTables(db);
  }

  Future<void> _createChatHistoryTables(Database db) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';

    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_chatSessionsTable (
          id $idType,
          title TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          is_active INTEGER DEFAULT 1
        )
      ''');
      print(' Tabla "$_chatSessionsTable" creada');
    } catch (e) {
      print(' Error creando tabla chat_sessions: $e');
    }

    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_chatMessagesTable (
          id $idType,
          session_id INTEGER NOT NULL,
          message_text $textType,
          is_user INTEGER NOT NULL,
          timestamp TEXT NOT NULL,
          FOREIGN KEY (session_id) REFERENCES chat_sessions (id)
        )
      ''');
      print(' Tabla "$_chatMessagesTable" creada');
    } catch (e) {
      print(' Error creando tabla chat_messages: $e');
    }
  }

  Future _createDB(Database db, int version) async {
    print(' Creando base de datos desde cero...');
    await _createMissingTables(db);
    await _checkAndInsertData(db);
  }

  Future<void> _checkAndInsertData(Database db) async {
    try {
      final categories = await db.query(_faqCategoriesTable);
      print(' Categorías en DB: ${categories.length}');
      
      if (categories.isEmpty) {
        print(' Insertando datos iniciales...');
        await _insertInitialData(db);
      } else {
        final questions = await db.query(_faqQuestionsTable);
        print(' Preguntas en DB: ${questions.length}');
        
        if (questions.isEmpty) {
          print(' Insertando preguntas...');
          await _insertFAQQuestions(db);
        }
      }
    } catch (e) {
      print(' Error verificando/insertando datos: $e');
    }
  }

  Future<void> _insertInitialData(Database db) async {
    try {
      // Insertar categorías FAQ
      final categoriesData = [
        {'name': 'Recuperar cuenta', 'icon': 'restore', 'color': '#4285F4'},
        {'name': 'Eliminar cuenta', 'icon': 'delete', 'color': '#EA4335'},
        {'name': 'Cambiar usuario', 'icon': 'person', 'color': '#FBBC05'},
        {'name': 'Reportar jugador', 'icon': 'flag', 'color': '#34A853'},
      ];
      
      for (var category in categoriesData) {
        await db.insert(_faqCategoriesTable, category);
      }
      print(' Categorías insertadas: ${categoriesData.length}');
      
      await _insertFAQQuestions(db);
      
      // Insertar usuario ADMIN por defecto
      final users = await db.query(_userTable, where: 'email = ?', whereArgs: ['admin@example.com']);
      if (users.isEmpty) {
        await db.insert(_userTable, {
          'email': 'admin@example.com',
          'password': _hashPassword('admin123'),
          'name': 'Administrador',
          'username': 'admin',
          'profile_image': 'assets/images/demon.png',
          'role': 'admin',
          'created_at': DateTime.now().toIso8601String(),
        });
        print(' Administrador insertado (admin@example.com / admin123)');
      }

      // Insertar usuario normal por defecto
      final normalUsers = await db.query(_userTable, where: 'email = ?', whereArgs: ['usuario@ejemplo.com']);
      if (normalUsers.isEmpty) {
        await db.insert(_userTable, {
          'email': 'usuario@ejemplo.com',
          'password': _hashPassword('usuario123'),
          'name': 'Usuario Normal',
          'username': 'usuario',
          'profile_image': 'assets/images/demon.png',
          'role': 'user',
          'created_at': DateTime.now().toIso8601String(),
        });
        print(' Usuario normal insertado (usuario@ejemplo.com / usuario123)');
      }
      
      // Insertar videos por defecto
      await _insertDefaultVideos(db);
      
    } catch (e) {
      print(' Error insertando datos iniciales: $e');
    }
  }

  Future<void> _insertDefaultVideos(Database db) async {
    try {
      // Obtener el ID del administrador
      final admin = await db.query(
        _userTable,
        where: 'role = ?',
        whereArgs: ['admin'],
        limit: 1,
      );
      
      int adminId = 1;
      if (admin.isNotEmpty) {
        adminId = admin.first['id'] as int;
      }
      
      final defaultVideos = [
        {
          'title': '¿Cómo usar la nueva carta?',
          'description': 'Aprende a utilizar la nueva carta Vine Spell en Clash Royale',
          'image_path': 'assets/images/vinespell_4K.png',
          'video_url': 'https://www.youtube.com/watch?v=2JQxCzMO6qg',
          'category': 'todo',
          'rating': 4.5,
          'comments': 34,
          'created_by': adminId,
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'title': 'Evolución del Horno ¿Sirve?',
          'description': 'Análisis completo de la evolución del Horno en Clash Royale',
          'image_path': 'assets/images/horno.png',
          'video_url': 'https://www.youtube.com/watch?v=1KKggCjRKso',
          'category': 'todo',
          'rating': 4.6,
          'comments': 67,
          'created_by': adminId,
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'title': 'Nueva Brawler ¿Cómo usar?',
          'description': 'Guía completa para usar a Mina en Brawl Stars',
          'image_path': 'assets/images/emoji_mina.png',
          'video_url': 'https://www.youtube.com/watch?v=pCQKnulc1Tw&t=27s',
          'category': 'todo',
          'rating': 4.2,
          'comments': 43,
          'created_by': adminId,
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'title': 'Consejos para mejorar en Brawl Stars',
          'description': 'Tips y estrategias para subir de trofeos',
          'image_path': 'assets/images/logito.png',
          'video_url': 'https://www.youtube.com/watch?v=NyyrnG6EhMg',
          'category': 'todo',
          'rating': 4.9,
          'comments': 180,
          'created_by': adminId,
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'title': 'Nuevos aspectos e iconos gratis',
          'description': 'Cómo conseguir aspectos e iconos gratuitos',
          'image_path': 'assets/images/queen.png',
          'video_url': 'https://www.youtube.com/watch?v=LM1E8MIjBzA',
          'category': 'todo',
          'rating': 4.5,
          'comments': 89,
          'created_by': adminId,
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'title': 'Llego la Hypercarga de Alli',
          'description': 'Review de la nueva hypercarga de Alli',
          'image_path': 'assets/images/ali.png',
          'video_url': 'https://www.youtube.com/watch?v=eAGmqT4CQ0w',
          'category': 'todo',
          'rating': 4.1,
          'comments': 49,
          'created_by': adminId,
          'created_at': DateTime.now().toIso8601String(),
        },
        // Videos de actualizaciones
        {
          'title': 'NUEVA COLABORACION: STRANGER THINGS',
          'description': 'Llega la colaboración más esperada. Premios y skins de Stranger Things.',
          'image_path': 'assets/images/stranger.jpg',
          'video_url': 'https://www.youtube.com/watch?v=tR872KZ_zAk',
          'category': 'updates',
          'rating': 4.8,
          'comments': 120,
          'created_by': adminId,
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'title': 'CAMBIOS DE BALANCE',
          'description': 'Revisa las estadísticas actualizadas para la nueva temporada.',
          'image_path': 'assets/images/cambios.jpg',
          'video_url': 'https://www.youtube.com/watch?v=NVrdbVy8rZM',
          'category': 'updates',
          'rating': 4.3,
          'comments': 56,
          'created_by': adminId,
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'title': 'EVENTOS DE TEMPORADA',
          'description': 'Nuevos desafíos, misiones especiales y recompensas únicas disponibles por tiempo limitado.',
          'image_path': 'assets/images/nuevos.jpg',
          'video_url': 'https://www.youtube.com/watch?v=eRquW5rSSao',
          'category': 'updates',
          'rating': 4.6,
          'comments': 78,
          'created_by': adminId,
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'title': 'MODO DUELO 2V2 MEJORADO',
          'description': 'Nuevas mecánicas y recompensas en el modo duelo. ¡Juega con amigos y gana premios exclusivos!',
          'image_path': 'assets/images/2vs2.jpg',
          'video_url': 'https://www.youtube.com/watch?v=8bQCJXfsE_w',
          'category': 'updates',
          'rating': 4.7,
          'comments': 92,
          'created_by': adminId,
          'created_at': DateTime.now().toIso8601String(),
        },
      ];
      
      for (var video in defaultVideos) {
        await db.insert(_videoContentTable, video);
      }
      
      print(' Videos por defecto insertados: ${defaultVideos.length}');
      
    } catch (e) {
      print(' Error insertando videos por defecto: $e');
    }
  }

  Future<void> _insertFAQQuestions(Database db) async {
    try {
      final categories = await db.query('faq_categories');
      Map<String, int> categoryIds = {};
      for (var cat in categories) {
        categoryIds[cat['name'] as String] = cat['id'] as int;
      }
      
      final questionsData = [
        {
          'category_id': categoryIds['Recuperar cuenta'],
          'question': '¿Cuál es el ID del jugador de la cuenta que has perdido?',
          'answer': 'El ID del jugador se encuentra en la pantalla de carga o en Configuración > Acerca de > ID de jugador.'
        },
        {
          'category_id': categoryIds['Recuperar cuenta'],
          'question': '¿Cuál es el nombre de la cuenta que has perdido?',
          'answer': 'El nombre aparece en la pantalla principal del juego, en la esquina superior izquierda.'
        },
        {
          'category_id': categoryIds['Recuperar cuenta'],
          'question': '¿Cuál es el nivel de experiencia de la cuenta que has perdido?',
          'answer': 'El nivel de experiencia se muestra en tu perfil junto a tu nombre.'
        },
        {
          'category_id': categoryIds['Eliminar cuenta'],
          'question': '¿Cómo elimino mi cuenta permanentemente?',
          'answer': 'Ve a Configuración > Privacidad > "Eliminar cuenta". Esta acción es irreversible.'
        },
        {
          'category_id': categoryIds['Cambiar usuario'],
          'question': '¿Cómo cambio mi nombre de usuario?',
          'answer': 'Ve a Configuración > Perfil > "Editar nombre de usuario". Solo puedes cambiarlo cada 30 días.'
        },
        {
          'category_id': categoryIds['Reportar jugador'],
          'question': '¿Cómo reporto a un jugador por comportamiento inapropiado?',
          'answer': 'Desde el perfil del jugador, haz clic en ⋮ y selecciona "Reportar".'
        },
      ];
      
      for (var question in questionsData) {
        await db.insert('faq_questions', question);
      }
      
      print(' Preguntas insertadas: ${questionsData.length}');
      
    } catch (e) {
      print(' Error insertando preguntas: $e');
    }
  }

  // ========== MÉTODOS PARA USUARIOS ==========

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<Map<String, dynamic>> createUser({
    required String name,
    required String username,
    required String email,
    required String password,
    String role = 'user',
  }) async {
    try {
      final db = await database;
      
      // Verificar si el email ya existe
      final existingEmail = await getUserByEmail(email);
      if (existingEmail != null) {
        return {
          'success': false,
          'message': 'Este correo electrónico ya está registrado',
        };
      }
      
      // Verificar si el username ya existe
      final existingUsername = await getUserByUsername(username);
      if (existingUsername != null) {
        return {
          'success': false,
          'message': 'Este nombre de usuario ya está en uso',
        };
      }
      
      // Encriptar la contraseña
      final hashedPassword = _hashPassword(password);
      
      // Crear el usuario
      final userData = {
        'email': email.toLowerCase(),
        'password': hashedPassword,
        'name': name,
        'username': username,
        'profile_image': 'assets/images/demon.png',
        'role': role,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      final id = await db.insert(_userTable, userData);
      
      print(' Usuario creado exitosamente. ID: $id, Rol: $role');
      
      return {
        'success': true,
        'message': ' Cuenta creada exitosamente. Ahora puedes iniciar sesión.',
        'user': {
          'id': id,
          'name': name,
          'username': username,
          'email': email,
          'role': role,
          'profile_image': 'assets/images/demon.png',
          'created_at': userData['created_at'],
        },
      };
      
    } catch (e) {
      print(' Error creando usuario: $e');
      return {
        'success': false,
        'message': 'Error al crear la cuenta. Intenta de nuevo.',
      };
    }
  }

  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final db = await database;
      final hashedPassword = _hashPassword(password);
      
      final result = await db.query(
        _userTable,
        where: 'email = ? AND password = ?',
        whereArgs: [email.toLowerCase(), hashedPassword],
      );

      if (result.isNotEmpty) {
        final user = result.first;
        print(' Usuario encontrado: ${user['name']} - Rol: ${user['role']}');
        
        return {
          'success': true,
          'message': ' Inicio de sesión exitoso',
          'user': {
            'id': user['id'],
            'name': user['name'],
            'username': user['username'],
            'email': user['email'],
            'role': user['role'] ?? 'user',
            'profile_image': user['profile_image'] ?? 'assets/images/demon.png',
            'created_at': user['created_at'],
          },
        };
      } else {
        final emailExists = await getUserByEmail(email);
        if (emailExists != null) {
          return {
            'success': false,
            'message': ' Contraseña incorrecta',
          };
        } else {
          return {
            'success': false,
            'message': ' Email no registrado',
          };
        }
      }
    } catch (e) {
      print(' Error en login: $e');
      return {
        'success': false,
        'message': ' Error al iniciar sesión',
      };
    }
  }

  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    try {
      final db = await database;
      final result = await db.query(
        _userTable,
        where: 'username = ?',
        whereArgs: [username],
      );
      
      if (result.isNotEmpty) {
        return result.first;
      }
      return null;
    } catch (e) {
      print(' Error obteniendo usuario por username: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      _userTable,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await database;
    final result = await db.query(
      _userTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return await db.query(_userTable, orderBy: 'id DESC');
  }

  Future<bool> deleteUser(int userId) async {
    try {
      final db = await database;
      
      final user = await getUserById(userId);
      if (user == null) {
        print(' Usuario con ID $userId no encontrado');
        return false;
      }
      
      final deletedRows = await db.delete(
        _userTable,
        where: 'id = ?',
        whereArgs: [userId],
      );
      
      if (deletedRows > 0) {
        print(' Usuario eliminado exitosamente: ID $userId - ${user['name']}');
        return true;
      } else {
        print(' No se pudo eliminar el usuario ID $userId');
        return false;
      }
    } catch (e) {
      print(' Error eliminando usuario: $e');
      return false;
    }
  }

  // ========== MÉTODOS PARA PERFIL ==========

  Future<bool> updateUserName(int userId, String newName) async {
    try {
      final db = await database;
      await db.update(
        _userTable,
        {'name': newName},
        where: 'id = ?',
        whereArgs: [userId],
      );
      print(' Nombre actualizado para usuario ID $userId: $newName');
      return true;
    } catch (e) {
      print(' Error actualizando nombre: $e');
      return false;
    }
  }

  Future<bool> updateUserEmail(int userId, String newEmail) async {
    try {
      final db = await database;
      
      final existingUser = await getUserByEmail(newEmail);
      if (existingUser != null && existingUser['id'] != userId) {
        print(' Email ya registrado por otro usuario: $newEmail');
        return false;
      }
      
      await db.update(
        _userTable,
        {'email': newEmail.toLowerCase()},
        where: 'id = ?',
        whereArgs: [userId],
      );
      print(' Email actualizado para usuario ID $userId: $newEmail');
      return true;
    } catch (e) {
      print(' Error actualizando email: $e');
      return false;
    }
  }

  Future<bool> updateUserUsername(int userId, String newUsername) async {
    try {
      final db = await database;
      
      final existingUser = await getUserByUsername(newUsername);
      if (existingUser != null && existingUser['id'] != userId) {
        print(' Username ya registrado por otro usuario: $newUsername');
        return false;
      }
      
      await db.update(
        _userTable,
        {'username': newUsername},
        where: 'id = ?',
        whereArgs: [userId],
      );
      print(' Username actualizado para usuario ID $userId: $newUsername');
      return true;
    } catch (e) {
      print(' Error actualizando username: $e');
      return false;
    }
  }

  Future<bool> updateUserProfileImage(int userId, String imagePath) async {
    try {
      final db = await database;
      await db.update(
        _userTable,
        {'profile_image': imagePath},
        where: 'id = ?',
        whereArgs: [userId],
      );
      print(' Imagen de perfil actualizada para usuario ID $userId: $imagePath');
      return true;
    } catch (e) {
      print(' Error actualizando imagen de perfil: $e');
      return false;
    }
  }

  Future<bool> updateUserRole(int userId, String newRole) async {
    try {
      final db = await database;
      await db.update(
        _userTable,
        {'role': newRole},
        where: 'id = ?',
        whereArgs: [userId],
      );
      print(' Rol actualizado para usuario ID $userId: $newRole');
      return true;
    } catch (e) {
      print(' Error actualizando rol: $e');
      return false;
    }
  }

  // ========== MÉTODOS PARA CONTENIDO DE VIDEO ==========

  Future<List<Map<String, dynamic>>> getVideoContent({String category = 'todo'}) async {
    try {
      final db = await database;
      return await db.query(
        _videoContentTable,
        where: 'category = ? AND is_active = 1',
        whereArgs: [category],
        orderBy: 'created_at DESC',
      );
    } catch (e) {
      print(' Error obteniendo videos: $e');
      return [];
    }
  }

  Future<int> addVideoContent({
    required String title,
    String description = '',
    required String imagePath,
    required String videoUrl,
    String category = 'todo',
    double rating = 4.0,
    int comments = 0,
    required int createdBy,
  }) async {
    try {
      final db = await database;
      return await db.insert(_videoContentTable, {
        'title': title,
        'description': description,
        'image_path': imagePath,
        'video_url': videoUrl,
        'category': category,
        'rating': rating,
        'comments': comments,
        'created_by': createdBy,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print(' Error añadiendo video: $e');
      return 0;
    }
  }

  Future<bool> updateVideoContent({
    required int videoId,
    String? title,
    String? description,
    String? imagePath,
    String? videoUrl,
    String? category,
    double? rating,
    int? comments,
  }) async {
    try {
      final db = await database;
      final updateData = <String, dynamic>{};
      
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (imagePath != null) updateData['image_path'] = imagePath;
      if (videoUrl != null) updateData['video_url'] = videoUrl;
      if (category != null) updateData['category'] = category;
      if (rating != null) updateData['rating'] = rating;
      if (comments != null) updateData['comments'] = comments;
      
      updateData['created_at'] = DateTime.now().toIso8601String();
      
      final result = await db.update(
        _videoContentTable,
        updateData,
        where: 'id = ?',
        whereArgs: [videoId],
      );
      
      return result > 0;
    } catch (e) {
      print(' Error actualizando video: $e');
      return false;
    }
  }

  Future<bool> deleteVideoContent(int videoId) async {
    try {
      final db = await database;
      final result = await db.delete(
        _videoContentTable,
        where: 'id = ?',
        whereArgs: [videoId],
      );
      return result > 0;
    } catch (e) {
      print(' Error eliminando video: $e');
      return false;
    }
  }

  // ========== MÉTODOS PARA CHAT ==========
  Future<int> getOrCreateActiveSession() async {
    try {
      final db = await database;
      
      final result = await db.query(
        _chatSessionsTable,
        where: 'is_active = 1',
        orderBy: 'updated_at DESC',
        limit: 1,
      );
      
      if (result.isNotEmpty) {
        final session = result.first;
        print(' Sesión activa encontrada: ID ${session['id']}');
        return session['id'] as int;
      } else {
        final now = DateTime.now().toIso8601String();
        final sessionId = await db.insert(_chatSessionsTable, {
          'title': 'Chat',
          'created_at': now,
          'updated_at': now,
          'is_active': 1,
        });
        
        print(' Nueva sesión activa creada: ID $sessionId');
        return sessionId;
      }
    } catch (e) {
      print(' Error obteniendo/creando sesión activa: $e');
      return 0;
    }
  }

  Future<int> createChatSession({String? title}) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      
      final sessionId = await db.insert(_chatSessionsTable, {
        'title': title ?? 'Chat ${DateTime.now().toString().substring(0, 16)}',
        'created_at': now,
        'updated_at': now,
        'is_active': 1,
      });
      
      print(' Nueva sesión de chat creada: ID $sessionId');
      return sessionId;
    } catch (e) {
      print(' Error creando sesión de chat: $e');
      return 0;
    }
  }

  Future<int> saveChatMessage({
    required int sessionId,
    required String text,
    required bool isUser,
    required DateTime timestamp,
  }) async {
    try {
      final db = await database;
      
      await db.update(
        _chatSessionsTable,
        {'updated_at': timestamp.toIso8601String()},
        where: 'id = ?',
        whereArgs: [sessionId],
      );
      
      final messageId = await db.insert(_chatMessagesTable, {
        'session_id': sessionId,
        'message_text': text,
        'is_user': isUser ? 1 : 0,
        'timestamp': timestamp.toIso8601String(),
      });
      
      print(' Mensaje guardado: "$text" (Sesión: $sessionId)');
      return messageId;
    } catch (e) {
      print(' Error guardando mensaje: $e');
      return 0;
    }
  }

  Future<List<ChatSession>> getAllChatSessions() async {
    try {
      final db = await database;
      final result = await db.query(
        _chatSessionsTable,
        orderBy: 'updated_at DESC',
      );
      
      return result.map((e) => ChatSession(
        id: e['id'] as int,
        title: e['title'] as String?,
        createdAt: DateTime.parse(e['created_at'] as String),
        updatedAt: DateTime.parse(e['updated_at'] as String),
      )).toList();
    } catch (e) {
      print(' Error obteniendo sesiones: $e');
      return [];
    }
  }

  Future<List<ChatMessage>> getChatMessages(int sessionId) async {
    try {
      final db = await database;
      final result = await db.query(
        _chatMessagesTable,
        where: 'session_id = ?',
        whereArgs: [sessionId],
        orderBy: 'timestamp ASC',
      );
      
      return result.map((e) => ChatMessage(
        id: e['id'] as int,
        sessionId: e['session_id'] as int,
        text: e['message_text'] as String,
        isUser: e['is_user'] == 1,
        timestamp: DateTime.parse(e['timestamp'] as String),
      )).toList();
    } catch (e) {
      print(' Error obteniendo mensajes: $e');
      return [];
    }
  }

  Future<bool> deleteChatSession(int sessionId) async {
    try {
      final db = await database;
      
      await db.delete(
        _chatMessagesTable,
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
      
      await db.delete(
        _chatSessionsTable,
        where: 'id = ?',
        whereArgs: [sessionId],
      );
      
      print(' Sesión eliminada: ID $sessionId');
      return true;
    } catch (e) {
      print(' Error eliminando sesión: $e');
      return false;
    }
  }

  Future<ChatSession?> getLastActiveSession() async {
    try {
      final db = await database;
      final result = await db.query(
        _chatSessionsTable,
        where: 'is_active = 1',
        orderBy: 'updated_at DESC',
        limit: 1,
      );
      
      if (result.isNotEmpty) {
        final session = result.first;
        return ChatSession(
          id: session['id'] as int,
          title: session['title'] as String?,
          createdAt: DateTime.parse(session['created_at'] as String),
          updatedAt: DateTime.parse(session['updated_at'] as String),
        );
      }
      return null;
    } catch (e) {
      print(' Error obteniendo última sesión: $e');
      return null;
    }
  }

  Future<void> closeActiveSession() async {
    try {
      final db = await database;
      await db.update(
        _chatSessionsTable,
        {'is_active': 0},
        where: 'is_active = 1',
      );
      print(' Sesión de chat cerrada');
    } catch (e) {
      print(' Error cerrando sesión: $e');
    }
  }

  Future<void> clearAllChatHistory() async {
    try {
      final db = await database;
      await db.delete(_chatMessagesTable);
      await db.delete(_chatSessionsTable);
      print(' Todo el historial de chat eliminado');
    } catch (e) {
      print(' Error limpiando historial: $e');
    }
  }

  // ========== MÉTODOS PARA FAQ ==========
  Future<List<FAQCategory>> getFAQCategories() async {
    try {
      final db = await database;
      final result = await db.query(_faqCategoriesTable);
      
      print(' getFAQCategories: ${result.length} categorías encontradas');
      
      return result.map((e) => FAQCategory(
        id: e['id'] as int,
        name: e['name'] as String,
        icon: e['icon'] as String?,
        color: e['color'] as String?,
      )).toList();
    } catch (e) {
      print(' Error en getFAQCategories: $e');
      return [];
    }
  }

  Future<List<FAQQuestion>> getQuestionsByCategory(int categoryId) async {
    try {
      final db = await database;
      print(' Buscando preguntas para categoría ID: $categoryId');
      
      final result = await db.query(
        _faqQuestionsTable,
        where: 'category_id = ?',
        whereArgs: [categoryId],
      );
      
      print(' getQuestionsByCategory: ${result.length} preguntas encontradas');
      
      return result.map((e) => FAQQuestion(
        id: e['id'] as int,
        categoryId: e['category_id'] as int,
        question: e['question'] as String,
        answer: e['answer'] as String,
      )).toList();
    } catch (e) {
      print(' Error en getQuestionsByCategory: $e');
      return [];
    }
  }

  Future<List<FAQQuestion>> searchQuestions(String query) async {
    try {
      final db = await database;
      print(' Buscando preguntas con query: "$query"');
      
      final result = await db.query(
        _faqQuestionsTable,
        where: 'question LIKE ? OR answer LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
      );
      
      print(' Resultados de búsqueda: ${result.length} preguntas');
      
      return result.map((e) => FAQQuestion(
        id: e['id'] as int,
        categoryId: e['category_id'] as int,
        question: e['question'] as String,
        answer: e['answer'] as String,
      )).toList();
    } catch (e) {
      print(' Error en searchQuestions: $e');
      return [];
    }
  }

  Future<List<FAQQuestion>> getAllQuestions() async {
    try {
      final db = await database;
      print(' Obteniendo todas las preguntas...');
      
      final result = await db.query(_faqQuestionsTable);
      
      print(' Total de preguntas en DB: ${result.length}');
      
      return result.map((e) => FAQQuestion(
        id: e['id'] as int,
        categoryId: e['category_id'] as int,
        question: e['question'] as String,
        answer: e['answer'] as String,
      )).toList();
    } catch (e) {
      print(' Error en getAllQuestions: $e');
      return [];
    }
  }

  // ========== MÉTODOS CRUD COMPLETOS PARA PREGUNTAS ==========

  // 1. Obtener todas las preguntas con información de categoría
  Future<List<Map<String, dynamic>>> getAllQuestionsWithCategory() async {
    try {
      final db = await database;
      
      final result = await db.rawQuery('''
        SELECT 
          q.id as question_id,
          q.question,
          q.answer,
          q.category_id,
          c.name as category_name,
          c.icon as category_icon,
          c.color as category_color
        FROM $_faqQuestionsTable q
        LEFT JOIN $_faqCategoriesTable c ON q.category_id = c.id
        ORDER BY c.name, q.question
      ''');
      
      print(' getAllQuestionsWithCategory: ${result.length} preguntas encontradas');
      return result;
    } catch (e) {
      print(' Error en getAllQuestionsWithCategory: $e');
      return [];
    }
  }

  // 2. Insertar nueva pregunta 
  Future<int> addFAQQuestion({
    required int categoryId,
    required String question,
    required String answer,
  }) async {
    try {
      final db = await database;
      final result = await db.insert(_faqQuestionsTable, {
        'category_id': categoryId,
        'question': question,
        'answer': answer,
      });
      
      print(' Pregunta agregada exitosamente: ID $result');
      return result;
    } catch (e) {
      print(' Error añadiendo pregunta: $e');
      return 0;
    }
  }

  // 3. Actualizar pregunta existente
  Future<bool> updateFAQQuestion({
    required int id,
    String? question,
    String? answer,
    int? categoryId,
  }) async {
    try {
      final db = await database;
      
      final updateData = <String, dynamic>{};
      if (question != null) updateData['question'] = question;
      if (answer != null) updateData['answer'] = answer;
      if (categoryId != null) updateData['category_id'] = categoryId;
      
      if (updateData.isEmpty) {
        print(' No hay datos para actualizar en la pregunta ID $id');
        return false;
      }
      
      final result = await db.update(
        _faqQuestionsTable,
        updateData,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (result > 0) {
        print(' Pregunta actualizada exitosamente: ID $id');
        return true;
      } else {
        print(' No se encontró la pregunta ID $id para actualizar');
        return false;
      }
    } catch (e) {
      print(' Error actualizando pregunta: $e');
      return false;
    }
  }

  // 4. Eliminar pregunta
  Future<bool> deleteFAQQuestion(int id) async {
    try {
      final db = await database;
      
      final result = await db.delete(
        _faqQuestionsTable,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (result > 0) {
        print(' Pregunta eliminada exitosamente: ID $id');
        return true;
      } else {
        print(' No se encontró la pregunta ID $id para eliminar');
        return false;
      }
    } catch (e) {
      print(' Error eliminando pregunta: $e');
      return false;
    }
  }

  // 5. Obtener pregunta por ID
  Future<Map<String, dynamic>?> getFAQQuestionById(int id) async {
    try {
      final db = await database;
      
      final result = await db.query(
        _faqQuestionsTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (result.isNotEmpty) {
        return result.first;
      }
      return null;
    } catch (e) {
      print(' Error obteniendo pregunta por ID: $e');
      return null;
    }
  }

  // 6. Buscar preguntas por texto
  Future<List<Map<String, dynamic>>> searchFAQQuestions(String query) async {
    try {
      final db = await database;
      
      final result = await db.rawQuery('''
        SELECT 
          q.id as question_id,
          q.question,
          q.answer,
          q.category_id,
          c.name as category_name
        FROM $_faqQuestionsTable q
        LEFT JOIN $_faqCategoriesTable c ON q.category_id = c.id
        WHERE q.question LIKE ? OR q.answer LIKE ? OR c.name LIKE ?
        ORDER BY c.name, q.question
      ''', ['%$query%', '%$query%', '%$query%']);
      
      print(' searchFAQQuestions: ${result.length} resultados para "$query"');
      return result;
    } catch (e) {
      print(' Error buscando preguntas: $e');
      return [];
    }
  }

  // ========== MÉTODOS PARA CATEGORÍAS ==========

  Future<int> addFAQCategory({
    required String name,
    String? icon,
    String? color,
  }) async {
    try {
      final db = await database;
      final result = await db.insert(_faqCategoriesTable, {
        'name': name,
        'icon': icon,
        'color': color ?? '#4285F4',
      });
      
      print(' Categoría agregada exitosamente: ID $result - $name');
      return result;
    } catch (e) {
      print(' Error añadiendo categoría: $e');
      return 0;
    }
  }

  Future<bool> updateFAQCategory({
    required int id,
    String? name,
    String? icon,
    String? color,
  }) async {
    try {
      final db = await database;
      
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (icon != null) updateData['icon'] = icon;
      if (color != null) updateData['color'] = color;
      
      final result = await db.update(
        _faqCategoriesTable,
        updateData,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      return result > 0;
    } catch (e) {
      print(' Error actualizando categoría: $e');
      return false;
    }
  }

  Future<bool> deleteFAQCategory(int id) async {
    try {
      final db = await database;
      
      
      await db.delete(
        _faqQuestionsTable,
        where: 'category_id = ?',
        whereArgs: [id],
      );
      
      // Luego eliminar la categoría
      final result = await db.delete(
        _faqCategoriesTable,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      return result > 0;
    } catch (e) {
      print(' Error eliminando categoría: $e');
      return false;
    }
  }

  Future<void> forceRecreateDatabase() async {
    print(' Forzando recreación completa de la base de datos...');
    final db = await database;
    
    await db.execute('DROP TABLE IF EXISTS $_chatMessagesTable');
    await db.execute('DROP TABLE IF EXISTS $_chatSessionsTable');
    await db.execute('DROP TABLE IF EXISTS $_faqQuestionsTable');
    await db.execute('DROP TABLE IF EXISTS $_faqCategoriesTable');
    await db.execute('DROP TABLE IF EXISTS $_videoContentTable');
    await db.execute('DROP TABLE IF EXISTS $_userTable');
    
    await _createMissingTables(db);
    await _insertInitialData(db);
    
    print(' Base de datos recreada completamente');
  }

  Future<void> checkDatabaseStatus() async {
    try {
      final db = await database;
      
      final tables = [_userTable, _videoContentTable, _faqCategoriesTable, _faqQuestionsTable, _chatSessionsTable, _chatMessagesTable];
      
      for (var table in tables) {
        try {
          final result = await db.rawQuery("SELECT COUNT(*) as count FROM $table");
          final count = result.first['count'] as int? ?? 0;
          print(' Tabla "$table": $count registros');
        } catch (e) {
          print(' Tabla "$table" no existe o tiene error: $e');
        }
      }
      
    } catch (e) {
      print(' Error verificando estado de DB: $e');
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}

// ========== MODELOS ==========
class FAQCategory {
  final int id;
  final String name;
  final String? icon;
  final String? color;
  
  FAQCategory({
    required this.id,
    required this.name,
    this.icon,
    this.color,
  });
}

class FAQQuestion {
  final int id;
  final int categoryId;
  final String question;
  final String answer;
  
  FAQQuestion({
    required this.id,
    required this.categoryId,
    required this.question,
    required this.answer,
  });
}

class ChatSession {
  final int id;
  final String? title;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  ChatSession({
    required this.id,
    this.title,
    required this.createdAt,
    required this.updatedAt,
  });
}

class ChatMessage {
  final int id;
  final int sessionId;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  
  ChatMessage({
    required this.id,
    required this.sessionId,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}