import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class StrukPage extends StatefulWidget {
  const StrukPage({super.key});

  @override
  State<StrukPage> createState() => _StrukPageState();
}

class _StrukPageState extends State<StrukPage> {
  final formatRupiah = NumberFormat("#,##0", "id_ID");

  Future<Map<String, dynamic>?> ambilTransaksiTerakhir() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('transaksi')
        .orderBy('tanggal', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    final data = snapshot.docs.first.data();
    data['id'] = snapshot.docs.first.id;
    return data;
  }

  Future<Map<String, dynamic>?> ambilProfilBengkel() async {
    final doc = await FirebaseFirestore.instance
        .collection('bengkel')
        .doc('profil')
        .get();

    if (!doc.exists) return null;
    return doc.data();
  }

  void cetakStruk() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🧾 Fitur cetak struk akan segera tersedia'),
      ),
    );
    // Nanti bisa disambungkan ke:
    // - package: printing (PDF)
    // - package: esc_pos_printer (thermal printer)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Struk Transaksi'),
        backgroundColor: Colors.orange,
      ),
      body: FutureBuilder<List<Map<String, dynamic>?>>(
        future: Future.wait([ambilTransaksiTerakhir(), ambilProfilBengkel()]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final transaksi = snapshot.data![0];
          final profil = snapshot.data![1];

          if (transaksi == null) {
            return const Center(child: Text("Belum ada transaksi"));
          }

          final items = List<Map<String, dynamic>>.from(transaksi['items']);
          final tanggal = (transaksi['tanggal'] as Timestamp).toDate();
          final dateFormatted = DateFormat(
            'dd MMM yyyy, HH:mm',
          ).format(tanggal);

          final namaBengkel = profil?['nama'] ?? 'Nama Bengkel';
          final alamatBengkel = profil?['alamat'] ?? 'Alamat Bengkel';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
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
                      // Header Bengkel
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
                            Text(alamatBengkel),
                            const SizedBox(height: 8),
                            const Divider(thickness: 1),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text("Tanggal   : $dateFormatted"),
                      Text("Customer : ${transaksi['nama_customer']}"),
                      Text("Engineer  : ${transaksi['nama_engineer']}"),
                      const Divider(thickness: 1),
                      const SizedBox(height: 6),

                      const Text(
                        "Detail Transaksi:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      ...items.map(
                        (item) => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(item['nama'])),
                            Text("${item['qty']}x"),
                            Text(
                              "Rp${formatRupiah.format(item['harga'] * item['qty'])}",
                            ),
                          ],
                        ),
                      ),
                      const Divider(thickness: 1),
                      const SizedBox(height: 6),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Total:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Rp${formatRupiah.format(transaksi['total_harga'])}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Metode Pembayaran: ${transaksi['metode_pembayaran']}",
                      ),
                      if (transaksi['metode_pembayaran'] == 'Cash') ...[
                        const SizedBox(height: 4),
                        Text(
                          "Uang Customer: Rp${formatRupiah.format(transaksi['uang_customer'] ?? 0)}",
                        ),
                        Text(
                          "Kembalian: Rp${formatRupiah.format(transaksi['kembalian'] ?? 0)}",
                        ),
                      ],
                      const SizedBox(height: 16),
                      const Divider(thickness: 1),
                      const Center(
                        child: Text(
                          "Terima kasih telah menggunakan layanan kami!",
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: cetakStruk,
                    icon: const Icon(Icons.print, color: Colors.white),
                    label: const Text(
                      "Cetak Struk",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
