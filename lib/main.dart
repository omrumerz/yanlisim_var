import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'error_categories.dart';
import 'database_helper.dart';
import 'history_page.dart';
import 'premium_page.dart';
import 'social_page.dart';
import 'login_page.dart';
import 'dart:html' as html;

// --- UYGULAMA BAŞLANGICI ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // MANUEL FIREBASE YAPILANDIRMASI
  // Bu bilgiler Firebase Console -> Proje Ayarları -> Uygulamalarım (Web) kısmından alınır.
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBQN0w9dJw_JhPdu3TGUZrfb1Y8rKfyg1s",
      authDomain: "yanlisim-var.firebaseapp.com",
      projectId: "yanlisim-var",
      storageBucket: "yanlisim-var.firebasestorage.app",
      messagingSenderId: "1090567723663",
      appId: "1:1090567723663:web:1d38fa34d316960073aefa",
      measurementId: "G-JV9ZJ39M72"
    ),
  );

  runApp(const YanlisimVar());
}

class YanlisimVar extends StatelessWidget {
  const YanlisimVar({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true, 
        colorSchemeSeed: Colors.deepPurple, 
        brightness: Brightness.light
      ),
      darkTheme: ThemeData(
        useMaterial3: true, 
        colorSchemeSeed: Colors.deepPurple, 
        brightness: Brightness.dark
      ),
      themeMode: ThemeMode.system,
      
      // OTOMATİK OTURUM KONTROLÜ
      home: FirebaseAuth.instance.currentUser == null 
          ? const LoginPage() 
          : const ErrorEntryPage(),
    );
  }
}

class ErrorEntryPage extends StatefulWidget {
  const ErrorEntryPage({super.key});
  @override
  State<ErrorEntryPage> createState() => _ErrorEntryPageState();
}

class _ErrorEntryPageState extends State<ErrorEntryPage> {
  final Set<String> _selectedErrors = {};
  Key _analizKey = UniqueKey();
  int _pomodoroSeconds = 25 * 60;
  Timer? _timer;
  bool _isTimerRunning = false;
  int _reviewCount = 0;
  int _totalErrorCount = 0;

  String? _selectedImagePath; 

  @override
  void initState() {
    super.initState();
    NotificationService.requestPermission(); 
    _checkSmartReview(); 
    _loadStats();
  }

