// home_screen.dart
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:http/http.dart' as http;
import 'package:pengaduan/models/gemini-response.dart';
import 'package:pengaduan/models/news-api.dart';
import 'package:pengaduan/widgets/action-button.dart';
import 'package:pengaduan/widgets/info-card.dart';
import 'package:pengaduan/widgets/news-item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<NewsArticle> articles = [];
  List<EducationData> dataGemini = [];

  String _userName = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getUserInfo();
    getNews();
    promtGemini();
  }

  Future<List<NewsArticle>> getNews({int limit = 8}) async {
    final String apiKey = dotenv.env['KEY_NEWS'] ?? '';
    const String baseUrl = 'https://newsapi.org/v2';
    final response = await http.get(
      Uri.parse(
          '$baseUrl/everything?q=kekerasan+seksual&language=id&sortBy=publishedAt&pageSize=$limit&apiKey=$apiKey'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      setState(() {
        for (var item in data['articles']) {
          articles.add(NewsArticle.fromJson(item));
        }
      });

      return data;
    } else {
      throw Exception('Failed to load news');
    }
  }

  Future<List<EducationData>> promtGemini() async {
    final response = await Gemini.instance.prompt(parts: [
      Part.text(
          'berikan saya sebuah informasi edukatif tentang kekerasan seksual guna mengisi data card saya, berikan dalam format json seperti berikut: { "title": "Judul" "description": "Deskripsi","image": "URL Gambar"}, jangan berikan data lain selain data json tersebut, saya hanya perlu data json tersebut. berikan 4 data saja')
    ]);

    final cleaned =
        response?.output?.replaceAll("```json", "").replaceAll("```", "");
    final jsonData = json.decode(cleaned!);

    setState(() {
      for (var item in jsonData) {
        dataGemini.add(EducationData.fromJson(item));
      }
    });

    return jsonData;
  }

  Future<void> _getUserInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null && !user.isAnonymous) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            _userName = doc.data()?['displayName'] ?? 'Pengguna';
          });
        }
      } else {
        setState(() {
          _userName = 'Pengguna Anonim';
        });
      }
    } catch (e) {
      print('Error getting user info: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'LAPOR SIGAP',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFE91E63),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              // Navigate to notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFFE91E63),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Color(0xFFE91E63),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isLoading ? 'Memuat...' : _userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _auth.currentUser?.isAnonymous ?? true
                        ? 'Mode Anonim'
                        : _auth.currentUser?.email ?? '',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Beranda'),
              selected: true,
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profil Pengguna'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Riwayat Laporan'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/history');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Tentang Aplikasi'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/about');
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Keluar'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _getUserInfo,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tagline dan Sambutan
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hai, $_userName',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Anda tidak sendirian. Laporkan kekerasan seksual dan dapatkan bantuan segera.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Quick Action Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Aksi Cepat',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: actionButton(
                                  context,
                                  'Laporkan Sekarang',
                                  Icons.report_problem,
                                  Colors.red.shade700,
                                  () {
                                    Navigator.pushNamed(context, '/report');
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: actionButton(
                                  context,
                                  'Butuh Bantuan',
                                  Icons.help,
                                  Colors.blue.shade700,
                                  () {
                                    Navigator.pushNamed(context, '/guide');
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: actionButton(
                                  context,
                                  'Customer Service',
                                  Icons.chat,
                                  Colors.green.shade700,
                                  () {
                                    Navigator.pushNamed(context, '/cs_chat');
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Info Edukatif
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Info Edukatif',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 85,
                            child: dataGemini.isEmpty
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    scrollDirection: Axis.horizontal,
                                    itemCount: dataGemini.length,
                                    itemBuilder: (context, index) => infoCard(
                                        context,
                                        dataGemini[index].title,
                                        dataGemini[index].description,
                                        dataGemini[index].image,
                                        'route'),
                                  ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Berita & Update Terkini
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Berita & Update Terkini',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/news');
                                },
                                child: const Text('Lihat Semua'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          articles.isEmpty
                              ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: articles.length,
                                  itemBuilder: (context, index) => newsItem(
                                    context,
                                    articles[index].title,
                                    articles[index].urlToImage,
                                    articles[index].description,
                                    articles[index].publishedAt,
                                    articles[index].url,
                                  ),
                                ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        selectedItemColor: const Color(0xFFE91E63),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Laporan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Konseling',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              // Sudah di beranda
              break;
            case 1:
              Navigator.pushNamed(context, '/history');
              break;
            case 2:
              Navigator.pushNamed(context, '/counseling');
              break;
            case 3:
              Navigator.pushNamed(context, '/profile');
              break;
          }
        },
      ),
    );
  }
}
