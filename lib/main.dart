import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kasir_bengkel/pages/engineer.dart';
import 'package:kasir_bengkel/pages/history.dart';
import 'package:kasir_bengkel/pages/home.dart';
import 'package:kasir_bengkel/pages/kasir.dart';
import 'package:kasir_bengkel/pages/login.dart';
import 'package:kasir_bengkel/pages/signup.dart';
import 'package:kasir_bengkel/pages/layanan.dart';
import 'package:kasir_bengkel/pages/struk.dart';
import 'package:kasir_bengkel/pages/laporan.dart';
import 'firebase_options.dart';
import 'package:get/get.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kasir Bengkel',
      initialRoute: '/login',
      getPages: [
        GetPage(name: '/login', page: () => const LoginPage()),
        GetPage(name: '/signup', page: () => const SignupPage()),
        GetPage(name: '/home', page: () => const HomePage()),
        GetPage(name: '/layanan', page: () => const LayananPage()),
        GetPage(
          name: '/kasir',
          page: () => KasirPage(keranjang: [], updateKeranjang: (k) {}),
        ),
        GetPage(name: '/engineer', page: () => const EngineerPage()),
        GetPage(name: '/history', page: () => const HistoryPage()),
        GetPage(name: '/struk', page: () => const StrukPage()),
        GetPage(
          name: '/laporan',
          page: () => const LaporanPage(),
        ), // <-- tambahan
      ],
    );
  }
}
