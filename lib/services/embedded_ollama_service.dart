import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

class EmbeddedOllamaService {
  Process? _ollamaProcess;
  static const String ollamaVersion = '0.12.2';
  static const String ollamaDownloadUrl = 
      'https://github.com/ollama/ollama/releases/download/v$ollamaVersion/ollama-windows-amd64.zip';

  /// Initialize and start embedded Ollama
  Future<bool> startEmbeddedOllama() async {
    try {
      // Get app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final ollamaDir = Directory(path.join(appDir.path, 'ollama'));
      final ollamaExe = File(path.join(ollamaDir.path, 'ollama.exe'));

      // Check if Ollama executable exists
      if (!await ollamaExe.exists()) {
        print('Ollama not found in app directory. Checking system installation...');
        
        // Try to use system-installed Ollama first
        final systemOllama = await _findSystemOllama();
        if (systemOllama != null) {
          print('Found system Ollama at: $systemOllama');
          await _startOllamaProcess(systemOllama);
          return true;
        }
        
        print('Ollama not found. Please install Ollama from https://ollama.ai');
        return false;
      }

      // Start the embedded Ollama
      await _startOllamaProcess(ollamaExe.path);
      
      // Wait a bit for Ollama to start
      await Future.delayed(const Duration(seconds: 2));
      
      // Verify Ollama is running
      final isRunning = await _checkOllamaRunning();
      if (!isRunning) {
        print('Ollama started but not responding');
        return false;
      }

      print('Embedded Ollama started successfully');
      
      // Check if model is downloaded
      await _ensureModelDownloaded();
      
      return true;
    } catch (e) {
      print('Error starting embedded Ollama: $e');
      return false;
    }
  }

  Future<String?> _findSystemOllama() async {
    // Common Ollama installation paths
    final possiblePaths = [
      Platform.environment['LOCALAPPDATA'] != null
          ? path.join(Platform.environment['LOCALAPPDATA']!, 'Programs', 'Ollama', 'ollama.exe')
          : null,
      r'C:\Program Files\Ollama\ollama.exe',
    ];

    for (final ollamaPath in possiblePaths) {
      if (ollamaPath != null && await File(ollamaPath).exists()) {
        return ollamaPath;
      }
    }

    // Try PATH
    try {
      final result = await Process.run('where', ['ollama']);
      if (result.exitCode == 0) {
        final path = result.stdout.toString().trim().split('\n').first;
        if (await File(path).exists()) {
          return path;
        }
      }
    } catch (e) {
      print('Could not search PATH for Ollama: $e');
    }

    return null;
  }

  Future<void> _startOllamaProcess(String ollamaPath) async {
    // Kill any existing Ollama process
    await stopEmbeddedOllama();

    // Start Ollama serve in background
    _ollamaProcess = await Process.start(
      ollamaPath,
      ['serve'],
      environment: {
        'OLLAMA_HOST': '127.0.0.1:11434',
        'OLLAMA_ORIGINS': '*',
      },
    );

    // Listen to output for debugging
    _ollamaProcess!.stdout.listen((data) {
      print('Ollama: ${String.fromCharCodes(data)}');
    });

    _ollamaProcess!.stderr.listen((data) {
      print('Ollama Error: ${String.fromCharCodes(data)}');
    });
  }

  Future<bool> _checkOllamaRunning() async {
    try {
      final response = await http
          .get(Uri.parse('http://localhost:11434/api/tags'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> _ensureModelDownloaded() async {
    try {
      // Check if mistral model exists
      final response = await http.get(Uri.parse('http://localhost:11434/api/tags'));
      if (response.statusCode == 200) {
        final body = response.body;
        if (!body.contains('mistral')) {
          print('Mistral model not found. Downloading in background...');
          // Start download in background (non-blocking)
          _downloadModel();
        }
      }
    } catch (e) {
      print('Could not check for models: $e');
    }
  }

  Future<void> _downloadModel() async {
    try {
      final systemOllama = await _findSystemOllama();
      if (systemOllama == null) return;

      // Run ollama pull in background
      Process.start(systemOllama, ['pull', 'mistral']).then((process) {
        process.stdout.listen((data) {
          print('Model download: ${String.fromCharCodes(data)}');
        });
      });
    } catch (e) {
      print('Error downloading model: $e');
    }
  }

  /// Stop embedded Ollama
  Future<void> stopEmbeddedOllama() async {
    if (_ollamaProcess != null) {
      _ollamaProcess!.kill();
      _ollamaProcess = null;
      print('Stopped embedded Ollama');
    }

    // Also try to kill any other Ollama processes
    if (Platform.isWindows) {
      try {
        await Process.run('taskkill', ['/F', '/IM', 'ollama.exe']);
      } catch (e) {
        // Ignore if process not found
      }
    }
  }

  /// Get Ollama installation instructions
  String getInstallInstructions() {
    return '''
Ollama AI is not installed on this system.

To enable AI features:

1. Download Ollama from: https://ollama.ai/download
2. Install Ollama (takes 2 minutes)
3. Restart this app

Or use the app without AI - keyword matching still works!
''';
  }
}

