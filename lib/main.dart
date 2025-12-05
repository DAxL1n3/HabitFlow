import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importar Auth
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'notification_service.dart';
import 'login_screen.dart';
import 'splash_screen.dart';
import 'main_screen.dart'; // Importamos la pantalla principal (Dashboard)

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('es_MX', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  final notificationService = NotificationService();
  await notificationService.initNotifications();
  await notificationService.programarRecordatorioPeriodico();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HabitFlow',
      debugShowCheckedModeBanner: false, // Quitamos la etiqueta de debug
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // --- LÓGICA DE SPLASH ---
      // StreamBuilder escucha el estado de autenticación de Firebase
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 1. Si está esperando conexión, muestra un círculo de carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }

          // 2. Si hay un usuario (snapshot tiene datos), ve directo a MainScreen
          if (snapshot.hasData) {
            return const MainScreen();
          }

          // 3. Si no hay usuario, ve al Login (o Onboarding si lo prefieres)
          return const LoginScreen();
        },
      ),
    );
  }
}
