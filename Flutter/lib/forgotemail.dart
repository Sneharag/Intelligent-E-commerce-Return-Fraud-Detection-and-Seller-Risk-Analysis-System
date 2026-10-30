import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'forgototp.dart';

void main() {
  runApp(forgotemail());
}

class forgotemail extends StatelessWidget {
  const forgotemail({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: forgotemailsub(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFACC15)),
        fontFamily: 'Roboto',
      ),
    );
  }
}

class forgotemailsub extends StatefulWidget {
  const forgotemailsub({Key? key}) : super(key: key);

  @override
  State<forgotemailsub> createState() => _forgotemailsubState();
}

class _forgotemailsubState extends State<forgotemailsub> {
  TextEditingController email = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

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

  Future<void> _checkEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      sh.setString("email", email.text);

      var res = await http.post(
        Uri.parse("${sh.getString("ip")}/forgotemail"),
        body: {'email': email.text},
      );

      var decode = json.decode(res.body);

      if (decode["status"] == "ok") {
        sh.setString("otpp", decode['otpp'].toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP sent to your email!'),
            backgroundColor: _charcoal,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.push(context, MaterialPageRoute(builder: (context) => forgototp()));
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              "Email Not Found",
              style: TextStyle(
                color: _ink,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              "The email address you entered is not registered. Please check and try again.",
              style: TextStyle(
                fontSize: 14,
                color: _muted,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  "OK",
                  style: TextStyle(
                    color: _charcoal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            "Connection Error",
            style: TextStyle(
              color: _ink,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "Unable to connect. Please check your internet connection and try again.",
            style: TextStyle(
              fontSize: 14,
              color: _muted,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                "OK",
                style: TextStyle(
                  color: _charcoal,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _warmWhite,
      appBar: AppBar(
        backgroundColor: _charcoal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        centerTitle: true,
        title: const Text(
          "Forgot Password",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
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
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    size: 42,
                    color: _charcoal,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Heading ──
                const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Enter your email address and we'll send you an OTP to reset your password",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: _muted,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
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
                            'EMAIL ADDRESS',
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

                      TextFormField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _ink,
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
                        decoration: InputDecoration(
                          hintText: 'you@example.com',
                          hintStyle: TextStyle(
                            color: _mutedSoft.withOpacity(0.7),
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIcon: const Icon(
                            Icons.mail_outline_rounded,
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
                            borderSide: const BorderSide(color: _line, width: 1.2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: _yellowDeep, width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFC23D2C), width: 1.4),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFC23D2C), width: 1.6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'We will send a 6-digit OTP to this email',
                        style: TextStyle(
                          fontSize: 12,
                          color: _mutedSoft.withOpacity(0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // ── Send OTP button ──
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _checkEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _yellow,
                      foregroundColor: _charcoal,
                      elevation: 0,
                      disabledBackgroundColor: _yellow.withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                        AlwaysStoppedAnimation<Color>(_charcoal),
                      ),
                    )
                        : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send_rounded, size: 18, color: _charcoal),
                        SizedBox(width: 8),
                        Text(
                          "Send OTP",
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                            color: _charcoal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Help note ──
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _yellowSoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _yellow.withOpacity(0.4),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: _charcoal,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Check your spam folder if you don't receive the OTP within a few minutes",
                          style: TextStyle(
                            fontSize: 12.5,
                            color: _ink.withOpacity(0.85),
                            fontWeight: FontWeight.w500,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}