import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // ── Client biasa (anon key) ──
  static final SupabaseClient client = Supabase.instance.client;

  // ── Client admin (service_role key) — hanya untuk buat/hapus user ──
  static SupabaseClient get adminClient => SupabaseClient(
        dotenv.env['SUPABASE_URL']!,
        dotenv.env['SUPABASE_SERVICE_ROLE_KEY']!,
      );

  // ───────────── AUTH ─────────────
  static Future<void> signIn(String email, String password) async {
    await client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static User? get currentUser => client.auth.currentUser;

  // ───────────── CEK ADMIN ─────────────
  static Future<bool> isAdmin() async {
    final uid = client.auth.currentUser?.id;
    if (uid == null) return false;
    final res = await client
        .from('profil')
        .select('is_admin')
        .eq('id', uid)
        .maybeSingle();
    return res?['is_admin'] == true;
  }

  // ───────────── KELOLA USER (admin only) ─────────────
  // Buat user baru — pakai service_role key
  static Future<void> buatUser(String email, String password, String nama) async {
    // 1. Buat akun auth
    final res = await adminClient.auth.admin.createUser(
      AdminUserAttributes(
        email: email,
        password: password,
        emailConfirm: true, // langsung aktif tanpa verifikasi email
      ),
    );

    final uid = res.user?.id;
    if (uid == null) throw Exception('Gagal membuat user');

    // 2. Isi profil
    await adminClient.from('profil').upsert({
      'id': uid,
      'nama': nama,
      'is_admin': false,
    });
  }

  // Ambil semua user (untuk tampilan di halaman admin)
  static Future<List<Map<String, dynamic>>> getDaftarUser() async {
    final res = await client
        .from('profil')
        .select('id, nama, is_admin, created_at')
        .order('created_at');
    return List<Map<String, dynamic>>.from(res);
  }

  // Hapus user (admin only)
  static Future<void> hapusUser(String uid) async {
    await adminClient.auth.admin.deleteUser(uid);
  }

  // ───────────── PRODUK ─────────────
  static Future<List<Map<String, dynamic>>> getProduk() async {
    final res = await client.from('produk').select().order('nama');
    return List<Map<String, dynamic>>.from(res);
  }

  static Future<void> tambahProduk(Map<String, dynamic> data) async {
    await client.from('produk').insert(data);
  }

  static Future<void> updateProduk(int id, Map<String, dynamic> data) async {
    await client.from('produk').update(data).eq('id', id);
  }

  static Future<void> hapusProduk(int id) async {
    await client.from('produk').delete().eq('id', id);
  }

  // ───────────── TRANSAKSI ─────────────
  static Future<List<Map<String, dynamic>>> getTransaksi() async {
    final res = await client
        .from('transaksi')
        .select('*, detail_transaksi(*, produk(nama))')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  static Future<int> tambahTransaksi(Map<String, dynamic> data) async {
    final res =
        await client.from('transaksi').insert(data).select('id').single();
    return res['id'];
  }

  static Future<void> tambahDetailTransaksi(
      List<Map<String, dynamic>> items) async {
    await client.from('detail_transaksi').insert(items);
  }

  static Future<void> updateStokProduk(int produkId, int qty) async {
    await client.rpc('kurangi_stok', params: {'p_id': produkId, 'p_qty': qty});
  }

  // ───────────── LAPORAN ─────────────
  static Future<List<Map<String, dynamic>>> getLaporanHarian(
      DateTime tanggal) async {
    final tgl = tanggal.toIso8601String().split('T')[0];
    final res = await client
        .from('transaksi')
        .select('*, detail_transaksi(*, produk(nama))')
        .gte('created_at', '${tgl}T00:00:00')
        .lte('created_at', '${tgl}T23:59:59')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  static Future<Map<String, dynamic>> getRingkasanBulan(
      int bulan, int tahun) async {
    final res = await client.rpc('ringkasan_bulan',
        params: {'p_bulan': bulan, 'p_tahun': tahun});
    return Map<String, dynamic>.from(res ?? {});
  }

  // ───────────── PROFIL ─────────────
  static Future<Map<String, dynamic>?> getProfil() async {
    final uid = client.auth.currentUser?.id;
    if (uid == null) return null;
    final res =
        await client.from('profil').select().eq('id', uid).maybeSingle();
    return res;
  }

  static Future<void> updateProfil(Map<String, dynamic> data) async {
    final uid = client.auth.currentUser?.id;
    if (uid == null) return;
    await client.from('profil').upsert({'id': uid, ...data});
  }

    // ───────────── ABSENSI ─────────────
 static Future<void> absenMasuk() async {
  final user = client.auth.currentUser;
  if (user == null) return;

  final now = DateTime.now();
  final today = now.toIso8601String().split('T')[0];

  final jam =
      "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

  final profil = await client
      .from('profil')
      .select('nama')
      .eq('id', user.id)
      .maybeSingle();

  final nama = profil?['nama'] ?? user.email ?? 'User';

  final cek = await client
      .from('absensi')
      .select()
      .eq('user_id', user.id)
      .eq('tanggal', today);

  if (cek.isEmpty) {
    await client.from('absensi').insert({
      'user_id': user.id,
      'nama_user': nama,
      'tanggal': today,
      'jam_masuk': jam,
    });
  }
}

  static Future<List<Map<String, dynamic>>> getAbsensiHariIni() async {
    final today = DateTime.now().toIso8601String().split('T')[0];

    final res = await client
        .from('absensi')
        .select()
        .eq('tanggal', today)
        .order('jam_masuk');

    return List<Map<String, dynamic>>.from(res);
  }

  static Future<List<Map<String, dynamic>>> getAbsensiByTanggal(
      String tanggal) async {
    final res = await client
        .from('absensi')
        .select()
        .eq('tanggal', tanggal)
        .order('jam_masuk');

    return List<Map<String, dynamic>>.from(res);
  }
  
}

