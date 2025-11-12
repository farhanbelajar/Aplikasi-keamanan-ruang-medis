import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

final database = FirebaseDatabase.instance.ref();
final rfid_logs = database.child('rfid_logs');
final dht_logs = database.child('dht_logs');
final sensor_logs = database.child('sensor_logs');

enum DataSourceMode { dht, sensor, gabungan }

class GrafikSensor extends StatefulWidget {
  const GrafikSensor({super.key});

  @override
  State<GrafikSensor> createState() => _GrafikSensorState();
}

class _GrafikSensorState extends State<GrafikSensor> with TickerProviderStateMixin {
  Map<dynamic, dynamic>? logs;
  Map<String, List<_ChartData>> uidDataMap = {};
  List<String> uniqueUids = [];
  late TooltipBehavior _tooltipBehavior;
  late ZoomPanBehavior _zoomPanBehavior;

  DateTime? startDate;
  DateTime? endDate;

  List<Map<String, dynamic>> suhuData = [];
  List<Map<String, dynamic>> kelembapanData = [];
  List<Map<String, dynamic>> luxData = [];
  bool isDataLoaded = false;

  DataSourceMode currentSource = DataSourceMode.sensor;

  bool showSuhu = true;
  bool showKelembapan = true;
  bool showLux = true;

