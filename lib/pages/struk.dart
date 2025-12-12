import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:get/get.dart';

class StrukPage extends StatefulWidget {
  const StrukPage({super.key});

  @override
  State<StrukPage> createState() => _StrukPageState();
}

class _StrukPageState extends State<StrukPage> {
  final formatRupiah = NumberFormat("#,##0", "id_ID");

  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  List<BluetoothDevice> devices = [];
  BluetoothDevice? selectedDevice;
  bool isPrinting = false;
  bool isLoadingDevices = false;
  bool isLoadingData = true;
  
  Map<String, dynamic>? transaksi;
  Map<String, dynamic>? profilBengkel;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initBluetooth();
      _loadData();
    });
  }

  Future<void> _loadData() async {
    try {
      setState(() => isLoadingData = true);
      
      // 1. Cek apakah ada data yang dikirim dari HistoryPage
      final arguments = Get.arguments;
      
      if (arguments != null && arguments is Map) {
        // Jika ada data dari HistoryPage, gunakan itu
        transaksi = arguments['transaksi'];
        if (arguments['transaksiId'] != null) {
          transaksi?['id'] = arguments['transaksiId'];
        }
      }
      
      // 2. Jika tidak ada dari arguments, ambil transaksi terakhir
      if (transaksi == null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('transaksi')
            .orderBy('tanggal', descending: true)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          transaksi = snapshot.docs.first.data();
          transaksi!['id'] = snapshot.docs.first.id;
        } else {
          errorMessage = "Belum ada transaksi";
        }
      }
      
      // 3. Load profil bengkel
      final doc = await FirebaseFirestore.instance
          .collection('bengkel')
          .doc('profil')
          .get();

      if (doc.exists) {
        profilBengkel = doc.data();
      }
      
    } catch (e) {
      print("Error load data: $e");
      errorMessage = "Gagal memuat data";
    } finally {
      if (mounted) {
        setState(() => isLoadingData = false);
      }
    }
  }

  Future<void> _initBluetooth() async {
    try {
      setState(() => isLoadingDevices = true);
      
      devices = await bluetooth.getBondedDevices();
      print("📱 Ditemukan ${devices.length} perangkat Bluetooth");
      
      if (devices.isNotEmpty) {
        selectedDevice = devices.first;
        print("🎯 Printer terpilih: ${selectedDevice!.name}");
        
        // Coba konek otomatis
        bool? isConnected = await bluetooth.isConnected;
        if (isConnected == false) {
          print("🔗 Mencoba menghubungkan...");
          await bluetooth.connect(selectedDevice!);
          await Future.delayed(const Duration(seconds: 2));
        }
      } else {
        print("❌ Tidak ada printer yang dipairing");
      }
    } catch (e) {
      print("❌ Error init Bluetooth: $e");
    } finally {
      if (mounted) {
        setState(() => isLoadingDevices = false);
      }
    }
  }

  // ✅ FUNGSI CETAK YANG SUDAH DIPERBAIKI (tanpa error font size)
  Future<void> cetakStruk() async {
    if (isPrinting || transaksi == null) return;
    
    setState(() => isPrinting = true);
    
    try {
      print("🖨 Memulai proses cetak...");
      
      // Cek apakah ada printer yang dipairing
      if (devices.isEmpty) {
        await _initBluetooth();
        if (devices.isEmpty) {
          _showSnackBar("Tidak ada printer yang dipairing");
          return;
        }
      }
      
      // Cek koneksi printer
      bool? connected = await bluetooth.isConnected;
      if (connected == false || selectedDevice == null) {
        if (selectedDevice != null) {
          await bluetooth.connect(selectedDevice!);
          await Future.delayed(const Duration(seconds: 2));
          connected = await bluetooth.isConnected;
        }
      }
      
      if (connected == false) {
        _showSnackBar("Gagal terhubung ke printer");
        return;
      }
      
      // Persiapan data
      final tanggal = (transaksi!['tanggal'] as Timestamp).toDate();
      final dateFormatted = DateFormat('dd MMM yyyy, HH:mm').format(tanggal);
      final items = List<Map<String, dynamic>>.from(transaksi!['items']);
      
      final namaBengkel = profilBengkel?['nama'] ?? 'Bengkel';
      final alamatBengkel = profilBengkel?['alamat'] ?? 'Alamat Bengkel';
      final teleponBengkel = profilBengkel?['telepon'] ?? '';

      // ========== MULAI CETAK ==========
      
      // HEADER BENGKEL - ✅ FIX: font size hanya 0-4
      bluetooth.printCustom(namaBengkel.toUpperCase(), 2, 1); // ✅ size=2 (besar), align=center
      bluetooth.printCustom(alamatBengkel, 1, 1); // ✅ size=1 (normal), align=center
      if (teleponBengkel.isNotEmpty) {
        bluetooth.printCustom("Telp: $teleponBengkel", 1, 1);
      }
      bluetooth.printNewLine();
      
      // GARIS PEMISAH
      bluetooth.printCustom("--------------------------------", 1, 1);
      
      // INFO TRANSAKSI
      bluetooth.printCustom("Tanggal   : $dateFormatted", 1, 0); // ✅ size=1, align=left
      bluetooth.printCustom("Customer  : ${transaksi!['nama_customer']}", 1, 0);
      bluetooth.printCustom("Engineer  : ${transaksi!['nama_engineer']}", 1, 0);
      if (transaksi!['id'] != null) {
        final idStr = transaksi!['id'].toString();
        final shortId = idStr.length > 8 ? idStr.substring(0, 8) : idStr;
        bluetooth.printCustom("No. Struk : $shortId", 1, 0);
      }
      
      bluetooth.printCustom("--------------------------------", 1, 1);
      
      // DETAIL ITEMS
      bluetooth.printCustom("DETAIL TRANSAKSI:", 2, 0); // ✅ size=2 (besar), align=left
      bluetooth.printNewLine();
      
      for (var item in items) {
        final namaItem = item['nama'] ?? 'Item';
        final qty = item['qty'] ?? 1;
        final harga = item['harga'] ?? 0;
        final total = harga * qty;
        
        // Nama item
        bluetooth.printCustom(namaItem, 1, 0); // ✅ size=1, align=left
        
        // Qty x Harga = Total
        bluetooth.printLeftRight(
          "  $qty x Rp${formatRupiah.format(harga)}",
          "Rp${formatRupiah.format(total)}",
          1, // ✅ size=1 untuk text normal
        );
      }
      
      bluetooth.printCustom("--------------------------------", 1, 1);
      
      // TOTAL & PEMBAYARAN
      final totalHarga = transaksi!['total_harga'] ?? 0;
      bluetooth.printLeftRight(
        "TOTAL",
        "Rp${formatRupiah.format(totalHarga)}",
        2, // ✅ size=2 untuk bold total
      );
      bluetooth.printNewLine();
      
      final metodeBayar = transaksi!['metode_pembayaran'] ?? 'Cash';
      bluetooth.printCustom(
        "Metode Bayar: ${metodeBayar.toUpperCase()}",
        1, // ✅ size=1
        0, // ✅ align=left
      );
      
      if (metodeBayar.toString().toLowerCase() == 'cash') {
        final uangCustomer = transaksi!['uang_customer'] ?? 0;
        final kembalian = transaksi!['kembalian'] ?? 0;
        
        bluetooth.printLeftRight(
          "Uang Customer",
          "Rp${formatRupiah.format(uangCustomer)}",
          1,
        );
        
        bluetooth.printLeftRight(
          "Kembalian",
          "Rp${formatRupiah.format(kembalian)}",
          1,
        );
      }
      
      bluetooth.printCustom("--------------------------------", 1, 1);
      
      // FOOTER
      bluetooth.printNewLine();
      bluetooth.printCustom("TERIMA KASIH", 2, 1); // ✅ size=2 (besar), align=center
      bluetooth.printCustom("Atas kunjungan Anda", 1, 1);
      bluetooth.printCustom("Semoga puas dengan layanan kami", 1, 1);
      
      // FEED PAPER untuk cutting (4x newline)
      for (int i = 0; i < 4; i++) {
        bluetooth.printNewLine();
      }
      
      print("✅ Struk berhasil dikirim ke printer");
      _showSnackBar("Struk berhasil dikirim ke printer", isError: false);
      
    } catch (e) {
      print("❌ Error saat mencetak: $e");
      _showSnackBar("Error: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => isPrinting = false);
      }
    }
  }

  // ✅ FUNGSI TEST PRINTER (SIMPLE)
  Future<void> testPrinter() async {
    if (isPrinting) return;
    
    setState(() => isPrinting = true);
    
    try {
      if (selectedDevice == null) {
        _showSnackBar("Tidak ada printer terpilih");
        return;
      }
      
      bool? connected = await bluetooth.isConnected;
      if (connected == false) {
        await bluetooth.connect(selectedDevice!);
        await Future.delayed(const Duration(seconds: 2));
      }
      
      connected = await bluetooth.isConnected;
      if (connected == true) {
        // Test dengan font size yang valid
        bluetooth.printCustom("TEST PRINT", 2, 1); // ✅ size=2
        bluetooth.printNewLine();
        bluetooth.printCustom("Bengkel Pro", 1, 1); // ✅ size=1
        bluetooth.printNewLine();
        bluetooth.printCustom("Test printer berhasil", 1, 1);
        bluetooth.printNewLine();
        bluetooth.printNewLine();
        bluetooth.printNewLine();
        
        _showSnackBar("Test print berhasil!", isError: false);
      } else {
        _showSnackBar("Gagal terhubung ke printer");
      }
    } catch (e) {
      _showSnackBar("Error test print: $e");
    } finally {
      if (mounted) {
        setState(() => isPrinting = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Struk Transaksi'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth),
            onPressed: _initBluetooth,
            tooltip: "Refresh printer",
          ),
        ],
      ),
      body: isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : transaksi == null
                  ? const Center(child: Text("Tidak ada data transaksi"))
                  : _buildContent(),
    );
  }

  Widget _buildContent() {
    final items = List<Map<String, dynamic>>.from(transaksi!['items']);
    final tanggal = (transaksi!['tanggal'] as Timestamp).toDate();
    final dateFormatted = DateFormat('dd MMM yyyy, HH:mm').format(tanggal);
    
    final namaBengkel = profilBengkel?['nama'] ?? 'Nama Bengkel';
    final alamatBengkel = profilBengkel?['alamat'] ?? 'Alamat Bengkel';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // INFO TRANSAKSI HEADER
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade100),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaksi!['nama_customer'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      Text(
                        dateFormatted,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  backgroundColor: Colors.green.shade100,
                  label: Text(
                    "Rp${formatRupiah.format(transaksi!['total_harga'])}",
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // INFO PRINTER
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Row(
              children: [
                Icon(
                  selectedDevice != null ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                  color: selectedDevice != null ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedDevice?.name ?? "Printer belum dipilih",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: selectedDevice != null ? Colors.green[700] : Colors.grey,
                        ),
                      ),
                      Text(
                        devices.isNotEmpty 
                            ? "${devices.length} printer ditemukan"
                            : "Tidak ada printer",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (isLoadingDevices)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _initBluetooth,
                  iconSize: 20,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // BUTTON TEST
          if (devices.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isPrinting ? null : testPrinter,
                icon: const Icon(Icons.print_outlined),
                label: const Text("Test Printer"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          
          const SizedBox(height: 20),
          
          // STRUK PREVIEW
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 4),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Text(
                        namaBengkel.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.orange,
                        ),
                      ),
                      Text(
                        alamatBengkel,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Divider(thickness: 1),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text("Tanggal   : $dateFormatted"),
                Text("Customer : ${transaksi!['nama_customer']}"),
                Text("Engineer  : ${transaksi!['nama_engineer']}"),
                const Divider(thickness: 1),
                const SizedBox(height: 6),
                const Text(
                  "Detail Transaksi:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item['nama'],
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text("${item['qty']}x"),
                        const SizedBox(width: 10),
                        Text(
                          "Rp${formatRupiah.format(item['harga'] * item['qty'])}",
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(thickness: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "TOTAL:",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      "Rp${formatRupiah.format(transaksi!['total_harga'])}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Metode Pembayaran: ${transaksi!['metode_pembayaran']}",
                ),
                if (transaksi!['metode_pembayaran'] == 'Cash') ...[
                  const SizedBox(height: 4),
                  Text(
                    "Uang Customer: Rp${formatRupiah.format(transaksi!['uang_customer'] ?? 0)}",
                  ),
                  Text(
                    "Kembalian: Rp${formatRupiah.format(transaksi!['kembalian'] ?? 0)}",
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          // BUTTON CETAK UTAMA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isPrinting ? null : cetakStruk,
              icon: isPrinting 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.print, color: Colors.white),
              label: Text(
                isPrinting ? "SEDANG MENCETAK..." : "CETAK STRUK",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPrinting ? Colors.orange[700] : Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}