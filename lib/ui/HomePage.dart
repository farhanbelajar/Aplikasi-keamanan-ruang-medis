import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  List<Map<String, String>> imageList = [];

  String lampuMode = 'auto';
  String relayMode = 'auto';
  bool lampuManual = false;
  bool relayManual = false;

  final db = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    fetchImagesFromSupabase();

    db.child("lampu_mode").onValue.listen((event) {
      final val = event.snapshot.value;
      if (val != null) setState(() => lampuMode = val.toString());
    });
    db.child("lampu_status").onValue.listen((event) {
      setState(() => lampuManual = event.snapshot.value == 1);
    });

    db.child("relay_mode").onValue.listen((event) {
      final val = event.snapshot.value;
      if (val != null) setState(() => relayMode = val.toString());
    });
    db.child("relay_status").onValue.listen((event) {
      setState(() => relayManual = event.snapshot.value == 1);
    });
  }

  Future<void> fetchImagesFromSupabase() async {
    final storage = Supabase.instance.client.storage;
    final files = await storage.from('camera').list(path: 'public');

    final newList = <Map<String, String>>[];

    for (var file in files) {
      final url = storage.from('camera').getPublicUrl('public/${file.name}');
      try {
        final filename = file.name.split('_').first;
        final timestamp = DateTime.fromMillisecondsSinceEpoch(int.parse(filename));
        final formatted = DateFormat('dd MMM yyyy, HH:mm').format(timestamp);
        newList.add({'url': url, 'created': formatted});
      } catch (_) {
        newList.add({'url': url, 'created': 'Unknown'});
      }
    }

    newList.sort((a, b) => b['created']!.compareTo(a['created']!));
    setState(() => imageList = newList);
  }

  void _openZoomableImage(String imageUrl) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Lihat Gambar'),
          backgroundColor: const Color(0xFF11579C),
        ),
        body: PhotoView(
          imageProvider: CachedNetworkImageProvider(imageUrl),
          backgroundDecoration: const BoxDecoration(color: Colors.black),
        ),
      ),
    ));
  }

  Widget _buildImageGallery() {
    if (imageList.isEmpty) {
      return const SizedBox(
        height: 140,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return SizedBox(
      height: 260,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: imageList.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, idx) {
          final img = imageList[idx];
          return GestureDetector(
            onTap: () => _openZoomableImage(img['url']!),
            child: Container(
              width: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                border: Border.all(color: Colors.blueGrey.shade50),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 9, offset: Offset(0, 5))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: CachedNetworkImage(
                      imageUrl: img['url']!,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 140,
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 140,
                        alignment: Alignment.center,
                        child: const Icon(Icons.error, size: 36, color: Colors.redAccent),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("🕒 Diunggah:",
                            style: TextStyle(fontSize: 12, color: Colors.black54)),
                        const SizedBox(height: 4),
                        Text(img['created'] ?? 'Unknown',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModeController({
    required String label,
    required String currentMode,
    required bool manualStatus,
    required void Function(String) onModeChange,
    required void Function(bool) onManualChange,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label Control",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800])),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: currentMode == 'auto'
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  currentMode.toUpperCase(),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: currentMode == 'auto' ? Colors.green : Colors.orange),
                ),
              ),
              DropdownButton<String>(
                value: currentMode,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'auto', child: Text('Otomatis')),
                  DropdownMenuItem(value: 'manual', child: Text('Manual')),
                ],
                onChanged: (val) {
                  if (val != null) onModeChange(val);
                },
              ),
              if (currentMode == 'manual')
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Status", style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 6),
                    Switch(value: manualStatus, onChanged: onManualChange),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1F5FA7), Color(0xFF4C9EEB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 6))
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white,
            child: Icon(Icons.local_hospital_rounded, size: 32, color: Color(0xFF1F5FA7)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("Monitoring Ruang Medis",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text("Kontrol lampu & kamera live",
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none, color: Colors.white),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEDF4FB), Color(0xFFDDE9F9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await fetchImagesFromSupabase();
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _buildHeader(),
                const SizedBox(height: 24),

                const Text("⚙️ Kontrol Mode",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildModeController(
                  label: "Lampu",
                  currentMode: lampuMode,
                  manualStatus: lampuManual,
                  onModeChange: (val) => db.child("lampu_mode").set(val),
                  onManualChange: (val) => db.child("lampu_status").set(val ? 1 : 0),
                ),
                _buildModeController(
                  label: "Relay",
                  currentMode: relayMode,
                  manualStatus: relayManual,
                  onModeChange: (val) => db.child("relay_mode").set(val),
                  onManualChange: (val) => db.child("relay_status").set(val ? 1 : 0),
                ),

                const SizedBox(height: 24),

                const Text("📷 Kamera Pemantau",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildImageGallery(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF11579C),
        title: const Text("Dashboard Monitoring"),
        elevation: 2,
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.account_circle, size: 28),
          )
        ],
      ),
    );
  }
}
