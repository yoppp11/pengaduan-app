import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pengaduan/views/admin-list-chat.dart';
import 'package:pengaduan/views/admin-list-report.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String adminUid =
      'Qv99NkMCMwb0NbOHlYZJt4e2sN32';

  Future<void> _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_auth.currentUser?.uid != adminUid) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Dashboard Admin',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFFE91E63),
        ),
        body: const Center(
          child: Text(
            'Anda tidak memiliki akses ke halaman ini.',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2, 
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Dashboard Admin',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFFE91E63),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _logout, 
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.chat), text: 'Daftar Chat'),
              Tab(icon: Icon(Icons.assignment), text: 'Daftar Laporan'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AdminChatListScreen(),
            AdminReportsListScreen(), 
          ],
        ),
      ),
    );
  }
}
