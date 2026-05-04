import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class ImageClassifier {
  Interpreter? _interpreter;
  late Map<String, String> _labelMap;
  final int inputSize = 128;

  Future<void> loadModel() async {
    final interpreterOptions = InterpreterOptions();
    _interpreter = await Interpreter.fromAsset(
      'assets/model_quantized.tflite',
      options: interpreterOptions,
    );

    final labelJson =
    await rootBundle.loadString('assets/label_map.json');
    final decoded = jsonDecode(labelJson) as Map<String, dynamic>;
    _labelMap = decoded.map((k, v) => MapEntry(k, v.toString()));
  }

  Future<Map<String, dynamic>> predict(File imageFile) async {
    if (_interpreter == null) {
      throw Exception('Model is not loaded yet.');
    }


    final rawBytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(rawBytes);
    if (image == null) throw Exception('Failed to decode image.');

    img.Image resized = img.copyResize(
      image,
      width: inputSize,
      height: inputSize,
    );


    final inputBuffer = Float32List(1 * inputSize * inputSize * 3);
    int bufferIndex = 0;
    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        inputBuffer[bufferIndex++] = pixel.r / 255.0;
        inputBuffer[bufferIndex++] = pixel.g / 255.0;
        inputBuffer[bufferIndex++] = pixel.b / 255.0;
      }
    }
    final input = inputBuffer.reshape([1, inputSize, inputSize, 3]);


    final outputShape = _interpreter!.getOutputTensor(0).shape;
    final int numClasses = outputShape.last;


    final outputBuffer =
    Float32List(numClasses).reshape([1, numClasses]);


    _interpreter!.run(input, outputBuffer);


    final List<double> probs = List<double>.from(outputBuffer[0]);
    final int predIdx =
    probs.indexOf(probs.reduce((a, b) => a > b ? a : b));


    final String predictedClass =
        _labelMap[predIdx.toString()] ?? 'Class $predIdx';

    return {
      'class': predictedClass,
      'confidence': '${(probs[predIdx] * 100).toStringAsFixed(2)}%',
      'all_probs': {
        for (var i = 0; i < probs.length; i++)
          (_labelMap[i.toString()] ?? 'Class $i'):
          '${(probs[i] * 100).toStringAsFixed(2)}%'
      },
    };
  }

  void dispose() => _interpreter?.close();
}