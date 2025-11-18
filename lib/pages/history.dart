import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final formatRupiah = NumberFormat("#,##0", "id_ID");

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('transaksi')
            .orderBy('tanggal', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Belum ada transaksi.'));
          }

          final transaksiList = snapshot.data!.docs;

          return ListView.builder(
            itemCount: transaksiList.length,
            itemBuilder: (context, index) {
              final data = transaksiList[index].data() as Map<String, dynamic>;
              final tanggal = (data['tanggal'] as Timestamp).toDate();

              return Card(
                margin: const EdgeInsets.all(10),
                child: ExpansionTile(
                  title: Text(
                    "${data['nama_customer']} - Rp${formatRupiah.format(data['total_harga'])}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "${DateFormat('dd MMM yyyy, HH:mm').format(tanggal)} • ${data['metode_pembayaran']}",
                  ),
                  children: [
                    ListTile(
                      title: Text("Engineer: ${data['nama_engineer'] ?? '-'}"),
                    ),
                    ...List<Widget>.from((data['items'] as List)
                        .map((item) => ListTile(
                              title: Text(item['nama']),
                              subtitle: Text(
                                "Rp${formatRupiah.format(item['harga'])} × ${item['qty']}",
                              ),
                            ))),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
