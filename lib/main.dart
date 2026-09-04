import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math'; // ✅ Untuk fungsi hitung jarak
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// ==== LOKASI SEKOLAH SD ZAHA.ID ====
const double sekolahLat = -7.787908;
const double sekolahLng = 113.375106;
const double radiusMeter = 100;

// ==== FUNGSI HITUNG JARAK ====
double hitungJarak(double latUser, double lngUser, double latSekolah, double lngSekolah) {
  const double jariJariBumi = 6371000;
  double lat1 = latUser * pi / 180;
  double lat2 = latSekolah * pi / 180;
  double deltaLat = (latSekolah - latUser) * pi / 180;
  double deltaLng = (lngSekolah - lngUser) * pi / 180;

  double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
      cos(lat1) * cos(lat2) *
      sin(deltaLng / 2) * sin(deltaLng / 2);
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return jariJariBumi * c;
}

// ==== DATA LOGIN ====
class LoginData {
  static String nama = "";
  static String username = "";
  static String jabatan = "";
  static String id = "";
  static bool isAdmin = false;
}

// ✅ PENYIMPANAN LOKAL UNTUK FITUR TAMBAH/HAPUS MANUAL
class LocalDataStorage {
  static Map<String, List<String>> items = {
    'Jadwal Sekolah': [
      '07.00 - 07.15 : Upacara / Doa Pagi',
      '07.15 - 12.00 : Kegiatan Belajar Mengajar',
      '12.00 - 13.00 : Istirahat & Sholat Dzuhur Berjamaah'
    ],
    'Sarana Sekolah': [
      'Ruang Kelas 1 sampai 6',
      'Laboratorium Komputer',
      'Perpustakaan Digital Sekolah',
      'Lapangan Olahraga Utama'
    ],
    'Agenda Sekolah': [
      'Rapat Koordinasi Guru dan Karyawan Bulanan',
      'Porseni Antar Kelas Semester Ganjil',
      'Penerimaan Rapor Hasil Belajar Siswa'
    ],
    'Informasi Penting': [
      'Seluruh guru dan karyawan wajib hadir pukul 06.45 WIB.',
      'Pengumpulan rekap penilaian paling lambat akhir pekan ini.'
    ],
  };
}

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
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ==================== HALAMAN LOGIN ====================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  void handleLogin() async {
    if (usernameController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username dan Password wajib diisi!')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(scriptUrl),
        body: jsonEncode({
          "action": "login",
          "username": usernameController.text.trim(),
          "password": passwordController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['status'] == 'success') {
          LoginData.nama = result['nama'] ?? "";
          LoginData.username = result['username'] ?? "";
          LoginData.jabatan = result['jabatan'] ?? "";
          LoginData.id = result['id'] ?? "";
          LoginData.isAdmin = LoginData.username.toLowerCase() == "admin";

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ Selamat datang, ${LoginData.nama}!')),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('⚠️ ${result['message']}')),
          );
        }
      } else {
        throw 'Gagal terhubung ke server';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Guru & Karyawan', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green[700],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.school, size: 80, color: Colors.green),
                const SizedBox(height: 16),
                const Text(
                  'SD Zainul Hasan Genggong',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                    ),
                    onPressed: isLoading ? null : handleLogin,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('LOGIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== HALAMAN UTAMA ====================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SD ZAHA.ID', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              LoginData.nama = "";
              LoginData.username = "";
              LoginData.jabatan = "";
              LoginData.id = "";
              LoginData.isAdmin = false;

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        children: [
          MenuCard(
            title: 'Absensi Guru',
            icon: Icons.how_to_reg,
            color: Colors.blue,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AbsenScreen())),
          ),
          if (LoginData.isAdmin)
            MenuCard(
              title: 'Rekap Absen',
              icon: Icons.assessment,
              color: Colors.brown,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RekapAbsenScreen())),
            ),
          MenuCard(
            title: 'Jadwal Sekolah',
            icon: Icons.schedule,
            color: Colors.orange,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LocalCrudScreen(title: 'Jadwal Sekolah'))),
          ),
          MenuCard(
            title: 'Sarana Prasarana',
            icon: Icons.inventory,
            color: Colors.purple,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LocalCrudScreen(title: 'Sarana Sekolah'))),
          ),
          MenuCard(
            title: 'Agenda Sekolah',
            icon: Icons.event,
            color: Colors.red,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LocalCrudScreen(title: 'Agenda Sekolah'))),
          ),
          MenuCard(
            title: 'Profil Guru & Karyawan',
            icon: Icons.people,
            color: Colors.teal,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GuruKaryawanScreen())),
          ),
          MenuCard(
            title: 'Chat Admin',
            icon: Icons.chat,
            color: Colors.green,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatAdminScreen())),
          ),
          MenuCard(
            title: 'Sosial Media',
            icon: Icons.share,
            color: Colors.indigo,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SosmedScreen())),
          ),
          MenuCard(
            title: 'Informasi Penting',
            icon: Icons.info,
            color: Colors.amber,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LocalCrudScreen(title: 'Informasi Penting'))),
          ),
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

  const MenuCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

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

