import 'package:firebase_database/firebase_database.dart';

final database = FirebaseDatabase.instance.ref();
final Cahaya = database.child('Cahaya');
final Kelembapan = database.child('Kelembapan');
final Suhu = database.child('Suhu');
final rfid_logs = database.child('rfid_logs');
final dht_logs = database.child('dht_logs/');
final sensor_logs = database.child('sensor_logs/');