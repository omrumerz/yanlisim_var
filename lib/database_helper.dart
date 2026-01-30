import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore için gerekli
import 'package:firebase_auth/firebase_auth.dart';    // Kullanıcı ID'si için gerekli

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  DatabaseHelper._init();
  final String _key = 'user_errors_web';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// insertError: Hatayı yerel hafızaya kaydeder ve Firestore puanını 1 artırır.
  Future<void> insertError(List<String> categories, String? imagePath) async {
    // 1. YEREL KAYIT (SharedPreferences)
    final prefs = await SharedPreferences.getInstance();
    List<String> currentData = prefs.getStringList(_key) ?? [];
    
    Map<String, dynamic> newEntry = {
      'categories': categories.join(','),
      'date': DateTime.now().toIso8601String(),
      'imagePath': imagePath, 
    };
    
    currentData.add(jsonEncode(newEntry));
    await prefs.setStringList(_key, currentData);

    // 2. BULUT PUAN GÜNCELLEME (Firestore)
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Hata kaydedildiğinde kullanıcının Firestore dokümanındaki totalErrors puanını 1 artırır.
        await _firestore.collection('users').doc(user.uid).update({
          'totalErrors': FieldValue.increment(1),
        });
      }
    } catch (e) {
      print("Firestore puan artırma hatası: $e");
      // Not: Kullanıcı internetsizse yerel kayıt devam eder, puan sonra güncellenebilir.
    }
  }

  /// fetchErrors: Kaydedilen tüm hataları döndürür.
  Future<List<Map<String, dynamic>>> fetchErrors() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> currentData = prefs.getStringList(_key) ?? [];
    
    return currentData
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList()
        .reversed
        .toList();
  }

  // --- PREMIUM DURUM YÖNETİMİ ---

  Future<void> setPremium(bool status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium', status);
  }

  Future<bool> isPremium() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_premium') ?? false;
  }
}