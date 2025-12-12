import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class LayananPage extends StatefulWidget {
  const LayananPage({super.key});

  @override
  State<LayananPage> createState() => _LayananPageState();
}

class _LayananPageState extends State<LayananPage> {
  final TextEditingController _namaCtrl = TextEditingController();
  final TextEditingController _hargaCtrl = TextEditingController();
  final TextEditingController _stokCtrl = TextEditingController();
  final TextEditingController _barcodeCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final formatRupiah = NumberFormat("#,##0", "id_ID");
  String _searchQuery = "";
  int _selectedFilter = 0;

  // ==========================
  // 🔹 Tampilkan Dialog Tambah Part (Bottom Sheet) - FIXED
  // ==========================
  void _tampilDialogTambah() {
    _namaCtrl.clear();
    _hargaCtrl.clear();
    _stokCtrl.clear();
    _barcodeCtrl.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Header dengan gradient
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: MediaQuery.of(context).size.height * 0.02,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.shade700,
                    Colors.orange.shade600,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tambah Part Baru',
                          style: GoogleFonts.poppins(
                            fontSize: MediaQuery.of(context).size.width * 0.045,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Lengkapi data part baru',
                          style: GoogleFonts.poppins(
                            fontSize: MediaQuery.of(context).size.width * 0.035,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: MediaQuery.of(context).size.width * 0.06,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                child: ListView(
                  children: [
                    // Form Input
                    _buildInputField(
                      controller: _namaCtrl,
                      label: 'Nama Part',
                      icon: Iconsax.box,
                      isRequired: true,
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),

                    // Row untuk Harga dan Stok
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isSmallScreen = constraints.maxWidth < 400;
                        if (isSmallScreen) {
                          return Column(
                            children: [
                              _buildInputField(
                                controller: _hargaCtrl,
                                label: 'Harga',
                                icon: Iconsax.money,
                                keyboardType: TextInputType.number,
                                isCurrency: true,
                                isRequired: true,
                              ),
                              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                              _buildInputField(
                                controller: _stokCtrl,
                                label: 'Stok Awal',
                                icon: Iconsax.box_add,
                                keyboardType: TextInputType.number,
                                defaultValue: '0',
                              ),
                            ],
                          );
                        } else {
                          return Row(
                            children: [
                              Expanded(
                                child: _buildInputField(
                                  controller: _hargaCtrl,
                                  label: 'Harga',
                                  icon: Iconsax.money,
                                  keyboardType: TextInputType.number,
                                  isCurrency: true,
                                  isRequired: true,
                                ),
                              ),
                              SizedBox(width: MediaQuery.of(context).size.width * 0.04),
                              Expanded(
                                child: _buildInputField(
                                  controller: _stokCtrl,
                                  label: 'Stok Awal',
                                  icon: Iconsax.box_add,
                                  keyboardType: TextInputType.number,
                                  defaultValue: '0',
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),

                    // Barcode Section - FIXED
                    Container(
                      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Iconsax.scan_barcode,
                                color: Colors.orange.shade700,
                                size: MediaQuery.of(context).size.width * 0.05,
                              ),
                              SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                              Text(
                                'Barcode (Opsional)',
                                style: GoogleFonts.poppins(
                                  fontSize: MediaQuery.of(context).size.width * 0.038,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: _barcodeCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'Masukkan kode barcode',
                                      hintStyle: GoogleFonts.poppins(
                                        fontSize: MediaQuery.of(context).size.width * 0.035,
                                        color: Colors.grey.shade500,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: MediaQuery.of(context).size.width * 0.04,
                                        vertical: MediaQuery.of(context).size.height * 0.02,
                                      ),
                                    ),
                                    style: GoogleFonts.poppins(
                                      fontSize: MediaQuery.of(context).size.width * 0.038,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                              // Tombol Scan - FIXED
                              InkWell(
                                onTap: () async {
                                  final result = await _bukaScanner();
                                  if (result != null && result is String) {
                                    setState(() {
                                      _barcodeCtrl.text = result;
                                    });
                                  }
                                },
                                child: Container(
                                  width: MediaQuery.of(context).size.width * 0.12,
                                  height: MediaQuery.of(context).size.width * 0.12,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.blue.shade600,
                                        Colors.blue.shade400,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.shade200.withOpacity(0.4),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Iconsax.scan,
                                    color: Colors.white,
                                    size: MediaQuery.of(context).size.width * 0.06,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.025),

                    // Info Tips
                    Container(
                      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.shade100,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Iconsax.info_circle,
                            color: Colors.blue.shade600,
                            size: MediaQuery.of(context).size.width * 0.05,
                          ),
                          SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                          Expanded(
                            child: Text(
                              'Stok akan otomatis terupdate saat melakukan transaksi penjualan.',
                              style: GoogleFonts.poppins(
                                fontSize: MediaQuery.of(context).size.width * 0.033,
                                color: Colors.blue.shade800,
                              ),
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.04),

                    // Tombol Simpan
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade100,
                              foregroundColor: Colors.grey.shade700,
                              padding: EdgeInsets.symmetric(
                                vertical: MediaQuery.of(context).size.height * 0.02,
                                horizontal: MediaQuery.of(context).size.width * 0.04,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Batal',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: MediaQuery.of(context).size.width * 0.038,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: MediaQuery.of(context).size.width * 0.04),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _simpanPartBaru,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade700,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: MediaQuery.of(context).size.height * 0.02,
                                horizontal: MediaQuery.of(context).size.width * 0.04,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 3,
                              shadowColor: Colors.orange.shade300,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Iconsax.save_2,
                                  size: MediaQuery.of(context).size.width * 0.05,
                                ),
                                SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                                Text(
                                  'Simpan Part',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: MediaQuery.of(context).size.width * 0.038,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function untuk parse harga
  int _parseHarga(String value) {
    if (value.isEmpty) return 0;
    String cleanValue = value
        .replaceAll('Rp', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .trim();
    return int.tryParse(cleanValue) ?? 0;
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isCurrency = false,
    bool isRequired = false,
    String? defaultValue,
  }) {
    if (defaultValue != null && controller.text.isEmpty) {
      if (isCurrency) {
        final numValue = int.tryParse(defaultValue) ?? 0;
        controller.text = formatRupiah.format(numValue);
      } else {
        controller.text = defaultValue;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: MediaQuery.of(context).size.width * 0.038,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: GoogleFonts.poppins(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: MediaQuery.of(context).size.width * 0.038,
                ),
              ),
          ],
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.01),
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
              hintText: 'Masukkan $label',
              hintStyle: GoogleFonts.poppins(
                fontSize: MediaQuery.of(context).size.width * 0.035,
                color: Colors.grey.shade500,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.04,
                vertical: MediaQuery.of(context).size.height * 0.02,
              ),
              prefixIcon: Container(
                padding: EdgeInsets.only(
                  left: MediaQuery.of(context).size.width * 0.04,
                  right: MediaQuery.of(context).size.width * 0.03,
                ),
                child: Icon(
                  icon,
                  color: Colors.orange.shade700,
                  size: MediaQuery.of(context).size.width * 0.055,
                ),
              ),
              prefixText: isCurrency ? 'Rp ' : null,
              prefixStyle: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
                fontSize: MediaQuery.of(context).size.width * 0.038,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            style: GoogleFonts.poppins(
              fontSize: MediaQuery.of(context).size.width * 0.038,
              color: isCurrency ? Colors.green.shade800 : Colors.grey.shade800,
              fontWeight: FontWeight.w500,
            ),
            onChanged: (value) {
              if (isCurrency) {
                final cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
                if (cleanValue.isNotEmpty) {
                  final number = int.tryParse(cleanValue) ?? 0;
                  final formatted = formatRupiah.format(number);
                  if (controller.text != formatted) {
                    controller.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                  }
                }
              }
            },
          ),
        ),
      ],
    );
  }

  // ==========================
  // 🔹 Fungsi Buka Scanner - FIXED
  // ==========================
  Future<String?> _bukaScanner() async {
    final result = await Get.to(() => const ScanBarcodePage());
    if (result != null && result is String) {
      return result;
    }
    return null;
  }

  Future<void> _simpanPartBaru() async {
    final nama = _namaCtrl.text.trim();
    final harga = _parseHarga(_hargaCtrl.text);
    final stok = int.tryParse(_stokCtrl.text) ?? 0;

    if (nama.isEmpty || harga == 0) {
      Get.snackbar(
        'Perhatian',
        'Nama dan harga harus diisi',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Iconsax.warning_2, color: Colors.white),
      );
      return;
    }

    try {
      final data = {
        'nama': nama,
        'harga': harga,
        'stok': stok,
        'barcode': _barcodeCtrl.text.trim(),
        'created_at': Timestamp.now(),
      };

      await _firestore.collection('part').add(data);

      _namaCtrl.clear();
      _hargaCtrl.clear();
      _stokCtrl.clear();
      _barcodeCtrl.clear();

      Navigator.pop(context);

      Get.snackbar(
        'Berhasil!',
        'Part berhasil ditambahkan ke database',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Iconsax.tick_circle, color: Colors.white),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menambahkan part: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  // ==========================
  // 🔹 Edit Part Dialog - FIXED
  // ==========================
  void _editPartDialog(
    String id,
    String nama,
    int harga,
    int stok,
    String barcode,
  ) {
    final namaEdit = TextEditingController(text: nama);
    final hargaEdit = TextEditingController(text: formatRupiah.format(harga));
    final stokEdit = TextEditingController(text: stok.toString());
    final barcodeEdit = TextEditingController(text: barcode);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: MediaQuery.of(context).size.height * 0.02,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade700,
                    Colors.blue.shade600,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Part',
                          style: GoogleFonts.poppins(
                            fontSize: MediaQuery.of(context).size.width * 0.045,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Perbarui data part',
                          style: GoogleFonts.poppins(
                            fontSize: MediaQuery.of(context).size.width * 0.035,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: MediaQuery.of(context).size.width * 0.06,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                child: ListView(
                  children: [
                    _buildInputField(
                      controller: namaEdit,
                      label: 'Nama Part',
                      icon: Iconsax.box,
                      isRequired: true,
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isSmallScreen = constraints.maxWidth < 400;
                        if (isSmallScreen) {
                          return Column(
                            children: [
                              _buildInputField(
                                controller: hargaEdit,
                                label: 'Harga',
                                icon: Iconsax.money,
                                keyboardType: TextInputType.number,
                                isCurrency: true,
                                isRequired: true,
                              ),
                              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                              _buildInputField(
                                controller: stokEdit,
                                label: 'Stok',
                                icon: Iconsax.box_add,
                                keyboardType: TextInputType.number,
                              ),
                            ],
                          );
                        } else {
                          return Row(
                            children: [
                              Expanded(
                                child: _buildInputField(
                                  controller: hargaEdit,
                                  label: 'Harga',
                                  icon: Iconsax.money,
                                  keyboardType: TextInputType.number,
                                  isCurrency: true,
                                  isRequired: true,
                                ),
                              ),
                              SizedBox(width: MediaQuery.of(context).size.width * 0.04),
                              Expanded(
                                child: _buildInputField(
                                  controller: stokEdit,
                                  label: 'Stok',
                                  icon: Iconsax.box_add,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),

                    // Barcode Section untuk Edit
                    Container(
                      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Iconsax.scan_barcode,
                                color: Colors.orange.shade700,
                                size: MediaQuery.of(context).size.width * 0.05,
                              ),
                              SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                              Text(
                                'Barcode',
                                style: GoogleFonts.poppins(
                                  fontSize: MediaQuery.of(context).size.width * 0.038,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: barcodeEdit,
                                    decoration: InputDecoration(
                                      hintText: 'Masukkan kode barcode',
                                      hintStyle: GoogleFonts.poppins(
                                        fontSize: MediaQuery.of(context).size.width * 0.035,
                                        color: Colors.grey.shade500,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: MediaQuery.of(context).size.width * 0.04,
                                        vertical: MediaQuery.of(context).size.height * 0.02,
                                      ),
                                    ),
                                    style: GoogleFonts.poppins(
                                      fontSize: MediaQuery.of(context).size.width * 0.038,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                              InkWell(
                                onTap: () async {
                                  final result = await _bukaScanner();
                                  if (result != null && result is String) {
                                    barcodeEdit.text = result;
                                  }
                                },
                                child: Container(
                                  width: MediaQuery.of(context).size.width * 0.12,
                                  height: MediaQuery.of(context).size.width * 0.12,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.blue.shade600,
                                        Colors.blue.shade400,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.shade200.withOpacity(0.4),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Iconsax.scan,
                                    color: Colors.white,
                                    size: MediaQuery.of(context).size.width * 0.06,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.04),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade100,
                              foregroundColor: Colors.grey.shade700,
                              padding: EdgeInsets.symmetric(
                                vertical: MediaQuery.of(context).size.height * 0.02,
                                horizontal: MediaQuery.of(context).size.width * 0.04,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Batal',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: MediaQuery.of(context).size.width * 0.038,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: MediaQuery.of(context).size.width * 0.04),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _simpanEdit(
                              id,
                              namaEdit,
                              hargaEdit,
                              stokEdit,
                              barcodeEdit,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: MediaQuery.of(context).size.height * 0.02,
                                horizontal: MediaQuery.of(context).size.width * 0.04,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 3,
                              shadowColor: Colors.blue.shade300,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Iconsax.save_2,
                                  size: MediaQuery.of(context).size.width * 0.05,
                                ),
                                SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                                Text(
                                  'Update',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: MediaQuery.of(context).size.width * 0.038,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _simpanEdit(
    String id,
    TextEditingController namaEdit,
    TextEditingController hargaEdit,
    TextEditingController stokEdit,
    TextEditingController barcodeEdit,
  ) async {
    try {
      final harga = _parseHarga(hargaEdit.text);

      await _firestore.collection('part').doc(id).update({
        'nama': namaEdit.text.trim(),
        'harga': harga,
        'stok': int.tryParse(stokEdit.text) ?? 0,
        'barcode': barcodeEdit.text.trim(),
        'updated_at': Timestamp.now(),
      });

      Navigator.pop(context);

      Get.snackbar(
        'Berhasil!',
        'Data part berhasil diperbarui',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Iconsax.tick_circle, color: Colors.white),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal memperbarui part: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  // ==========================
  // 🔹 Fungsi CRUD
  // ==========================
  Future<void> _hapusPart(String id, String nama) async {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.06),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Iconsax.warning_2,
                  color: Colors.red.shade600,
                  size: MediaQuery.of(context).size.width * 0.12,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              Text(
                'Hapus Part?',
                style: GoogleFonts.poppins(
                  fontSize: MediaQuery.of(context).size.width * 0.045,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.015),
              Text(
                'Anda akan menghapus "$nama". Tindakan ini tidak dapat dibatalkan.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: MediaQuery.of(context).size.width * 0.035,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.03),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        foregroundColor: Colors.grey.shade700,
                        padding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.height * 0.018,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Batal',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: MediaQuery.of(context).size.width * 0.038,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.04),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Get.back();
                        try {
                          await _firestore.collection('part').doc(id).delete();
                          Get.snackbar(
                            'Berhasil',
                            'Part berhasil dihapus',
                            backgroundColor: Colors.green,
                            colorText: Colors.white,
                            borderRadius: 12,
                            margin: const EdgeInsets.all(16),
                          );
                        } catch (e) {
                          Get.snackbar(
                            'Error',
                            'Gagal menghapus part: $e',
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                            borderRadius: 12,
                            margin: const EdgeInsets.all(16),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.height * 0.018,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Hapus',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: MediaQuery.of(context).size.width * 0.038,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _ubahStok(String id, int stokSekarang, int perubahan) async {
    final newStock = stokSekarang + perubahan;
    if (newStock < 0) {
      Get.snackbar(
        'Perhatian',
        'Stok tidak boleh kurang dari 0',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    try {
      await _firestore.collection('part').doc(id).update({
        'stok': newStock,
        'updated_at': Timestamp.now(),
      });
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal mengubah stok: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Part',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: MediaQuery.of(context).size.width * 0.045,
                color: Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 2),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('part').snapshots(),
              builder: (context, snapshot) {
                final totalParts = snapshot.data?.docs.length ?? 0;
                return Text(
                  '$totalParts part tersedia',
                  style: GoogleFonts.poppins(
                    fontSize: MediaQuery.of(context).size.width * 0.03,
                    color: Colors.grey.shade600,
                  ),
                );
              },
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.grey.shade200,
        surfaceTintColor: Colors.white,
        centerTitle: false,
        titleSpacing: 20,
      ),
      body: Column(
        children: [
          // 🔍 Search Section
          Container(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade100,
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.toLowerCase();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Cari nama part atau barcode...',
                            hintStyle: GoogleFonts.poppins(
                              fontSize: MediaQuery.of(context).size.width * 0.035,
                              color: Colors.grey.shade500,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: MediaQuery.of(context).size.width * 0.04,
                              vertical: MediaQuery.of(context).size.height * 0.02,
                            ),
                            prefixIcon: Icon(
                              Iconsax.search_normal,
                              color: Colors.orange.shade700,
                              size: MediaQuery.of(context).size.width * 0.055,
                            ),
                          ),
                          style: GoogleFonts.poppins(
                            fontSize: MediaQuery.of(context).size.width * 0.038,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                      Container(
                        height: MediaQuery.of(context).size.height * 0.07,
                        width: MediaQuery.of(context).size.height * 0.07,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.shade600,
                              Colors.orange.shade400,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(14),
                          ),
                        ),
                        child: IconButton(
                          onPressed: () async {
                            final result = await _bukaScanner();
                            if (result != null && result is String) {
                              setState(() {
                                _searchCtrl.text = result;
                                _searchQuery = result.toLowerCase();
                              });
                            }
                          },
                          icon: Icon(
                            Iconsax.scan_barcode,
                            color: Colors.white,
                            size: MediaQuery.of(context).size.width * 0.06,
                          ),
                          tooltip: 'Scan Barcode',
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),

                // Filter Chips
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.05,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip('Semua', 0),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                      _buildFilterChip('Stok Rendah', 1),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                      _buildFilterChip('Tanpa Barcode', 2),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                      _buildFilterChip('Populer', 3),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stats Cards - Responsive
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.04,
              vertical: MediaQuery.of(context).size.height * 0.015,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 400;
                
                return StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('part').snapshots(),
                  builder: (context, snapshot) {
                    final docs = snapshot.data?.docs ?? [];
                    final totalStok = docs.fold<int>(
                      0, (sum, doc) => sum + ((doc['stok'] as int?) ?? 0));
                    final totalNilai = docs.fold<int>(0,
                      (sum, doc) => sum + ((doc['stok'] as int?) ?? 0) * ((doc['harga'] as int?) ?? 0));
                    final lowStock = docs.where((doc) => ((doc['stok'] as int?) ?? 0) < 5).length;

                    if (isSmallScreen) {
                      return Column(
                        children: [
                          _buildStatCard(
                            icon: Iconsax.box,
                            value: docs.length.toString(),
                            label: 'Total Part',
                            color: Colors.blue.shade600,
                            isSmall: true,
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  icon: Iconsax.box_tick,
                                  value: totalStok.toString(),
                                  label: 'Total Stok',
                                  color: Colors.green.shade600,
                                  isSmall: true,
                                ),
                              ),
                              SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                              Expanded(
                                child: _buildStatCard(
                                  icon: Iconsax.warning_2,
                                  value: lowStock.toString(),
                                  label: 'Stok Rendah',
                                  color: Colors.orange.shade600,
                                  isSmall: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    } else {
                      return Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              icon: Iconsax.box,
                              value: docs.length.toString(),
                              label: 'Total Part',
                              color: Colors.blue.shade600,
                              isSmall: false,
                            ),
                          ),
                          SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                          Expanded(
                            child: _buildStatCard(
                              icon: Iconsax.box_tick,
                              value: totalStok.toString(),
                              label: 'Total Stok',
                              color: Colors.green.shade600,
                              isSmall: false,
                            ),
                          ),
                          SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                          Expanded(
                            child: _buildStatCard(
                              icon: Iconsax.warning_2,
                              value: lowStock.toString(),
                              label: 'Stok Rendah',
                              color: Colors.orange.shade600,
                              isSmall: false,
                            ),
                          ),
                        ],
                      );
                    }
                  },
                );
              },
            ),
          ),

          // 📋 List Parts
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('part')
                  .orderBy('created_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.1,
                          height: MediaQuery.of(context).size.width * 0.1,
                          child: CircularProgressIndicator(
                            color: Colors.orange.shade700,
                            strokeWidth: 3,
                          ),
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                        Text(
                          'Memuat data part...',
                          style: GoogleFonts.poppins(
                            fontSize: MediaQuery.of(context).size.width * 0.035,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.08),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width * 0.3,
                            height: MediaQuery.of(context).size.width * 0.3,
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Iconsax.box_remove,
                              size: MediaQuery.of(context).size.width * 0.15,
                              color: Colors.orange.shade300,
                            ),
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                          Text(
                            'Belum ada part',
                            style: GoogleFonts.poppins(
                              fontSize: MediaQuery.of(context).size.width * 0.045,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                          Text(
                            'Tambahkan part pertama Anda untuk memulai',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: MediaQuery.of(context).size.width * 0.035,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                          ElevatedButton(
                            onPressed: _tampilDialogTambah,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade700,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: MediaQuery.of(context).size.width * 0.08,
                                vertical: MediaQuery.of(context).size.height * 0.02,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Iconsax.add,
                                  size: MediaQuery.of(context).size.width * 0.05,
                                ),
                                SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                                Text(
                                  'Tambah Part',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: MediaQuery.of(context).size.width * 0.038,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final nama = (data['nama'] ?? '').toString().toLowerCase();
                  final barcode =
                      (data['barcode'] ?? '').toString().toLowerCase();
                  final stok = (data['stok'] as int?) ?? 0;

                  // Filter berdasarkan search
                  if (!nama.contains(_searchQuery) &&
                      !barcode.contains(_searchQuery)) {
                    return false;
                  }

                  // Filter tambahan
                  switch (_selectedFilter) {
                    case 1: // Stok Rendah
                      return stok < 5;
                    case 2: // Tanpa Barcode
                      return barcode.isEmpty;
                    case 3: // Populer
                      return stok > 0;
                    default:
                      return true;
                  }
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.search_normal,
                          size: MediaQuery.of(context).size.width * 0.15,
                          color: Colors.grey.shade300,
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                        Text(
                          'Part tidak ditemukan',
                          style: GoogleFonts.poppins(
                            fontSize: MediaQuery.of(context).size.width * 0.04,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                        Text(
                          'Coba kata kunci lain atau filter berbeda',
                          style: GoogleFonts.poppins(
                            fontSize: MediaQuery.of(context).size.width * 0.035,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                  itemCount: filteredDocs.length,
                  separatorBuilder: (context, index) =>
                      SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final nama = data['nama'] ?? '-';
                    final harga = data['harga'] ?? 0;
                    final stok = data['stok'] ?? 0;
                    final barcode = data['barcode'] ?? '';

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final isSmallScreen = constraints.maxWidth < 380;
                        
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.08),
                                blurRadius: 12,
                                spreadRadius: 2,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            border: Border.all(
                              color: stok < 5
                                  ? Colors.orange.shade100
                                  : Colors.grey.shade100,
                              width: 1.5,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () => _editPartDialog(
                                doc.id,
                                nama,
                                harga,
                                stok,
                                barcode,
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                                child: Row(
                                  children: [
                                    // Icon/Image
                                    Container(
                                      width: MediaQuery.of(context).size.width * 0.14,
                                      height: MediaQuery.of(context).size.width * 0.14,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: stok > 0
                                              ? [
                                                  Colors.orange.shade100,
                                                  Colors.orange.shade50,
                                                ]
                                              : [
                                                  Colors.grey.shade100,
                                                  Colors.grey.shade50,
                                                ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        stok > 0
                                            ? Iconsax.box
                                            : Iconsax.box_remove,
                                        color: stok > 0
                                            ? Colors.orange.shade700
                                            : Colors.grey.shade500,
                                        size: MediaQuery.of(context).size.width * 0.07,
                                      ),
                                    ),
                                    SizedBox(width: MediaQuery.of(context).size.width * 0.04),

                                    // Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nama,
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              fontSize: isSmallScreen 
                                                ? MediaQuery.of(context).size.width * 0.038
                                                : MediaQuery.of(context).size.width * 0.04,
                                              color: Colors.grey.shade900,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                                          Text(
                                            'Rp${formatRupiah.format(harga)}',
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w700,
                                              fontSize: isSmallScreen
                                                ? MediaQuery.of(context).size.width * 0.035
                                                : MediaQuery.of(context).size.width * 0.038,
                                              color: Colors.green.shade700,
                                            ),
                                          ),
                                          SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                                          Wrap(
                                            spacing: MediaQuery.of(context).size.width * 0.02,
                                            runSpacing: MediaQuery.of(context).size.height * 0.008,
                                            children: [
                                              // Stok Badge
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: MediaQuery.of(context).size.width * 0.025,
                                                  vertical: MediaQuery.of(context).size.height * 0.005,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: stok > 0
                                                      ? stok < 5
                                                          ? Colors.orange.shade50
                                                          : Colors.green.shade50
                                                      : Colors.red.shade50,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: stok > 0
                                                        ? stok < 5
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
                                                      stok > 0
                                                          ? stok < 5
                                                              ? Iconsax.warning_2
                                                              : Iconsax.box_tick
                                                          : Iconsax.box_remove,
                                                      size: MediaQuery.of(context).size.width * 0.03,
                                                      color: stok > 0
                                                          ? stok < 5
                                                              ? Colors.orange.shade700
                                                              : Colors.green.shade700
                                                          : Colors.red.shade700,
                                                    ),
                                                    SizedBox(width: MediaQuery.of(context).size.width * 0.01),
                                                    Text(
                                                      '$stok pcs',
                                                      style: GoogleFonts.poppins(
                                                        fontSize: MediaQuery.of(context).size.width * 0.03,
                                                        fontWeight: FontWeight.w600,
                                                        color: stok > 0
                                                            ? stok < 5
                                                                ? Colors.orange.shade700
                                                                : Colors.green.shade700
                                                            : Colors.red.shade700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Barcode Badge
                                              if (barcode.isNotEmpty)
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: MediaQuery.of(context).size.width * 0.025,
                                                    vertical: MediaQuery.of(context).size.height * 0.005,
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
                                                        Iconsax.scan_barcode,
                                                        size: MediaQuery.of(context).size.width * 0.03,
                                                        color: Colors.blue.shade700,
                                                      ),
                                                      SizedBox(width: MediaQuery.of(context).size.width * 0.01),
                                                      Text(
                                                        'Barcode',
                                                        style: GoogleFonts.poppins(
                                                          fontSize: MediaQuery.of(context).size.width * 0.03,
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

                                    // Actions
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Stok Controls
                                        Row(
                                          children: [
                                            InkWell(
                                              onTap: () => _ubahStok(doc.id, stok, -1),
                                              borderRadius: BorderRadius.circular(8),
                                              child: Container(
                                                padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.02),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.shade50,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.red.shade200,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Icon(
                                                  Iconsax.minus,
                                                  size: MediaQuery.of(context).size.width * 0.04,
                                                  color: Colors.red.shade700,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                                            InkWell(
                                              onTap: () => _ubahStok(doc.id, stok, 1),
                                              borderRadius: BorderRadius.circular(8),
                                              child: Container(
                                                padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.02),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.shade50,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.green.shade200,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Icon(
                                                  Iconsax.add,
                                                  size: MediaQuery.of(context).size.width * 0.04,
                                                  color: Colors.green.shade700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                                        // More Menu
                                        PopupMenuButton(
                                          itemBuilder: (context) => [
                                            PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Iconsax.edit_2,
                                                    color: Colors.blue.shade700,
                                                    size: MediaQuery.of(context).size.width * 0.045,
                                                  ),
                                                  SizedBox(width: MediaQuery.of(context).size.width * 0.025),
                                                  Text(
                                                    'Edit Part',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: MediaQuery.of(context).size.width * 0.035,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Iconsax.trash,
                                                    color: Colors.red.shade700,
                                                    size: MediaQuery.of(context).size.width * 0.045,
                                                  ),
                                                  SizedBox(width: MediaQuery.of(context).size.width * 0.025),
                                                  Text(
                                                    'Hapus',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: MediaQuery.of(context).size.width * 0.035,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                          onSelected: (value) {
                                            if (value == 'edit') {
                                              _editPartDialog(
                                                doc.id,
                                                nama,
                                                harga,
                                                stok,
                                                barcode,
                                              );
                                            } else if (value == 'delete') {
                                              _hapusPart(doc.id, nama);
                                            }
                                          },
                                          child: Container(
                                            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.025),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              Iconsax.more,
                                              color: Colors.grey.shade700,
                                              size: MediaQuery.of(context).size.width * 0.05,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tampilDialogTambah,
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        icon: Icon(
          Iconsax.add,
          size: MediaQuery.of(context).size.width * 0.06,
        ),
        label: Text(
          'Part Baru',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: MediaQuery.of(context).size.width * 0.038,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: MediaQuery.of(context).size.width * 0.033,
          fontWeight: FontWeight.w500,
          color: _selectedFilter == index ? Colors.white : Colors.grey.shade700,
        ),
      ),
      selected: _selectedFilter == index,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = selected ? index : 0;
        });
      },
      selectedColor: Colors.orange.shade700,
      backgroundColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: _selectedFilter == index
              ? Colors.orange.shade700
              : Colors.grey.shade300,
          width: 1,
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.04,
        vertical: MediaQuery.of(context).size.height * 0.01,
      ),
      elevation: 0,
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isSmall,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmall 
        ? MediaQuery.of(context).size.width * 0.03
        : MediaQuery.of(context).size.width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade100,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmall
              ? MediaQuery.of(context).size.width * 0.025
              : MediaQuery.of(context).size.width * 0.03),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: isSmall
                ? MediaQuery.of(context).size.width * 0.055
                : MediaQuery.of(context).size.width * 0.06,
            ),
          ),
          SizedBox(width: MediaQuery.of(context).size.width * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: isSmall
                      ? MediaQuery.of(context).size.width * 0.045
                      : MediaQuery.of(context).size.width * 0.05,
                    color: color,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.002),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: isSmall
                      ? MediaQuery.of(context).size.width * 0.03
                      : MediaQuery.of(context).size.width * 0.033,
                    color: Colors.grey.shade600,
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

// ===============================================
// 🔸 ScanBarcodePage - IMPROVED
// ===============================================
class ScanBarcodePage extends StatefulWidget {
  const ScanBarcodePage({super.key});

  @override
  State<ScanBarcodePage> createState() => _ScanBarcodePageState();
}

class _ScanBarcodePageState extends State<ScanBarcodePage> {
  bool _detected = false;
  MobileScannerController? _controller;

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
    if (_detected) return;
    final barcode = capture.barcodes.first.rawValue;
    if (barcode == null) return;

    setState(() => _detected = true);
    
    // Haptic feedback dan delay sebelum kembali
    Future.delayed(const Duration(milliseconds: 300), () {
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
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.025),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Iconsax.arrow_left_2,
              color: Colors.white,
              size: MediaQuery.of(context).size.width * 0.06,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            fit: BoxFit.cover,
          ),
          // Overlay gradient
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
          // Scanner frame - Responsive
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height: MediaQuery.of(context).size.width * 0.7,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.8),
                  width: 3,
                ),
              ),
              child: CustomPaint(
                painter: ScannerBorderPainter(),
              ),
            ),
          ),
          // Instruction text
          Positioned(
            top: MediaQuery.of(context).padding.top + MediaQuery.of(context).size.height * 0.12,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  'Scan Barcode',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: MediaQuery.of(context).size.width * 0.06,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.1,
                  ),
                  child: Text(
                    'Arahkan kamera ke barcode part',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: MediaQuery.of(context).size.width * 0.04,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom controls - Responsive
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.05,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Torch button
                Container(
                  width: MediaQuery.of(context).size.width * 0.14,
                  height: MediaQuery.of(context).size.width * 0.14,
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
                    icon: Icon(
                      Iconsax.flash_1,
                      color: Colors.white,
                      size: MediaQuery.of(context).size.width * 0.07,
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                // Cancel button
                ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.1,
                      vertical: MediaQuery.of(context).size.height * 0.02,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                  ),
                  child: Text(
                    'Batal Scan',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: MediaQuery.of(context).size.width * 0.04,
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

// Custom painter untuk efek scanner
class ScannerBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    
    // Corner lines
    final lineLength = size.width * 0.07;
    
    // Top left
    path.moveTo(0, lineLength);
    path.lineTo(0, 0);
    path.lineTo(lineLength, 0);
    
    // Top right
    path.moveTo(size.width - lineLength, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, lineLength);
    
    // Bottom right
    path.moveTo(size.width, size.height - lineLength);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width - lineLength, size.height);
    
    // Bottom left
    path.moveTo(lineLength, size.height);
    path.lineTo(0, size.height);
    path.lineTo(0, size.height - lineLength);

    canvas.drawPath(path, paint);
    
    // Scanning line effect
    final scanPaint = Paint()
      ..color = Colors.green.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    
    final animatedValue = DateTime.now().millisecond / 1000;
    final scanLineY = size.height * animatedValue;
    
    canvas.drawRect(
      Rect.fromLTRB(2, scanLineY - 2, size.width - 2, scanLineY + 2),
      scanPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}