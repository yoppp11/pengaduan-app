import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({Key? key}) : super(key: key);

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      print('Tidak dapat melakukan panggilan ke $phoneNumber');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bantuan & Panduan PPKPT',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFE91E63),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Halaman ini menyediakan informasi penting dan langkah-langkah yang dapat Anda lakukan jika mengalami atau menyaksikan kekerasan di lingkungan kampus. Keselamatan dan kesejahteraan Anda adalah prioritas.',
              style: TextStyle(fontSize: 16, height: 1.5),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 25),

            const Text(
              'Kontak Penting Kampus:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE91E63),
              ),
            ),
            const SizedBox(height: 15),

            _buildEmergencyContactCard(
              context,
              'Satuan Tugas PPKPT Kampus',
              '0812-3456-7890',
              'Tim kampus yang bertanggung jawab menangani laporan kekerasan seksual dan kekerasan lainnya di lingkungan perguruan tinggi.',
              Icons.verified_user,
              Colors.pink.shade700,
            ),
            _buildEmergencyContactCard(
              context,
              'Layanan Konseling Kampus',
              '0813-9876-1234',
              'Dapatkan dukungan psikologis dari konselor kampus secara rahasia dan profesional.',
              Icons.psychology,
              Colors.teal.shade700,
            ),
            _buildEmergencyContactCard(
              context,
              'Biro Kemahasiswaan',
              '021-12345678',
              'Untuk informasi dan pengaduan terkait kehidupan kampus serta perlindungan hak mahasiswa.',
              Icons.account_balance,
              Colors.indigo.shade700,
            ),
            _buildEmergencyContactCard(
              context,
              'Polisi - Unit Perlindungan Perempuan dan Anak (PPA)',
              '110',
              'Hubungi jika situasi membutuhkan intervensi pihak kepolisian secara langsung.',
              Icons.local_police,
              Colors.blue.shade700,
            ),

            const SizedBox(height: 30),

            const Text(
              'Langkah yang Dapat Anda Lakukan:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE91E63),
              ),
            ),
            const SizedBox(height: 15),

            _buildEducationPoint(
              '1. Tetap Tenang dan Cari Tempat Aman',
              'Jika memungkinkan, segera menjauh dari pelaku dan cari tempat aman di dalam kampus.',
              Icons.safety_check,
            ),
            _buildEducationPoint(
              '2. Catat Kejadian',
              'Tulis rincian kejadian selengkap mungkin: waktu, lokasi, pelaku, dan saksi (jika ada).',
              Icons.note_alt,
            ),
            _buildEducationPoint(
              '3. Hubungi Pihak Terkait',
              'Laporkan ke Satgas PPKPT, dosen, atau pihak yang dipercaya. Gunakan layanan kampus yang tersedia.',
              Icons.report,
            ),
            _buildEducationPoint(
              '4. Simpan Bukti',
              'Jangan hapus pesan, foto, atau barang bukti yang berkaitan dengan kejadian. Ini dapat membantu proses investigasi.',
              Icons.archive,
            ),
            _buildEducationPoint(
              '5. Dapatkan Dukungan',
              'Bicaralah dengan konselor atau orang yang Anda percaya. Dukungan emosional sangat penting.',
              Icons.support,
            ),
            _buildEducationPoint(
              '6. Jangan Takut Melapor',
              'Anda berhak atas lingkungan kampus yang aman. Semua laporan akan ditangani secara rahasia dan profesional.',
              Icons.shield_moon,
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContactCard(
    BuildContext context,
    String title,
    String number,
    String description,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      )),
                  const SizedBox(height: 5),
                  Text(description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: ElevatedButton.icon(
                      onPressed: () => _makePhoneCall(number.replaceAll(' ', '')),
                      icon: const Icon(Icons.call, color: Colors.white),
                      label: Text('Panggil $number',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationPoint(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: const Color(0xFFE91E63)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    )),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 15, color: Colors.grey[800]),
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
