import 'package:flutter/material.dart';

class About extends StatelessWidget {
  const About({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      appBar: AppBar(
        title: const Text("Tentang Aplikasi"),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.verified_user, size: 80, color: Colors.deepPurple),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              "Sistem Keamanan Akses Ruang Medis",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              "Versi 1.0.0",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
          const Divider(height: 40, thickness: 1.2),
          const ListTile(
            leading: Icon(Icons.security, color: Colors.green),
            title: Text("Fungsi Aplikasi"),
            subtitle: Text(
              "Aplikasi ini berfungsi sebagai sistem keamanan untuk mengatur akses ke ruang medis "
                  "dengan autentikasi berbasis pengenalan wajah (Face Recognition) dan RFID. "
                  "Pengguna yang terdaftar dapat membuka akses pintu secara aman dan otomatis.",
            ),
          ),
          const ListTile(
            leading: Icon(Icons.settings_applications, color: Colors.amber),
            title: Text("Teknologi yang Digunakan"),
            subtitle: Text(
              "- Flutter (Mobile App)\n"
                  "- Firebase / Supabase (Database & Storage)\n"
                  "- ESP32-CAM (Face Recognition)\n"
                  "- RFID RC522 (Scanner)\n"
                  "- Servo / Solenoid Lock (Kunci Pintu)",
            ),
          ),
          const ListTile(
            leading: Icon(Icons.help_outline, color: Colors.blue),
            title: Text("Cara Penggunaan"),
            subtitle: Text(
              "1. Pengguna mendaftar wajah dan ID RFID.\n"
                  "2. ESP32-CAM mengenali wajah dan mencocokkan data.\n"
                  "3. Jika cocok, pintu akan terbuka otomatis.\n"
                  "4. Semua log akses tersimpan di database dan ditampilkan di aplikasi Flutter.",
            ),
          ),
          const ListTile(
            leading: Icon(Icons.person, color: Colors.deepPurple),
            title: Text("Dibuat Oleh"),
            subtitle: Text("Muhammad Farhan\nMahasiswa Teknik Informatika"),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.deepPurple[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.email, color: Colors.deepPurple),
                SizedBox(width: 12),
                Text("Kontak: farhan@example.com", style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
