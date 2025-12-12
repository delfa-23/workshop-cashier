import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final formatRupiah = NumberFormat("#,##0", "id_ID");
  String selectedFilter = 'semua'; // 'semua', 'hari_ini', 'minggu_ini', 'custom'
  DateTime? startDate;
  DateTime? endDate;

  // Fungsi untuk memilih tanggal
  Future<void> _pilihTanggal({required bool isStart}) async {
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
        selectedFilter = 'custom';
      });
    }
  }

  // Fungsi untuk reset filter tanggal
  void _resetFilterTanggal() {
    setState(() {
      selectedFilter = 'semua';
      startDate = null;
      endDate = null;
    });
  }

  // Fungsi untuk memfilter transaksi berdasarkan tanggal
  List<QueryDocumentSnapshot> _filterTransaksi(List<QueryDocumentSnapshot> allDocs) {
    final now = DateTime.now();
    
    switch (selectedFilter) {
      case 'hari_ini':
        final todayStart = DateTime(now.year, now.month, now.day);
        final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final tanggal = (data['tanggal'] as Timestamp).toDate();
          return tanggal.isAfter(todayStart) && tanggal.isBefore(todayEnd);
        }).toList();
        
      case 'minggu_ini':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startWeek = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        final endWeek = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final tanggal = (data['tanggal'] as Timestamp).toDate();
          return tanggal.isAfter(startWeek) && tanggal.isBefore(endWeek);
        }).toList();
        
      case 'custom':
        return allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final tanggal = (data['tanggal'] as Timestamp).toDate();
          
          bool cocokStart = startDate == null || tanggal.isAfter(startDate!);
          bool cocokEnd = endDate == null || tanggal.isBefore(endDate!);
          
          return cocokStart && cocokEnd;
        }).toList();
        
      case 'semua':
      default:
        return allDocs;
    }
  }

  // Tombol untuk membuka custom date picker
  void _openCustomDatePicker() {
    setState(() {
      selectedFilter = 'custom';
      // Reset tanggal sebelumnya
      startDate = null;
      endDate = null;
    });
    
    // Tampilkan dialog atau langsung pilih tanggal
    _pilihTanggal(isStart: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Riwayat Transaksi',
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
        actions: [
          if (selectedFilter == 'custom' && (startDate != null || endDate != null))
            IconButton(
              onPressed: _resetFilterTanggal,
              icon: const Icon(Icons.refresh),
              tooltip: 'Reset Filter',
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('transaksi')
            .orderBy('tanggal', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.orange,
                strokeWidth: 3,
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada transaksi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Transaksi akan muncul di sini',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            );
          }

          final allTransaksi = snapshot.data!.docs;
          final filteredTransaksi = _filterTransaksi(allTransaksi);
          
          // Hitung total pendapatan
          double totalPendapatan = 0;
          for (var doc in filteredTransaksi) {
            final data = doc.data() as Map<String, dynamic>;
            totalPendapatan += (data['total_harga'] ?? 0).toDouble();
          }

          return Column(
            children: [
              // HEADER SUMMARY
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.orange.shade600,
                      Colors.orange.shade800,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 10,
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
                          'Total Transaksi',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${filteredTransaksi.length}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total Pendapatan',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rp${formatRupiah.format(totalPendapatan)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // FILTER TABS DAN TANGGAL
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // FILTER TABS (4 TAB)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          // TAB SEMUA
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedFilter = 'semua';
                                  startDate = null;
                                  endDate = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: selectedFilter == 'semua'
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: selectedFilter == 'semua'
                                      ? [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.1),
                                            blurRadius: 4,
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Center(
                                  child: Text(
                                    'Semua',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: selectedFilter == 'semua'
                                          ? Colors.orange
                                          : Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          // TAB HARI INI
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedFilter = 'hari_ini';
                                  startDate = null;
                                  endDate = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: selectedFilter == 'hari_ini'
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: selectedFilter == 'hari_ini'
                                      ? [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.1),
                                            blurRadius: 4,
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Center(
                                  child: Text(
                                    'Hari Ini',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: selectedFilter == 'hari_ini'
                                          ? Colors.orange
                                          : Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          // TAB MINGGU INI
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedFilter = 'minggu_ini';
                                  startDate = null;
                                  endDate = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: selectedFilter == 'minggu_ini'
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: selectedFilter == 'minggu_ini'
                                      ? [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.1),
                                            blurRadius: 4,
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Center(
                                  child: Text(
                                    'Minggu Ini',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: selectedFilter == 'minggu_ini'
                                          ? Colors.orange
                                          : Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          // TAB CUSTOM RANGE
                          Expanded(
                            child: GestureDetector(
                              onTap: _openCustomDatePicker,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: selectedFilter == 'custom'
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: selectedFilter == 'custom'
                                      ? [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.1),
                                            blurRadius: 4,
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Center(
                                  child: Text(
                                    'Custom',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: selectedFilter == 'custom'
                                          ? Colors.orange
                                          : Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // TAMPILKAN TANGGAL YANG DIPILIH (Hanya untuk Custom)
                    if (selectedFilter == 'custom' && (startDate != null || endDate != null))
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.shade100,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_month,
                                  color: Colors.blue.shade700,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Rentang Tanggal:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: _resetFilterTanggal,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.close,
                                          size: 14,
                                          color: Colors.red.shade700,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Reset',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.red.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _pilihTanggal(isStart: true),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            color: startDate == null
                                                ? Colors.grey.shade400
                                                : Colors.orange.shade700,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              startDate == null
                                                  ? 'Pilih Tanggal Awal'
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
                                    onTap: () => _pilihTanggal(isStart: false),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.event,
                                            color: endDate == null
                                                ? Colors.grey.shade400
                                                : Colors.orange.shade700,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              endDate == null
                                                  ? 'Pilih Tanggal Akhir'
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
                            
                            // TAMPILKAN RANGE TANGGAL
                            if (startDate != null && endDate != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      DateFormat('dd MMM yyyy').format(startDate!),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.arrow_forward,
                                      size: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('dd MMM yyyy').format(endDate!),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // LIST TITLE
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(
                      Icons.history,
                      color: Colors.grey.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Daftar Transaksi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${filteredTransaksi.length} items',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // LIST TRANSAKSI
              Expanded(
                child: filteredTransaksi.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
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
                            const SizedBox(height: 8),
                            if (selectedFilter == 'custom')
                              TextButton(
                                onPressed: _resetFilterTanggal,
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.orange,
                                ),
                                child: const Text('Reset Filter Tanggal'),
                              ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredTransaksi.length,
                        itemBuilder: (context, index) {
                          final doc = filteredTransaksi[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final tanggal = (data['tanggal'] as Timestamp).toDate();
                          final dateFormatted = DateFormat('dd/MM/yyyy, HH:mm').format(tanggal);
                          final total = data['total_harga'] ?? 0;
                          final metodeBayar = data['metode_pembayaran'] ?? '-';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // HEADER CARD
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.orange.shade100,
                                          Colors.orange.shade200,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.receipt_long,
                                      color: Colors.orange.shade700,
                                      size: 24,
                                    ),
                                  ),
                                  title: Text(
                                    data['nama_customer'] ?? 'Customer',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            size: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            dateFormatted,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(metodeBayar),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          metodeBayar,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Rp${formatRupiah.format(total)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${(data['items'] as List).length} items',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // DETAIL SECTION
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // INFO ENGINEER
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.person,
                                              size: 16,
                                              color: Colors.blue.shade700,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Engineer',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  data['nama_engineer'] ?? '-',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 12),

                                      // LIST ITEMS
                                      Text(
                                        'Items Pembelian:',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ...List<Widget>.from(
                                        (data['items'] as List).map(
                                          (item) => Container(
                                            margin: const EdgeInsets.only(bottom: 6),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade50,
                                              borderRadius: BorderRadius.circular(10),
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
                                                    borderRadius:
                                                        BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    '${item['qty']}x',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.orange.shade700,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    item['nama'],
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  'Rp${formatRupiah.format(item['harga'] * item['qty'])}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.green.shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 16),

                                      // ACTION BUTTONS
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () {
                                                Get.toNamed(
                                                  '/struk',
                                                  arguments: {
                                                    'transaksi': data,
                                                    'transaksiId': doc.id,
                                                  },
                                                );
                                              },
                                              icon: const Icon(
                                                Icons.visibility,
                                                size: 18,
                                              ),
                                              label: const Text('Lihat Detail'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.blue.shade700,
                                                side: BorderSide(
                                                  color: Colors.blue.shade300,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                padding: const EdgeInsets.symmetric(
                                                  vertical: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getStatusColor(String metodeBayar) {
    switch (metodeBayar.toLowerCase()) {
      case 'tunai':
        return Colors.green.shade500;
      case 'transfer':
        return Colors.blue.shade500;
      case 'qris':
        return Colors.purple.shade500;
      case 'debit':
        return Colors.orange.shade500;
      default:
        return Colors.grey.shade500;
    }
  }
}