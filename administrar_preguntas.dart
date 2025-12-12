import 'package:flutter/material.dart';
import 'database/database_helper.dart';

class AdministrarPreguntasScreen extends StatefulWidget {
  const AdministrarPreguntasScreen({super.key});

  @override
  State<AdministrarPreguntasScreen> createState() => _AdministrarPreguntasScreenState();
}

class _AdministrarPreguntasScreenState extends State<AdministrarPreguntasScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<FAQCategory> _categories = [];
  List<FAQQuestion> _questions = [];
  int? _selectedCategoryId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Cargar categorías
      _categories = await _dbHelper.getFAQCategories();
      
      if (_categories.isNotEmpty) {
        _selectedCategoryId = _categories.first.id;
        await _loadQuestions(_selectedCategoryId!);
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error cargando datos: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadQuestions(int categoryId) async {
    setState(() => _isLoading = true);
    
    try {
      _questions = await _dbHelper.getQuestionsByCategory(categoryId);
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error cargando preguntas: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showAddQuestionDialog() {
    final TextEditingController preguntaController = TextEditingController();
    final TextEditingController respuestaController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar nueva pregunta'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: _categories.map((category) {
                  return DropdownMenuItem<int>(
                    value: category.id,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (value) {
                  // Permitir cambiar categoría en el diálogo
                  if (value != null) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: preguntaController,
                decoration: const InputDecoration(
                  labelText: 'Pregunta',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: respuestaController,
                decoration: const InputDecoration(
                  labelText: 'Respuesta',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
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
              if (preguntaController.text.isNotEmpty && 
                  respuestaController.text.isNotEmpty && 
                  _selectedCategoryId != null) {
                
                try {
                  final result = await _dbHelper.addFAQQuestion(
                    categoryId: _selectedCategoryId!,
                    question: preguntaController.text,
                    answer: respuestaController.text,
                  );
                  
                  if (result > 0) {
                    await _loadQuestions(_selectedCategoryId!);
                    Navigator.pop(context);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(' Pregunta agregada exitosamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    throw Exception('Error al agregar pregunta');
                  }
                } catch (e) {
                  print('Error agregando pregunta: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(' Error al agregar la pregunta'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(' Completa todos los campos'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showEditQuestionDialog(FAQQuestion question) {
    final TextEditingController preguntaController = 
        TextEditingController(text: question.question);
    final TextEditingController respuestaController = 
        TextEditingController(text: question.answer);
    int? selectedCategoryId = question.categoryId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar pregunta'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: _categories.map((category) {
                  return DropdownMenuItem<int>(
                    value: category.id,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedCategoryId = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: preguntaController,
                decoration: const InputDecoration(
                  labelText: 'Pregunta',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: respuestaController,
                decoration: const InputDecoration(
                  labelText: 'Respuesta',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
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
              if (preguntaController.text.isNotEmpty && 
                  respuestaController.text.isNotEmpty &&
                  selectedCategoryId != null) {
                
                try {
                  final success = await _dbHelper.updateFAQQuestion(
                    id: question.id,
                    question: preguntaController.text,
                    answer: respuestaController.text,
                    categoryId: selectedCategoryId,
                  );
                  
                  if (success) {
                    await _loadQuestions(selectedCategoryId!);
                    Navigator.pop(context);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(' Pregunta actualizada'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    throw Exception('Error al actualizar pregunta');
                  }
                } catch (e) {
                  print('Error actualizando pregunta: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(' Error al actualizar la pregunta'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(' Completa todos los campos'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(FAQQuestion question) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar pregunta'),
        content: const Text('¿Estás seguro de que quieres eliminar esta pregunta? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                final success = await _dbHelper.deleteFAQQuestion(question.id);
                
                if (success) {
                  await _loadQuestions(_selectedCategoryId!);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(' Pregunta eliminada'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  throw Exception('Error al eliminar pregunta');
                }
              } catch (e) {
                print('Error eliminando pregunta: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(' Error al eliminar la pregunta'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar Preguntas del Chatbot'),
        backgroundColor: const Color(0xFF6B2E9C),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Datos actualizados'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Selector de categoría
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Row(
              children: [
                const Text('Categoría:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<int>(
                    value: _selectedCategoryId,
                    isExpanded: true,
                    hint: const Text('Selecciona una categoría'),
                    items: _categories.map((category) {
                      return DropdownMenuItem<int>(
                        value: category.id,
                        child: Text(category.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCategoryId = value);
                        _loadQuestions(value);
                      }
                    },
                  ),
                ),
                if (_categories.isNotEmpty)
                  Text(
                    '(${_categories.length} categorías)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          
          // Lista de preguntas
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF6B2E9C)),
                        SizedBox(height: 16),
                        Text('Cargando preguntas...'),
                      ],
                    ),
                  )
                : _questions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.question_mark, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text(
                              'No hay preguntas en esta categoría',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Selecciona otra categoría o agrega una nueva pregunta',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _showAddQuestionDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6B2E9C),
                              ),
                              child: const Text(
                                'Agregar primera pregunta',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _questions.length,
                        itemBuilder: (context, index) {
                          final question = _questions[index];
                          // Encontrar el nombre de la categoría
                          final category = _categories.firstWhere(
                            (cat) => cat.id == question.categoryId,
                            orElse: () => FAQCategory(id: 0, name: 'Desconocida'),
                          );
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF6B2E9C).withOpacity(0.1),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Color(0xFF6B2E9C),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                question.question,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    question.answer.length > 80
                                        ? '${question.answer.substring(0, 80)}...'
                                        : question.answer,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  Chip(
                                    label: Text(
                                      category.name,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    backgroundColor: const Color(0xFF6B2E9C).withOpacity(0.1),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                    onPressed: () => _showEditQuestionDialog(question),
                                    tooltip: 'Editar',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                    onPressed: () => _showDeleteConfirmation(question),
                                    tooltip: 'Eliminar',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          
          // Contador de preguntas
          if (!_isLoading && _questions.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    '${_questions.length} pregunta${_questions.length != 1 ? 's' : ''} en esta categoría',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddQuestionDialog,
        backgroundColor: const Color(0xFF6B2E9C),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}