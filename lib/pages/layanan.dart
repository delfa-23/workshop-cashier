import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class LayananPage extends StatefulWidget {
  const LayananPage({super.key});

  @override
  State<LayananPage> createState() => _LayananPageState();
}

class _LayananPageState extends State<LayananPage> {
  final TextEditingController namaCtrl = TextEditingController();
  final TextEditingController hargaCtrl = TextEditingController();
  final TextEditingController stokCtrl = TextEditingController();
  final TextEditingController barcodeCtrl = TextEditingController();
  final TextEditingController searchCtrl = TextEditingController();

  final partRef = FirebaseFirestore.instance.collection('part');
  String searchQuery = "";

  // ==========================
  // 🔹 Dialog Tambah Part
  // ==========================
  void _tampilDialogTambah() {
    namaCtrl.clear();
    hargaCtrl.clear();
    stokCtrl.clear();
    barcodeCtrl.clear();

    Get.defaultDialog(
      title: "Tambah Part",
      content: Column(
        children: [
          TextField(
            controller: namaCtrl,
            decoration: const InputDecoration(labelText: "Nama Part"),
          ),
          TextField(
            controller: hargaCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Harga (Rp)"),
          ),
          TextField(
            controller: stokCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Stok"),
          ),
          TextField(
            controller: barcodeCtrl,
            decoration: const InputDecoration(labelText: "Barcode (opsional)"),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
              if (namaCtrl.text.isEmpty || hargaCtrl.text.isEmpty) return;

              final data = {
                'nama': namaCtrl.text.trim(),
                'harga': int.tryParse(hargaCtrl.text) ?? 0,
                'stok': int.tryParse(stokCtrl.text) ?? 0,
                'barcode': barcodeCtrl.text.trim(),
                'created_at': Timestamp.now(),
              };

              await partRef.add(data);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ==========================
  // 🔹 Edit Part
  // ==========================
  void _editDataDialog(
    String id,
    String nama,
    int harga,
    int stok,
    String barcode,
  ) {
    final namaEdit = TextEditingController(text: nama);
    final hargaEdit = TextEditingController(text: harga.toString());
    final stokEdit = TextEditingController(text: stok.toString());
    final barcodeEdit = TextEditingController(text: barcode);

    Get.defaultDialog(
      title: "Edit Part",
      content: Column(
        children: [
          TextField(
            controller: namaEdit,
            decoration: const InputDecoration(labelText: "Nama Part"),
          ),
          TextField(
            controller: hargaEdit,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Harga (Rp)"),
          ),
          TextField(
            controller: stokEdit,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Stok"),
          ),
          TextField(
            controller: barcodeEdit,
            decoration: const InputDecoration(labelText: "Barcode"),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
              if (namaEdit.text.isEmpty || hargaEdit.text.isEmpty) return;

              await partRef.doc(id).update({
                'nama': namaEdit.text.trim(),
                'harga': int.tryParse(hargaEdit.text) ?? harga,
                'stok': int.tryParse(stokEdit.text) ?? stok,
                'barcode': barcodeEdit.text.trim(),
              });
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _hapusData(String id) async {
    await partRef.doc(id).delete();
  }

  void _ubahStok(String id, int stokSekarang, int perubahan) async {
    final newStock = stokSekarang + perubahan;
    if (newStock < 0) return;

    await partRef.doc(id).update({'stok': newStock});
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat("#,##0", "id_ID");

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Part', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _tampilDialogTambah,
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔍 Search bar dengan tombol scan
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchCtrl,
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Cari part atau barcode...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.orange.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: partRef
                  .orderBy('created_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final nama = (doc['nama'] ?? '').toString().toLowerCase();
                  final barcode = (doc['barcode'] ?? '')
                      .toString()
                      .toLowerCase();
                  return nama.contains(searchQuery) ||
                      barcode.contains(searchQuery);
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text("Tidak ada data part"));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index];
                    final map = data.data() as Map<String, dynamic>;
                    final nama = map['nama'] ?? '-';
                    final harga = map['harga'] ?? 0;
                    final stok = map['stok'] ?? 0;
                    final barcode = map['barcode'] ?? '-';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange[50],
                          child: const Icon(
                            Icons.settings,
                            color: Colors.orange,
                          ),
                        ),
                        title: Text(
                          nama,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Rp ${formatter.format(harga)}  |  Stok: $stok\nBarcode: $barcode',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle,
                                color: Colors.red,
                              ),
                              onPressed: () => _ubahStok(data.id, stok, -1),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle,
                                color: Colors.green,
                              ),
                              onPressed: () => _ubahStok(data.id, stok, 1),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editDataDialog(
                                data.id,
                                nama,
                                harga,
                                stok,
                                barcode,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _hapusData(data.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ===============================================
// 🔸 ScanBarcodePage — halaman scanner sederhana
// ===============================================
class ScanBarcodePage extends StatefulWidget {
  const ScanBarcodePage({super.key});

  @override
  State<ScanBarcodePage> createState() => _ScanBarcodePageState();
}

class _ScanBarcodePageState extends State<ScanBarcodePage> {
  bool detected = false;

  void _onDetect(BarcodeCapture capture) {
    if (detected) return;
    final barcode = capture.barcodes.first.rawValue;
    if (barcode == null) return;

    setState(() => detected = true);
    Navigator.pop(context, barcode); // kirim barcode ke halaman sebelumnya
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Barcode")),
      body: MobileScanner(onDetect: _onDetect),
    );
  }
}
