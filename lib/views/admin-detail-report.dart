import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pengaduan/models/report.dart';

class ReportDetailScreen extends StatefulWidget {
  final Report report;

  const ReportDetailScreen({Key? key, required this.report}) : super(key: key);

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.report.status;
  }

  Future<void> _updateReportStatus(String newStatus) async {
    try {
      await _firestore.collection('reports').doc(widget.report.reportId).update({
        'status': newStatus,
      });
      setState(() {
        _currentStatus = newStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status laporan berhasil diperbarui menjadi ${newStatus.toUpperCase()}')),
      );
    } catch (e) {
      print('Error updating report status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memperbarui status laporan.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Detail Laporan: ${widget.report.title}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFE91E63),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Judul Laporan:', style: Theme.of(context).textTheme.titleSmall),
                    Text(widget.report.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const Divider(),
                    Text('Deskripsi:', style: Theme.of(context).textTheme.titleSmall),
                    Text(widget.report.description, style: Theme.of(context).textTheme.bodyLarge),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tanggal Insiden:', style: Theme.of(context).textTheme.titleSmall),
                            Text(DateFormat('dd MMM yyyy, HH:mm').format(widget.report.incidentDate.toDate()), style: Theme.of(context).textTheme.bodyLarge),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tanggal Lapor:', style: Theme.of(context).textTheme.titleSmall),
                            Text(DateFormat('dd MMM yyyy, HH:mm').format(widget.report.reportDate.toDate()), style: Theme.of(context).textTheme.bodyLarge),
                          ],
                        ),
                      ],
                    ),
                    const Divider(),
                    Text('Alamat:', style: Theme.of(context).textTheme.titleSmall),
                    Text(widget.report.address, style: Theme.of(context).textTheme.bodyLarge),
                    const Divider(),
                    Text('Status Laporan:', style: Theme.of(context).textTheme.titleSmall),
                    Chip(
                      label: Text(_currentStatus.toUpperCase(), style: const TextStyle(color: Colors.white)),
                      backgroundColor: _getStatusColor(_currentStatus),
                    ),
                    const Divider(),
                    Text('Dilaporkan oleh:', style: Theme.of(context).textTheme.titleSmall),
                    Text(
                      widget.report.isAnonymous ? 'Anonim' : 'User ID: ${widget.report.userId ?? 'N/A'}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    if (!widget.report.isAnonymous) ...[
                      const Divider(),
                      Text('Preferensi Kontak:', style: Theme.of(context).textTheme.titleSmall),
                      Text(widget.report.contactPreference, style: Theme.of(context).textTheme.bodyLarge),
                    ],
                    const Divider(),
                    Text('Ditugaskan Kepada:', style: Theme.of(context).textTheme.titleSmall),
                    Text(widget.report.assignedTo.isEmpty ? 'Belum ditugaskan' : widget.report.assignedTo, style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Bukti (${widget.report.evidenceCount} berkas):', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            widget.report.evidenceUrls.isEmpty
                ? const Text('Tidak ada bukti terlampir.', style: TextStyle(fontStyle: FontStyle.italic))
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                    ),
                    itemCount: widget.report.evidenceUrls.length,
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          widget.report.evidenceUrls[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 30),
            Text('Ubah Status Laporan:', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _currentStatus,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Pilih Status',
              ),
              items: <String>['new', 'in_progress', 'resolved', 'rejected']
                  .map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value.toUpperCase()),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null && newValue != _currentStatus) {
                  _updateReportStatus(newValue);
                }
              },
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}