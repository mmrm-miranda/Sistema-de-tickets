import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_PUBLISHABLE_KEY']!,
  );

  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.requestPermissions();

  Supabase.instance.client
      .channel('public:Conversaciones')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'Conversaciones',
        callback: (payload) {
          final newRecord = payload.newRecord;
          final msg = newRecord['mensaje']?.toString() ?? 'Nuevo mensaje';
          final ticketId = newRecord['incidente_id']?.toString() ?? '';
          
          notificationService.showNotification(
            id: newRecord['id'] ?? 0,
            title: 'Nuevo comentario en Ticket #$ticketId',
            body: msg,
          );
        },
      )
      .subscribe();

  runApp(const App());
}
