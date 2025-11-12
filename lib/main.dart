import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:skripsi_hangans/setting/Splash.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // ✅ Tambahkan ini
import 'package:skripsi_hangans/database/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Inisialisasi Supabase
  await Supabase.initialize(
    url: 'https://hogopaorxqjnblsejcnp.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhvZ29wYW9yeHFqbmJsc2VqY25wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAwOTA5MDQsImV4cCI6MjA2NTY2NjkwNH0.W5S5-oP82SdXputyM1WLhVJrTRQMKeKXVDPqX5PYzos',
  );
  // await dotenv.load(fileName: ".env");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: Splash(),
    );
  }
}
