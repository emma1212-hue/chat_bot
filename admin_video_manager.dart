import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'database/database_helper.dart';

class AdminVideoManager extends StatefulWidget {
  final Map<String, dynamic> userData;
  
  const AdminVideoManager({super.key, required this.userData});

  @override
  State<AdminVideoManager> createState() => _AdminVideoManagerState();
}

class _AdminVideoManagerState extends State<AdminVideoManager> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _videos = [];
  bool _isLoading = true;
  String _selectedCategory = 'todo';
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _imagePathController = TextEditingController();
  final TextEditingController _videoUrlController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      _videos = await _dbHelper.getVideoContent(category: _selectedCategory);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando videos: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAddVideoDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar Nuevo Video'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _imagePathController,
                  decoration: const InputDecoration(
                    labelText: 'Ruta de la imagen * (assets/images/...)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _videoUrlController,
                  decoration: const InputDecoration(
                    labelText: 'URL del video * (YouTube)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Categoría *',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'todo',
                      child: Text('Todo'),
                    ),
                    DropdownMenuItem(
                      value: 'updates',
                      child: Text('Actualizaciones'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value ?? 'todo';
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_titleController.text.isEmpty || 
                    _imagePathController.text.isEmpty || 
                    _videoUrlController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor completa todos los campos requeridos (*)'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                final videoId = await _dbHelper.addVideoContent(
                  title: _titleController.text,
                  description: _descriptionController.text,
                  imagePath: _imagePathController.text,
                  videoUrl: _videoUrlController.text,
                  category: _selectedCategory,
                  createdBy: widget.userData['id'],
                );
                
                if (videoId > 0) {
                  Navigator.pop(context);
                  _clearControllers();
                  await _loadVideos();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(' Video agregado exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(' Error al agregar el video'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B2E9C),
              ),
              child: const Text('Agregar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showEditVideoDialog(Map<String, dynamic> video) {
    _titleController.text = video['title'] ?? '';
    _descriptionController.text = video['description'] ?? '';
    _imagePathController.text = video['image_path'] ?? '';
    _videoUrlController.text = video['video_url'] ?? '';
    final videoCategory = video['category'] ?? 'todo';
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Editar Video'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Título *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _imagePathController,
                      decoration: const InputDecoration(
                        labelText: 'Ruta de la imagen *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _videoUrlController,
                      decoration: const InputDecoration(
                        labelText: 'URL del video *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: videoCategory,
                      decoration: const InputDecoration(
                        labelText: 'Categoría *',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'todo',
                          child: Text('Todo'),
                        ),
                        DropdownMenuItem(
                          value: 'updates',
                          child: Text('Actualizaciones'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _clearControllers();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_titleController.text.isEmpty || 
                        _imagePathController.text.isEmpty || 
                        _videoUrlController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Por favor completa todos los campos requeridos'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    final success = await _dbHelper.updateVideoContent(
                      videoId: video['id'],
                      title: _titleController.text,
                      description: _descriptionController.text,
                      imagePath: _imagePathController.text,
                      videoUrl: _videoUrlController.text,
                      category: videoCategory,
                    );
                    
                    if (success) {
                      Navigator.pop(context);
                      _clearControllers();
                      await _loadVideos();
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(' Video actualizado exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(' Error al actualizar el video'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B2E9C),
                  ),
                  child: const Text('Guardar', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _clearControllers() {
    _titleController.clear();
    _imagePathController.clear();
    _videoUrlController.clear();
    _descriptionController.clear();
  }

  void _showDeleteDialog(int videoId, String title) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar Video'),
          content: Text('¿Estás seguro de eliminar el video "$title"? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await _dbHelper.deleteVideoContent(videoId);
                
                if (success) {
                  await _loadVideos();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(' Video eliminado exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(' Error al eliminar el video'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Videos - Administrador'),
        backgroundColor: const Color(0xFF6B2E9C),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVideos,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B2E9C).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_list, color: Color(0xFF6B2E9C)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCategory,
                              isExpanded: true,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'todo',
                                  child: Text('Sección: Todo'),
                                ),
                                DropdownMenuItem(
                                  value: 'updates',
                                  child: Text('Sección: Actualizaciones'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value ?? 'todo';
                                });
                                _loadVideos();
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Color(0xFF6B2E9C),
                        ),
                        SizedBox(height: 16),
                        Text('Cargando videos...'),
                      ],
                    ),
                  )
                : _videos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.video_library,
                              size: 80,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No hay videos en esta categoría',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedCategory == 'todo'
                                  ? 'Agrega videos para mostrar en la sección "Todo"'
                                  : 'Agrega videos para mostrar en "Actualizaciones"',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _showAddVideoDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6B2E9C),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text(
                                'Agregar Primer Video',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _videos.length,
                        itemBuilder: (context, index) {
                          final video = _videos[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 8,
                            ),
                            elevation: 2,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    video['image_path'] ?? 'assets/images/demon.png',
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: Icon(
                                            Icons.videocam,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              title: Text(
                                video['title'] ?? 'Sin título',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    video['description']?.isNotEmpty == true
                                        ? video['description']
                                        : 'Sin descripción',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _selectedCategory == 'todo'
                                          ? Colors.blue[100]
                                          : Colors.green[100],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _selectedCategory == 'todo' ? 'Todo' : 'Actualizaciones',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _selectedCategory == 'todo'
                                            ? Colors.blue[800]
                                            : Colors.green[800],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 20),
                                        SizedBox(width: 8),
                                        Text('Editar'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red, size: 20),
                                        SizedBox(width: 8),
                                        Text('Eliminar', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditVideoDialog(video);
                                  } else if (value == 'delete') {
                                    _showDeleteDialog(
                                      video['id'],
                                      video['title'] ?? 'este video',
                                    );
                                  }
                                },
                              ),
                              onTap: () {
                                // Previsualización rápida
                                if (video['video_url'] != null) {
                                  _previewVideo(video);
                                }
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddVideoDialog,
        backgroundColor: const Color(0xFF6B2E9C),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Agregar Video',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void _previewVideo(Map<String, dynamic> video) {
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
                    Expanded(
                      child: Text(
                        video['title'] ?? 'Video Preview',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.open_in_new, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Scaffold(
                              appBar: AppBar(
                                title: Text(video['title'] ?? 'Video'),
                                backgroundColor: Colors.black,
                              ),
                              body: WebViewWidget(
                                controller: WebViewController()
                                  ..setJavaScriptMode(JavaScriptMode.unrestricted)
                                  ..setBackgroundColor(Colors.black)
                                  ..loadRequest(Uri.parse(video['video_url'])),
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
                    ..loadRequest(Uri.parse(video['video_url'])),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}