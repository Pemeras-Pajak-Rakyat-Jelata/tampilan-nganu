import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _transaksiHarian = [];
  Map<String, dynamic> _ringkasanBulan = {};
  bool _loading = false;
  final _fmt = NumberFormat('#,##0', 'id_ID');
  final _fmtTgl = DateFormat('d MMMM yyyy', 'id_ID');
  final _fmtBulan = DateFormat('MMMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
    _loadHarian();
    _loadBulanan();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHarian() async {
    setState(() => _loading = true);
    try {
      final data = await SupabaseService.getLaporanHarian(_selectedDate);
      if (mounted) setState(() => _transaksiHarian = data);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadBulanan() async {
    try {
      final data = await SupabaseService.getRingkasanBulan(
          _selectedDate.month, _selectedDate.year);
      if (mounted) setState(() => _ringkasanBulan = data);
    } catch (_) {}
  }

  Future<void> _pilihTanggal() async {
    final tgl = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.hijauEmerald,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (tgl != null) {
      setState(() => _selectedDate = tgl);
      _loadHarian();
      _loadBulanan();
    }
  }

  double get _totalHarian =>
      _transaksiHarian.fold(0, (s, t) => s + (t['total'] as num));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kremGelap,
      appBar: AppBar(
        title: const Text('Laporan'),
        backgroundColor: AppTheme.hijauEmerald,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded, color: Colors.white),
            onPressed: _pilihTanggal,
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppTheme.emasTerang,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.6),
          labelStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 13),
          tabs: const [
            Tab(text: 'Harian'),
            Tab(text: 'Bulanan'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.hijauEmerald))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _HarianTab(
                  tanggal: _selectedDate,
                  transaksi: _transaksiHarian,
                  total: _totalHarian,
                  fmt: _fmt,
                  fmtTgl: _fmtTgl,
                  onRefresh: _loadHarian,
                ),
                _BulananTab(
                  tanggal: _selectedDate,
                  ringkasan: _ringkasanBulan,
                  fmt: _fmt,
                  fmtBulan: _fmtBulan,
                  onRefresh: _loadBulanan,
                ),
              ],
            ),
    );
  }
}

class _HarianTab extends StatelessWidget {
  final DateTime tanggal;
  final List<Map<String, dynamic>> transaksi;
  final double total;
  final NumberFormat fmt;
  final DateFormat fmtTgl;
  final VoidCallback onRefresh;

  const _HarianTab({
    required this.tanggal,
    required this.transaksi,
    required this.total,
    required this.fmt,
    required this.fmtTgl,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppTheme.hijauEmerald,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Tanggal badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.hijauEmerald.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      fmtTgl.format(tanggal),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppTheme.hijauEmerald,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Summary cards
                  Row(children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Total Omzet',
                        value: 'Rp ${fmt.format(total)}',
                        icon: Icons.payments_rounded,
                        color: AppTheme.hijauEmerald,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Transaksi',
                        value: '${transaksi.length}x',
                        icon: Icons.receipt_long_rounded,
                        color: AppTheme.emas,
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),

          if (transaksi.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 56,
                        color: AppTheme.abuAbu.withOpacity(0.4)),
                    const SizedBox(height: 12),
                    const Text('Tidak ada transaksi pada tanggal ini',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            color: AppTheme.abuAbu,
                            fontSize: 13)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final t = transaksi[i];
                    final waktu =
                        DateTime.parse(t['created_at']).toLocal();
                    final detail = (t['detail_transaksi'] as List?) ?? [];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color:
                                AppTheme.hijauEmerald.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.receipt_rounded,
                              color: AppTheme.hijauEmerald, size: 22),
                        ),
                        title: Text(
                          'Transaksi #${t['id']}',
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                        ),
                        subtitle: Text(
                          '${DateFormat('HH:mm').format(waktu)} · ${t['metode_bayar'] ?? '-'}',
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: AppTheme.abuAbu),
                        ),
                        trailing: Text(
                          'Rp ${fmt.format(t['total'])}',
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppTheme.hijauEmerald),
                        ),
                        children: detail.map<Widget>((d) {
                          final nama = d['produk']?['nama'] ?? '-';
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                            child: Row(
                              children: [
                                const Icon(Icons.circle,
                                    size: 6, color: AppTheme.abuAbu),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '$nama x${d['qty']}',
                                    style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12),
                                  ),
                                ),
                                Text(
                                  'Rp ${fmt.format(d['subtotal'])}',
                                  style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      color: AppTheme.hijauEmerald,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                  childCount: transaksi.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BulananTab extends StatelessWidget {
  final DateTime tanggal;
  final Map<String, dynamic> ringkasan;
  final NumberFormat fmt;
  final DateFormat fmtBulan;
  final VoidCallback onRefresh;

  const _BulananTab({
    required this.tanggal,
    required this.ringkasan,
    required this.fmt,
    required this.fmtBulan,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final totalBulan = (ringkasan['total'] ?? 0) as num;
    final totalTransaksi = (ringkasan['jumlah_transaksi'] ?? 0) as num;
    final rataHari = (ringkasan['rata_per_hari'] ?? 0) as num;

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppTheme.hijauEmerald,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Bulan badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.emas.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                fmtBulan.format(tanggal),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppTheme.coklat,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Islamic decorative total card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.hijauEmerald, Color(0xFF0D4A33)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                Opacity(
                  opacity: 0.06,
                  child: CustomPaint(
                    size: const Size(double.infinity, 120),
                    painter: IslamicPatternPainter(color: Colors.white),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Omzet Bulan Ini',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rp ${fmt.format(totalBulan)}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'بَارَكَ اللهُ فِي رِزْقِكَ',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.emasTerang,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Row(children: [
            Expanded(
              child: _StatCard(
                label: 'Total Transaksi',
                value: '${totalTransaksi}x',
                icon: Icons.receipt_long_rounded,
                color: AppTheme.emas,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Rata-rata/Hari',
                value: 'Rp ${fmt.format(rataHari)}',
                icon: Icons.trending_up_rounded,
                color: AppTheme.birInfo,
              ),
            ),
          ]),

          if (ringkasan.isEmpty) ...[
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  Icon(Icons.bar_chart_rounded,
                      size: 56, color: AppTheme.abuAbu.withOpacity(0.4)),
                  const SizedBox(height: 12),
                  const Text('Data bulanan belum tersedia',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          color: AppTheme.abuAbu,
                          fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    'Pastikan RPC ringkasan_bulan sudah dibuat di Supabase',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppTheme.abuAbu.withOpacity(0.7)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppTheme.abuAbu)),
                Text(value,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.hitamLembut)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
