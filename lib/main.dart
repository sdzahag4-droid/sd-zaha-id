import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
      home: const PortalScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// 1. Portal Utama Sekolah
class PortalScreen extends StatelessWidget {
  const PortalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SD Zainul Hasan Genggong')),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildMenuCard(
              context,
              'Absensi Guru',
              Icons.how_to_reg,
              const LoginGuruScreen(),
            ),
            const SizedBox(width: 20),
            _buildMenuCard(
              context,
              'Rekap Absen',
              Icons.bar_chart,
              const PlaceholderScreen(title: 'Rekap Absen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, Widget targetScreen) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => targetScreen));
      },
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.blueGrey),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// 2. Halaman Login Guru (Mengambil data dari Sheet GuruKaryawan)
class LoginGuruScreen extends StatefulWidget {
  const LoginGuruScreen({super.key});

  @override
  State<LoginGuruScreen> createState() => _LoginGuruScreenState();
}

class _LoginGuruScreenState extends State<LoginGuruScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // Ganti dengan URL Web App Apps Script Anda yang aktif
  final String webAppUrl = "MASUKKAN_URL_WEB_APP_APPS_SCRIPT_ANDA_DISINI";

  void _login() async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username dan Password harus diisi!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Mengambil data dari sheet GuruKaryawan menggunakan doGet getData
      final response = await http.get(Uri.parse('$webAppUrl?action=getData&sheet=GuruKaryawan'));
      
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        
        // Cari data guru berdasarkan Username & Password (Kolom G dan H)
        var guru = data.firstWhere(
          (item) => item['Username'].toString().toLowerCase() == username.toLowerCase() &&
                    item['Password'].toString() == password,
          orElse: () => null,
        );

        setState(() => _isLoading = false);

        if (guru != null) {
          String namaLengkap = guru['Nama Lengkap'] ?? 'Tanpa Nama';
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AbsenScreen(namaGuru: namaLengkap),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Username atau Password salah!')),
          );
        }
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal terhubung ke database server.')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login Absensi Guru')),
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 10)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Silakan Login', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('MASUK', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 3. Menu Absensi Guru (Tanpa input Nama & Keterangan statis di atas)
class AbsenScreen extends StatefulWidget {
  final String namaGuru;
  const AbsenScreen({super.key, required this.namaGuru});

  @override
  State<AbsenScreen> createState() => _AbsenScreenState();
}

class _AbsenScreenState extends State<AbsenScreen> {
  final String webAppUrl = "MASUKKAN_URL_WEB_APP_APPS_SCRIPT_ANDA_DISINI";

  void submitAbsen(String status, {bool needKeterangan = false}) async {
    String keterangan = "-";

    // Jika jenis absen memerlukan keterangan (Izin, Sakit, Cuti, Tidak Masuk), tampilkan dialog input
    if (needKeterangan) {
      TextEditingController ketController = TextEditingController();
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Masukkan Keterangan untuk $status'),
            content: TextField(
              controller: ketController,
              decoration: const InputDecoration(hintText: 'Tuliskan alasan/keterangan...'),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Kirim')),
            ],
          );
        },
      );

      if (confirm != true || ketController.text.trim().isEmpty) {
        return; // Batalkan jika user batal atau keterangan kosong
      }
      keterangan = ketController.text.trim();
    }

    var body = {
      "action": "absen",
      "nama": widget.namaGuru,
      "status": status,
      "keterangan": keterangan,
      "waktu": TimeOfDay.now().format(context),
      "foto": "-",
      "gps": "-"
    };

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      var response = await http.post(
        Uri.parse(webAppUrl),
        body: jsonEncode(body),
        headers: {"Content-Type": "application/json"},
      );

      Navigator.pop(context); // Tutup loading

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Absen Berhasil: $status')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengirim data absen ke server.')),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Menu Absensi Guru (${widget.namaGuru})')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text("Selamat Datang, ${widget.namaGuru}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildAbsenButton('Absen Masuk (05.45 - 07.30 WIB)', Icons.login, Colors.green, () => submitAbsen('Hadir - Masuk')),
            _buildAbsenButton('Absen Izin (05.00 - 07.15 WIB)', Icons.assignment_outlined, Colors.orange, () => submitAbsen('Izin', needKeterangan: true)),
            _buildAbsenButton('Absen Terlambat (07.00 - 08.00 WIB)', Icons.alarm, Colors.amber, () => submitAbsen('Terlambat', needKeterangan: true)),
            _buildAbsenButton('Absen Sakit (Bebas Jam + Kamera Belakang)', Icons.sick, Colors.purple, () => submitAbsen('Sakit', needKeterangan: true)),
            _buildAbsenButton('Absen Cuti (Bebas Jam + Kamera Belakang)', Icons.event_busy, Colors.blueGrey, () => submitAbsen('Cuti', needKeterangan: true)),
            _buildAbsenButton('Absen Tidak Masuk (Wajib Isi Keterangan)', Icons.cancel, Colors.red, () => submitAbsen('Tidak Masuk', needKeterangan: true)),
            _buildAbsenButton('Absen Pulang (10.00 - 14.00 WIB)', Icons.logout, Colors.teal, () => submitAbsen('Pulang')),
          ],
        ),
      ),
    );
  }

  Widget _buildAbsenButton(String title, IconData icon, Color color, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(16),
          alignment: Alignment.centerLeft,
        ),
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(title, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Halaman $title dalam pengembangan')),
    );
  }
}