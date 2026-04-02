import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
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

  final List<Widget> _pages = const [
    DashboardPage(),
    KasirPage(),
    StokPage(),
    LaporanPage(),
    AkunPage(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _NavItem(icon: Icons.point_of_sale_rounded, label: 'Kasir'),
    _NavItem(icon: Icons.inventory_2_rounded, label: 'Stok'),
    _NavItem(icon: Icons.bar_chart_rounded, label: 'Laporan'),
    _NavItem(icon: Icons.person_rounded, label: 'Akun'),
  ];

  @override
  Widget build(BuildContext context) {
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
                // Kasir (index 1) jadi FAB style
                if (i == 1) {
                  return GestureDetector(
                    onTap: () => setState(() => _currentIndex = i),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.hijauMuda, AppTheme.hijauEmerald],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.hijauEmerald.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Icon(item.icon,
                              color: Colors.white,
                              size: selected ? 26 : 24),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.hijauEmerald,
                          ),
                        )
                      ],
                    ),
                  );
                }
                return GestureDetector(
                  onTap: () => setState(() => _currentIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: selected
                        ? BoxDecoration(
                            color: AppTheme.hijauEmerald.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          )
                        : null,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          color: selected
                              ? AppTheme.hijauEmerald
                              : AppTheme.abuAbu,
                          size: 24,
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
  const _NavItem({required this.icon, required this.label});
}
