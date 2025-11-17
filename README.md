
# Aplikasi-keamanan-ruang-medis

**Sistem Keamanan Ruang Medis Berbasis Face Recognition dan RFID Terintegrasi Flutter**

Aplikasi ini dirancang untuk meningkatkan keamanan ruang medis dengan memanfaatkan teknologi **Face Recognition** dan **RFID (Radio Frequency Identification)** yang diintegrasikan ke dalam sistem berbasis **Flutter**.
Sistem ini memungkinkan proses autentikasi ganda—wajah dan kartu RFID—sebelum seseorang dapat mengakses ruangan medis, sehingga hanya pengguna yang terdaftar yang dapat masuk.

Selain itu, aplikasi Flutter berfungsi untuk:

* Menampilkan data pengguna yang terdaftar.
* Memantau log aktivitas akses secara real-time.
* Mengelola proses pendaftaran wajah dan kartu RFID.
* Menyimpan data ke database terintegrasi untuk kebutuhan keamanan dan audit.

---

### 🖥️ UI Aplikasi

<p align="center">
  <img src="https://github.com/farhanbelajar/Aplikasi-keamanan-ruang-medis/blob/main/asset/UI_apk.png" width="600" alt="Tampilan Aplikasi"/>
</p>

---

### ⚙️ Gambaran Umum Sistem

<p align="center">
  <img src="https://github.com/farhanbelajar/Aplikasi-keamanan-ruang-medis/blob/main/asset/Gambaran_Umum.png" width="600" alt="Gambaran Umum Alat"/>
</p>

Sistem keamanan ini terdiri dari:

* **ESP32-CAM** untuk mendeteksi dan mengenali wajah pengguna.
* **RFID-RC522** untuk membaca kartu identitas pengguna.
* **Relay & Solenoid Lock** untuk mengontrol kunci pintu berdasarkan hasil autentikasi.
* **Firebase & Supabase** sebagai database dan autentikasi data pengguna.
* **Aplikasi Flutter** sebagai antarmuka monitoring dan manajemen sistem.

Dengan sistem ini, keamanan ruang medis dapat ditingkatkan secara signifikan melalui proses verifikasi yang lebih ketat, cepat, dan efisien.