  void _goToPremium() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (c) => const PremiumPage()),
    );
    _loadStats(); 
    _checkSmartReview();
    setState(() {}); 
  }

  void _pickImage() {
    setState(() {
      _selectedImagePath = "soru_yuklendi"; 
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Soru fotoğrafı başarıyla eklendi! 📸"))
    );
  }

  void _removeImage() {
    setState(() {
      _selectedImagePath = null;
    });
  }

  Future<void> _loadStats() async {
    final all = await DatabaseHelper.instance.fetchErrors();
    setState(() => _totalErrorCount = all.length);
  }

  Future<void> _checkSmartReview() async {
    final all = await DatabaseHelper.instance.fetchErrors();
    final now = DateTime.now();
    int count = 0;
    for (var error in all) {
      final date = DateTime.parse(error['date']);
      final diff = now.difference(date).inDays;
      if (diff == 1 || diff == 3 || diff == 7) {
        count++;
      }
    }
    if (count > 0) {
      NotificationService.showNotification(
        "Zamanı Geldi! 🧠", 
        "Bugün tekrar etmen gereken $count hata var. Hadi netlerini artıralım!"
      );
    }
    setState(() => _reviewCount = count);
  }

  Future<Map<String, String>> _getSmartAssistantData() async {
    final isPremium = await DatabaseHelper.instance.isPremium();
    final allErrors = await DatabaseHelper.instance.fetchErrors();
    
    if (allErrors.isEmpty) {
      return {
        "label": "Analiz Bekleniyor...",
        "advice": "Hatalarını girdikçe sana özel taktikler hazırlayacağım! ✨"
      };
    }

    Map<String, int> counts = {};
    for (var error in allErrors) {
      for (var cat in (error['categories'] as String).split(',')) {
        counts[cat] = (counts[cat] ?? 0) + 1;
      }
    }

    var sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    String top = sorted.first.key;
    String pTag = isPremium ? " (Premium 🌟)" : "";

    if (top == "İşlem Hatası") {
      return {"label": "Hızlı ama Dikkatsiz$pTag ⚡", "advice": "Beyin hızın kaleminden fazla! Sonucu yazmadan önce 2 saniye derin nefes al."};
    } else if (top == "Zaman Yönetimi") {
      return {"label": "Yavaş ama Garantici$pTag 🐢", "advice": "Mükemmeliyetçilik bazen engeldir. Zor sorularla inatlaşma, turlama tekniğini kullan!"};
    } else if (top == "Konu Eksikliği") {
      return {"label": "Temeli Eksik Gezgin$pTag 📚", "advice": "Bugün bu konunun özetine 15 dakika bakarsan, yarınki sınavda kendine teşekkür edeceksin!"};
    } else if (top == "Dikkat Dağınıklığı") {
      return {"label": "Zihni Dağınık Deha$pTag 🎈", "advice": "Odaklanmak bir kas gibidir. Pomodoro ile bu kası her gün güçlendiriyoruz!"};
    } else if (top == "Soru Kökünü Yanlış Anlama") {
      return {"label": "Heyecanlı Detaycı$pTag 🔍", "advice": "Soru kökündeki 'değildir' kelimesinin altını çizmeyi unutma!"};
    }
    
    return {"label": "Çok Yönlü Analist$pTag 📊", "advice": "$_totalErrorCount hata ile harika bir gelişim gösteriyorsun!"};
  }

  Future<void> _saveAnalysis() async {
    final isPremium = await DatabaseHelper.instance.isPremium();
    final all = await DatabaseHelper.instance.fetchErrors(); 
    final todayCount = all.where((e) => DateTime.parse(e['date']).day == DateTime.now().day).length;

    if (!isPremium && todayCount >= 2) {
      _showPremiumUpgradeDialog();
      return;
    }

    await DatabaseHelper.instance.insertError(_selectedErrors.toList(), _selectedImagePath); 
    
    setState(() {
      _selectedErrors.clear();
      _selectedImagePath = null; 
      _analizKey = UniqueKey();
    });
    _checkSmartReview();
    _loadStats();
  }

  void _showPremiumUpgradeDialog() {
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text("Günlük Limit Doldu!"),
      content: const Text("Ücretsiz planda günde 2 hata girebilirsin. Sınırları tamamen kaldırmak ister misin?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text("Kapat")),
        ElevatedButton(onPressed: _goToPremium, child: const Text("Premium'u İncele")),
      ],
    ));
  }

  void _toggleTimer() {
    if (_isTimerRunning) { _timer?.cancel(); } 
    else {
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        setState(() { if (_pomodoroSeconds > 0) _pomodoroSeconds--; else { _timer?.cancel(); _isTimerRunning = false; } });
      });
    }
    setState(() => _isTimerRunning = !_isTimerRunning);
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    String min = (_pomodoroSeconds ~/ 60).toString().padLeft(2, '0');
    String sec = (_pomodoroSeconds % 60).toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Yanlışım Var"), 
        actions: [
          IconButton(
            icon: const Icon(Icons.group), 
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SocialPage()))
          ),
          IconButton(
            icon: const Icon(Icons.history), 
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const HistoryPage()))
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          FutureBuilder<bool>(
            future: DatabaseHelper.instance.isPremium(),
            builder: (c, s) => Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _badge(Icons.catching_pokemon, "Avcı", _totalErrorCount >= 5),
              _badge(Icons.workspace_premium, "Usta", _totalErrorCount >= 20),
              _badge(Icons.star, "Premium", s.data ?? false),
            ]),
          ),
          const Divider(),
          
          if (_reviewCount > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 15), 
              padding: const EdgeInsets.all(12), 
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.orange.withOpacity(0.2) : Colors.orange[100], 
                borderRadius: BorderRadius.circular(10), 
                border: Border.all(color: Colors.orange)
              ), 
              child: Row(children: [
                const Icon(Icons.psychology, color: Colors.orange), 
                const SizedBox(width: 10), 
                Expanded(child: Text("Bugün tekrar etmen gereken $_reviewCount hata var!", style: const TextStyle(fontWeight: FontWeight.bold)))
              ])
            ),

          FutureBuilder<Map<String, String>>(
            key: _analizKey,
            future: _getSmartAssistantData(),
            builder: (c, s) {
              final d = s.data ?? {"label": "...", "advice": "..."};
              return Container(
                width: double.infinity, 
                padding: const EdgeInsets.all(20), 
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDarkMode ? [Colors.deepPurple[700]!, Colors.black87] : [Colors.deepPurple[400]!, Colors.deepPurple[800]!]
                  ), 
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))],
                ), 
                child: Column(children: [
                  Text(d["label"]!, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)), 
                  const SizedBox(height: 10), 
                  Text(d["advice"]!, style: const TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic), textAlign: TextAlign.center)
                ])
              );
            },
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(10), 
            decoration: BoxDecoration(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey[200], borderRadius: BorderRadius.circular(15)), 
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              Text("$min:$sec", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.deepPurpleAccent : Colors.deepPurple)), 
              ElevatedButton.icon(onPressed: _toggleTimer, icon: Icon(_isTimerRunning ? Icons.pause : Icons.play_arrow), label: Text(_isTimerRunning ? "Durdur" : "Odaklan"))
            ])
          ),
          
          const SizedBox(height: 10),
          ...errorCategories.map((e) => CheckboxListTile(title: Text(e), value: _selectedErrors.contains(e), onChanged: (v) => setState(() => v! ? _selectedErrors.add(e) : _selectedErrors.remove(e)))),

          const SizedBox(height: 15),
          
          FutureBuilder<bool>(
            future: DatabaseHelper.instance.isPremium(),
            builder: (context, snapshot) {
              bool isPremium = snapshot.data ?? false;

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white10 : Colors.grey[100],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isPremium ? Colors.deepPurple.withOpacity(0.3) : Colors.grey,
                  ),
                ),
                child: Column(
                  children: [
                    if (!isPremium) ...[
                      const Icon(Icons.lock_outline, color: Colors.grey),
                      const SizedBox(height: 8),
                      const Text(
                        "Fotoğraf Ekleme sadece Premium üyeler içindir.",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      TextButton(
                        onPressed: _goToPremium, 
                        child: const Text("Premium'a Geç"),
                      ),
                    ] else if (_selectedImagePath == null) ...[
                      TextButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.add_a_photo, color: Colors.deepPurple),
                        label: const Text("Sorunun Fotoğrafını Ekle", style: TextStyle(color: Colors.deepPurple)),
                      ),
                    ] else ...[
                      Stack(
                        children: [
                          Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              image: const DecorationImage(
                                image: NetworkImage("https://via.placeholder.com/300x150?text=Soru+Fotografi+📸"),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 5, top: 5,
                            child: IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: _removeImage,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, 
            height: 55, 
            child: ElevatedButton(
              onPressed: _selectedErrors.isEmpty ? null : _saveAnalysis, 
              child: const Text("Analizi ve Tavsiyeyi Kaydet")
            )
          ),
        ]),
      ),
    );
  }

  Widget _badge(IconData i, String l, bool u) => Column(children: [Icon(i, color: u ? Colors.amber : Colors.grey[300], size: 30), Text(l, style: TextStyle(fontSize: 10, color: u ? null : Colors.grey))]);
}

class NotificationService {
  static void requestPermission() { html.Notification.requestPermission(); }
  static void showNotification(String title, String body) {
    if (html.Notification.permission == 'granted') { html.Notification(title, body: body); }
  }
}