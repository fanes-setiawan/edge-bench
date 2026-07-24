import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

final modelDownloaderProvider = Provider((ref) => ModelDownloaderService());

class ModelDownloaderService {
  // Qwen2.5-0.5B-Instruct-GGUF (Q4_K_M) - Approx 350MB
  static const String modelUrl = 'https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf';
  static const String modelFileName = 'qwen2.5-0.5b-instruct.gguf';

  Future<File> getModelFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$modelFileName');
  }

  Future<bool> isModelDownloaded() async {
    final file = await getModelFile();
    return file.exists();
  }

  Stream<double> downloadModel() async* {
    final file = await getModelFile();
    if (await file.exists()) {
      yield 1.0;
      return;
    }

    final request = http.Request('GET', Uri.parse(modelUrl));
    final response = await http.Client().send(request);
    
    final contentLength = response.contentLength ?? 1;
    int bytesReceived = 0;
    
    final sink = file.openWrite();
    
    await for (final chunk in response.stream) {
      sink.add(chunk);
      bytesReceived += chunk.length;
      yield bytesReceived / contentLength;
    }
    
    await sink.flush();
    await sink.close();
  }
}