  @override
  void initState() {
    super.initState();

    _tooltipBehavior = TooltipBehavior(enable: true, header: '', canShowMarker: true);
    _zoomPanBehavior = ZoomPanBehavior(
      enablePinching: true,
      enablePanning: true,
      zoomMode: ZoomMode.xy,
      enableMouseWheelZooming: true,
    );

    rfid_logs.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map<dynamic, dynamic>) {
        setState(() {
          logs = data;
          _processData(data);
        });
      }
    });

    dht_logs.onValue.listen((event) {
      if (currentSource == DataSourceMode.dht || currentSource == DataSourceMode.gabungan) {
        final data = event.snapshot.value as Map?;
        if (data != null) {
          final newSuhuData = <Map<String, dynamic>>[];
          final newKelembapanData = <Map<String, dynamic>>[];

          data.forEach((key, value) {
            if (value is Map) {
              final entry = Map<String, dynamic>.from(value);
              final timestamp = DateTime.tryParse(entry['timestamp'].toString());
              final suhu = double.tryParse(entry['suhu'].toString());
              final kelembapan = double.tryParse(entry['kelembapan'].toString());

              if (timestamp != null && suhu != null && kelembapan != null) {
                newSuhuData.add({'time': timestamp, 'value': suhu});
                newKelembapanData.add({'time': timestamp, 'value': kelembapan});
              }
            }
          });

          newSuhuData.sort((a, b) => a['time'].compareTo(b['time']));
          newKelembapanData.sort((a, b) => a['time'].compareTo(b['time']));

          if (newSuhuData.length > 20) newSuhuData.removeRange(0, newSuhuData.length - 20);
          if (newKelembapanData.length > 20) newKelembapanData.removeRange(0, newKelembapanData.length - 20);

          setState(() {
            suhuData = newSuhuData;
            kelembapanData = newKelembapanData;
            isDataLoaded = true;
          });
        }
      }
    });

    sensor_logs.onValue.listen((event) {
      if (currentSource == DataSourceMode.sensor || currentSource == DataSourceMode.gabungan) {
        final data = event.snapshot.value as Map?;
        if (data != null) {
          final newSuhuData = <Map<String, dynamic>>[];
          final newKelembapanData = <Map<String, dynamic>>[];
          final newLuxData = <Map<String, dynamic>>[];

          data.forEach((key, value) {
            if (value is Map) {
              final entry = Map<String, dynamic>.from(value);
              final timestampStr = entry['timestamp']?.toString();
              final suhu = double.tryParse(entry['suhu']?.toString() ?? '');
              final kelembapan = double.tryParse(entry['kelembapan']?.toString() ?? '');
              final lux = double.tryParse(entry['lux']?.toString() ?? '');

              DateTime? timestamp;
              if (timestampStr != null) {
                try {
                  timestamp = DateTime.parse(timestampStr);
                } catch (_) {}
              }

              if (timestamp != null) {
                if (suhu != null) newSuhuData.add({'time': timestamp, 'value': suhu});
                if (kelembapan != null) newKelembapanData.add({'time': timestamp, 'value': kelembapan});
                if (lux != null) newLuxData.add({'time': timestamp, 'value': lux});
              }
            }
          });

          void sortAndTrim(List<Map<String, dynamic>> list) {
            list.sort((a, b) => (a['time'] as DateTime).compareTo(b['time'] as DateTime));
            if (list.length > 20) list.removeRange(0, list.length - 20);
          }

          sortAndTrim(newSuhuData);
          sortAndTrim(newKelembapanData);
          sortAndTrim(newLuxData);

          setState(() {
            suhuData = newSuhuData;
            kelembapanData = newKelembapanData;
            luxData = newLuxData;
            isDataLoaded = true;
          });
        }
      }
    });
  }

  void _processData(Map<dynamic, dynamic> logs) {
    Map<String, List<_ChartData>> tempMap = {};
    Set<String> uidSet = {};

    logs.forEach((key, value) {
      if (value is Map && value['timestamp'] != null && value['uid'] != null) {
        try {
          DateTime dt = DateTime.parse(value['timestamp']);
          String uid = value['uid'];
          uidSet.add(uid);

          if ((startDate == null || dt.isAfter(startDate!)) &&
              (endDate == null || dt.isBefore(endDate!.add(const Duration(days: 1))))) {
            tempMap.putIfAbsent(uid, () => []);
            tempMap[uid]!.add(_ChartData(uid, 1));
          }
        } catch (e) {
          debugPrint("Error parsing timestamp: $e");
        }
      }
    });

    tempMap.forEach((key, list) => list.sort((a, b) => a.label.compareTo(b.label)));

    setState(() {
      uidDataMap = tempMap;
      uniqueUids = uidSet.toList()..sort();
    });
  }

  List<DoughnutSeries<_ChartData, String>> _buildDoughnutSeries() {
    List<_ChartData> chartData = uidDataMap.entries.map((entry) {
      return _ChartData(entry.key, entry.value.length.toDouble());
    }).toList();

    return [
      DoughnutSeries<_ChartData, String>(
        dataSource: chartData,
        xValueMapper: (_ChartData data, _) => data.label,
        yValueMapper: (_ChartData data, _) => data.count,
        dataLabelSettings: const DataLabelSettings(isVisible: true),
        enableTooltip: true,
        innerRadius: '60%',
        radius: '100%',
      )
    ];
  }

  Widget _buildChart({
    required String title,
    required List<Map<String, dynamic>> data,
    required String yAxisTitle,
    required Color color,
    required bool visible,
  }) {
    if (!visible) return const SizedBox.shrink();
    if (data.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SizedBox(
          height: 160,
          child: Center(
            child: Text(
              "Tidak ada data untuk $title",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ),
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.indigo.shade50),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              Text(yAxisTitle, style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 200,
            child: SfCartesianChart(
              primaryXAxis: DateTimeAxis(
                intervalType: DateTimeIntervalType.minutes,
                edgeLabelPlacement: EdgeLabelPlacement.shift,
                majorGridLines: const MajorGridLines(width: 0.5),
                axisLine: const AxisLine(width: 0),
              ),
              primaryYAxis: NumericAxis(
                minimum: 0,
                title: AxisTitle(text: yAxisTitle),
                axisLine: const AxisLine(width: 0),
              ),
              zoomPanBehavior: _zoomPanBehavior,
              tooltipBehavior: _tooltipBehavior,
              series: <CartesianSeries>[
                LineSeries<Map<String, dynamic>, DateTime>(
                  dataSource: data,
                  xValueMapper: (d, _) => d['time'] as DateTime,
                  yValueMapper: (d, _) => d['value'] as double,
                  markerSettings: const MarkerSettings(isVisible: true),
                  color: color,
                  animationDuration: 400,
                  name: title,
                  width: 2,
                )
              ],
              legend: Legend(isVisible: false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestSummary() {
    if (suhuData.isEmpty && kelembapanData.isEmpty && luxData.isEmpty) return const SizedBox();
    DateTime? latest;
    if (suhuData.isNotEmpty) latest = suhuData.last['time'] as DateTime;
    if (kelembapanData.isNotEmpty) {
      final kp = kelembapanData.last['time'] as DateTime;
      if (latest == null || kp.isAfter(latest)) latest = kp;
    }
    if (luxData.isNotEmpty) {
      final l = luxData.last['time'] as DateTime;
      if (latest == null || l.isAfter(latest)) latest = l;
    }
    final suhu = suhuData.isNotEmpty ? suhuData.last['value'] : null;
    final kelembapan = kelembapanData.isNotEmpty ? kelembapanData.last['value'] : null;
    final lux = luxData.isNotEmpty ? luxData.last['value'] : null;

    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.indigo.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(10),
            child: const Icon(Icons.local_hospital, size: 28, color: Colors.indigo),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Data Terakhir",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 6),
                if (latest != null)
                  Text("Waktu: ${latest.toLocal().toString().split('.').first}",
                      style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    if (suhu != null)
                      Chip(
                        backgroundColor: Colors.red.shade50,
                        avatar: const Icon(Icons.thermostat, size: 16, color: Colors.red),
                        label: Text("Suhu: ${suhu.toStringAsFixed(1)}°C"),
                      ),
                    if (kelembapan != null)
                      Chip(
                        backgroundColor: Colors.blue.shade50,
                        avatar: const Icon(Icons.water_drop, size: 16, color: Colors.blue),
                        label: Text("Kelembapan: ${kelembapan.toStringAsFixed(1)}%"),
                      ),
                    if (lux != null)
                      Chip(
                        backgroundColor: Colors.amber.shade50,
                        avatar: const Icon(Icons.light_mode, size: 16, color: Colors.amber),
                        label: Text("Lux: ${lux.toStringAsFixed(2)}"),
                      ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _pickDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: Colors.indigo, // header
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: Colors.indigo),
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });

      if (logs != null) {
        _processData(logs!);
      }
    }
  }

  String _sourceLabel() {
    switch (currentSource) {
      case DataSourceMode.dht:
        return 'DHT Logs';
      case DataSourceMode.sensor:
        return 'Sensor Logs';
      case DataSourceMode.gabungan:
        return 'Gabungan';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9F2FA),
      appBar: AppBar(
        title: const Text('Grafik Sensor'),
        backgroundColor: Colors.indigo.shade700,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _pickDateRange,
            tooltip: 'Filter rentang tanggal',
          )
        ],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
        ),
      ),
      body: logs == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () async {
          if (logs != null) _processData(logs!);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    "📊 Distribusi Akses UID (RFID)",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade900,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_sourceLabel(),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                )
              ],
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Total Akses per UID',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      DropdownButton<DataSourceMode>(
                        value: currentSource,
                        items: const [
                          DropdownMenuItem(value: DataSourceMode.dht, child: Text("DHT")),
                          DropdownMenuItem(value: DataSourceMode.sensor, child: Text("Sensor")),
                          DropdownMenuItem(
                              value: DataSourceMode.gabungan, child: Text("Gabungan")),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setState(() {
                              currentSource = v;
                              suhuData = [];
                              kelembapanData = [];
                              luxData = [];
                              isDataLoaded = false;
                            });
                          }
                        },
                        underline: const SizedBox(),
                        isDense: true,
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 200,
                    child: SfCircularChart(
                      legend: Legend(
                          isVisible: true,
                          overflowMode: LegendItemOverflowMode.wrap,
                          position: LegendPosition.bottom),
                      tooltipBehavior: _tooltipBehavior,
                      series: _buildDoughnutSeries(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "🌡️ Grafik Suhu, Kelembapan & Lux",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildLatestSummary(),
            // toggles
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  FilterChip(
                    label: const Text("Suhu"),
                    selected: showSuhu,
                    onSelected: (v) => setState(() => showSuhu = v),
                    avatar: const Icon(Icons.thermostat, size: 18),
                    selectedColor: Colors.red.shade100,
                  ),
                  FilterChip(
                    label: const Text("Kelembapan"),
                    selected: showKelembapan,
                    onSelected: (v) => setState(() => showKelembapan = v),
                    avatar: const Icon(Icons.water_drop, size: 18),
                    selectedColor: Colors.blue.shade100,
                  ),
                  FilterChip(
                    label: const Text("Lux"),
                    selected: showLux,
                    onSelected: (v) => setState(() => showLux = v),
                    avatar: const Icon(Icons.light_mode, size: 18),
                    selectedColor: Colors.amber.shade100,
                  ),
                ],
              ),
            ),
            if (startDate != null && endDate != null)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Rentang: ${startDate!.toLocal().toString().split(' ').first} - ${endDate!.toLocal().toString().split(' ').first}",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: "Reset rentang",
                    onPressed: () {
                      setState(() {
                        startDate = null;
                        endDate = null;
                        if (logs != null) _processData(logs!);
                      });
                    },
                  ),
                ],
              ),
            _buildChart(
              title: "Grafik Suhu (°C)",
              data: suhuData,
              yAxisTitle: "°C",
              color: Colors.redAccent,
              visible: showSuhu,
            ),
            _buildChart(
              title: "Grafik Kelembapan (%)",
              data: kelembapanData,
              yAxisTitle: "%",
              color: Colors.blue,
              visible: showKelembapan,
            ),
            _buildChart(
              title: "Grafik Lux (intensitas cahaya)",
              data: luxData,
              yAxisTitle: "lux",
              color: Colors.amber.shade700,
              visible: showLux,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ChartData {
  final dynamic label;
  final double count;

  _ChartData(this.label, this.count);

  DateTime get time => label is DateTime ? label : DateTime.now();
}
