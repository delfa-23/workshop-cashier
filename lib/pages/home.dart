import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kasir_bengkel/pages/transaksi.dart';
import 'package:kasir_bengkel/pages/kasir.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> keranjang = [];
  String? _logoPath;

  @override
  void initState() {
    super.initState();
    _loadLogoLokal();
  }

  // 🔸 Ambil logo dari SharedPreferences
  Future<void> _loadLogoLokal() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _logoPath = prefs.getString('bengkel_logo');
    });
  }

  // 🔸 Simpan logo ke SharedPreferences
  Future<void> _gantiLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('bengkel_logo', picked.path);
      setState(() {
        _logoPath = picked.path;
      });
    }
  }

  void updateKeranjang(List<Map<String, dynamic>> newKeranjang) {
    setState(() {
      keranjang = newKeranjang;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.orangeAccent,
        elevation: 0,
        title: Row(
          children: const [
            Text(
              'Kasir',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 4),
            Text(
              'Bengkel',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: const [Icon(Icons.menu), SizedBox(width: 12)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Laporan Hari Ini ---
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.bar_chart, color: Colors.redAccent, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Laporan Hari ini',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Total Penjualan: Rp. 0',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- Info Bengkel ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),

                // === DATA FIRESTORE ===
                Expanded(
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('bengkel')
                        .doc('profil')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text('Memuat data bengkel...');
                      }

                      // kalau dokumen belum ada, langsung buat default
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        FirebaseFirestore.instance
                            .collection('bengkel')
                            .doc('profil')
                            .set({
                              'nama': 'Nama Bengkel',
                              'alamat': 'Alamat Bengkel',
                            }, SetOptions(merge: true));
                        return const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nama Bengkel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Alamat Bengkel',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        );
                      }

                      final data =
                          snapshot.data!.data() as Map<String, dynamic>;
                      final nama = data['nama'] ?? 'Nama Bengkel';
                      final alamat = data['alamat'] ?? 'Alamat Bengkel';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nama,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            alamat,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // === EDIT NAMA & ALAMAT (Firestore) ===
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orangeAccent),
                  onPressed: () async {
                    final doc = await FirebaseFirestore.instance
                        .collection('bengkel')
                        .doc('profil')
                        .get();

                    final data = doc.data() ?? {};
                    final namaCtrl = TextEditingController(
                      text: data['nama'] ?? '',
                    );
                    final alamatCtrl = TextEditingController(
                      text: data['alamat'] ?? '',
                    );

                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Edit Profil Bengkel'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: namaCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Nama Bengkel',
                              ),
                            ),
                            TextField(
                              controller: alamatCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Alamat Bengkel',
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Batal'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('bengkel')
                                  .doc('profil')
                                  .set({
                                    'nama': namaCtrl.text,
                                    'alamat': alamatCtrl.text,
                                  });
                              Navigator.pop(context);
                            },
                            child: const Text('Simpan'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // --- Menu ---
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _menuItem(Icons.build, 'Stock Part', route: '/layanan'),
              _menuItem(Icons.history, 'History', route: '/history'),
              _menuItem(Icons.receipt_long, 'Laporan', route: '/laporan'),
              _menuItem(Icons.person, 'Pelanggan'),
              _menuItem(Icons.engineering, 'Engineer', route: '/engineer'),
              _menuItem(Icons.credit_card, 'Pengeluaran'),
              _menuItem(
                Icons.point_of_sale,
                'Input Item',
                onTap: () async {
                  final updatedKeranjang = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => KasirPage(
                        keranjang: keranjang,
                        updateKeranjang: (list) {
                          setState(() {
                            keranjang = List<Map<String, dynamic>>.from(list);
                          });
                        },
                      ),
                    ),
                  );

                  if (updatedKeranjang != null) {
                    setState(() {
                      keranjang = List<Map<String, dynamic>>.from(
                        updatedKeranjang,
                      );
                    });
                  }
                },
              ),
              _menuItem(Icons.receipt_long, 'Struk', route: '/struk'),
              _menuItem(Icons.security, 'Sekuriti'),
            ],
          ),

          const SizedBox(height: 30),

          // --- Tombol Transaksi ---
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TransaksiPage(keranjang: keranjang),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Transaksi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔸 Template item menu
  Widget _menuItem(
    IconData icon,
    String title, {
    VoidCallback? onTap,
    String? route,
    Map<String, dynamic>? extraData,
  }) {
    return InkWell(
      onTap: () {
        if (onTap != null) {
          onTap();
        } else if (route != null) {
          if (extraData != null) {
            Get.toNamed(route, arguments: extraData);
          } else {
            Get.toNamed(route);
          }
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 3)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: Colors.orangeAccent),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
