import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';

class StokPage extends StatefulWidget {
  const StokPage({super.key});

  @override
  State<StokPage> createState() => _StokPageState();
}

class _StokPageState extends State<StokPage> {
  List<Map<String, dynamic>> _produk = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String _query = '';
  final _fmt = NumberFormat('#,##0', 'id_ID');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await SupabaseService.getProduk();
      if (mounted) {
        setState(() {
          _produk = data;
          _filter();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filter() {
    final q = _query.toLowerCase();
    _filtered = q.isEmpty
        ? List.from(_produk)
        : _produk
        .where((p) => p['nama'].toLowerCase().contains(q))
        .toList();
  }

  void _showForm({Map<String, dynamic>? produk}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProdukForm(
        produk: produk,
        onSaved: _load,
      ),
    );
  }

  Future<void> _hapus(int id, String nama) async {
    final konfirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Produk',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: Text('Yakin ingin menghapus "$nama"?',
            style: const TextStyle(fontFamily: 'Poppins')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.merahError),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (konfirm == true) {
      await SupabaseService.hapusProduk(id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kremGelap,
      appBar: AppBar(
        title: const Text('Stok Produk'),
        backgroundColor: AppTheme.hijauEmerald,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (v) => setState(() {
                _query = v;
                _filter();
              }),
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Cari produk...',
                hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                prefixIcon:
                const Icon(Icons.search, color: AppTheme.abuAbu),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        backgroundColor: AppTheme.hijauEmerald,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Produk',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: Colors.white)),
      ),
      body: _loading
          ? const Center(
          child: CircularProgressIndicator(color: AppTheme.hijauEmerald))
          : _filtered.isEmpty
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 56,
                color: AppTheme.abuAbu.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text(
              _query.isEmpty
                  ? 'Belum ada produk'
                  : 'Produk tidak ditemukan',
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: AppTheme.abuAbu,
                  fontSize: 14),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.hijauEmerald,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: _filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) {
            final p = _filtered[i];
            final stok = p['stok'] as int;
            final minimum = (p['stok_minimum'] ?? 5) as int;
            final rendah = stok <= minimum;
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: rendah
                      ? const Color(0xFFFBBF24).withOpacity(0.5)
                      : const Color(0xFFE5E7EB),
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: rendah
                        ? const Color(0xFFFEF3C7)
                        : AppTheme.hijauEmerald.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.inventory_2_rounded,
                    color: rendah
                        ? const Color(0xFFD97706)
                        : AppTheme.hijauEmerald,
                    size: 22,
                  ),
                ),
                title: Text(
                  p['nama'],
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.hitamLembut,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      'Rp ${_fmt.format(p['harga'])}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: AppTheme.hijauEmerald,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (p['kategori'] != null)
                      Text(
                        p['kategori'],
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: AppTheme.abuAbu,
                        ),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: rendah
                                ? const Color(0xFFFEF3C7)
                                : AppTheme.hijauEmerald
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$stok',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: rendah
                                  ? const Color(0xFFD97706)
                                  : AppTheme.hijauEmerald,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p['satuan'] ?? 'pcs',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: AppTheme.abuAbu,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert,
                          color: AppTheme.abuAbu),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      onSelected: (v) {
                        if (v == 'edit') _showForm(produk: p);
                        if (v == 'hapus') _hapus(p['id'], p['nama']);
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Edit',
                                style:
                                TextStyle(fontFamily: 'Poppins')),
                          ]),
                        ),
                        const PopupMenuItem(
                          value: 'hapus',
                          child: Row(children: [
                            Icon(Icons.delete_outline,
                                size: 18, color: AppTheme.merahError),
                            SizedBox(width: 8),
                            Text('Hapus',
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: AppTheme.merahError)),
                          ]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Form Tambah / Edit Produk ──
class _ProdukForm extends StatefulWidget {
  final Map<String, dynamic>? produk;
  final VoidCallback onSaved;

  const _ProdukForm({this.produk, required this.onSaved});

  @override
  State<_ProdukForm> createState() => _ProdukFormState();
}

class _ProdukFormState extends State<_ProdukForm> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _hargaCtrl = TextEditingController();
  final _stokCtrl = TextEditingController();
  final _kategoriCtrl = TextEditingController();
  final _satuanCtrl = TextEditingController();
  final _minCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.produk != null) {
      final p = widget.produk!;
      _namaCtrl.text = p['nama'] ?? '';
      _hargaCtrl.text = p['harga']?.toString() ?? '';
      _stokCtrl.text = p['stok']?.toString() ?? '';
      _kategoriCtrl.text = p['kategori'] ?? '';
      _satuanCtrl.text = p['satuan'] ?? '';
      _minCtrl.text = p['stok_minimum']?.toString() ?? '5';
    } else {
      _satuanCtrl.text = 'pcs';
      _minCtrl.text = '5';
    }
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final data = {
      'nama': _namaCtrl.text.trim(),
      'harga': int.parse(_hargaCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')),
      'stok': int.parse(_stokCtrl.text),
      'kategori': _kategoriCtrl.text.trim(),
      'satuan': _satuanCtrl.text.trim(),
      'stok_minimum': int.parse(_minCtrl.text),
      'user_id': SupabaseService.currentUser?.id,
    };
    try {
      if (widget.produk != null) {
        await SupabaseService.updateProduk(widget.produk!['id'], data);
      } else {
        await SupabaseService.tambahProduk(data);
      }
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal menyimpan: $e'),
          backgroundColor: AppTheme.merahError,
        ));
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.produk == null ? 'Tambah Produk' : 'Edit Produk',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.hitamLembut,
                ),
              ),
              const SizedBox(height: 20),
              _field(_namaCtrl, 'Nama Produk', Icons.label_outline,
                  required: true),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: _field(_hargaCtrl, 'Harga (Rp)', Icons.payments_outlined,
                      keyboardType: TextInputType.number, required: true),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(_stokCtrl, 'Stok', Icons.inventory_outlined,
                      keyboardType: TextInputType.number, required: true),
                ),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: _field(_satuanCtrl, 'Satuan', Icons.straighten_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(_minCtrl, 'Stok Minimum',
                      Icons.warning_amber_outlined,
                      keyboardType: TextInputType.number),
                ),
              ]),
              const SizedBox(height: 14),
              _field(_kategoriCtrl, 'Kategori (opsional)',
                  Icons.category_outlined),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _simpan,
                  child: _loading
                      ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                      : Text(
                    widget.produk == null ? 'Simpan Produk' : 'Update Produk',
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
      TextEditingController ctrl,
      String label,
      IconData icon, {
        TextInputType keyboardType = TextInputType.text,
        bool required = false,
      }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.hijauEmerald, size: 20),
      ),
      validator: required
          ? (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null
          : null,
    );
  }
}