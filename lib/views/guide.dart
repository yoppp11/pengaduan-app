import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; 

class GuideScreen extends StatelessWidget {
  const GuideScreen({Key? key}) : super(key: key);

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      print('Could not launch $phoneNumber');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Butuh Bantuan',
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
              'Dalam situasi darurat, setiap detik berharga. Halaman ini menyediakan informasi kontak penting dan panduan singkat untuk membantu Anda mengambil tindakan yang tepat.',
              style: TextStyle(fontSize: 16, height: 1.5),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 25),

            const Text(
              'Nomor Telepon Darurat:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE91E63),
              ),
            ),
            const SizedBox(height: 15),

            _buildEmergencyContactCard(
              context,
              'Polisi (Panggilan Darurat)',
              '110',
              'Hubungi jika ada tindak kriminal, kecelakaan, atau kondisi darurat lainnya yang memerlukan intervensi polisi.',
              Icons.local_police,
              Colors.blue.shade700,
            ),
            _buildEmergencyContactCard(
              context,
              'Pusat Krisis Kekerasan Dalam Rumah Tangga',
              '021-112', 
              'Pusat layanan yang memberikan dukungan, konseling, dan bantuan hukum bagi korban KDRT.',
              Icons.family_restroom,
              Colors.purple.shade700,
            ),
            _buildEmergencyContactCard(
              context,
              'Ambulans / Gawat Darurat Medis',
              '118 / 119',
              'Panggilan untuk situasi medis darurat seperti kecelakaan serius, serangan jantung, atau kondisi kesehatan kritis lainnya.',
              Icons.medical_services,
              Colors.red.shade700,
            ),
            _buildEmergencyContactCard(
              context,
              'Pemadam Kebakaran',
              '113',
              'Hubungi jika terjadi kebakaran atau insiden yang memerlukan penanganan dari dinas pemadam kebakaran.',
              Icons.fire_truck,
              Colors.orange.shade700,
            ),
             _buildEmergencyContactCard(
              context,
              'Basarnas (SAR)',
              '115',
              'Untuk operasi pencarian dan penyelamatan dalam bencana alam, kecelakaan laut/udara, atau orang hilang.',
              Icons.safety_divider,
              Colors.lightGreen.shade700,
            ),
            const SizedBox(height: 30),

            const Text(
              'Apa yang Harus Dilakukan Saat Kondisi Darurat:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE91E63),
              ),
            ),
            const SizedBox(height: 15),

            _buildEducationPoint(
              '1. Tetap Tenang',
              'Tarik napas dalam-dalam. Ketenangan membantu Anda berpikir jernih dan mengambil keputusan yang tepat.',
              Icons.self_improvement,
            ),
            _buildEducationPoint(
              '2. Amankan Diri dan Orang Lain',
              'Prioritaskan keselamatan. Jika memungkinkan, menjauh dari bahaya langsung.',
              Icons.shield,
            ),
            _buildEducationPoint(
              '3. Hubungi Nomor Darurat',
              'Telepon nomor yang sesuai sesegera mungkin. Berikan informasi yang jelas dan ringkas mengenai lokasi dan jenis darurat.',
              Icons.phone_in_talk,
            ),
            _buildEducationPoint(
              '4. Berikan Informasi Akurat',
              'Sebutkan lokasi kejadian (alamat lengkap atau patokan), jenis insiden, jumlah korban (jika ada), dan kondisi yang terlihat.',
              Icons.info_outline,
            ),
            _buildEducationPoint(
              '5. Ikuti Instruksi',
              'Dengarkan baik-baik instruksi dari operator telepon darurat atau petugas yang tiba di lokasi.',
              Icons.record_voice_over,
            ),
            _buildEducationPoint(
              '6. Dokumentasikan (Jika Aman)',
              'Jika aman untuk dilakukan, ambil foto atau video sebagai bukti. Ini dapat membantu penyelidikan lebih lanjut.',
              Icons.camera_alt,
            ),
            _buildEducationPoint(
              '7. Jangan Berangkat Sendiri',
              'Jika Anda adalah korban atau saksi kekerasan, jangan coba menghadapi situasi sendiri. Cari bantuan dari orang terpercaya atau pihak berwenang.',
              Icons.group,
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContactCard(
      BuildContext context, String title, String number, String description, IconData icon, Color color) {
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
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: ElevatedButton.icon(
                      onPressed: () => _makePhoneCall(number.replaceAll(' ', '')), // Hapus spasi dari nomor
                      icon: const Icon(Icons.call, color: Colors.white),
                      label: Text(
                        'Panggil $number',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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