// ==================== HALAMAN ABSENSI ====================
class AbsenScreen extends StatefulWidget {
  const AbsenScreen({super.key});
  @override
  State<AbsenScreen> createState() => _AbsenScreenState();
}

class _AbsenScreenState extends State<AbsenScreen> {
  late final TextEditingController nameController;
  final TextEditingController ketController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: LoginData.nama);
  }

  void submitAbsen(String status, {bool needGps = false, bool needCamera = false, bool useBackCamera = false}) async {
    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Data login tidak ditemukan. Silakan login ulang!')),
      );
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

        double jarak = hitungJarak(position.latitude, position.longitude, sekolahLat, sekolahLng);
        if (jarak > radiusMeter) {
          throw '❌ Lokasi Terlalu Jauh!\nJarak Anda: ${jarak.toStringAsFixed(0)} meter\nBatas Maksimal: $radiusMeter meter dari sekolah';
        }
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

      var response = await http.post(Uri.parse(scriptUrl), body: jsonEncode(body));

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Absen Berhasil Terkirim!')));
        Navigator.pop(context);
      } else {
        throw 'Gagal terhubung ke Google Sheets';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
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
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Color(0xFFF5F5F5),
                    ),
                    enabled: false,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ketController,
                    decoration: const InputDecoration(
                      labelText: 'Keterangan / Alasan',
                      border: OutlineInputBorder(),
                    ),
                  ),
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

// ==================== REVISI 1: PROFIL GURU & KARYAWAN (BERSIH & NOMOR URUT) ====================
class GuruKaryawanScreen extends StatefulWidget {
  const GuruKaryawanScreen({super.key});

  @override
  State<GuruKaryawanScreen> createState() => _GuruKaryawanScreenState();
}

