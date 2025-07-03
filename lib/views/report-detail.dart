import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

class ReportDetailPage extends StatefulWidget {
  final String reportId;

  const ReportDetailPage({super.key, required this.reportId});

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _report;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final reportId = ModalRoute.of(context)!.settings.arguments as String;
      _fetchReport(reportId);
    });
  }

  Future<void> _fetchReport(String reportId) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final doc = await _firestore.collection('reports').doc(reportId).get();
      if (!doc.exists) {
        setState(() {
          _error = 'Laporan tidak ditemukan.';
          _isLoading = false;
        });
        return;
      }

      final data = doc.data()!;
      setState(() {
        _report = {
          ...data,
          'reportId': doc.id,
          'reportDate': (data['reportDate'] as Timestamp).toDate(),
          'incidentDate': (data['incidentDate'] as Timestamp).toDate(),
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Terjadi kesalahan: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Detail Laporan', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFE91E63),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child:
                      Text(_error!, style: const TextStyle(color: Colors.red)))
              : _report == null
                  ? const Center(child: Text('Tidak ada data'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildTitleSection(),
                        const SizedBox(height: 16),
                        _buildInfoTile(Icons.calendar_month, 'Tanggal Kejadian',
                            dateFormat.format(_report!['incidentDate'])),
                        _buildInfoTile(
                            Icons.access_time,
                            'Dilaporkan',
                            timeago.format(_report!['reportDate'],
                                locale: 'id')),
                        _buildInfoTile(
                            Icons.place, 'Alamat', _report!['address']),
                        _buildInfoTile(Icons.chat, 'Kontak via',
                            _report!['contactPreference']),
                        _buildInfoTile(Icons.person_off, 'Anonim',
                            _report!['isAnonymous'] ? 'Ya' : 'Tidak'),
                        const SizedBox(height: 16),
                        _buildDescription(),
                        const SizedBox(height: 16),
                        _buildEvidenceSection(),
                        const SizedBox(height: 16),
                        // _buildMapSection(),
                      ],
                    ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _report!['title'] ?? 'Tanpa Judul',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Chip(
          label: Text(_statusText(_report!['status']),
              style: const TextStyle(color: Colors.white)),
          backgroundColor: _statusColor(_report!['status']),
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.grey[700]),
      title:
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
      subtitle: Text(value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Deskripsi Laporan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(_report!['description'], style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildEvidenceSection() {
    final List<String> evidenceUrls =
        List<String>.from(_report!['evidenceUrls'] ?? []);
    if (evidenceUrls.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Bukti Pendukung',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...evidenceUrls.map((url) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(url, fit: BoxFit.cover),
              ),
            )),
      ],
    );
  }

  // Widget _buildMapSection() {
  //   final location = _report!['location'];
  //   if (location == null) return const SizedBox();

  //   final LatLng latLng = LatLng(location.latitude, location.longitude);
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       const Text('Lokasi Kejadian',
  //           style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
  //       const SizedBox(height: 12),
  //       ClipRRect(
  //         borderRadius: BorderRadius.circular(12),
  //         child: SizedBox(
  //           height: 200,
  //           child: GoogleMap(
  //             initialCameraPosition: CameraPosition(target: latLng, zoom: 16),
  //             markers: {
  //               Marker(markerId: const MarkerId('location'), position: latLng),
  //             },
  //             zoomControlsEnabled: false,
  //             myLocationButtonEnabled: false,
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  String _statusText(String status) {
    switch (status) {
      case 'new':
        return 'Baru';
      case 'in_progress':
        return 'Diproses';
      case 'resolved':
        return 'Selesai';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'new':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
