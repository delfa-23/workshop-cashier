import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  /// 🔹 Login pakai Email & Password
  Future<void> login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Get.offAllNamed('/home');
    } on FirebaseAuthException {
      Get.snackbar("Error", "Email or password is wrong",
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
              const SizedBox(height: 13),

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
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text("Forgot Password?"),
                ),
              ),

              // Button Login
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Login",
                      style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),

              // OR Divider
              Row(
                children: const [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text("Or Login with"),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),

              // Google Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red, width: 2),
                    textStyle: const TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: (){},
                  icon: Image.asset("../assets/images/google.png", height: 24),
                  label: const Text("Google",
                      style: TextStyle(color: Colors.red)),
                ),
              ),
              const SizedBox(height: 20),

              // Signup
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't Have An Account? "),
                  GestureDetector(
                    onTap: () => Get.toNamed('/signup'),
                    child: Text("Signup now",
                        style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.bold)),
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
