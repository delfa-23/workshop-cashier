import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  Future<void> signup() async {
    if (_passwordController.text.trim() != _confirmController.text.trim()) {
      Get.snackbar("Error", "Password & Confirm Password are not same",
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      if (_passwordController.text.trim().length < 3) {
        Get.snackbar(
          "Error",
          "Password must be at least 3 characters",
          snackPosition: SnackPosition.BOTTOM,
        );
        return; // stop biar ga lanjut ke Firebase
      }

      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // simpan ke Firestore
      await FirebaseFirestore.instance
          .collection("users")
          .doc(userCredential.user!.uid)
          .set({
        "username": _usernameController.text.trim(),
        "email": _emailController.text.trim(),
        "photoUrl": "",
        "createdAt": DateTime.now(),
      });

      Get.offAllNamed('/login');
    } on FirebaseAuthException catch (e) {
      Get.snackbar("Error", "Signup Failed: ${e.message}",
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar("Error", "Unexpected Error: $e",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Icon(Icons.build_circle, size: 100, color: Colors.orangeAccent),
              const SizedBox(height: 24),
              Text(
                'Kasir Bengkel',
                style: GoogleFonts.abhayaLibre(
                  fontWeight: FontWeight.w600,
                  fontSize: 40,
                ),
              ),
              const SizedBox(height: 20),

              // Username
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: "Username",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              // Email
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              // Password
              TextField(
                controller: _passwordController,
                obscureText: _obscurePass,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscurePass ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Konfirmasi Password
              TextField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: "Confirm Password",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Tombol daftar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Signup",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: const [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text("Or Signup with"),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),

              // Tombol Google
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: (){},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                    side: const BorderSide(color: Colors.red, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: Image.asset("../assets/images/google.png", height: 24),
                  label: const Text(
                    "Google",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already Have An Account? "),
                  GestureDetector(
                    onTap: () => Get.toNamed('/login'),
                    child: const Text(
                      "Login",
                      style: TextStyle(
                          color: Colors.orange, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
