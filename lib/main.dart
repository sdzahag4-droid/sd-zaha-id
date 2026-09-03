import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

// Ganti dengan URL Web App Google Apps Script Anda
const String scriptUrl = "https://script.google.com/macros/s/AKfycbzmwc8kVmf17HjXVn7MFf-85ZxPfZG8x0oc4aI2j64Ym6sphMp2vhnRfrIyoTHokYD5gg/exec";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SD ZAHA.ID',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SD ZAHA.ID - Portal Sekolah', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green[700],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        children: [
          MenuCard(title: 'Absensi Guru', icon: Icons.how_to_reg, color: Colors.blue, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AbsenScreen()))),
          MenuCard(title: 'Rekap Absen', icon: Icons.assessment, color: Colors.brown, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DataViewScreen(sheetName: 'RekapAbsen', title: 'Rekap Absen')))),
          MenuCard(title: 'Jadwal Sekolah', icon: Icons.schedule, color: Colors.orange, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DataViewScreen(sheetName: 'Jadwal', title: 'Jadwal Sekolah')))),
          MenuCard(title: 'Sarana Prasarana', icon: Icons.inventory, color: Colors.purple, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DataViewScreen(sheetName: 'Sarana', title: 'Sarana Sekolah')))),
          MenuCard(title: 'Agenda Sekolah', icon: Icons.event, color: Colors.red, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DataViewScreen(sheetName: 'Agenda', title: 'Agenda Sekolah')))),
          MenuCard(title: 'Profil Guru & Karyawan', icon: Icons.people, color: Colors.teal, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DataViewScreen(sheetName: 'GuruKaryawan', title: 'Profil Guru & Karyawan')))),
          MenuCard(title: 'Chat Admin', icon: Icons.chat, color: Colors.green, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatAdminScreen()))),
          MenuCard(title: 'Sosial Media', icon: Icons.share, color: Colors.indigo, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SosmedScreen()))),
          MenuCard(title: 'Informasi Penting', icon: Icons.info, color: Colors.amber, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DataViewScreen(sheetName: 'Informasi', title: 'Informasi Penting')))),
        ],
      ),
    );
  }
}

class MenuCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const MenuCard({super.key, required this.title, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class AbsenScreen extends StatefulWidget {
  const AbsenScreen({super.key});

  @override
  State<AbsenScreen> createState() => _AbsenScreenState();
}

class _AbsenScreenState extends State<AbsenScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ketController = TextEditingController();
  bool isLoading = false;

  void submitAbsen(String status, {bool needGps = false, bool needCamera = false, bool useBackCamera = false}) async {
    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama Lengkap wajib diisi!')));
      return;
    }

    setState(() => isLoading = true);

    try {
      String gpsData = "-";
      if (needGps) {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) throw 'GPS tidak aktif. Mohon aktifkan GPS.';
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) throw 'Izin GPS ditolak.';
        }
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        gpsData = "${position.latitude}, ${position.longitude}";
      }

      String fotoData = "-";
      if (needCamera) {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: useBackCamera ? CameraDevice.rear : CameraDevice.front,
        );
        if (image != null) fotoData = image.path;
      }

      var body = {
        "action": "absen",
        "nama": nameController.text,
        "status": status,
        "keterangan": ketController.text,
        "waktu": DateTime.now().toString(),
        "gps": gpsData,
        "foto": fotoData,
      };

      var response = await http.post(
      Uri.parse(scriptUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Absen Berhasil Terkirim & Notifikasi Telegram Terkirim!')));
        Navigator.pop(context);
      } else {
        throw 'Gagal terhubung ke Google Sheets';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    TimeOfDay now = TimeOfDay.now();
    int currentTimeMinutes = now.hour * 60 + now.minute;

    return Scaffold(
      appBar: AppBar(title: const Text('Menu Absensi Guru')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nama Lengkap', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: ketController, decoration: const InputDecoration(labelText: 'Keterangan / Alasan', border: OutlineInputBorder())),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: (currentTimeMinutes >= 345 && currentTimeMinutes <= 450)
                        ? () => submitAbsen('Absen Masuk', needGps: true, needCamera: true, useBackCamera: false)
                        : null,
                    icon: const Icon(Icons.login),
                    label: const Text('Absen Masuk (05.45 - 07.30 WIB) [GPS + Selfie]'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: (currentTimeMinutes >= 300 && currentTimeMinutes <= 435)
                        ? () => submitAbsen('Absen Izin')
                        : null,
                    icon: const Icon(Icons.assignment),
                    label: const Text('Absen Izin (05.00 - 07.15 WIB)'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: (currentTimeMinutes >= 420 && currentTimeMinutes <= 480)
                        ? () => submitAbsen('Absen Terlambat')
                        : null,
                    icon: const Icon(Icons.warning),
                    label: const Text('Absen Terlambat (07.00 - 08.00 WIB)'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () => submitAbsen('Absen Sakit', needCamera: true, useBackCamera: true),
                    icon: const Icon(Icons.sick),
                    label: const Text('Absen Sakit (Bebas Jam + Kamera Belakang)'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () => submitAbsen('Absen Cuti', needCamera: true, useBackCamera: true),
                    icon: const Icon(Icons.beach_access),
                    label: const Text('Absen Cuti (Bebas Jam + Kamera Belakang)'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () => submitAbsen('Absen Tidak Masuk'),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Absen Tidak Masuk (Wajib Isi Keterangan)'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: (currentTimeMinutes >= 600 && currentTimeMinutes <= 840)
                        ? () => submitAbsen('Absen Pulang', needGps: true, needCamera: true, useBackCamera: false)
                        : null,
                    icon: const Icon(Icons.logout),
                    label: const Text('Absen Pulang (10.00 - 14.00 WIB) [GPS + Selfie]'),
                  ),
                ],
              ),
            ),
    );
  }
}

class DataViewScreen extends StatefulWidget {
  final String sheetName;
  final String title;
  const DataViewScreen({super.key, required this.sheetName, required this.title});

  @override
  State<DataViewScreen> createState() => _DataViewScreenState();
}

class _DataViewScreenState extends State<DataViewScreen> {
  List dataList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  void fetchData() async {
    try {
      final response = await http.get(Uri.parse("$scriptUrl?action=getData&sheet=${widget.sheetName}"));
      if (response.statusCode == 200) {
        setState(() {
          dataList = jsonDecode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : dataList.isEmpty
              ? const Center(child: Text('Belum ada data di Google Sheets.'))
              : ListView.builder(
                  itemCount: dataList.length,
                  itemBuilder: (context, index) {
                    var item = dataList[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(item.values.first.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(item.toString()),
                      ),
                    );
                  },
                ),
    );
  }
}

class ChatAdminScreen extends StatelessWidget {
  const ChatAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat Admin Sekolah')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.chat, color: Colors.green, size: 36),
            title: const Text('WhatsApp Admin SD ZAHA.ID'),
            subtitle: const Text('Ketuk untuk diarahkan ke WhatsApp Admin'),
            onTap: () => launchUrl(Uri.parse("https://wa.me/6281234567890"), mode: LaunchMode.externalApplication),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.telegram, color: Colors.blue, size: 36),
            title: const Text('Telegram Admin SD ZAHA.ID'),
            subtitle: const Text('Ketuk untuk diarahkan ke Telegram Admin'),
            onTap: () => launchUrl(Uri.parse("https://t.me/username_admin"), mode: LaunchMode.externalApplication),
          ),
        ],
      ),
    );
  }
}

class SosmedScreen extends StatelessWidget {
  const SosmedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sosial Media Sekolah')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Colors.purple),
            title: const Text('Instagram Resmi SD ZAHA.ID'),
            onTap: () => launchUrl(Uri.parse("https://instagram.com"), mode: LaunchMode.externalApplication),
          ),
          ListTile(
            leading: const Icon(Icons.video_collection, color: Colors.black),
            title: const Text('TikTok Resmi SD ZAHA.ID'),
            onTap: () => launchUrl(Uri.parse("https://tiktok.com"), mode: LaunchMode.externalApplication),
          ),
          ListTile(
            leading: const Icon(Icons.play_arrow, color: Colors.red),
            title: const Text('Channel YouTube SD ZAHA.ID'),
            onTap: () => launchUrl(Uri.parse("https://youtube.com"), mode: LaunchMode.externalApplication),
          ),
          ListTile(
            leading: const Icon(Icons.message, color: Colors.green),
            title: const Text('Channel WhatsApp SD ZAHA.ID'),
            onTap: () => launchUrl(Uri.parse("https://whatsapp.com"), mode: LaunchMode.externalApplication),
          ),
          ListTile(
            leading: const Icon(Icons.send, color: Colors.blue),
            title: const Text('Channel Telegram SD ZAHA.ID'),
            onTap: () => launchUrl(Uri.parse("https://t.me/channel_sekolah"), mode: LaunchMode.externalApplication),
          ),
        ],
      ),
    );
  }
}