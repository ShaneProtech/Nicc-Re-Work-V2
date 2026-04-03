import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'widgets/app_shell.dart';
import 'services/database_service.dart';
import 'services/embedded_ollama_service.dart';
import 'providers/calibration_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database
  final dbService = DatabaseService();
  await dbService.initializeDatabase();
  
  // Start embedded Ollama (non-blocking)
  final ollamaService = EmbeddedOllamaService();
  ollamaService.startEmbeddedOllama().then((started) {
    if (started) {
      print('Ollama AI started successfully');
    } else {
      print('Ollama AI not available - using fallback mode');
    }
  });
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.backgroundDark,
    ),
  );
  
  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseService>.value(value: dbService),
        ChangeNotifierProvider(create: (_) => CalibrationProvider(dbService)),
      ],
      child: const NICCCalibrationApp(),
    ),
  );
}

class NICCCalibrationApp extends StatelessWidget {
  const NICCCalibrationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NICC Calibration Suite',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AppShell(),
    );
  }
}

