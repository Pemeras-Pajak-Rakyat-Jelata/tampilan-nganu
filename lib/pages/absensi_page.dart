import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AbsensiPage extends StatefulWidget {
  const AbsensiPage({super.key});

  @override
  State<AbsensiPage> createState() => _AbsensiPageState();
}

class _AbsensiPageState extends State<AbsensiPage> {
  DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> data = [];
  List<Map<String, dynamic>> filtered = [];
  bool loading = true;

  final searchCtrl = TextEditingController();
  final fmt = DateFormat('d MMMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();
    loadData();
    searchCtrl.addListener(filterData);
  }

  Future<void> loadData() async {
    setState(() => loading = true);

    final tgl = DateFormat('yyyy-MM-dd').format(selectedDate);

    final result = await SupabaseService.getAbsensiByTanggal(tgl);

    if (mounted) {
      setState(() {
        data = result;
        filtered = result;
        loading = false;
      });
    }
  }

  void filterData() {
    final q = searchCtrl.text.toLowerCase();

    setState(() {
      filtered = data.where((e) {
        final nama = e['nama_user'].toString().toLowerCase();
        return nama.contains(q);
      }).toList();
    });
  }

  Future<void> pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      selectedDate = picked;
      loadData();
    }
  }

  Future<void> exportPdf() async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.MultiPage(
      build: (context) => [
        pw.Text(
          'Laporan Absensi',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),

        pw.SizedBox(height: 8),

        pw.Text(
          DateFormat('d MMMM yyyy', 'id_ID').format(selectedDate),
        ),

        pw.SizedBox(height: 20),

        pw.Table.fromTextArray(
          headers: ['No', 'Nama', 'Jam Masuk', 'Status'],
          data: List.generate(filtered.length, (i) {
            final item = filtered[i];
            final jam = item['jam_masuk'] ?? '-';
            final nama = item['nama_user'] ?? '-';
            final telat = isLate(jam);

            return [
              '${i + 1}',
              nama,
              jam,
              telat ? 'Telat' : 'Tepat',
            ];
          }),
        ),
      ],
    ),
  );

  await Printing.layoutPdf(
    onLayout: (format) async => pdf.save(),
  );
}

  bool isLate(String jam) {
    try {
      final p = jam.split(':');
      final h = int.parse(p[0]);
      final m = int.parse(p[1]);

      if (h > 8) return true;
      if (h == 8 && m > 0) return true;

      return false;
    } catch (_) {
      return false;
    }
  }

  int telatCount() =>
      filtered.where((e) => isLate(e['jam_masuk'] ?? '')).length;

  int tepatCount() =>
      filtered.where((e) => !isLate(e['jam_masuk'] ?? '')).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kremGelap,
      appBar: AppBar(
        title: const Text("Absensi Karyawan"),
        centerTitle: true,
        backgroundColor: AppTheme.hijauEmerald,
      actions: [
      IconButton(
        onPressed: exportPdf,
        icon: const Icon(Icons.picture_as_pdf),
      ),
      IconButton(
        onPressed: pilihTanggal,
        icon: const Icon(Icons.calendar_month),
      ),
    ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(
              color: AppTheme.hijauEmerald,
            ))
          : RefreshIndicator(
              onRefresh: loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  headerCard(),
                  const SizedBox(height: 16),
                  searchBox(),
                  const SizedBox(height: 16),
                  summaryCard(),
                  const SizedBox(height: 16),

                  if (filtered.isEmpty) emptyState(),

                  ...filtered.map((e) => itemCard(e)).toList(),
                ],
              ),
            ),
    );
  }

  Widget headerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppTheme.hijauEmerald,
            Color(0xFF0D4A33),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Icon(Icons.fact_check, color: Colors.white, size: 42),
          const SizedBox(height: 10),
          Text(
            fmt.format(selectedDate),
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "${filtered.length} Karyawan Hadir",
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontFamily: 'Poppins',
            ),
          )
        ],
      ),
    );
  }

  Widget searchBox() {
    return TextField(
      controller: searchCtrl,
      decoration: InputDecoration(
        hintText: "Cari nama karyawan...",
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget summaryCard() {
    return Row(
      children: [
        Expanded(child: statBox("Hadir", filtered.length, Colors.green)),
        const SizedBox(width: 10),
        Expanded(child: statBox("Tepat", tepatCount(), Colors.blue)),
        const SizedBox(width: 10),
        Expanded(child: statBox("Telat", telatCount(), Colors.orange)),
      ],
    );
  }

  Widget statBox(String title, int val, Color c) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            "$val",
            style: TextStyle(
              color: c,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(title),
        ],
      ),
    );
  }

  Widget itemCard(Map<String, dynamic> e) {
    final nama = e['nama_user'] ?? '-';
    final jam = e['jam_masuk'] ?? '-';
    final telat = isLate(jam);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.hijauEmerald.withOpacity(0.1),
            child: Text(
              nama.toString()[0].toUpperCase(),
              style: const TextStyle(
                color: AppTheme.hijauEmerald,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Masuk Jam $jam",
                  style: const TextStyle(
                    color: AppTheme.abuAbu,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: telat
                  ? Colors.orange.withOpacity(0.12)
                  : Colors.green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              telat ? "Telat" : "Tepat",
              style: TextStyle(
                color: telat ? Colors.orange : Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget emptyState() {
    return const Padding(
      padding: EdgeInsets.only(top: 60),
      child: Center(
        child: Text(
          "Belum ada data absensi",
          style: TextStyle(
            fontFamily: 'Poppins',
            color: AppTheme.abuAbu,
          ),
        ),
      ),
    );
  }
}