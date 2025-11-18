import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:kasir_bengkel/pages/cart.dart';

class KasirPage extends StatefulWidget {
  final List<Map<String, dynamic>> keranjang;
  final Function(List<Map<String, dynamic>>) updateKeranjang;

  const KasirPage({
    super.key,
    required this.keranjang,
    required this.updateKeranjang,
  });

  @override
  State<KasirPage> createState() => _KasirPageState();
}

class _KasirPageState extends State<KasirPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> keranjang = [];
  final formatRupiah = NumberFormat("#,##0", "id_ID");

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  final TextEditingController _namaServiceController = TextEditingController();
  final TextEditingController _hargaServiceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    keranjang = List<Map<String, dynamic>>.from(widget.keranjang);

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });

    // Auto-format harga service
    _hargaServiceController.addListener(() {
      final text = _hargaServiceController.text.replaceAll('.', '');
      if (text.isEmpty) return;
      final number = int.tryParse(text);
      if (number != null) {
        final formatted = NumberFormat('#,###', 'id_ID').format(number);
        _hargaServiceController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    });
  }

  @override
  void dispose() {
    widget.updateKeranjang(keranjang);
    _tabController.dispose();
    _searchController.dispose();
    _namaServiceController.dispose();
    _hargaServiceController.dispose();
    super.dispose();
  }

  // ==== FIX PALING PENTING ====
  Future<bool> _onWillPop() async {
    widget.updateKeranjang(List<Map<String, dynamic>>.from(keranjang));
    Navigator.pop(context, keranjang);
    return false;
  }

  int qtyInCart(String id) {
    final idx = keranjang.indexWhere((e) => e['id'] == id);
    if (idx == -1) return 0;
    return (keranjang[idx]['qty'] as num?)?.toInt() ?? 0;
  }

  Future<void> scanBarcode() async {
    try {
      String barcode = await FlutterBarcodeScanner.scanBarcode(
        "#ff6666",
        "Batal",
        true,
        ScanMode.BARCODE,
      );

      if (barcode == "-1") return;

      final snapshot = await FirebaseFirestore.instance
          .collection('part')
          .where('barcode', isEqualTo: barcode)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();

        tambahKeranjang({
          'id': data['barcode'],
          'nama': data['nama'],
          'harga': data['harga'],
          'stok': data['stok'] ?? 0,
          'tipe': 'part',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text("${data['nama']} berhasil discan dan masuk keranjang"),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Part tidak ditemukan di database!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal scan: $e")),
      );
    }
  }

  Future<List<Map<String, dynamic>>> ambilData(String koleksi) async {
    final snapshot = await FirebaseFirestore.instance.collection(koleksi).get();
    return snapshot.docs.map((d) {
      final data = d.data();
      return {
        "id": d.id,
        "nama": data['nama'],
        "harga": data['harga'],
        "stok": data['stok'] ?? 0,
        "tipe": koleksi,
        "qty": 0,
      };
    }).toList();
  }

  void tambahKeranjang(Map<String, dynamic> item) {
    if (item['tipe'] == 'layanan') {
      setState(() {
        keranjang.add({
          'id': DateTime.now().toString(),
          'nama': item['nama'],
          'harga': item['harga'],
          'tipe': 'layanan',
          'qty': 1,
        });
      });
      return;
    }

    final index = keranjang.indexWhere((i) => i['id'] == item['id']);
    final stokFirestore = (item['stok'] as num?)?.toInt() ?? 0;
    final qtyCart = qtyInCart(item['id']);
    final available = stokFirestore - qtyCart;

    if (available <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Stok ${item['nama']} habis!")));
      return;
    }

    setState(() {
      if (index == -1) {
        keranjang.add({
          'id': item['id'],
          'nama': item['nama'],
          'harga': item['harga'],
          'tipe': item['tipe'],
          'stok': stokFirestore,
          'qty': 1,
        });
      } else {
        keranjang[index]['qty'] =
            ((keranjang[index]['qty'] as num?)?.toInt() ?? 0) + 1;
      }
    });
  }

  Widget _buildServiceInput() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Tambah Layanan",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            TextField(
              controller: _namaServiceController,
              decoration: const InputDecoration(
                labelText: "Nama Layanan",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _hargaServiceController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(
                labelText: "Harga",
                prefixText: "Rp ",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size(double.infinity, 48),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Tambah ke Keranjang",
                  style: TextStyle(color: Colors.white)),
              onPressed: () {
                final nama = _namaServiceController.text.trim();
                final hargaText =
                    _hargaServiceController.text.replaceAll('.', '').trim();

                if (nama.isEmpty || hargaText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Isi semua data layanan terlebih dahulu")),
                  );
                  return;
                }

                tambahKeranjang({
                  'nama': nama,
                  'harga': int.parse(hargaText),
                  'tipe': 'layanan',
                });

                _namaServiceController.clear();
                _hargaServiceController.clear();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListViewPart() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ambilData('part'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var data = snapshot.data!;
        if (_searchQuery.isNotEmpty) {
          data = data
              .where((item) =>
                  item['nama'].toString().toLowerCase().contains(_searchQuery))
              .toList();
        }

        if (data.isEmpty) {
          return const Center(child: Text("Tidak ada part ditemukan"));
        }

        return ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, i) {
            final item = data[i];
            final stok = (item['stok'] as num?)?.toInt() ?? 0;
            final qty = qtyInCart(item['id']);
            final available = stok - qty;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: ListTile(
                title: Text(item['nama']),
                subtitle: Text(
                    "Rp${formatRupiah.format(item['harga'])} • Stok: $available"),
                trailing: IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.orange),
                  onPressed: () => tambahKeranjang(item),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildKeranjangIcon() {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart),
          onPressed: () async {
            final updated = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CartPage(
                  keranjang: keranjang,
                  updateKeranjang: (list) {
                    setState(() {
                      keranjang = List<Map<String, dynamic>>.from(list);
                    });
                  },
                ),
              ),
            );

            if (updated != null) {
              setState(() {
                keranjang = List<Map<String, dynamic>>.from(updated);
              });
            }
          },
        ),
        if (keranjang.isNotEmpty)
          Positioned(
            right: 6,
            top: 6,
            child: CircleAvatar(
              radius: 8,
              backgroundColor: Colors.red,
              child: Text(
                keranjang.length.toString(),
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Input Item"),
          actions: [_buildKeranjangIcon()],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: "Service"),
              Tab(text: "Part"),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildServiceInput(),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: "Ketik atau Scan Barcode Part...",
                      prefixIcon: IconButton(
                        icon: const Icon(Icons.qr_code_scanner,
                            color: Colors.orange),
                        onPressed: scanBarcode,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onSubmitted: (value) async {
                      final input = value.trim();
                      if (input.isEmpty) return;

                      final byBarcode = await FirebaseFirestore.instance
                          .collection('part')
                          .where('barcode', isEqualTo: input)
                          .get();

                      if (byBarcode.docs.isNotEmpty) {
                        final d = byBarcode.docs.first.data();
                        tambahKeranjang({
                          'id': d['barcode'],
                          'nama': d['nama'],
                          'harga': d['harga'],
                          'stok': d['stok'] ?? 0,
                          'tipe': 'part',
                        });
                      } else {
                        final byName = await FirebaseFirestore.instance
                            .collection('part')
                            .where('nama', isEqualTo: input)
                            .get();

                        if (byName.docs.isNotEmpty) {
                          final d = byName.docs.first.data();
                          tambahKeranjang({
                            'id': byName.docs.first.id,
                            'nama': d['nama'],
                            'harga': d['harga'],
                            'stok': d['stok'] ?? 0,
                            'tipe': 'part',
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Part tidak ditemukan")),
                          );
                        }
                      }

                      _searchController.clear();
                    },
                  ),
                ),
                Expanded(child: _buildListViewPart()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
