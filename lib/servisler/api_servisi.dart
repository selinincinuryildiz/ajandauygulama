import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; 
import '../modeller/ajanda_modelleri.dart';

class ApiService {
  // ADB Reverse kullanıyorsan 127.0.0.1 kalabilir.
  // Eğer Hotspot (Wi-Fi) ile bağlanıyorsan buraya bilgisayarın IP'sini yazmalısın (örn: 192.168.1.35)
  static const String bilgisayarIpAdresi = '127.0.0.1';

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    } else {
      return 'http://$bilgisayarIpAdresi:3000/api';
    }
  }

  // --- AUTH (KİMLİK DOĞRULAMA) ---
  
  Future<bool> register(String adSoyad, String email, String password, String unvan) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ad_soyad': adSoyad,
          'eposta': email,
          'sifre': password,
          'unvan': unvan,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print("Register Hatası: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'eposta': email,
          'sifre': password,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body); 
      }
      return null;
    } catch (e) {
      print("Login Hatası: $e");
      return null;
    }
  }

  // --- KATEGORİLER (YENİ EKLENDİ) ---

  // Kategorileri Getir
  Future<List<Kategori>> getCategories(int userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/categories/$userId'));
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((dynamic item) => Kategori.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print("Get Categories Hatası: $e");
      return [];
    }
  }

  // Kategori Ekle
  Future<bool> addCategory(int userId, String baslik, int? ustKategoriId, String renkKodu) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/categories'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'kullanici_id': userId,
          'baslik': baslik,
          'ust_kategori_id': ustKategoriId,
          'renk_kodu': renkKodu
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print("Add Category Hatası: $e");
      return false;
    }
  }

  // --- ETKİNLİKLER (GÜNCELLENDİ) ---

  // Listele
  Future<List<Etkinlik>> getEvents(int userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/events/$userId'));
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((dynamic item) => Etkinlik.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print("Get Events Hatası: $e");
      return [];
    }
  }

  // Ekle (kategoriId parametresi eklendi)
  Future<bool> addEvent(int userId, String baslik, String aciklama, DateTime tarih, String oncelik, {int? kategoriId}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/events'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'kullanici_id': userId,
          'baslik': baslik,
          'aciklama': aciklama,
          'baslangic_tarihi': tarih.toIso8601String(),
          'oncelik_duzeyi': oncelik,
          'kategori_id': kategoriId // YENİ
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print("Add Event Hatası: $e");
      return false;
    }
  }
  
  // Güncelle (kategoriId parametresi eklendi)
  Future<bool> updateEvent(int eventId, String baslik, String aciklama, DateTime tarih, String oncelik, {int? kategoriId}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/events/$eventId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'baslik': baslik,
          'aciklama': aciklama,
          'baslangic_tarihi': tarih.toIso8601String(),
          'oncelik_duzeyi': oncelik,
          'kategori_id': kategoriId // YENİ
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Update Event Hatası: $e");
      return false;
    }
  }

  // Durum Güncelle
  Future<bool> toggleEventStatus(int eventId, bool status) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/events/$eventId/toggle'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'tamamlandi_mi': status}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Sil
  Future<bool> deleteEvent(int eventId) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/events/$eventId'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}