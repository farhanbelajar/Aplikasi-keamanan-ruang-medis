import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LaporanKejadianPage extends StatefulWidget {
  const LaporanKejadianPage({super.key});

  @override
  State<LaporanKejadianPage> createState() => _LaporanKejadianPageState();
}

class _LaporanKejadianPageState extends State<LaporanKejadianPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final String bucketName = "camera";

  List<Map<String, dynamic>> laporanList = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchLaporanFromFirestore();
  }

  // Show a modal to let the user choose between camera and gallery
  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blueAccent),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blueAccent),
                title: const Text('Ambil dari Kamera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Pick an image from the specified source (camera or gallery)
  Future<void> _pickImage(ImageSource source) async {
    final imagePicker = ImagePicker();
    final pickedFile = await imagePicker.pickImage(source: source, imageQuality: 80);
    if (pickedFile != null) {
      _showDescriptionDialog(pickedFile);
    }
  }

  // Show a dialog to get the user's description for the report
  Future<void> _showDescriptionDialog(XFile pickedFile) async {
    final descriptionController = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Deskripsi Kejadian',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        content: TextField(
          controller: descriptionController,
          decoration: const InputDecoration(
            hintText: 'Contoh: Alat infus bocor',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _uploadImageAndSaveData(pickedFile, descriptionController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Unggah'),
          )
        ],
      ),
    );
  }

  // Upload the image to Supabase Storage and save the data to Firestore
  Future<void> _uploadImageAndSaveData(XFile pickedFile, String description) async {
    if (description.isEmpty) {
      showSnackBar("Deskripsi tidak boleh kosong", Colors.orange);
      return;
    }

    try {
      setState(() => isLoading = true);

      final Uint8List fileBytes = await pickedFile.readAsBytes();
      final String fileName = "${DateTime.now().millisecondsSinceEpoch}_kejadian.jpg";

      final response = await supabase.storage.from(bucketName).uploadBinary(fileName, fileBytes);
      final publicUrl = supabase.storage.from(bucketName).getPublicUrl(fileName);

      if (response.isNotEmpty) {
        final now = DateTime.now();
        await firestore.collection("laporan_kejadian").add({
          "imageUrl": publicUrl,
          "timestamp": now.toIso8601String(),
          "description": description,
        });

        showSnackBar("\u{1F44D} Laporan berhasil diunggah!", Colors.green);
        fetchLaporanFromFirestore();
      } else {
        showSnackBar("\u{274C} Gagal mengunggah gambar", Colors.red);
      }
    } catch (error) {
      showSnackBar("Terjadi kesalahan: $error", Colors.red);
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Fetch all reports from Firestore
  Future<void> fetchLaporanFromFirestore() async {
    try {
      setState(() => isLoading = true);
      final snapshot = await firestore.collection("laporan_kejadian").orderBy("timestamp", descending: true).get();

      final data = snapshot.docs.map((doc) => doc.data()).toList();

      setState(() {
        laporanList = data;
      });
    } catch (error) {
      showSnackBar("\u{274C} Gagal mengambil data: $error", Colors.red);
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Show a snackbar message
  void showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 16, color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Show a full-screen image dialog with Hero animation
  void showFullImage(String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (BuildContext context, _, __) {
          return Hero(
            tag: imageUrl,
            child: InteractiveViewer(
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
          );
        },
      ),
    );
  }

  // Helper widget for a loading skeleton effect
  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 150,
                      height: 14,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 200,
                      height: 14,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 14,
                      color: Colors.grey[300],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper widget to build each report item
  Widget _buildLaporanItem(Map<String, dynamic> laporan) {
    final timestamp = DateTime.parse(laporan["timestamp"]);
    final formatted = DateFormat("EEEE, dd MMM yyyy HH:mm").format(timestamp);

    return GestureDetector(
      onTap: () => showFullImage(laporan["imageUrl"]),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Hero(
                tag: laporan["imageUrl"],
                child: Image.network(
                  laporan["imageUrl"],
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 20, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        formatted,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text("Deskripsi:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    laporan["description"] ?? "-",
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8), // A soft, light blue background
      appBar: AppBar(
        title: const Text(
          "Laporan Medis",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade800,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: fetchLaporanFromFirestore,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: "Refresh Data",
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showImageSourcePicker,
        backgroundColor: Colors.blue.shade800,
        tooltip: "Unggah Laporan Baru",
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: isLoading
          ? _buildLoadingSkeleton()
          : laporanList.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_late_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "Belum ada laporan kerusakan ditemukan.",
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )
          : Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: laporanList.length,
          itemBuilder: (context, index) {
            return _buildLaporanItem(laporanList[index]);
          },
        ),
      ),
    );
  }
}