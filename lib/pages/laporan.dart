import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';

import 'utils/report_stub.dart'
    if (dart.library.html) 'utils/report_web.dart'
    if (dart.library.io) 'utils/report_mobile.dart';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  String searchQuery = '';
  DateTime? startDate;
  DateTime? endDate;

  // 🟠 PILIH TANGGAL
  Future<void> pilihTanggal({required bool isStart}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      helpText: isStart ? 'Pilih Tanggal Awal' : 'Pilih Tanggal Akhir',
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked.add(const Duration(hours: 23, minutes: 59));
        }
      });
    }
  }

  // 🟢 EXPORT KE EXCEL
  Future<void> exportToExcel(
    BuildContext context,
    List<QueryDocumentSnapshot> docs,
  ) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );

      // Generate Excel di compute
      final bytes = await compute(_generateExcelBytes, docs);

      final fileName =
          'laporan_transaksi_${DateFormat('ddMMyyyy').format(DateTime.now())}.xlsx';

      // SAVE REPORT (Mobile / Web otomatis)
      final savedPath = await saveReport(
        bytes: bytes,
        fileName: fileName,
      );

      // Show snack bar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📁 Berhasil diexport ke: $savedPath'),
            backgroundColor: Colors.green,
          ),
        );
      }

      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 🧾 BUAT EXCEL
  static Uint8List _generateExcelBytes(List<QueryDocumentSnapshot> docs) {
    final excel = Excel.createExcel();
    final sheet = excel['Laporan Transaksi'];

    sheet.appendRow([
      TextCellValue('Tanggal'),
      TextCellValue('Customer'),
      TextCellValue('Engineer'),
      TextCellValue('Metode Pembayaran'),
      TextCellValue('Total Harga'),
    ]);

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final tanggal = (data['tanggal'] as Timestamp).toDate();
      final total = data['total_harga'] ?? 0;
      sheet.appendRow([
        TextCellValue(DateFormat('dd/MM/yyyy HH:mm').format(tanggal)),
        TextCellValue(data['nama_customer'] ?? '-'),
        TextCellValue(data['nama_engineer'] ?? '-'),
        TextCellValue(data['metode_pembayaran'] ?? '-'),
        TextCellValue('Rp${NumberFormat("#,###", "id_ID").format(total)}'),
      ]);
    }

    return Uint8List.fromList(excel.encode()!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Laporan Transaksi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.orange,
        centerTitle: true,
        elevation: 2,
      ),
      body: Column(
        children: [
          // 🔍 SEARCH BAR
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari nama customer...',
                prefixIcon: const Icon(Icons.search, color: Colors.orange),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),

          // 📅 FILTER TANGGAL - Versi sederhana tanpa BoxDecoration bermasalah
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => pilihTanggal(isStart: true),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        // border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Colors.orange.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              startDate == null
                                  ? 'Tanggal Awal'
                                  : DateFormat('dd/MM/yyyy').format(startDate!),
                              style: TextStyle(
                                color: startDate == null
                                    ? Colors.grey.shade500
                                    : Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => pilihTanggal(isStart: false),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        // border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event,
                            color: Colors.orange.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              endDate == null
                                  ? 'Tanggal Akhir'
                                  : DateFormat('dd/MM/yyyy').format(endDate!),
                              style: TextStyle(
                                color: endDate == null
                                    ? Colors.grey.shade500
                                    : Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 📊 INFO SUMMARY
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('transaksi')
                .orderBy('tanggal', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }

              final filteredDocs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final nama = (data['nama_customer'] ?? '')
                    .toString()
                    .toLowerCase();
                final tanggal = (data['tanggal'] as Timestamp).toDate();

                final cocokNama = nama.contains(searchQuery.toLowerCase());
                final cocokTanggal =
                    (startDate == null || tanggal.isAfter(startDate!)) &&
                        (endDate == null || tanggal.isBefore(endDate!));

                return cocokNama && cocokTanggal;
              }).toList();

              final totalHarga = filteredDocs.fold<double>(0, (sum, doc) {
                final data = doc.data() as Map<String, dynamic>;
                return sum + ((data['total_harga'] as num?)?.toDouble() ?? 0);
              });

              return Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${filteredDocs.length} Transaksi',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total Pendapatan',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Rp${NumberFormat("#,###", "id_ID").format(totalHarga)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // 📋 DAFTAR TRANSAKSI
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('transaksi')
                  .orderBy('tanggal', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.orange,
                    ),
                  );
                }

                final transaksi = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final nama = (data['nama_customer'] ?? '')
                      .toString()
                      .toLowerCase();
                  final tanggal = (data['tanggal'] as Timestamp).toDate();

                  final cocokNama = nama.contains(searchQuery.toLowerCase());
                  final cocokTanggal =
                      (startDate == null || tanggal.isAfter(startDate!)) &&
                          (endDate == null || tanggal.isBefore(endDate!));

                  return cocokNama && cocokTanggal;
                }).toList();

                if (transaksi.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada transaksi ditemukan',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // HEADER LIST
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.list, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Daftar Transaksi',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${transaksi.length} items',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // LIST TRANSAKSI
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: transaksi.length,
                        itemBuilder: (context, index) {
                          final data =
                              transaksi[index].data() as Map<String, dynamic>;
                          final tanggal =
                              (data['tanggal'] as Timestamp).toDate();
                          final total = data['total_harga'] ?? 0;
                          final metodeBayar = data['metode_pembayaran'] ?? '-';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              // border: Border.all(
                              //   color: Colors.grey.shade200,
                              //   width: 1,
                              // ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.05),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  // border: Border.all(
                                  //   color: Colors.orange.shade100,
                                  //   width: 1,
                                  // ),
                                ),
                                child: Icon(
                                  Icons.receipt_long,
                                  color: Colors.orange.shade700,
                                  size: 22,
                                ),
                              ),
                              title: Text(
                                data['nama_customer'] ?? '-',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('dd/MM/yyyy HH:mm')
                                        .format(tanggal),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person,
                                        size: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        data['nama_engineer'] ?? '-',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(
                                        Icons.payment,
                                        size: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        metodeBayar,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Rp${NumberFormat("#,###", "id_ID").format(total)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                      // border: Border.all(
                                      //   color: Colors.green.shade100,
                                      //   width: 1,
                                      // ),
                                    ),
                                    child: const Text(
                                      'Lunas',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // ⬇️ TOMBOL EXPORT
                    Container(
                      margin: const EdgeInsets.all(16),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.download, size: 22),
                        label: const Text(
                          'Export ke Excel',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        onPressed: () => exportToExcel(context, transaksi),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}