import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EngineerPage extends StatefulWidget {
  const EngineerPage({super.key});

  @override
  State<EngineerPage> createState() => _EngineerPageState();
}

class _EngineerPageState extends State<EngineerPage> {
  final TextEditingController _namaController = TextEditingController();

  Future<void> _tambahEngineer() async {
    if (_namaController.text.trim().isEmpty) return;

    await FirebaseFirestore.instance.collection('engineer').add({
      'nama': _namaController.text.trim(),
    });

    _namaController.clear();
  }

  Future<void> _editEngineer(String id, String currentName) async {
    _namaController.text = currentName;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Engineer'),
        content: TextField(
          controller: _namaController,
          decoration: const InputDecoration(labelText: 'Nama Engineer'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_namaController.text.trim().isEmpty) return;
              await FirebaseFirestore.instance
                  .collection('engineer')
                  .doc(id)
                  .update({'nama': _namaController.text.trim()});
              _namaController.clear();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _hapusEngineer(String id) async {
    await FirebaseFirestore.instance.collection('engineer').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Engineer'),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('engineer').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.docs ?? [];

          if (data.isEmpty) {
            return const Center(child: Text('Belum ada engineer'));
          }

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final doc = data[index];
              final nama = doc['nama'];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(nama),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editEngineer(doc.id, nama),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _hapusEngineer(doc.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Tambah Engineer', ),
              content: TextField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: 'Nama Engineer'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _tambahEngineer();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text('Tambah', style: TextStyle(color: Colors.white),),
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
