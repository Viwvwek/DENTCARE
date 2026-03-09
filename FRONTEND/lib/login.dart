import 'package:dentcare/getstart.dart';
import 'package:dentcare/home.dart';
import 'package:flutter/material.dart';
import 'package:dentcare/signup.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  String? _errorText;
  bool _obscurePassword = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4FD1C5), // Top Teal
              Color(0xFF38B2AC), // Bottom Teal
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header Row (Back Icon + Title)
                Padding(
                  padding:
                      const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                          icon: const Icon(Icons.arrow_back_ios,
                              color: Colors.white, size: 20),
                          onPressed: () {
                            Navigator.pop(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const Getstart()));
                          }),
                      //const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                      const Text(
                        "Log In",
                        style: TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 20), // To balance the row
                    ],
                  ),
                ),

                // Email Label
                const Padding(
                  padding: EdgeInsets.only(right: 30, left: 30, bottom: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Email or Mobile Number",
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),

                // Email TextField
                Padding(
                  padding: const EdgeInsets.only(right: 30, left: 30),
                  child: TextField(
                    controller: _emailController,
                    style: const TextStyle(color: Color(0xFF2C7A7B)),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFB2F5EA).withOpacity(0.5),
                      hintText: "example@example.com",
                      hintStyle: TextStyle(
                          color: const Color(0xFF2C7A7B).withOpacity(0.5)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25), // Your radius
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 20),
                    ),
                  ),
                ),

                // Password Label
                const Padding(
                  padding:
                      EdgeInsets.only(right: 30, left: 30, top: 20, bottom: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Password",
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),

                // Password TextField
                Padding(
                  padding: const EdgeInsets.only(right: 30, left: 30),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword, // 👁 toggles visibility
                    style: const TextStyle(color: Color(0xFF2C7A7B)),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFB2F5EA).withOpacity(0.5),
                      hintText: "* * * * * * * *",
                      errorText: _errorText, // ❌ inline error text
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF2C7A7B),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 20),
                    ),
                  ),
                ),

                // Log In Button
                Padding(
                  padding: const EdgeInsets.only(top: 45),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: MaterialButton(
                      onPressed: () async {
                        setState(() {
                          _errorText = null; // clear old error
                        });

                        try {
                          await FirebaseAuth.instance
                              .signInWithEmailAndPassword(
                            email: _emailController.text.trim(),
                            password: _passwordController.text.trim(),
                          );

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const Home()),
                          );
                        } on FirebaseAuthException {
                          setState(() {
                            _errorText = "Incorrect email or password";
                          });
                        }
                      },

                      height: 55,
                      minWidth: 260, // Matches your minWidth preference
                      color: const Color(0xFF2C7A7B), // Darker Teal Button
                      child: const Text(
                        "Log In",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                // "Welcome" Text (Using ListTile pattern from your snippet, or just Text)
                Padding(
                  padding: const EdgeInsets.only(top: 40, bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? ",
                          style: TextStyle(color: Colors.white70)),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const Signup()),
                          );
                        },
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // "or sign up with" text
                const Padding(
                  padding: EdgeInsets.only(top: 30, bottom: 20),
                  child: Text(
                    "or sign up with",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),

                // Social Icons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _socialIcon(Icons.g_mobiledata),
                    const SizedBox(width: 20),
                    _socialIcon(Icons.facebook),
                    const SizedBox(width: 20),
                    _socialIcon(Icons.fingerprint),
                  ],
                ),


                
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Simple helper for the social icons to keep the main code clean
  Widget _socialIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white54),
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}
