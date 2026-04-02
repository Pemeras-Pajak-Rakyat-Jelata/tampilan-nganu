import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _transaksiHariIni = [];
  List<Map<String, dynamic>> _stokRendah = [];
  double _totalHariIni = 0;
  int _jumlahTransaksi = 0;

  final _fmt = NumberFormat('#,##0', 'id_ID');
  final _fmtTgl = DateFormat('EEEE, d MMMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final transaksi =
          await SupabaseService.getLaporanHarian(DateTime.now());
      final produk = await SupabaseService.getProduk();

      double total = 0;
      for (final t in transaksi) {
        total += (t['total'] as num).toDouble();
      }

      final stokRendah = produk
          .where((p) => (p['stok'] as num) <= (p['stok_minimum'] ?? 5))
          .toList();

      if (mounted) {
        setState(() {
          _transaksiHariIni = transaksi.take(5).toList();
          _totalHariIni = total;
          _jumlahTransaksi = transaksi.length;
          _stokRendah = stokRendah;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = now.hour < 11
        ? 'Selamat Pagi'
        : now.hour < 15
            ? 'Selamat Siang'
            : now.hour < 18
                ? 'Selamat Sore'
                : 'Selamat Malam';

    return Scaffold(
      backgroundColor: AppTheme.kremGelap,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.hijauEmerald,
        child: CustomScrollView(
          slivers: [
            // ── Header ──
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  Container(
                    height: 200,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.hijauEmerald, Color(0xFF0D4A33)],
                      ),
                      borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(32)),
                    ),
                  ),
                  Opacity(
                    opacity: 0.06,
                    child: CustomPaint(
                      size: const Size(double.infinity, 200),
                      painter: IslamicPatternPainter(color: AppTheme.emas),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$greeting 👋',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 13,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                    const Text(
                                      'Dashboard',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      _fmtTgl.format(now),
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.emas.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color:
                                          AppTheme.emasTerang.withOpacity(0.5)),
                                ),
                                child: const Text(
                                  'بَارَكَ اللهُ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.emasTerang,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_loading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.hijauEmerald),
                ),
              )
            else ...[
              // ── Summary Cards ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          label: 'Omzet Hari Ini',
                          value: 'Rp ${_fmt.format(_totalHariIni)}',
                          icon: Icons.payments_rounded,
                          iconColor: AppTheme.hijauEmerald,
                          bgColor: AppTheme.hijauEmerald.withOpacity(0.1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          label: 'Transaksi',
                          value: '$_jumlahTransaksi kali',
                          icon: Icons.receipt_long_rounded,
                          iconColor: AppTheme.emas,
                          bgColor: AppTheme.emas.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Stok Rendah Alert ──
              if (_stokRendah.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFFFBBF24).withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: Color(0xFFD97706), size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${_stokRendah.length} produk stok menipis: '
                              '${_stokRendah.take(2).map((p) => p['nama']).join(', ')}'
                              '${_stokRendah.length > 2 ? ', ...' : ''}',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Transaksi Terbaru ──
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Transaksi Terbaru',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.hitamLembut,
                        ),
                      ),
                      Text(
                        'Hari ini',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppTheme.abuAbu,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_transaksiHariIni.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 48,
                              color: AppTheme.abuAbu.withOpacity(0.5)),
                          const SizedBox(height: 8),
                          const Text(
                            'Belum ada transaksi hari ini',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: AppTheme.abuAbu,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final t = _transaksiHariIni[i];
                        final waktu = DateTime.parse(t['created_at']).toLocal();
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: const Color(0xFFE5E7EB), width: 1),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.hijauEmerald.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.receipt_rounded,
                                  color: AppTheme.hijauEmerald,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Transaksi #${t['id']}',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.hitamLembut,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('HH:mm').format(waktu),
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 11,
                                        color: AppTheme.abuAbu,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Rp ${_fmt.format(t['total'])}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.hijauEmerald,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: _transaksiHariIni.length,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: AppTheme.abuAbu,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.hitamLembut,
            ),
          ),
        ],
      ),
    );
  }
}
