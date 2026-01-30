import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SocialPage extends StatefulWidget {
  const SocialPage({super.key});

  @override
  State<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage> {
  final TextEditingController _searchController = TextEditingController();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // --- 1. ARKADAŞLIK İSTEĞİNİ KABUL ETME (EKSİKTİ, EKLENDİ) ---
  Future<void> _acceptRequest(String fromId, String fromEmail) async {
    final batch = FirebaseFirestore.instance.batch();

    // Kendi 'friends' listene karşı tarafı ekle
    batch.update(FirebaseFirestore.instance.collection('users').doc(_currentUserId), {
      'friends': FieldValue.arrayUnion([fromId])
    });

    // Karşı tarafın 'friends' listesine seni ekle
    batch.update(FirebaseFirestore.instance.collection('users').doc(fromId), {
      'friends': FieldValue.arrayUnion([_currentUserId])
    });

    // Onaylanan isteği 'requests' klasöründen sil
    batch.delete(FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .collection('requests')
        .doc(fromId));

    await batch.commit();
    _showSnackBar("$fromEmail ile artık arkadaşsınız! 🤝");
  }

  // --- 2. GELEN İSTEKLERİ DİNLEME (EKSİKTİ, EKLENDİ) ---
  Stream<QuerySnapshot> _getIncomingRequests() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .collection('requests')
        .snapshots();
  }

  // --- 3. LİDERLİK TABLOSU ---
  Stream<List<Map<String, dynamic>>> _getFriendsLeaderboard() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .snapshots()
        .asyncMap((userDoc) async {
      
      List<dynamic> friendIds = userDoc.data()?['friends'] ?? [];
      List<String> idsToFetch = List<String>.from(friendIds)..add(_currentUserId);

      final friendsQuery = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: idsToFetch)
          .get();

      return friendsQuery.docs.map((doc) {
        final data = doc.data();
        return {
          "name": (data['email'] as String).split('@')[0],
          "score": data['totalErrors'] ?? 0,
          "isMe": doc.id == _currentUserId,
          "avatar": doc.id == _currentUserId ? "👤" : "👫",
        };
      }).toList()
        ..sort((a, b) => b['score'].compareTo(a['score']));
    });
  }

  Future<void> _sendRequest(String email) async {
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email;
    if (currentUserEmail == email) {
      _showSnackBar("Kendine istek gönderemezsin! 😊");
      return;
    }

    try {
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userQuery.docs.isEmpty) {
        _showSnackBar("Kullanıcı bulunamadı.");
        return;
      }

      final targetUserId = userQuery.docs.first.id;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .collection('requests')
          .doc(_currentUserId)
          .set({
        'from': currentUserEmail,
        'fromId': _currentUserId,
        'status': 'pending',
        'time': FieldValue.serverTimestamp(),
      });

      _showSnackBar("İstek başarıyla gönderildi! 🚀");
      _searchController.clear();
    } catch (e) {
      _showSnackBar("Bir hata oluştu.");
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sosyal Alan"), centerTitle: true),
      body: Column(
        children: [
          // ARAMA ÇUBUĞU
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "E-posta ile arkadaş bul...",
                filled: true,
                fillColor: Colors.grey[100],
                suffixIcon: IconButton(
                  icon: const Icon(Icons.person_add, color: Colors.deepPurple),
                  onPressed: () => _sendRequest(_searchController.text.trim()),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // --- GELEN İSTEKLER PANELİ (YENİ EKLENDİ) ---
          StreamBuilder<QuerySnapshot>(
            stream: _getIncomingRequests(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox();
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.mail_outline, color: Colors.orange),
                      title: Text("${data['from']} isteği gönderdi.", style: const TextStyle(fontSize: 13)),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                        onPressed: () => _acceptRequest(data['fromId'], data['from']),
                        child: const Text("Onayla"),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                SizedBox(width: 8),
                Text("Liderlik Tablosu", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(),

          // LİDERLİK TABLOSU
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _getFriendsLeaderboard(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text("Henüz arkadaşın yok. Hemen birilerini davet et!"),
                  );
                }

                final friends = snapshot.data!;
                return ListView.builder(
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    final f = friends[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: f['isMe'] ? Colors.deepPurple : Colors.grey[200],
                        child: Text(f['avatar']),
                      ),
                      title: Text(f['name'], style: TextStyle(fontWeight: f['isMe'] ? FontWeight.bold : FontWeight.normal)),
                      subtitle: Text("${f['score']} Hata Analizi"),
                      trailing: Text("#${index + 1}"),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}