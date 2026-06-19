import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/root_shell.dart';
import 'services/content_repository.dart';
import 'services/storage_service.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final content = await ContentRepository.load();
  final appState = AppState(StorageService())..init();
  runApp(
    MultiProvider(
      providers: [
        Provider<ContentRepository>.value(value: content),
        ChangeNotifierProvider<AppState>.value(value: appState),
      ],
      child: const EnglishWritingProApp(),
    ),
  );
}

class EnglishWritingProApp extends StatelessWidget {
  const EnglishWritingProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'English Writing Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const _Gate(),
    );
  }
}

/// Shows a splash until the persisted state has loaded.
class _Gate extends StatelessWidget {
  const _Gate();

  @override
  Widget build(BuildContext context) {
    final loaded = context.select<AppState, bool>((s) => s.loaded);
    if (!loaded) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.7, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutBack,
                builder: (context, v, child) =>
                    Transform.scale(scale: v, child: child),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.seed, AppTheme.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: AppTheme.softShadow(AppTheme.seed, opacity: 0.4),
                  ),
                  child: const Icon(Icons.edit_note,
                      size: 56, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'English Writing Pro ✍️',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 28),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }
    return const RootShell();
  }
}
