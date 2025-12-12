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
  String? selectedMetode;
  final TextEditingController uangCustomerController = TextEditingController();
  final formatRupiah = NumberFormat("#,##0", "id_ID");
  bool isLoading = false;

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
        const SnackBar(
          content: Text('Lengkapi semua data transaksi'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (selectedMetode == 'Cash') {
      final text = uangCustomerController.text.replaceAll('.', '');
      final bayar = int.tryParse(text) ?? 0;
      if (bayar < totalHarga) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Uang customer kurang: Rp${formatRupiah.format(totalHarga - bayar)}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    setState(() => isLoading = true);

    try {
      num uangCustomer = 0;
      num kembalian = 0;

      if (selectedMetode == 'Cash') {
        final text = uangCustomerController.text.replaceAll('.', '');
        uangCustomer = int.tryParse(text) ?? 0;
        kembalian = uangCustomer - totalHarga;
      }

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

      await FirebaseFirestore.instance.collection('transaksi').add(transaksi);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Transaksi Rp${formatRupiah.format(totalHarga)} berhasil disimpan!',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      // Clear form
      widget.keranjang.clear();
      namaCustomerController.clear();
      uangCustomerController.clear();
      setState(() {
        selectedEngineer = null;
        selectedMetode = null;
        namaEngineer = null;
        isLoading = false;
      });

      // Navigate back
      if (context.mounted) Navigator.pop(context);

    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    final num bayar = uangCustomerController.text.replaceAll('.', '').isNotEmpty
        ? int.tryParse(uangCustomerController.text.replaceAll('.', '')) ?? 0
        : 0;
    final num kembalian = bayar - totalHarga;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Transaksi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.orange,
        centerTitle: true,
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CARD INFORMASI CUSTOMER
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.person,
                            color: Colors.orange.shade700,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nama Customer',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: namaCustomerController,
                                decoration: InputDecoration(
                                  hintText: 'Masukkan nama customer',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // PILIH ENGINEER
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.engineering,
                            color: Colors.blue.shade700,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Engineer Bertugas',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              FutureBuilder<List<Map<String, dynamic>>>(
                                future: ambilEngineer(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const SizedBox(
                                      height: 40,
                                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                    );
                                  }
                                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                    return Text(
                                      'Belum ada engineer',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                      ),
                                    );
                                  }
                                  
                                  final engineers = snapshot.data!;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      value: selectedEngineer,
                                      hint: Text(
                                        'Pilih engineer',
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                      icon: Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.grey.shade600,
                                      ),
                                      underline: const SizedBox(),
                                      onChanged: (value) {
                                        setState(() {
                                          selectedEngineer = value;
                                          namaEngineer = engineers.firstWhere(
                                            (e) => e['id'] == value,
                                          )['nama'];
                                        });
                                      },
                                      items: engineers.map((e) {
                                        return DropdownMenuItem<String>(
                                          value: e['id'],
                                          child: Text(
                                            e['nama'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // CARD DAFTAR BARANG
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.shopping_cart,
                            color: Colors.purple.shade700,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Daftar Barang / Layanan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${widget.keranjang.length} items',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    if (widget.keranjang.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.shopping_basket_outlined,
                              size: 60,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Keranjang kosong',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...widget.keranjang.map(
                        (item) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${item['qty']}x',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['nama'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Rp${formatRupiah.format(item['harga'])}/item',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Rp${formatRupiah.format(item['harga'] * item['qty'])}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (widget.keranjang.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.shade100,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Harga',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Rp${formatRupiah.format(totalHarga)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // CARD METODE PEMBAYARAN
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.payment,
                            color: Colors.green.shade700,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Metode Pembayaran',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.grey.shade200,
                        ),
                      ),
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedMetode,
                        hint: Text(
                          'Pilih metode pembayaran',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                          ),
                        ),
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: Colors.grey.shade600,
                        ),
                        underline: const SizedBox(),
                        onChanged: (value) {
                          setState(() {
                            selectedMetode = value;
                            if (value != 'Cash') {
                              uangCustomerController.clear();
                            }
                          });
                        },
                        items: const [
                          DropdownMenuItem(
                            value: 'Cash',
                            child: Text('💵 Cash'),
                          ),
                          DropdownMenuItem(
                            value: 'Transfer',
                            child: Text('🏦 Transfer'),
                          ),
                          DropdownMenuItem(
                            value: 'QRIS',
                            child: Text('📱 QRIS'),
                          ),
                        ],
                      ),
                    ),

                    if (selectedMetode == 'Cash') ...[
                      const SizedBox(height: 20),
                      Text(
                        'Uang Customer',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: uangCustomerController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Rp 0',
                          prefixIcon: const Icon(Icons.monetization_on),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      if (uangCustomerController.text.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: kembalian >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: kembalian >= 0 ? Colors.green.shade100 : Colors.red.shade100,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                kembalian >= 0 ? 'Kembalian' : 'Kurang Bayar',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: kembalian >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                                ),
                              ),
                              Text(
                                'Rp${formatRupiah.format(kembalian.abs())}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: kembalian >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],

                    if (selectedMetode == 'Transfer') ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.shade100,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.account_balance,
                                  color: Colors.blue.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Transfer ke:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Bank BCA',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const Text(
                              '1234567890',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'a/n. Bengkel Sejahtera',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // TOMBOL SIMPAN
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : simpanTransaksi,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                    shadowColor: Colors.orange.withOpacity(0.3),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save, size: 22),
                            SizedBox(width: 12),
                            Text(
                              'Simpan Transaksi',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}