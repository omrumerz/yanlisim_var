import 'package:flutter/material.dart';
import 'database_helper.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});
  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  // Seçilen ödeme yöntemini takip etmek için
  String _selectedMethod = ""; 

  // --- 1. NET ARTIŞ PROJEKSİYONU KUTUSU ---
  Widget _buildNetIncreaseCard(int errorCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        children: [
          const Text(
            "NET ARTIŞ TAHMİNİ", 
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)
          ),
          const SizedBox(height: 10),
          Text(
            "+${(errorCount * 1.25).toStringAsFixed(1)} Net Artış",
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const Text(
            "Analiz ettiğin hataların sınavdaki karşılığıdır.", 
            style: TextStyle(fontSize: 11, color: Colors.black54)
          ),
        ],
      ),
    );
  }

  // --- 2. PDF ÖNİZLEME PENCERESİ ---
  void _showPdfPreview() {
    showDialog(
      context: context, 
      builder: (c) => AlertDialog(
        title: const Text("Hata Karneniz Hazır"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 50),
            const SizedBox(height: 15),
            const Text("• En çok: İşlem Hatası\n• Gelişim: +1.5 Net", style: TextStyle(fontSize: 14)),
            const Divider(),
            const Text("Karne başarıyla oluşturuldu.", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("Kapat")),
          ElevatedButton(onPressed: () => Navigator.pop(c), child: const Text("İNDİR")),
        ],
      )
    );
  }

  // --- 3. DİNAMİK ÖDEME YÖNTEMLERİ VE BİLGİ GİRİŞ PANELİ ---
  void _showPaymentMethods(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Klavye açıldığında ekranın kayması için
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder( // BottomSheet içinde anlık seçim değişimi için
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom, // Klavye yüksekliği kadar boşluk
            left: 20, right: 20, top: 20
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Ödeme Detayları", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              // Yöntem Seçim İkonları
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _methodButton(Icons.credit_card, "Kart", setModalState),
                  _methodButton(Icons.account_balance_wallet, "Cüzdan", setModalState),
                  _methodButton(Icons.phone_android, "Mobil", setModalState),
                ],
              ),
              const Divider(height: 30),

              // OTOMATİK GELEN BİLGİ GİRİŞ ALANLARI
              if (_selectedMethod == "Kart") ...[
                const TextField(decoration: InputDecoration(labelText: "Kart Sahibi", border: OutlineInputBorder())),
                const SizedBox(height: 10),
                const TextField(decoration: InputDecoration(labelText: "Kart Numarası", border: OutlineInputBorder(), prefixIcon: Icon(Icons.credit_card))),
              ] else if (_selectedMethod == "Cüzdan") ...[
                const TextField(decoration: InputDecoration(labelText: "Cüzdan No / Tel", border: OutlineInputBorder(), prefixIcon: Icon(Icons.wallet))),
              ] else if (_selectedMethod == "Mobil") ...[
                const TextField(decoration: InputDecoration(labelText: "Telefon Numarası", border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone))),
              ] else 
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text("Lütfen yukarıdan bir ödeme yöntemi seçin", style: TextStyle(color: Colors.grey)),
                ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _selectedMethod == "" ? null : () {
                  Navigator.pop(context);
                  _simulatePayment(); // Ödemeyi tamamla
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: const Text("GÜVENLİ ÖDEME YAP"),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Yöntem Seçme İkonu İçin Yardımcı Widget
  Widget _methodButton(IconData icon, String label, StateSetter setModalState) {
    bool isSelected = _selectedMethod == label;
    return GestureDetector(
      onTap: () => setModalState(() => _selectedMethod = label),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: isSelected ? Colors.deepPurple : Colors.grey[200],
            child: Icon(icon, color: isSelected ? Colors.white : Colors.grey),
          ),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  // --- 4. ÖDEME SİMÜLASYONU ---
  void _simulatePayment() async {
    await DatabaseHelper.instance.setPremium(true);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Premium Aktif! ✨ Tüm sınırlar kaldırıldı."), backgroundColor: Colors.green)
    );
  }

  // --- 5. PDF SECTİON WİDGET ---
  Widget _buildPdfSection(bool isP, int count) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isP ? Colors.blue[50] : Colors.grey[100], 
        borderRadius: BorderRadius.circular(15), 
        border: Border.all(color: isP ? Colors.blue : Colors.grey)
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.picture_as_pdf, color: isP ? Colors.blue : Colors.grey), 
              const SizedBox(width: 10), 
              const Text("Haftalık Hata Karnesi", style: TextStyle(fontWeight: FontWeight.bold))
            ]
          ),
          const SizedBox(height: 10),
          Text(
            isP ? "$count hata analiz edilerek raporunuz hazırlandı." : "Hata karnenizi PDF olarak indirmek için Premium'a geçin.",
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isP ? () => _showPdfPreview() : null, 
              style: ElevatedButton.styleFrom(
                backgroundColor: isP ? Colors.blue : Colors.grey,
                foregroundColor: Colors.white,
              ),
              child: const Text("KARNEYİ İNDİR"),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Premium Avantajları"), centerTitle: true),
      body: FutureBuilder<bool>(
        future: DatabaseHelper.instance.isPremium(),
        builder: (context, pSnap) {
          bool isP = pSnap.data ?? false;
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: DatabaseHelper.instance.fetchErrors(),
            builder: (context, eSnap) {
              int count = eSnap.data?.length ?? 0;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildNetIncreaseCard(count),
                    _buildPremiumHeader(isP),
                    _buildPdfSection(isP, count),
                    const SizedBox(height: 30),
                    _benefitItem(Icons.check_circle, "Günde 2 hata sınırını kaldırın."),
                    _benefitItem(Icons.check_circle, "Detaylı konu yoğunluk haritasına erişin."),
                    _benefitItem(Icons.check_circle, "Haftalık PDF karnesi oluşturun."),
                    const SizedBox(height: 30),
                    if (!isP)
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () => _showPaymentMethods(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple, 
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: const Text("HEMEN ABONE OL - ₺199", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      )
                    else
                      const Center(
                        child: Text(
                          "Tebrikler! Premium avantajlarından yararlanıyorsunuz.",
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPremiumHeader(bool isP) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isP ? [Colors.amber, Colors.orange] : [Colors.grey, Colors.blueGrey]
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        children: [
          Icon(isP ? Icons.workspace_premium : Icons.lock, color: Colors.white, size: 50),
          const SizedBox(height: 10),
          Text(
            isP ? "SÜPER GÜÇLER AKTİF" : "SINIRSIZ ANALİZ", 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)
          ),
        ],
      ),
    );
  }

  Widget _benefitItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 20),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}