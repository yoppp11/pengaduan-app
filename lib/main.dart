import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pengaduan/firebase_options.dart';
import 'package:pengaduan/views/add-report-page.dart';
import 'package:pengaduan/views/auth-wrapper.dart';
import 'package:pengaduan/views/detail-info.dart';
import 'package:pengaduan/views/history-reports.dart';
import 'package:pengaduan/views/home-page.dart';
import 'package:pengaduan/views/login-page.dart';
import 'package:pengaduan/views/profile-page.dart';
import 'package:pengaduan/views/register-page.dart';
import 'package:pengaduan/views/update-profile.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  String api_key = dotenv.env['GEMINI_API_KEY'] ?? '';

  Gemini.init(apiKey: api_key);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initializeDateFormatting('id_ID', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lapor Sigap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE91E63),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFE91E63), width: 2),
          ),
          focusColor: Color(0xFFE91E63),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFE91E63),
          ),
        ),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/report': (context) => const AddReportScreen(),
        '/history': (context) => const ReportHistoryPage(),
        '/profile': (context) => const ProfilePage(),
        '/edit-profile': (context) => const UpdateProfilePage(),
        '/info-detail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>;
          return InfoDetailPage(
            title: args['title']!,
            description: args['description']!,
            image: args['image']!,
          );
        },
      },
    );
  }
}
