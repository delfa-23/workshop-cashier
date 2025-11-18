import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CartPage extends StatefulWidget {
  final List<Map<String, dynamic>> keranjang;
  final Function(List<Map<String, dynamic>>) updateKeranjang;

  const CartPage({
    super.key,
    required this.keranjang,
    required this.updateKeranjang,
  });

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late List<Map<String, dynamic>> keranjang;

  @override
  void initState() {
    super.initState();
    keranjang = List<Map<String, dynamic>>.from(widget.keranjang);
  }

  final formatRupiah = NumberFormat('#,###', 'id_ID');

  int qtyInCart(String id) {
    final idx = keranjang.indexWhere((e) => e['id'] == id);
    if (idx == -1) return 0;
    return (keranjang[idx]['qty'] as num?)?.toInt() ?? 0;
  }

  Widget _buildKeranjang() {
    if (keranjang.isEmpty) {
      return const Center(child: Text("Keranjang masih kosong"));
    }

    return ListView.builder(
      itemCount: keranjang.length,
      itemBuilder: (context, index) {
        final item = keranjang[index];
        final bool isLayanan = item['tipe'] == 'layanan';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            title: Text(item['nama']),
            subtitle: Text(
              "Rp${formatRupiah.format(item['harga'])} × ${item['qty']} = "
              "Rp${formatRupiah.format(item['harga'] * item['qty'])}",
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isLayanan)
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.orange,
                    ),
                    onPressed: () {
                      setState(() {
                        if (item['qty'] > 1) {
                          item['qty']--;
                        } else {
                          keranjang.removeAt(index);
                        }
                      });
                      widget.updateKeranjang(keranjang);
                    },
                  ),
                Text(
                  '${item['qty']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (!isLayanan)
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Colors.orange,
                    ),
                    onPressed: () {
                      final stok = (item['stok'] as num?)?.toInt() ?? 0;
                      final qtyCart = qtyInCart(item['id']);
                      if (qtyCart < stok) {
                        setState(() {
                          item['qty']++;
                        });
                        widget.updateKeranjang(keranjang);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Stok ${item['nama']} tidak cukup'),
                          ),
                        );
                      }
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      keranjang.removeAt(index);
                    });
                    widget.updateKeranjang(keranjang);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, keranjang); // kirim data balik ke Kasir
        return false; // cegah pop default (biar gak dobel)
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Keranjang'),
          backgroundColor: Colors.orange,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context, keranjang); // tombol back juga kirim data
            },
          ),
        ),
        body: _buildKeranjang(),
      ),
    );
  }
}
