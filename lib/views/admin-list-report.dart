import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pengaduan/models/report.dart';
import 'package:pengaduan/views/admin-detail-report.dart';

class AdminReportsListScreen extends StatefulWidget {
  const AdminReportsListScreen({Key? key}) : super(key: key);

  @override
  State<AdminReportsListScreen> createState() => _AdminReportsListScreenState();
}

class _AdminReportsListScreenState extends State<AdminReportsListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('reports').orderBy('reportDate', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Belum ada laporan masuk.'));
          }

          final reports = snapshot.data!.docs
              .map((doc) => Report.fromFirestore(doc))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 3,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16.0),
                  title: Text(
                    report.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: ${report.status.toUpperCase()}'),
                      Text('Tanggal Lapor: ${DateFormat('dd MMM yyyy, HH:mm').format(report.reportDate.toDate())}'),
                      Text('Deskripsi: ${report.description}', maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[600],
                    size: 16,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReportDetailScreen(report: report),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}