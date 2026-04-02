import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';

class AkunPage extends StatefulWidget {
  const AkunPage({super.key});

  @override
  State<AkunPage> createState() => _AkunPageState();
}

class _AkunPageState extends State<AkunPage> {
  Map<String, dynamic>? _profil;
  bool _loading = true;
  bool _editMode = false;
  bool _saving = false;

  final _namaCtrl = TextEditingController();
  final _telpCtrl = TextEditingController();
  final _alamatCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final p = await SupabaseService.getProfil();
      if (mounted) {
        setState(() {
          _profil = p;
          _loading = false;
        });
        if (p != null) {
          _namaCtrl.text = p['nama'] ?? '';
          _telpCtrl.text = p['telepon'] ?? '';
          _alamatCtrl.text = p['alamat'] ?? '';
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _simpan() async {
    setState(() => _saving = true);
    try {
      await SupabaseService.updateProfil({
        'nama': _namaCtrl.text.trim(),
        'telepon': _telpCtrl.text.trim(),
        'alamat': _alamatCtrl.text.trim(),
      });
      await _load();
      if (mounted) {
        setState(() => _editMode = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profil berhasil diperbarui',
              style: TextStyle(fontFamily: 'Poppins')),
          backgroundColor: AppTheme.hijauEmerald,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal: $e'),
          backgroundColor: AppTheme.merahError,
        ));
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _logout() async {
    final konfirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar',
            style: TextStyle(
                fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: const Text('Yakin ingin keluar dari akun?',
            style: TextStyle(fontFamily: 'Poppins')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal',
                  style: TextStyle(fontFamily: 'Poppins'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.merahError),
            child: const Text('Keluar',
                style: TextStyle(fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
    if (konfirm == true) {
      await SupabaseService.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.currentUser;
    return Scaffold(
      backgroundColor: AppTheme.kremGelap,
      appBar: AppBar(
        title: const Text('Akun'),
        backgroundColor: AppTheme.hijauEmerald,
        actions: [
          if (!_loading)
            TextButton(
              onPressed: _editMode
                  ? () => setState(() => _editMode = false)
                  : () => setState(() => _editMode = true),
              child: Text(
                _editMode ? 'Batal' : 'Edit',
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(
          child:
          CircularProgressIndicator(color: AppTheme.hijauEmerald))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Profile Header ──
            Container(
              width: double.infinity,
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
                    opacity: 0.07,
                    child: CustomPaint(
                      size: const Size(double.infinity, 100),
                      painter:
                      IslamicPatternPainter(color: AppTheme.emas),
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppTheme.emasTerang, width: 2),
                        ),
                        child: const Icon(Icons.person_rounded,
                            color: Colors.white, size: 44),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _profil?['nama'] ?? 'Pengguna',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppTheme.emasTerang,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Form / Info ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border:
                Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informasi Profil',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.hitamLembut,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_editMode) ...[
                    _editField(_namaCtrl, 'Nama Lengkap',
                        Icons.person_outline),
                    const SizedBox(height: 12),
                    _editField(_telpCtrl, 'Nomor Telepon',
                        Icons.phone_outlined,
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: 12),
                    _editField(_alamatCtrl, 'Alamat',
                        Icons.location_on_outlined,
                        maxLines: 2),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _simpan,
                        child: _saving
                            ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5))
                            : const Text('Simpan Perubahan',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 15)),
                      ),
                    ),
                  ] else ...[
                    _infoRow(Icons.person_outline, 'Nama',
                        _profil?['nama'] ?? '-'),
                    _infoRow(Icons.email_outlined, 'Email',
                        user?.email ?? '-'),
                    _infoRow(Icons.phone_outlined, 'Telepon',
                        _profil?['telepon'] ?? '-'),
                    _infoRow(Icons.location_on_outlined, 'Alamat',
                        _profil?['alamat'] ?? '-'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Logout ──
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded,
                    color: AppTheme.merahError),
                label: const Text('Keluar',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        color: AppTheme.merahError,
                        fontSize: 15)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.merahError),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kasir Barokah · بَارَكَ اللهُ',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: AppTheme.abuAbu.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _editField(
      TextEditingController ctrl,
      String label,
      IconData icon, {
        TextInputType keyboardType = TextInputType.text,
        int maxLines = 1,
      }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.hijauEmerald, size: 20),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.hijauEmerald, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppTheme.abuAbu)),
                Text(value,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.hitamLembut)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}