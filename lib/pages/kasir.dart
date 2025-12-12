import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:kasir_bengkel/pages/cart.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:get/get.dart';

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

  double _totalKeranjang = 0;
  bool _isScanning = false;
  String? _lastScannedBarcode;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    keranjang = List<Map<String, dynamic>>.from(widget.keranjang);
    _hitungTotal();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });

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

  void _hitungTotal() {
    double total = 0;
    for (var item in keranjang) {
      final harga = (item['harga'] as num?)?.toDouble() ?? 0;
      final qty = (item['qty'] as num?)?.toInt() ?? 1;
      total += harga * qty;
    }
    _totalKeranjang = total;
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

  Future<void> _scanBarcode() async {
    setState(() {
      _isScanning = true;
    });

    final result = await Get.to(() => const ScanBarcodeScreen());

    if (result != null && result is String) {
      await _processScannedBarcode(result);
    }

    setState(() {
      _isScanning = false;
    });
  }

  Future<void> _processScannedBarcode(String barcode) async {
    try {
      // Cek apakah barcode sudah discan baru saja
      if (_lastScannedBarcode == barcode) {
        return; // Hindari scan ganda
      }

      _lastScannedBarcode = barcode;

      // Cari part berdasarkan barcode
      final snapshot = await FirebaseFirestore.instance
          .collection('part')
          .where('barcode', isEqualTo: barcode)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data();

        await tambahKeranjang({
          'id': doc.id,
          'nama': data['nama'],
          'harga': data['harga'],
          'stok': data['stok'] ?? 0,
          'tipe': 'part',
          'barcode': data['barcode'] ?? '',
        });

        // Play success sound/haptic feedback
        HapticFeedback.lightImpact();

        _showSnackBar(
          "✓ ${data['nama']} ditambahkan ke keranjang",
          Colors.green.shade600,
          Iconsax.tick_circle,
        );
      } else {
        _showSnackBar(
          "Barcode tidak ditemukan",
          Colors.orange.shade600,
          Iconsax.warning_2,
        );
      }
    } catch (e) {
      _showSnackBar(
        "Gagal memproses barcode",
        Colors.red.shade600,
        Iconsax.close_circle,
      );
    }
  }

  void _showSnackBar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> ambilData(String koleksi) async {
    final snapshot = await FirebaseFirestore.instance
        .collection(koleksi)
        .orderBy('nama')
        .get();
    return snapshot.docs.map((d) {
      final data = d.data();
      return {
        "id": d.id,
        "nama": data['nama'],
        "harga": data['harga'],
        "stok": data['stok'] ?? 0,
        "tipe": koleksi,
        "qty": 0,
        "barcode": data['barcode'] ?? '',
      };
    }).toList();
  }

  Future<void> tambahKeranjang(Map<String, dynamic> item) async {
    if (item['tipe'] == 'layanan') {
      setState(() {
        keranjang.add({
          'id': DateTime.now().toString(),
          'nama': item['nama'],
          'harga': item['harga'],
          'tipe': 'layanan',
          'qty': 1,
        });
        _hitungTotal();
      });
      return;
    }

    final index = keranjang.indexWhere((i) => i['id'] == item['id']);
    final stokFirestore = (item['stok'] as num?)?.toInt() ?? 0;
    final qtyCart = qtyInCart(item['id']);
    final available = stokFirestore - qtyCart;

    if (available <= 0) {
      _showSnackBar(
        "Stok ${item['nama']} habis!",
        Colors.orange.shade600,
        Iconsax.warning_2,
      );
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
          'barcode': item['barcode'] ?? '',
        });
      } else {
        keranjang[index]['qty'] =
            ((keranjang[index]['qty'] as num?)?.toInt() ?? 0) + 1;
      }
      _hitungTotal();
    });

    // Haptic feedback untuk user
    HapticFeedback.lightImpact();
  }

  Widget _buildServiceInput() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.shade100, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(Iconsax.setting_2, color: Colors.orange.shade700, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Tambah Layanan",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Tambahkan layanan/service baru",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Form Input
          _buildInputField(
            controller: _namaServiceController,
            label: 'Nama Layanan',
            hintText: 'Contoh: Ganti oli, Servis rem, dll.',
            icon: Iconsax.document_text,
            isRequired: true,
          ),
          const SizedBox(height: 16),

          _buildInputField(
            controller: _hargaServiceController,
            label: 'Harga Layanan',
            hintText: 'Masukkan harga',
            icon: Iconsax.money,
            keyboardType: TextInputType.number,
            isCurrency: true,
            isRequired: true,
          ),
          const SizedBox(height: 8),

          // Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100, width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  Iconsax.info_circle,
                  color: Colors.blue.shade600,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Layanan akan langsung masuk ke keranjang",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Tombol
          ElevatedButton(
            onPressed: () {
              final nama = _namaServiceController.text.trim();
              final hargaText =
                  _hargaServiceController.text.replaceAll('.', '').trim();

              if (nama.isEmpty || hargaText.isEmpty) {
                _showSnackBar(
                  "Isi semua data layanan terlebih dahulu",
                  Colors.orange.shade600,
                  Iconsax.warning_2,
                );
                return;
              }

              tambahKeranjang({
                'id': DateTime.now().toString(),
                'nama': nama,
                'harga': int.parse(hargaText),
                'tipe': 'layanan',
              });

              _namaServiceController.clear();
              _hargaServiceController.clear();

              _showSnackBar(
                "$nama berhasil ditambahkan",
                Colors.green.shade600,
                Iconsax.tick_circle,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 3,
              shadowColor: Colors.orange.shade300,
            ),
            child: SizedBox(
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.add_circle, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    "Tambah ke Keranjang",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isCurrency = false,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: GoogleFonts.poppins(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hintText,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              prefixIcon: Container(
                padding: const EdgeInsets.only(left: 16, right: 12),
                child: Icon(icon, color: Colors.orange.shade700, size: 22),
              ),
              prefixText: isCurrency ? 'Rp ' : null,
              prefixStyle: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: isCurrency ? Colors.green.shade800 : Colors.grey.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListViewPart() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ambilData('part'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    color: Colors.orange.shade700,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Memuat data part...',
                  style: GoogleFonts.poppins(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Iconsax.box_remove,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Belum ada part tersedia',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tambahkan part terlebih dahulu di menu Data Part',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _scanBarcode,
                  icon: const Icon(Iconsax.scan_barcode, size: 18),
                  label: const Text('Scan Barcode'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        var data = snapshot.data!;
        if (_searchQuery.isNotEmpty) {
          data = data
              .where(
                (item) =>
                    item['nama'].toString().toLowerCase().contains(
                          _searchQuery,
                        ) ||
                    (item['barcode']?.toString().toLowerCase().contains(
                          _searchQuery,
                        ) ??
                        false),
              )
              .toList();
        }

        if (data.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.search_normal,
                  size: 60,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'Part tidak ditemukan',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Coba kata kunci lain atau scan barcode',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _scanBarcode,
                  icon: const Icon(Iconsax.scan_barcode, size: 18),
                  label: const Text('Scan Barcode'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: data.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final item = data[i];
            final stok = (item['stok'] as num?)?.toInt() ?? 0;
            final qty = qtyInCart(item['id']);
            final available = stok - qty;

            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => tambahKeranjang(item),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.08),
                        blurRadius: 12,
                        spreadRadius: 2,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: Border.all(color: Colors.grey.shade100, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      // Icon/Image
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: available > 0
                              ? Colors.orange.shade100
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          available > 0 ? Iconsax.box : Iconsax.box_remove,
                          color: available > 0
                              ? Colors.orange.shade700
                              : Colors.grey.shade500,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['nama'],
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.grey.shade900,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  'Rp${formatRupiah.format(item['harga'])}',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if ((item['barcode'] as String?)?.isNotEmpty ?? false)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Barcode',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                // Stok Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: available > 0
                                        ? available < 5
                                            ? Colors.orange.shade50
                                            : Colors.green.shade50
                                        : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: available > 0
                                          ? available < 5
                                              ? Colors.orange.shade200
                                              : Colors.green.shade200
                                          : Colors.red.shade200,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        available > 0
                                            ? available < 5
                                                ? Iconsax.warning_2
                                                : Iconsax.box_tick
                                            : Iconsax.box_remove,
                                        size: 12,
                                        color: available > 0
                                            ? available < 5
                                                ? Colors.orange.shade700
                                                : Colors.green.shade700
                                            : Colors.red.shade700,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$available tersedia',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: available > 0
                                              ? available < 5
                                                  ? Colors.orange.shade700
                                                  : Colors.green.shade700
                                              : Colors.red.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Qty in cart badge
                                if (qty > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.blue.shade200,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Iconsax.shopping_cart,
                                          size: 12,
                                          color: Colors.blue.shade700,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$qty di keranjang',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Add Button
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: available > 0
                                ? [
                                    Colors.orange.shade600,
                                    Colors.orange.shade400,
                                  ]
                                : [Colors.grey.shade400, Colors.grey.shade300],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: available > 0
                              ? [
                                  BoxShadow(
                                    color: Colors.orange.shade200.withOpacity(
                                      0.5,
                                    ),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: IconButton(
                          onPressed: available > 0
                              ? () => tambahKeranjang(item)
                              : null,
                          icon: Icon(
                            Iconsax.add,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
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
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CartPage(
                      keranjang: keranjang,
                      updateKeranjang: (list) {
                        setState(() {
                          keranjang = List<Map<String, dynamic>>.from(list);
                          _hitungTotal();
                        });
                      },
                    ),
                  ),
                );

                if (updated != null) {
                  setState(() {
                    keranjang = List<Map<String, dynamic>>.from(updated);
                    _hitungTotal();
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Iconsax.shopping_cart, color: Colors.orange.shade700),
                    if (keranjang.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Text(
                            'Rp${formatRupiah.format(_totalKeranjang)}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (keranjang.isNotEmpty)
          Positioned(
            right: 2,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.shade300.withOpacity(0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
              child: Text(
                keranjang.length.toString(),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
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
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Tambah Item",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Pilih part atau tambah layanan",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.grey.shade200,
          surfaceTintColor: Colors.white,
          centerTitle: false,
          titleSpacing: 20,
          actions: [_buildKeranjangIcon()],
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.orange.shade700,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: Colors.orange.shade700,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(fontSize: 14),
            tabs: const [
              Tab(icon: Icon(Iconsax.setting_2, size: 20), text: "Layanan"),
              Tab(icon: Icon(Iconsax.box, size: 20), text: "Part"),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildServiceInput(),
            Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.05),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: "Cari part atau scan barcode...",
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              prefixIcon: Icon(
                                Iconsax.search_normal,
                                color: Colors.orange.shade700,
                              ),
                            ),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade800,
                            ),
                            onSubmitted: (value) async {
                              final input = value.trim();
                              if (input.isEmpty) return;

                              final byBarcode = await FirebaseFirestore.instance
                                  .collection('part')
                                  .where('barcode', isEqualTo: input)
                                  .limit(1)
                                  .get();

                              if (byBarcode.docs.isNotEmpty) {
                                final doc = byBarcode.docs.first;
                                final data = doc.data();
                                await tambahKeranjang({
                                  'id': doc.id,
                                  'nama': data['nama'],
                                  'harga': data['harga'],
                                  'stok': data['stok'] ?? 0,
                                  'tipe': 'part',
                                  'barcode': data['barcode'] ?? '',
                                });
                              } else {
                                final byName = await FirebaseFirestore.instance
                                    .collection('part')
                                    .where('nama', isEqualTo: input)
                                    .limit(1)
                                    .get();

                                if (byName.docs.isNotEmpty) {
                                  final doc = byName.docs.first;
                                  final data = doc.data();
                                  await tambahKeranjang({
                                    'id': doc.id,
                                    'nama': data['nama'],
                                    'harga': data['harga'],
                                    'stok': data['stok'] ?? 0,
                                    'tipe': 'part',
                                    'barcode': data['barcode'] ?? '',
                                  });
                                } else {
                                  _showSnackBar(
                                    "Part tidak ditemukan",
                                    Colors.orange.shade600,
                                    Iconsax.warning_2,
                                  );
                                }
                              }

                              _searchController.clear();
                            },
                          ),
                        ),
                        Container(
                          height: 56,
                          width: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade600,
                                Colors.blue.shade400,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(14),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.shade200.withOpacity(0.3),
                                blurRadius: 6,
                                spreadRadius: 1,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: _isScanning ? null : _scanBarcode,
                            icon: _isScanning
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Iconsax.scan_barcode,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                            tooltip: 'Scan Barcode',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.shade100,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Iconsax.info_circle,
                          color: Colors.green.shade600,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Klik item atau scan barcode untuk menambah ke keranjang",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(child: _buildListViewPart()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ===============================================
// 🔸 ScanBarcodeScreen
// ===============================================
class ScanBarcodeScreen extends StatefulWidget {
  const ScanBarcodeScreen({super.key});

  @override
  State<ScanBarcodeScreen> createState() => _ScanBarcodeScreenState();
}

class _ScanBarcodeScreenState extends State<ScanBarcodeScreen> {
  MobileScannerController? _controller;
  bool _scanned = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    
    final barcode = capture.barcodes.first.rawValue;
    if (barcode == null) return;

    _scanned = true;
    HapticFeedback.heavyImpact();
    
    Future.delayed(const Duration(milliseconds: 500), () {
      Get.back(result: barcode);
    });
  }

  void _toggleTorch() {
    _controller?.toggleTorch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Iconsax.arrow_left_2,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        title: Text(
          'Scan Barcode',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            fit: BoxFit.cover,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.6),
                ],
              ),
            ),
          ),
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.green.withOpacity(0.8),
                  width: 3,
                ),
              ),
              child: CustomPaint(
                painter: ScannerBorderPainter(),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 100,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  'Arahkan ke Barcode',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Part akan otomatis ditambahkan ke keranjang',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: IconButton(
                    onPressed: _toggleTorch,
                    icon: const Icon(
                      Iconsax.flash_1,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                  ),
                  child: Text(
                    'Tutup Scanner',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final lineLength = 20.0;
    
    path.moveTo(0, lineLength);
    path.lineTo(0, 0);
    path.lineTo(lineLength, 0);
    
    path.moveTo(size.width - lineLength, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, lineLength);
    
    path.moveTo(size.width, size.height - lineLength);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width - lineLength, size.height);
    
    path.moveTo(lineLength, size.height);
    path.lineTo(0, size.height);
    path.lineTo(0, size.height - lineLength);

    canvas.drawPath(path, paint);
    
    final animatedValue = DateTime.now().millisecond / 1000;
    final scanLineY = size.height * animatedValue;
    
    canvas.drawRect(
      Rect.fromLTRB(2, scanLineY - 2, size.width - 2, scanLineY + 2),
      Paint()..color = Colors.green.withOpacity(0.6),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}