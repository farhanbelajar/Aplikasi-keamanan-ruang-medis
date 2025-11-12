import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skripsi_hangans/database/realtime_database.dart';
import 'package:skripsi_hangans/ui/ImageDetail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Riwayatpage extends StatefulWidget {
  @override
  State<Riwayatpage> createState() => _RiwayatpageState();
}

class _RiwayatpageState extends State<Riwayatpage> {
  Map<dynamic, dynamic>? logs;
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  final Map<String, String> uidNameMap = {
    "D7DE2502": "Dr. Muhammad Farhan",
    "6401C801": "Dr. Dwi Lestari Budiasih",
    // Tambahkan UID lainnya jika perlu
  };

  final Map<String, String> uidPhotoMap = {
    "D7DE2502": "assets/farhan.jpeg",
    "6401C801": "assets/dwi.jpeg",
    // fallback: Supabase
  };

  @override
  void initState() {
    super.initState();
    rfid_logs.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map<dynamic, dynamic>) {
        setState(() {
          logs = data;
        });
      }
    });
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text.trim();
      });
    });
  }

  String _formatTime(String timestamp) {
    try {
      DateTime dt = DateTime.parse(timestamp);
      return DateFormat('dd MMM yyyy, HH:mm:ss').format(dt);
    } catch (e) {
      return timestamp;
    }
  }

  String _groupKey(String timestamp) {
    try {
      DateTime dt = DateTime.parse(timestamp);
      return DateFormat('yyyy-MM-dd').format(dt);
    } catch (_) {
      return 'Unknown';
    }
  }

  Future<String?> fetchLatestImageUrlForUid(String uid) async {
    final SupabaseClient supabase = Supabase.instance.client;
    try {
      final files = await supabase.storage.from('camera').list();
      final userImages = files.where((file) => file.name.startsWith(uid)).toList();
      if (userImages.isEmpty) return null;
      userImages.sort((a, b) => b.name.compareTo(a.name));
      final latestFile = userImages.first;
      return supabase.storage.from('camera').getPublicUrl(latestFile.name);
    } catch (e) {
      debugPrint('Error saat mengambil gambar terbaru: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (logs == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Riwayat Pengguna RFID'),
          backgroundColor: Colors.indigo,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Prepare and filter
    final entries = logs!.entries.toList()
      ..sort((a, b) {
        final tsA = a.value['timestamp']?.toString() ?? '';
        final tsB = b.value['timestamp']?.toString() ?? '';
        return tsB.compareTo(tsA);
      });

    final filtered = entries.where((entry) {
      final item = entry.value;
      if (item is Map && item['uid'] != null) {
        final uid = item['uid'].toString().toLowerCase();
        final name = uidNameMap[uid.toUpperCase()]?.toLowerCase() ?? '';
        return uid.contains(searchQuery.toLowerCase()) ||
            name.contains(searchQuery.toLowerCase());
      }
      return false;
    }).toList();

    // Group by day
    final Map<String, List<MapEntry<dynamic, dynamic>>> grouped = {};
    for (var e in filtered) {
      final timestamp = (e.value is Map) ? (e.value['timestamp']?.toString() ?? '') : '';
      final key = _groupKey(timestamp);
      grouped.putIfAbsent(key, () => []).add(e);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Riwayat Pengguna RFID'),
        backgroundColor: Colors.indigo,
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 300));
          setState(() {}); // rebuild from listener
        },
        child: Column(
          children: [
            // search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Material(
                elevation: 3,
                borderRadius: BorderRadius.circular(14),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau UID...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        searchController.clear();
                        setState(() => searchQuery = '');
                      },
                    )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            if (filtered.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.history, size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(
                        searchQuery.isEmpty
                            ? "Belum ada riwayat."
                            : "Tidak ditemukan: \"$searchQuery\"",
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      if (searchQuery.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            searchController.clear();
                            setState(() => searchQuery = '');
                          },
                          child: const Text("Reset pencarian"),
                        )
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 16),
                  children: grouped.entries.map((group) {
                    final dayKey = group.key;
                    final list = group.value;
                    String humanDate;
                    if (dayKey == 'Unknown') {
                      humanDate = 'Tanggal tidak diketahui';
                    } else {
                      final parsed = DateTime.tryParse(dayKey);
                      humanDate = parsed != null
                          ? DateFormat('EEEE, dd MMM yyyy').format(parsed)
                          : dayKey;
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // header
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            child: Text(
                              humanDate,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo.shade700,
                              ),
                            ),
                          ),
                          ...List.generate(list.length, (idx) {
                            final entry = list[idx];
                            final key = entry.key;
                            final item = entry.value;
                            final delay = (idx + 1) * 80;
                            if (item is Map && item['uid'] != null && item['timestamp'] != null) {
                              final uid = item['uid'].toString();
                              final isKnownUid = uidNameMap.containsKey(uid);
                              final name = isKnownUid
                                  ? uidNameMap[uid]!
                                  : "Orang Asing (UID: $uid)";
                              final supabaseFallback =
                                  "https://hogopaorxqjnblsejcnp.supabase.co/storage/v1/object/public/profile_images/$uid.jpg";
                              final photoUrl = uidPhotoMap[uid] ?? supabaseFallback;

                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: 1),
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOut,
                                builder: (context, val, child) => Opacity(
                                  opacity: val,
                                  child: Transform.translate(
                                    offset: Offset(0, (1 - val) * 8),
                                    child: child,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  child: Card(
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    color: isKnownUid ? Colors.white : Colors.red.shade50,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(14),
                                      onTap: () async {
                                        final latestImageUrl =
                                        await fetchLatestImageUrlForUid(uid);
                                        if (!context.mounted) return;
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => DetailImagePage(
                                              imageUrl: latestImageUrl ?? "",
                                              name: name,
                                              uid: uid,
                                              timestamp: item['timestamp'],
                                            ),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 12),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Stack(
                                              alignment: Alignment.bottomRight,
                                              children: [
                                                CircleAvatar(
                                                  backgroundImage: photoUrl.startsWith('assets/')
                                                      ? AssetImage(photoUrl) as ImageProvider
                                                      : NetworkImage(photoUrl),
                                                  radius: 28,
                                                  backgroundColor: Colors.grey[200],
                                                ),
                                                if (!isKnownUid)
                                                  Container(
                                                    padding: const EdgeInsets.all(4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      shape: BoxShape.circle,
                                                      boxShadow: [
                                                        BoxShadow(
                                                            color: Colors.black12,
                                                            blurRadius: 4)
                                                      ],
                                                    ),
                                                    child: const Icon(
                                                      Icons.warning_amber_rounded,
                                                      color: Colors.red,
                                                      size: 18,
                                                    ),
                                                  )
                                              ],
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          name,
                                                          style: const TextStyle(
                                                              fontWeight: FontWeight.w600,
                                                              fontSize: 16),
                                                          overflow:
                                                          TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      if (!isKnownUid)
                                                        const Padding(
                                                          padding:
                                                          EdgeInsets.only(left: 6),
                                                          child: Icon(
                                                            Icons.report_problem,
                                                            color: Colors.red,
                                                            size: 18,
                                                          ),
                                                        )
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.access_time,
                                                        size: 14,
                                                        color: Colors.grey,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Flexible(
                                                        child: Text(
                                                          _formatTime(
                                                              item['timestamp']
                                                                  .toString()),
                                                          style: const TextStyle(
                                                              fontSize: 12,
                                                              color: Colors.black87),
                                                          overflow:
                                                          TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text("Log ID: $key",
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey[700])),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(Icons.arrow_forward_ios_rounded,
                                                size: 18, color: Colors.indigo),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                child: Card(
                                  color: Colors.red.shade50,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                  child: ListTile(
                                    leading:
                                    const Icon(Icons.error, color: Colors.red),
                                    title: const Text('Data tidak valid'),
                                    subtitle: Text('$item'),
                                    trailing: Text('ID: $key',
                                        style: const TextStyle(fontSize: 12)),
                                  ),
                                ),
                              );
                            }
                          })
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
