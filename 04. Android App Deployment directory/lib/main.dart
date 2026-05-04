import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'classifier.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CNN Keras Image Classifier',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const ClassifierPage(),
    );
  }
}

class ClassifierPage extends StatefulWidget {
  const ClassifierPage({super.key});

  @override
  State<ClassifierPage> createState() => _ClassifierPageState();
}

class _ClassifierPageState extends State<ClassifierPage> {
  final ImageClassifier _classifier = ImageClassifier();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  Map<String, dynamic>? _result;
  bool _isLoading = false;
  bool _modelLoaded = false;
  String _statusMessage = 'Loading model...';

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      await _classifier.loadModel();
      setState(() {
        _modelLoaded = true;
        _statusMessage = 'Model ready!';
      });
    } catch (e) {
      setState(() {
        _modelLoaded = false;
        _statusMessage = 'Error: $e';
      });
      // Print detail error
      print('MODEL LOAD ERROR: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> _pickAndPredict(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(source: source);
    if (picked == null) return;

    setState(() {
      _selectedImage = File(picked.path);
      _isLoading = true;
      _result = null;
    });

    try {
      final result = await _classifier.predict(_selectedImage!);
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _result = {
          'class': 'Error',
          'confidence': e.toString(),
          'all_probs': <String, String>{},
        };
      });
    }
  }

  @override
  void dispose() {
    _classifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CNN Image Classifier'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // -- Model Status Banner
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _modelLoaded
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _modelLoaded ? Colors.green : Colors.orange,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _modelLoaded
                        ? Icons.check_circle
                        : Icons.hourglass_empty,
                    color: _modelLoaded ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_statusMessage)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // -- Image Preview
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  _selectedImage!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              )
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_outlined,
                    size: 60,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No image selected',
                    style:
                    TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Gallery & Camera Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _modelLoaded
                        ? () => _pickAndPredict(ImageSource.gallery)
                        : null,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    style: ElevatedButton.styleFrom(
                      padding:
                      const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _modelLoaded
                        ? () => _pickAndPredict(ImageSource.camera)
                        : null,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      padding:
                      const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Prediction Result
            if (_isLoading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text('Analyzing image...'),
                  ],
                ),
              )
            else if (_result != null) ...[
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Card Header
                      Row(
                        children: [
                          const Icon(Icons.analytics,
                              color: Colors.indigo),
                          const SizedBox(width: 8),
                          Text(
                            'Prediction Result',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 20),

                      // Predicted Class & Confidence
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Class',
                                style:
                                TextStyle(color: Colors.grey),
                              ),
                              Text(
                                _result!['class'],
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Confidence',
                                style:
                                TextStyle(color: Colors.grey),
                              ),
                              Text(
                                _result!['confidence'],
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // All Class Probabilities
                      const Text(
                        'All Probabilities:',
                        style: TextStyle(
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      ...(_result!['all_probs']
                      as Map<String, String>)
                          .entries
                          .map(
                            (e) => Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 3),
                          child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text(e.key),
                              Text(
                                e.value,
                                style: const TextStyle(
                                    fontWeight:
                                    FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}