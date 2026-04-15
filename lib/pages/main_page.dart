import 'package:flutter/material.dart';
import 'package:kasir_barokah/pages/absensi_page.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';

import 'dashboard_page.dart';
import 'kasir_page.dart';
import 'stok_page.dart';
import 'laporan_page.dart';
import 'akun_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  bool _loading = true;
  bool _isAdmin = false;

  List<Widget> _pages = [];
  List<_NavItem> _navItems = [];

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    try {
      final admin = await SupabaseService.isAdmin();

      setState(() {
        _isAdmin = admin;

        if (_isAdmin) {
          // ADMIN = semua akses
          _pages = const [
            DashboardPage(),
            KasirPage(),
            StokPage(),
            LaporanPage(),
            AbsensiPage(),
            AkunPage(),
          ];

          _navItems = const [
            _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
            _NavItem(icon: Icons.point_of_sale_rounded, label: 'Kasir'),
            _NavItem(icon: Icons.inventory_2_rounded, label: 'Stok'),
            _NavItem(icon: Icons.bar_chart_rounded, label: 'Laporan'),
            _NavItem(icon: Icons.fact_check_rounded, label: 'List Absen'),
            _NavItem(icon: Icons.person_rounded, label: 'Akun'),
          ];
        } else {
          _pages = const [
            DashboardPage(),
            KasirPage(),
            StokPage(),
            AkunPage(),
          ];

          _navItems = const [
            _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
            _NavItem(icon: Icons.point_of_sale_rounded, label: 'Kasir'),
            _NavItem(icon: Icons.inventory_2_rounded, label: 'Stok'),
            _NavItem(icon: Icons.person_rounded, label: 'Akun'),
          ];
        }

        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AppTheme.hijauEmerald,
          ),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_navItems.length, (i) {
                final item = _navItems[i];
                final selected = _currentIndex == i;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentIndex = i;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: selected
                        ? BoxDecoration(
                            color:
                                AppTheme.hijauEmerald.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(12),
                          )
                        : null,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          size: 24,
                          color: selected
                              ? AppTheme.hijauEmerald
                              : AppTheme.abuAbu,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: selected
                                ? AppTheme.hijauEmerald
                                : AppTheme.abuAbu,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.label,
  });
}