import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

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

  static Future<Map<String, dynamic>> getRingkasanBulan(int bulan, int tahun) async {
    final res = await client.rpc('ringkasan_bulan',
        params: {'p_bulan': bulan, 'p_tahun': tahun});
    return Map<String, dynamic>.from(res ?? {});
  }

  // ───────────── AKUN / PROFIL ─────────────
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

  static Future<void> signIn(String email, String password) async {
    await client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static User? get currentUser => client.auth.currentUser;
}
