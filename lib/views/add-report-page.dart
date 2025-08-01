import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:pengaduan/widgets/upload-button.dart';
import 'package:uuid/uuid.dart';

class AddReportScreen extends StatefulWidget {
  const AddReportScreen({Key? key}) : super(key: key);

  @override
  _AddReportScreenState createState() => _AddReportScreenState();
}

class _AddReportScreenState extends State<AddReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  final String _cloudinaryCloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  final String _cloudinaryUploadPreset = dotenv.env['CLOUDINARY_PRESET'] ?? '';

  final TextEditingController _name = TextEditingController();
  final TextEditingController _nim = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  DateTime _incidentDate = DateTime.now();
  String _contactPreference = 'Telepon';

  double? _latitude;
  double? _longitude;
  String _address = '';

  List<File> _evidenceFiles = [];
  List<String> _evidenceFileNames = [];
  bool _isAnonymous = false;
  bool _isSubmitting = false;

  List<String> _contactOptions = [
    'Telepon',
    'Email',
    'WhatsApp',
    'Tidak ingin dihubungi'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        _evidenceFiles.add(File(image.path));
        _evidenceFileNames.add(path.basename(image.path));
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (photo != null) {
      setState(() {
        _evidenceFiles.add(File(photo.path));
        _evidenceFileNames.add(path.basename(photo.path));
      });
    }
  }

  Future<List<Map<String, String>>> _prepareEvidenceData() async {
    List<Map<String, String>> evidenceData = [];

    for (int i = 0; i < _evidenceFiles.length; i++) {
      try {
        List<int> imageBytes = await _evidenceFiles[i].readAsBytes();

        String base64Image = base64Encode(imageBytes);

        evidenceData.add({
          'name': _evidenceFileNames[i],
          'data': base64Image,
        });
      } catch (e) {
        print('Error encoding image: $e');
      }
    }

    return evidenceData;
  }

  Future<String> _uploadFileToCloudinary(File file) async {
    try {
      final ext = path.extension(file.path).toLowerCase();
      String resourceType = 'image';

      if (['.mp4', '.mov', '.avi', '.mkv'].contains(ext)) {
        resourceType = 'video';
      } else if (['.mp3', '.wav', '.m4a'].contains(ext)) {
        resourceType = 'video';
      }

      final url = Uri.parse(
          'https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/$resourceType/upload');

      var request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _cloudinaryUploadPreset;

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: path.basename(file.path),
      ));

      var response = await request.send();

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final Map<String, dynamic> responseData = json.decode(respStr);
        return responseData['secure_url'];
      } else {
        final respStr = await response.stream.bytesToString();
        print('Cloudinary upload error: ${response.statusCode} - $respStr');
        throw Exception(
            'Gagal mengunggah file ke Cloudinary: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading file to Cloudinary: $e');
      rethrow;
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _evidenceFiles.add(File(video.path));
        _evidenceFileNames.add(path.basename(video.path));
      });
    }
  }

  Future<void> _pickAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _evidenceFiles.add(File(result.files.single.path!));
        _evidenceFileNames.add(path.basename(result.files.single.path!));
      });
    }
  }

  Future<void> _getLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Izin lokasi ditolak')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Izin lokasi ditolak secara permanen, silakan ubah di pengaturan'),
          ),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      _latitude = position.latitude;
      _longitude = position.longitude;

      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        _address =
            '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}';
        _locationController.text = _address;
      }

      setState(() {});
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error mendapatkan lokasi: $e')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _incidentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFFE91E63),
            colorScheme: const ColorScheme.light(primary: Color(0xFFE91E63)),
            buttonTheme:
                const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _incidentDate) {
      setState(() {
        _incidentDate = picked;
      });
    }
  }

  Future<void> _submitReport() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        String reportId = const Uuid().v4();
        User? user = _auth.currentUser;
        String userId = user?.uid ?? 'anonymous';

        List<String> evidenceUrls = [];
        for (File file in _evidenceFiles) {
          String downloadUrl = await _uploadFileToCloudinary(file);
          evidenceUrls.add(downloadUrl);
        }

        Map<String, dynamic> reportData = {
          'reportId': reportId,
          'userId': userId,
          'name': _name.text.isNotEmpty ? _name.text : user?.displayName ?? '',
          'nim': _nim.text,
          'title': _titleController.text,
          'description': _descriptionController.text,
          'location': _latitude != null && _longitude != null
              ? GeoPoint(_latitude!, _longitude!)
              : null,
          'address': _address,
          'incidentDate': Timestamp.fromDate(_incidentDate),
          'reportDate': Timestamp.now(),
          'status': 'new',
          'assignedTo': '',
          'evidenceUrls': evidenceUrls,
          'evidenceCount': evidenceUrls.length,
          'contactPreference': _contactPreference,
          'isAnonymous': _isAnonymous,
        };

        await _firestore.collection('reports').doc(reportId).set(reportData);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laporan berhasil dikirim')),
        );

        Navigator.pop(context);
      } catch (e) {
        setState(() {
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error mengirim laporan: $e')),
        );
      }
    }
  }

  void _removeEvidence(int index) {
    setState(() {
      _evidenceFiles.removeAt(index);
      _evidenceFileNames.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Buat Laporan Baru',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFE91E63),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isSubmitting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Mengirim laporan Anda...')
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Petunjuk Pengisian',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Silakan isi formulir dengan informasi selengkap-lengkapnya untuk membantu kami menangani laporan Anda dengan baik. Informasi yang Anda berikan akan dijaga kerahasiaannya sesuai dengan pilihan Anda.',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Nama Pelapor',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _name,
                      decoration: InputDecoration(
                        hintText: 'Masukkan nama pelapor',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFFE91E63)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama pelapor tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'NIM Pelapor',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nim,
                      decoration: InputDecoration(
                        hintText: 'Masukkan nim pelapor',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFFE91E63)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'NIM pelapor tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Judul Laporan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Masukkan judul laporan',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFFE91E63)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Judul laporan tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Deskripsi Kejadian',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        hintText: 'Jelaskan secara detail apa yang terjadi',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFFE91E63)),
                        ),
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Deskripsi kejadian tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Tanggal Kejadian',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 15),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd MMMM yyyy', 'id_ID')
                                  .format(_incidentDate),
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                            Icon(Icons.calendar_today,
                                color: Colors.grey.shade600)
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Lokasi Kejadian',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _locationController,
                            decoration: InputDecoration(
                              hintText: 'Masukkan lokasi kejadian',
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: Color(0xFFE91E63)),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Lokasi kejadian tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _getLocation,
                          child: Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE91E63),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.my_location,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Bukti / Foto Kejadian',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Unggah foto atau bukti pendukung untuk memperkuat laporan (maks. 3 foto)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap:
                                _evidenceFiles.length < 3 ? _pickImage : null,
                            child: buildUploadButton(
                                Icons.photo_library, 'Galeri'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap:
                                _evidenceFiles.length < 3 ? _takePhoto : null,
                            child:
                                buildUploadButton(Icons.camera_alt, 'Kamera'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap:
                                _evidenceFiles.length < 3 ? _pickVideo : null,
                            child: buildUploadButton(Icons.videocam, 'Video'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap:
                                _evidenceFiles.length < 3 ? _pickAudio : null,
                            child: buildUploadButton(Icons.audiotrack, 'Audio'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_evidenceFiles.isNotEmpty) ...[
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _evidenceFiles.length,
                          itemBuilder: (context, index) {
                            final file = _evidenceFiles[index];
                            final fileExt =
                                path.extension(file.path).toLowerCase();

                            bool isImage = ['.jpg', '.jpeg', '.png', '.webp']
                                .contains(fileExt);
                            bool isVideo = ['.mp4', '.mov', '.avi', '.mkv']
                                .contains(fileExt);
                            bool isAudio =
                                ['.mp3', '.wav', '.m4a'].contains(fileExt);
                            return Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: isImage
                                        ? Image.file(file, fit: BoxFit.cover)
                                        : isVideo
                                            ? const Icon(Icons.videocam,
                                                size: 40, color: Colors.pink)
                                            : isAudio
                                                ? const Icon(Icons.audiotrack,
                                                    size: 40,
                                                    color: Colors.pink)
                                                : const Icon(
                                                    Icons.insert_drive_file,
                                                    size: 40),
                                  ),
                                ),
                                Positioned(
                                  right: 10,
                                  top: 2,
                                  child: GestureDetector(
                                    onTap: () => _removeEvidence(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Text(
                      'Preferensi Kontak',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Bagaimana kami dapat menghubungi Anda untuk tindak lanjut?',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _contactPreference,
                          isExpanded: true,
                          items: _contactOptions.map((String option) {
                            return DropdownMenuItem<String>(
                              value: option,
                              child: Text(option),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _contactPreference = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: _isAnonymous,
                          activeColor: const Color(0xFFE91E63),
                          onChanged: (value) {
                            setState(() {
                              _isAnonymous = value ?? false;
                            });
                          },
                        ),
                        const Text('Laporkan secara anonim'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 36),
                      child: Text(
                        'Identitas Anda akan dirahasiakan, namun kami tetap bisa menghubungi Anda sesuai preferensi kontak jika diperlukan.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE91E63),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'KIRIM LAPORAN',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }
}
