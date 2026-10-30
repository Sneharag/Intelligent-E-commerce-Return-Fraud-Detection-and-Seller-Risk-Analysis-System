import 'dart:convert';
import 'package:ecommerce_return_fraud_detection/register.dart';
import 'package:ecommerce_return_fraud_detection/userdashboard.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'forgotemail.dart';

class LoginPageSub extends StatefulWidget {
  const LoginPageSub({super.key});

  @override
  State<LoginPageSub> createState() => _LoginPageSubState();
}

class _LoginPageSubState extends State<LoginPageSub> {
  @override
  final _formkey = GlobalKey<FormState>();
  TextEditingController username = TextEditingController();
  TextEditingController password = TextEditingController();
  bool _obscureText1 = true;

  // ── E-commerce palette (yellow · charcoal) ──
  static const Color _yellow     = Color(0xFFFACC15);
  static const Color _yellowDeep = Color(0xFFEAB308);
  static const Color _yellowSoft = Color(0xFFFEF9C3);

  static const Color _charcoal   = Color(0xFF1F2937);
  static const Color _ink        = Color(0xFF111827);
  static const Color _warmWhite  = Color(0xFFFAFAF9);
  static const Color _line       = Color(0xFFE7E5E4);
  static const Color _muted      = Color(0xFF78716C);
  static const Color _mutedSoft  = Color(0xFFA8A29E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _warmWhite,
      appBar: AppBar(
        backgroundColor: _charcoal,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            // ── Logo ──
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(4),
              child: Image.asset(
                'assets/images/returnlogo.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.shield_rounded,
                    color: _charcoal,
                    size: 20,
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            // ── Brand name ──
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
                children: [
                  TextSpan(text: 'Return'),
                  TextSpan(
                    text: 'Guard',
                    style: TextStyle(color: _yellow),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formkey,
            child: Column(
              children: [
                const SizedBox(height: 10),

                // ── App icon chip ──
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: _yellowSoft,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: _yellow.withOpacity(0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/returnlogo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.shield_rounded,
                        color: _charcoal,
                        size: 20,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // ── Heading ──
                const Text(
                  'Welcome back',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sign in to your account to continue',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: _muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 28),

                // ── Card ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _line, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: _charcoal.withOpacity(0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Username label ──
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 14,
                            decoration: BoxDecoration(
                              color: _yellow,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'USERNAME / EMAIL',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _muted,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // ── Username field ──
                      TextFormField(
                        controller: username,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _ink,
                        ),
                        decoration: InputDecoration(
                          hintText: 'you@example.com',
                          hintStyle: TextStyle(
                            color: _mutedSoft.withOpacity(0.7),
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIcon: const Icon(
                            Icons.person_outline_rounded,
                            color: _charcoal,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: _warmWhite,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: _line,
                              width: 1.2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: _yellowDeep,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFC23D2C),
                              width: 1.4,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFC23D2C),
                              width: 1.6,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null) {
                            return "Required";
                          }
                          if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(value)) {
                            return "Enter a valid email address";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // ── Password label ──
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 14,
                            decoration: BoxDecoration(
                              color: _yellow,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'PASSWORD',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _muted,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // ── Password field ──
                      TextFormField(
                        controller: password,
                        obscureText: _obscureText1,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _ink,
                        ),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          hintStyle: TextStyle(
                            color: _mutedSoft.withOpacity(0.7),
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIcon: const Icon(
                            Icons.key_rounded,
                            color: _charcoal,
                            size: 20,
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscureText1 = !_obscureText1;
                              });
                            },
                            icon: Icon(
                              _obscureText1
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: _muted,
                              size: 20,
                            ),
                          ),
                          filled: true,
                          fillColor: _warmWhite,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: _line,
                              width: 1.2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: _yellowDeep,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFC23D2C),
                              width: 1.4,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFC23D2C),
                              width: 1.6,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null) {
                            return "Required";
                          }
                          if (!RegExp(r"^(?=.*\d)(?=.*[a-z])(?=.*[A-Z]).{8,}$").hasMatch(value)) {
                            return "Min 8 chars with 1 uppercase, 1 lowercase, 1 number";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 22),

                      // ── Login button ──
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_formkey.currentState!.validate()) {
                              SharedPreferences prefs =
                              await SharedPreferences.getInstance();

                              var data = await http.post(
                                Uri.parse(
                                    "${prefs.getString("ip")}/user_login"),
                                body: {
                                  "username": username.text,
                                  "password": password.text,
                                },
                              );

                              var jsonData = json.decode(data.body);
                              print("${jsonData['status']}");

                              if (jsonData['status'] == 'success') {
                                prefs.setString("user", jsonData['user'].toString());
                                await prefs.setString("name", jsonData['name'].toString());

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => Userdashboard()),
                                );
                              } else if (jsonData['status'] == 'blocked') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Row(
                                      children: [
                                        Icon(Icons.block_rounded, color: Colors.white, size: 20),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            "Your account has been blocked. Please contact support.",
                                            style: TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                    duration: const Duration(seconds: 5),
                                    backgroundColor: const Color(0xFFC23D2C),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              } else if (jsonData['status'] == 'error') {
                                // keep your existing error handling here if backend uses it
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text("Incorrect Username/Password"),
                                    duration: const Duration(seconds: 5),
                                    backgroundColor: _charcoal,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _yellow,
                            foregroundColor: _charcoal,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Login",
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                  color: _charcoal,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 18,
                                color: _charcoal,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Forgot / Register row ──
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        child: TextButton(
                          style: TextButton.styleFrom(
                              overlayColor: _yellowSoft),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => forgotemailsub()));
                          },
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              fontSize: 14,
                              color: _charcoal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                    Expanded(
                      child: Align(
                        child: TextButton(
                          style: TextButton.styleFrom(
                              overlayColor: _yellowSoft),
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Register()));
                          },
                          child: const Text(
                            'New User? Register',
                            style: TextStyle(
                              fontSize: 14,
                              color: _charcoal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}