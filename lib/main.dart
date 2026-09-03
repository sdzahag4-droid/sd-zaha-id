import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

const String scriptUrl = "URL_WEB_APP_GOOGLE_SCRIPT_ANDA";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SD ZAHA.ID',
      theme: ThemeData(primarySwatch: Colors.green),
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
      appBar: AppBar(title: const Text('SD ZAHA.ID - Portal Sekolah')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        children: [
          MenuCard(title: 'Absensi Guru', icon: Icons.how_to_reg, color: Colors.blue, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AbsenScreen()))),
          MenuCard(title: 'Jadwal Sekolah', icon: Icons.schedule, color: Colors.orange, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DataViewScreen(sheetName: 'Jadwal', title: 'Jadwal Sekolah')))),
          MenuCard(title: 'Sarana Prasarana', icon: Icons.inventory, color: Colors.purple, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DataViewScreen(sheetName: 'Sarana', title: 'Sarana Sekolah')))),
          MenuCard(title: 'Agenda', icon: Icons.event, color: Colors.red, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DataViewScreen(sheetName: 'Agenda', title: 'Agenda Sekolah')))),
          MenuCard(title: 'Profil Guru', icon: Icons.people, color: Colors.teal, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DataViewScreen(sheetName: 'GuruKaryawan', title: 'Profil Guru & Karyawan')))),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
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

  void submitAbsen(String status, {bool needGps = false, bool needCamera = false}) async {
    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama wajib diisi!')));
      return;
    }

    String gpsData = "-";
    if (needGps) {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      gpsData = "${position.latitude}, ${position.longitude}";
    }

    String fotoData = "-";
    if (needCamera) {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        fotoData = image.path; 
      }
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

    var response = await http.post(Uri.parse(scriptUrl), body: jsonEncode(body));
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Absen Berhasil Terkirim!')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    TimeOfDay now = TimeOfDay.now();
    int currentTimeMinutes = now.hour * 60 + now.minute;

    return Scaffold(
      appBar: AppBar(title: const Text('Menu Absensi Guru')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nama Lengkap')),
            TextField(controller: ketController, decoration: const InputDecoration(labelText: 'Keterangan (Opsional)')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: (currentTimeMinutes >= 345 && currentTimeMinutes <= 450) // 05.45 - 07.30
                  ? () => submitAbsen('Absen Masuk', needGps: true, needCamera: true)
                  : null,
              child: const Text('Absen Masuk (05.45 - 07.30)'),
            ),
            ElevatedButton(
              onPressed: (currentTimeMinutes >= 300 && currentTimeMinutes <= 435) // 05.00 - 07.15
                  ? () => submitAbsen('Absen Izin')
                  : null,
              child: const Text('Absen Izin (05.00 - 07.15)'),
            ),
            ElevatedButton(
              onPressed: (currentTimeMinutes >= 420 && currentTimeMinutes <= 480) // 07.00 - 08.00
                  ? () => submitAbsen('Absen Terlambat')
                  : null,
              child: const Text('Absen Terlambat (07.00 - 08.00)'),
            ),
            ElevatedButton(
              onPressed: () => submitAbsen('Absen Sakit', needCamera: true),
              child: const Text('Absen Sakit (Wajib Foto)'),
            ),
            ElevatedButton(
              onPressed: () => submitAbsen('Absen Cuti', needCamera: true),
              child: const Text('Absen Cuti (Wajib Foto)'),
            ),
            ElevatedButton(
              onPressed: () => submitAbsen('Absen Tidak Masuk'),
              child: const Text('Absen Tidak Masuk'),
            ),
            ElevatedButton(
              onPressed: (currentTimeMinutes >= 600 && currentTimeMinutes <= 840) // 10.00 - 14.00
                  ? () => submitAbsen('Absen Pulang', needGps: true, needCamera: true)
                  : null,
              child: const Text('Absen Pulang (10.00 - 14.00)'),
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
    final response = await http.get(Uri.parse("$scriptUrl?action=getData&sheet=${widget.sheetName}"));
    if (response.statusCode == 200) {
      setState(() {
        dataList = jsonDecode(response.body);
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: dataList.length,
              itemBuilder: (context, index) {
                var item = dataList[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
            leading: const Icon(Icons.chat, color: Colors.green),
            title: const Text('WhatsApp Admin SD ZAHA'),
            subtitle: const Text('Klik untuk langsung chat via WA'),
            onTap: () => launchUrl(Uri.parse("https://wa.me/6281234567890"), mode: LaunchMode.externalApplication),
          ),
          ListTile(
            leading: const Icon(Icons.telegram, color: Colors.blue),
            title: const Text('Telegram Admin SD ZAHA'),
            subtitle: const Text('Klik untuk langsung chat via Telegram'),
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
          ListTile(title: const Text('Instagram Resmi'), onTap: () => launchUrl(Uri.parse("https://instagram.com"))),
          ListTile(title: const Text('TikTok Resmi'), onTap: () => launchUrl(Uri.parse("https://tiktok.com"))),
          ListTile(title: const Text('Channel YouTube'), onTap: () => launchUrl(Uri.parse("https://youtube.com"))),
          ListTile(title: const Text('Channel WhatsApp'), onTap: () => launchUrl(Uri.parse("https://whatsapp.com"))),
        ],
      ),
    );
  }
}