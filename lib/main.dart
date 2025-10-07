import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'dart:io' show Platform; // Asegúrate de que esta línea esté presente
import 'package:firebase_core/firebase_core.dart'; 
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización INCONDICIONAL
  // Esto inicializa Firebase en todas las plataformas, incluyendo Windows.
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(child: MyApp()));
}
// CORRECCIÓN: Clase renombrada a MyApp y se asegura el constructor 'const'
class MyApp extends ConsumerWidget {
  const MyApp({super.key}); // <-- Aquí está la corrección

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'RepoCheck',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}