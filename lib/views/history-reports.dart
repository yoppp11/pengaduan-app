import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pengaduan/widgets/status-chip.dart';
import 'package:timeago/timeago.dart' as timeago;

class ReportHistoryPage extends StatefulWidget {
  const ReportHistoryPage({super.key});

  @override
  State<ReportHistoryPage> createState() => _ReportHistoryPageState();
}

class _ReportHistoryPageState extends State<ReportHistoryPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _reports = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUserReports();
  }

  Future<void> _fetchUserReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        setState(() {
          _errorMessage = 'Anda belum login. Silakan login terlebih dahulu.';
          _isLoading = false;
        });
        return;
      }

      final String userId = currentUser.uid;
      final QuerySnapshot reportSnapshot = await _firestore
          .collection('reports')
          .where('userId', isEqualTo: userId)
          .get();

      final List<Map<String, dynamic>> reports = [];
      for (var doc in reportSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        final reportDate = (data['reportDate'] as Timestamp).toDate();
        final incidentDate = (data['incidentDate'] as Timestamp).toDate();

        reports.add({
          'id': doc.id,
          'title': data['title'],
          'description': data['description'],
          'location': data['location'],
          'incidentDate': incidentDate,
          'reportDate': reportDate,
          'status': data['status'],
          'contactPreference': data['contactPreference'],
        });
      }

      setState(() {
        _reports = reports;
        reports.sort((a, b) => (b['reportDate'] as DateTime)
            .compareTo(a['reportDate'] as DateTime));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi keslahan: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Riwayat Pengaduan',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFFE91E63),
        actions: [
          IconButton(
            onPressed: _fetchUserReports,
            icon: Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchUserReports,
                        child: Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : _reports.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Belum ada pengaduan yang Anda laporkan',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: Icon(Icons.add_circle_outline),
                            label: Text('Buat Pengaduan Baru'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple[800],
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).pushNamed('/create-report');
                            },
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchUserReports,
                      child: ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _reports.length,
                        itemBuilder: (context, index) {
                          final report = _reports[index];
                          final DateFormat dateFormat =
                              DateFormat('dd MMM yyyy');

                          return Card(
                            margin: EdgeInsets.only(bottom: 16),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).pushNamed(
                                  '/report-detail',
                                  arguments: report['id'],
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            report['title'],
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        buildStatusChip(report['status']),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      report['description'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 16),
                                    Divider(height: 1),
                                    SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              size: 14,
                                              color: Colors.grey[600],
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Kejadian: ${dateFormat.format(report['incidentDate'])}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          'Dilaporkan ${timeago.format(report['reportDate'], locale: 'id')}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed('/report');
        },
        backgroundColor: const Color(0xFFE91E63),
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
        tooltip: 'Buat Pengaduan Baru',
      ),
    );
  }
}