class _GuruKaryawanScreenState extends State<GuruKaryawanScreen> {
  List dataList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  void fetchData() async {
    try {
      final response = await http.get(Uri.parse("$scriptUrl?action=getData&sheet=GuruKaryawan"));
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
    // Saring baris kosong dan ID == 'SD0'
    final filteredList = dataList.where((item) {
      final id = item['ID']?.toString() ?? '';
      final nama = item['Nama Lengkap']?.toString() ?? '';
      return id != 'SD0' && nama.trim().isNotEmpty;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Profil Guru & Karyawan')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredList.isEmpty
              ? const Center(child: Text('Belum ada data guru & karyawan.'))
              : ListView.builder(
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    var item = filteredList[index];
                    int nomor = index + 1;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal,
                          child: Text('$nomor', style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text('$nomor. ${item['Nama Lengkap'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Jabatan: ${item['Jabatan'] ?? '-'}'),
                            Text('Telegram: ${item['Username Telegram'] ?? '-'}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

// ==================== REVISI 3: REKAP ABSEN (BULANAN + EKSPOR PDF) ====================
class RekapAbsenScreen extends StatefulWidget {
  const RekapAbsenScreen({super.key});

  @override
  State<RekapAbsenScreen> createState() => _RekapAbsenScreenState();
}

class _RekapAbsenScreenState extends State<RekapAbsenScreen> {
  List dataList = [];
  bool isLoading = true;
  String selectedMonth = 'September';
  String selectedYear = '2026';

  final List<String> months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    if (!LoginData.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Hanya Admin yang dapat mengakses Rekap Absen!')),
        );
      });
      return;
    }
    fetchData();
  }

  void fetchData() async {
    try {
      final response = await http.get(Uri.parse("$scriptUrl?action=getData&sheet=RekapAbsen"));
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

  void exportPdf() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Rekap Absen Guru dan Karyawan', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text('SD Zainul Hasan Genggong', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text('Periode Bulan: $selectedMonth $selectedYear', style: pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 15),
              pw.Table.fromTextArray(
                headers: ['No', 'Data / Rekap Absen'],
                data: List.generate(dataList.length, (index) {
                  return [
                    (index + 1).toString(),
                    dataList[index].toString(),
                  ];
                }),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekap Absen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF',
            onPressed: exportPdf,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rekap Absen Guru dan Karyawan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Text('SD Zainul Hasan Genggong', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Periode Bulan', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                        value: selectedMonth,
                        items: months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                        onChanged: (val) => setState(() => selectedMonth = val!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(labelText: 'Tahun', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                        initialValue: selectedYear,
                        onChanged: (val) => selectedYear = val,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                    onPressed: exportPdf,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Export Rekap ke PDF'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : dataList.isEmpty
                    ? const Center(child: Text('Belum ada data rekap absen.'))
                    : ListView.builder(
                        itemCount: dataList.length,
                        itemBuilder: (context, index) {
                          var item = dataList[index];
                          int nomor = index + 1;
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.brown,
                                child: Text('$nomor', style: const TextStyle(color: Colors.white)),
                              ),
                              title: Text('$nomor. ${item.values.first.toString()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(item.toString()),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ==================== REVISI 5: FITUR TAMBAH & HAPUS MANUAL (LOKAL) ====================
class LocalCrudScreen extends StatefulWidget {
  final String title;
  const LocalCrudScreen({super.key, required this.title});

  @override
  State<LocalCrudScreen> createState() => _LocalCrudScreenState();
}

class _LocalCrudScreenState extends State<LocalCrudScreen> {
  late List<String> currentList;

  @override
  void initState() {
    super.initState();
    LocalDataStorage.items.putIfAbsent(widget.title, () => []);
    currentList = LocalDataStorage.items[widget.title]!;
  }

  void _addItem() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Tambah ${widget.title}'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Masukkan data baru...', border: OutlineInputBorder()),
            maxLines: 3,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    currentList.add(controller.text.trim());
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Berhasil ditambahkan!')));
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _deleteItem(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Data'),
        content: const Text('Apakah Anda yakin ingin menghapus item ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              setState(() {
                currentList.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🗑️ Berhasil dihapus!')));
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: currentList.isEmpty
          ? Center(child: Text('Belum ada data ${widget.title}. Ketuk tombol tambah di bawah.'))
          : ListView.builder(
              itemCount: currentList.length,
              itemBuilder: (context, index) {
                int nomor = index + 1;
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green[700],
                      child: Text('$nomor', style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text('$nomor. ${currentList[index]}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteItem(index),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addItem,
        icon: const Icon(Icons.add),
        label: Text('Tambah ${widget.title}'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
    );
  }
}

// ==================== REVISI 4: CHAT ADMIN ====================
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
            subtitle: const Text('0857-9251-8395 (Ketuk untuk chat)'),
            onTap: () => launchUrl(Uri.parse("https://wa.me/6285792518395"), mode: LaunchMode.externalApplication),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.telegram, color: Colors.blue, size: 36),
            title: const Text('Telegram Admin SD ZAHA.ID'),
            subtitle: const Text('@azkiyak07 (Ketuk untuk chat)'),
            onTap: () => launchUrl(Uri.parse("https://t.me/azkiyak07"), mode: LaunchMode.externalApplication),
          ),
        ],
      ),
    );
  }
}

// ==================== REVISI 2: SOSIAL MEDIA SEKOLAH LENGKAP ====================
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
            subtitle: const Text('https://www.instagram.com/sdzahag4/'),
            onTap: () => launchUrl(Uri.parse("https://www.instagram.com/sdzahag4/"), mode: LaunchMode.externalApplication),
          ),
          ListTile(
            leading: const Icon(Icons.play_arrow, color: Colors.red),
            title: const Text('Channel YouTube SD ZAHA.ID'),
            subtitle: const Text('https://www.youtube.com/channel/UCHx4mIM0fpCHL0fsQL6Z-rQ/videos'),
            onTap: () => launchUrl(Uri.parse("https://www.youtube.com/channel/UCHx4mIM0fpCHL0fsQL6Z-rQ/videos"), mode: LaunchMode.externalApplication),
          ),
          ListTile(
            leading: const Icon(Icons.video_collection, color: Colors.black),
            title: const Text('TikTok Resmi SD ZAHA.ID'),
            subtitle: const Text('https://www.tiktok.com/@sdzahag4'),
            onTap: () => launchUrl(Uri.parse("https://www.tiktok.com/@sdzahag4"), mode: LaunchMode.externalApplication),
          ),
          ListTile(
            leading: const Icon(Icons.language, color: Colors.blueAccent),
            title: const Text('Website Resmi SD ZAHA.ID'),
            subtitle: const Text('https://www.sdzaha.sch.id/'),
            onTap: () => launchUrl(Uri.parse("https://www.sdzaha.sch.id/"), mode: LaunchMode.externalApplication),
          ),
          ListTile(
            leading: const Icon(Icons.facebook, color: Colors.blue),
            title: const Text('Fanspage Facebook SD ZAHA.ID'),
            subtitle: const Text('https://www.facebook.com/profile.php?id=61560695901686'),
            onTap: () => launchUrl(Uri.parse("https://www.facebook.com/profile.php?id=61560695901686"), mode: LaunchMode.externalApplication),
          ),
          ListTile(
            leading: const Icon(Icons.message, color: Colors.green),
            title: const Text('Channel WhatsApp SD ZAHA.ID'),
            subtitle: const Text('https://whatsapp.com/channel/0029VbAhEFdCcW4vU6pekE1T'),
            onTap: () => launchUrl(Uri.parse("https://whatsapp.com/channel/0029VbAhEFdCcW4vU6pekE1T"), mode: LaunchMode.externalApplication),
          ),
        ],
      ),
    );
  }
}