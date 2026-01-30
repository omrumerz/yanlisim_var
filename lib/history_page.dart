import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'database_helper.dart';
import 'dart:math';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  Color _getHeatmapColor(int count, int maxCount) {
    if (count == 0) return Colors.green[100]!;
    double ratio = count / maxCount;
    if (ratio > 0.7) return Colors.red[400]!;
    if (ratio > 0.3) return Colors.orange[400]!;
    return Colors.green[400]!;
  }

  // --- YENİ: ÇİZGİ GRAFİĞİ İÇİN VERİ HAZIRLAMA ---
  List<FlSpot> _getLineChartSpots(List<Map<String, dynamic>> errors) {
    if (errors.isEmpty) return [];
    
    // Tarihlere göre hata sayılarını grupla (Son 7 kayıt günü)
    Map<String, int> dailyCounts = {};
    for (var e in errors.reversed) { // Eskiden yeniye
      String date = e['date'].toString().substring(0, 10);
      dailyCounts[date] = (dailyCounts[date] ?? 0) + 1;
    }

    List<FlSpot> spots = [];
    var entries = dailyCounts.entries.toList();
    for (int i = 0; i < entries.length; i++) {
      spots.add(FlSpot(i.toDouble(), entries[i].value.toDouble()));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text("Hata Haritası & Gelişim"), centerTitle: true),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseHelper.instance.fetchErrors(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Henüz analiz edilecek veri yok. ✨"));
          }

          final errors = snapshot.data!;
          Map<String, int> counts = {};
          for (var e in errors) {
            List<String> cats = (e['categories'] as String).split(',');
            for (var c in cats) {
              counts[c] = (counts[c] ?? 0) + 1;
            }
          }

          int maxCount = counts.values.isNotEmpty ? counts.values.reduce(max) : 1;
          List<FlSpot> lineSpots = _getLineChartSpots(errors);

          return SingleChildScrollView(
            child: Column(
              children: [
                // 1. HATA DAĞILIM (PASTA)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Text("Hata Kategorileri Oranı", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                SizedBox(
                  height: 180,
                  child: PieChart(PieChartData(
                    sections: counts.entries.map((entry) {
                      return PieChartSectionData(
                        color: _getHeatmapColor(entry.value, maxCount),
                        value: entry.value.toDouble(),
                        title: entry.key.length > 3 ? entry.key.substring(0, 3) : entry.key,
                        radius: 50,
                        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      );
                    }).toList(),
                  )),
                ),

                const Divider(height: 40),

                // 2. YENİ: HATA GELİŞİM GRAFİĞİ (ÇİZGİ)
                const Text("Hata Giriş Trendi (Gelişim)", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Container(
                  height: 200,
                  padding: const EdgeInsets.only(right: 25, left: 10),
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false), // Sade görünüm için kapalı
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: lineSpots,
                          isCurved: true,
                          color: Colors.deepPurple,
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true, 
                            color: Colors.deepPurple.withOpacity(0.1)
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text("Hata analiz etme sıklığını takip et.", style: TextStyle(fontSize: 11, color: Colors.grey)),
                ),

                const Divider(height: 30),

                // 3. KONU YOĞUNLUK HARİTASI
                const Text("Hata Yoğunluğu", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8, runSpacing: 8,
                    children: counts.entries.map((entry) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _getHeatmapColor(entry.value, maxCount),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text("${entry.key}: ${entry.value}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 30),

                // 4. KRONOLOJİK ARŞİV
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 16, bottom: 10),
                    child: Text("Hata Kayıtları", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: errors.length,
                  itemBuilder: (context, index) {
                    final entry = errors[index];
                    final imagePath = entry['imagePath'];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          if (imagePath != null)
                            Image.network(
                              "https://via.placeholder.com/400x150?text=Soru+Fotografi+📸",
                              height: 150, width: double.infinity, fit: BoxFit.cover,
                            ),
                          ListTile(
                            title: Text(entry['categories'].toString().replaceAll(',', ', ')),
                            subtitle: Text("Tarih: ${entry['date'].toString().substring(0, 10)}"),
                            trailing: const Icon(Icons.chevron_right, size: 18),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}