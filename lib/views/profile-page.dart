import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pengaduan/widgets/info-item.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final User? currentUser = _auth.currentUser;
      
      if (currentUser == null) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Anda belum login. Silakan login terlebih dahulu.';
            _isLoading = false;
          });
        }
        return;
      }

      final String userId = currentUser.uid;
      
      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Profil pengguna tidak ditemukan.';
            _isLoading = false;
          });
        }
        return;
      }

      final data = userDoc.data() as Map<String, dynamic>;
      
      if (mounted) {
        setState(() {
          _userData = {
            'displayName': data['displayName'] ?? 'Nama tidak tersedia',
            'phoneNumber': data['phoneNumber'] ?? 'Nomor telepon tidak tersedia',
            'email': data['email'] ?? 'Email tidak tersedia',
            'photoUrl': data['photoUrl'] ?? '',
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya', style: TextStyle(color: Colors.white),),
        backgroundColor: Color(0xFFE91E63),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white,),
            onPressed: () {
              Navigator.of(context).pushNamed('/edit-profile').then((_) {
                _loadUserData();
              });
            },
            tooltip: 'Edit Profil',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white,),
            onPressed: _loadUserData,
            tooltip: 'Segarkan Data',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red[700]),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadUserData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE91E63),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            margin: const EdgeInsets.only(top: 16, bottom: 24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFE91E63).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: _userData!['photoUrl']?.isNotEmpty == true
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: _userData!['photoUrl']!,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.grey,
                      ),
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.grey,
                  ),
          ),

          Text(
            _userData!['displayName'] ?? 'Nama tidak tersedia',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildInfoItem(
                    icon: Icons.email_outlined,
                    title: 'Email',
                    value: _userData!['email'] ?? 'Email tidak tersedia',
                  ),
                  const Divider(),
                  buildInfoItem(
                    icon: Icons.phone_outlined,
                    title: 'Nomor Telepon',
                    value: _userData!['phoneNumber'] ?? 'Nomor telepon tidak tersedia',
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          OutlinedButton.icon(
            onPressed: () {
              _showLogoutConfirmation(context);
            },
            icon: const Icon(Icons.logout),
            label: const Text('Keluar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Color(0xFFE91E63),
              side: BorderSide(color: Color(0xFFE91E63)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  

  Future<void> _showLogoutConfirmation(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Keluar'),
          content: const SingleChildScrollView(
            child: Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFFE91E63),
              ),
              child: const Text('Keluar'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _auth.signOut();
                if (mounted) {
                  // Kembali ke halaman login
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}