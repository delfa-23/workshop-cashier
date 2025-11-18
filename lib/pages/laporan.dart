import 'dart:io';
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
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
      BuildContext context, List<QueryDocumentSnapshot> docs) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );

      final bytes = await compute(_generateExcelBytes, docs);
      final fileName =
          'laporan_transaksi_${DateFormat('ddMMyyyy').format(DateTime.now())}.xlsx';

      if (kIsWeb) {
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        await Permission.storage.request();
        Directory? dir;
        if (Platform.isAndroid) {
          dir = Directory('/storage/emulated/0/Download');
        } else {
          dir = await getDownloadsDirectory();
        }

        final filePath = '${dir!.path}/$fileName';
        final file = File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(bytes);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ Laporan disimpan di: $filePath')),
          );
        }
      }

      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Gagal export: $e')),
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
      sheet.appendRow([
        TextCellValue(DateFormat('dd/MM/yyyy HH:mm').format(tanggal)),
        TextCellValue(data['nama_customer'] ?? '-'),
        TextCellValue(data['nama_engineer'] ?? '-'),
        TextCellValue(data['metode_pembayaran'] ?? '-'),
        TextCellValue('Rp${data['total_harga'] ?? 0}'),
      ]);
    }

    return Uint8List.fromList(excel.encode()!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Transaksi'),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          // 🔍 SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari nama customer...',
                prefixIcon: const Icon(Icons.search, color: Colors.orange),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),

          // 📅 FILTER TANGGAL
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => pilihTanggal(isStart: true),
                    icon: const Icon(Icons.date_range, color: Colors.orange),
                    label: Text(
                      startDate == null
                          ? 'Tanggal Awal'
                          : DateFormat('dd/MM/yyyy').format(startDate!),
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => pilihTanggal(isStart: false),
                    icon: const Icon(Icons.event, color: Colors.orange),
                    label: Text(
                      endDate == null
                          ? 'Tanggal Akhir'
                          : DateFormat('dd/MM/yyyy').format(endDate!),
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
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
                  return const Center(child: CircularProgressIndicator());
                }

                final transaksi = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final nama =
                      (data['nama_customer'] ?? '').toString().toLowerCase();
                  final tanggal = (data['tanggal'] as Timestamp).toDate();

                  final cocokNama =
                      nama.contains(searchQuery.toLowerCase());
                  final cocokTanggal =
                      (startDate == null || tanggal.isAfter(startDate!)) &&
                          (endDate == null || tanggal.isBefore(endDate!));

                  return cocokNama && cocokTanggal;
                }).toList();

                if (transaksi.isEmpty) {
                  return const Center(child: Text('Tidak ada transaksi ditemukan.'));
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: transaksi.length,
                        itemBuilder: (context, index) {
                          final data =
                              transaksi[index].data() as Map<String, dynamic>;
                          final tanggal =
                              (data['tanggal'] as Timestamp).toDate();
                          final total = data['total_harga'] ?? 0;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: const Icon(Icons.receipt_long,
                                  color: Colors.orange),
                              title: Text(data['nama_customer'] ?? '-'),
                              subtitle: Text(
                                  DateFormat('dd/MM/yyyy HH:mm').format(tanggal)),
                              trailing: Text(
                                'Rp ${NumberFormat("#,###", "id_ID").format(total)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // ⬇️ TOMBOL EXPORT
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          minimumSize: const Size.fromHeight(50),
                        ),
                        icon: const Icon(Icons.download, color: Colors.white),
                        label: const Text(
                          'Export ke Excel',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
