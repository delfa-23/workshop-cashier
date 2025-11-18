import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TransaksiPage extends StatefulWidget {
  final List<Map<String, dynamic>> keranjang;

  const TransaksiPage({super.key, required this.keranjang});

  @override
  State<TransaksiPage> createState() => _TransaksiPageState();
}

class _TransaksiPageState extends State<TransaksiPage> {
  final TextEditingController namaCustomerController = TextEditingController();
  String? selectedEngineer;
  String? namaEngineer;
  String? selectedMetode; // 🔥 Tambahan baru
  final formatRupiah = NumberFormat("#,##0", "id_ID");

  num get totalHarga {
    return widget.keranjang.fold<num>(
      0,
      (sum, item) => sum + (item['harga'] * item['qty']),
    );
  }

  Future<List<Map<String, dynamic>>> ambilEngineer() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('engineer')
        .get();
    return snapshot.docs
        .map((d) => {'id': d.id, 'nama': d['nama'] as String})
        .toList();
  }

  Future<void> simpanTransaksi() async {
    if (namaCustomerController.text.trim().isEmpty ||
        selectedEngineer == null ||
        selectedMetode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi semua data transaksi')),
      );
      return;
    }

    num uangCustomer = 0;
    num kembalian = 0;

    if (selectedMetode == 'Cash') {
      final text = uangCustomerController.text.replaceAll('.', '');
      uangCustomer = int.tryParse(text) ?? 0;
      kembalian = uangCustomer - totalHarga;
    }

    // Buat data transaksi
    final transaksi = {
      'nama_customer': namaCustomerController.text.trim(),
      'id_engineer': selectedEngineer,
      'nama_engineer': namaEngineer,
      'metode_pembayaran': selectedMetode,
      'total_harga': totalHarga,
      'tanggal': DateTime.now(),
      'items': widget.keranjang,
      if (selectedMetode == 'Cash') ...{
        'uang_customer': uangCustomer,
        'kembalian': kembalian,
      },
    };

    // Simpan ke Firestore
    await FirebaseFirestore.instance.collection('transaksi').add(transaksi);

    // 🔥 Kosongkan keranjang setelah transaksi berhasil
    setState(() {
      widget.keranjang.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaksi berhasil disimpan!')),
    );

    // 🔥 Arahkan ke halaman History (ganti dengan rute/halaman lo)
    Navigator.pushReplacementNamed(context, '/history');
  }

  @override
  void initState() {
    super.initState();

    uangCustomerController.addListener(() {
      final text = uangCustomerController.text.replaceAll('.', '');
      if (text.isEmpty) return;
      final number = int.tryParse(text);
      if (number != null) {
        final formatted = NumberFormat('#,###', 'id_ID').format(number);
        uangCustomerController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    });
  }

  final TextEditingController uangCustomerController = TextEditingController();
  num kembali = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nama Customer',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: namaCustomerController,
                decoration: const InputDecoration(
                  hintText: 'Masukkan nama customer',
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Pilih Engineer',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: ambilEngineer(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final engineers = snapshot.data!;
                  if (engineers.isEmpty) {
                    return const Text('Belum ada engineer di database.');
                  }

                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Pilih engineer',
                    ),
                    initialValue: selectedEngineer,
                    onChanged: (value) {
                      setState(() {
                        selectedEngineer = value;
                        namaEngineer = engineers.firstWhere(
                          (e) => e['id'] == value,
                        )['nama'];
                      });
                    },
                    items: engineers
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: e['id'],
                            child: Text(e['nama']),
                          ),
                        )
                        .toList(),
                  );
                },
              ),

              const SizedBox(height: 30),
              const Text(
                'Daftar Barang / Layanan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...widget.keranjang.map(
                (item) => ListTile(
                  title: Text(item['nama']),
                  subtitle: Text(
                    "Rp${formatRupiah.format(item['harga'])} × ${item['qty']} = Rp${formatRupiah.format(item['harga'] * item['qty'])}",
                  ),
                ),
              ),
              const Divider(),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Harga',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    "Rp${formatRupiah.format(totalHarga)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 🔥 Dropdown Metode Pembayaran
              const Text(
                'Metode Pembayaran',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Pilih metode pembayaran',
                ),
                value: selectedMetode,
                onChanged: (value) {
                  setState(() {
                    selectedMetode = value;
                  });
                },
                items: const [
                  DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'Transfer', child: Text('Transfer')),
                  DropdownMenuItem(value: 'QRIS', child: Text('QRIS')),
                ],
              ),

              const SizedBox(height: 20),

              if (selectedMetode == 'Cash') ...[
                const Text(
                  'Uang Customer',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: uangCustomerController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    prefixText: 'Rp ',
                    hintText: 'Masukkan jumlah uang dari customer',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 10),
                Builder(
                  builder: (context) {
                    final text = uangCustomerController.text.replaceAll(
                      '.',
                      '',
                    );
                    num bayar = int.tryParse(text) ?? 0;
                    final kembali = bayar - totalHarga;
                    return Text(
                      uangCustomerController.text.isEmpty
                          ? ''
                          : (kembali >= 0
                                ? "Kembalian: Rp${formatRupiah.format(kembali)}"
                                : "Kurang bayar: Rp${formatRupiah.format(-kembali)}"),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                        fontSize: 16,
                      ),
                    );
                  },
                ),
              ],

              if (selectedMetode == 'Transfer') ...[
                const Text(
                  'No. Rekening',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text(
                  'BCA 1234567890 a.n. Bengkel Sejahtera',
                  style: TextStyle(fontSize: 16),
                ),
              ],

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: simpanTransaksi,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Simpan Transaksi',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
