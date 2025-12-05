import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Notificación en Segundo Plano: ${message.notification?.title}");
}

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Configuración Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotificationsPlugin.initialize(initializationSettings);

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _mostrarNotificacionLocal(message);
      }
    });
  }

  Future<void> programarRecordatorioPeriodico() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'channel_recordatorios',
      'Recordatorios de Hábitos',
      channelDescription: 'Te recuerda registrar tu progreso',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    await _localNotificationsPlugin.periodicallyShow(
      0,
      '¡Es hora de tus hábitos! ⏰',
      'Recuerda registrar tu progreso en HabitFlow. ¡Tú puedes!',
      RepeatInterval.everyMinute, // Recuerda cambiar esto a daily/hourly para producción
      notificationDetails,
      // --- AQUÍ ESTABA EL ERROR, CAMBIAMOS A INEXACTO ---
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  // Mostrar notificación inmediata (la que ya tenías)
  Future<void> _mostrarNotificacionLocal(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'high_importance_channel',
          'Notificaciones Importantes',
          importance: Importance.max,
          priority: Priority.high,
        );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      notificationDetails,
    );
  }

  // Función para cancelar recordatorios (útil para el logout)
  Future<void> cancelarNotificaciones() async {
    await _localNotificationsPlugin.cancelAll();
  }
}
