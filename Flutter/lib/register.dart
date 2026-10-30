import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'login.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  @override

  final _formkey = GlobalKey<FormState>();
  TextEditingController name = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController phone = TextEditingController();
  TextEditingController house = TextEditingController();
  TextEditingController street = TextEditingController();
  TextEditingController place = TextEditingController();
  TextEditingController post = TextEditingController();
  TextEditingController pin = TextEditingController();
  TextEditingController password1 = TextEditingController();
  TextEditingController password2 = TextEditingController();
  bool _obscureText1 = true;
  bool _obscureText2 = true;
  bool _isSubmitting = false;

  // ── E-commerce palette (yellow · charcoal · deep blue) ──
  static const Color _yellow     = Color(0xFFFACC15);
  static const Color _yellowDeep = Color(0xFFEAB308);
  static const Color _yellowSoft = Color(0xFFFEF9C3);

  static const Color _charcoal   = Color(0xFF1F2937);
  static const Color _charcoalDark = Color(0xFF111827);
  static const Color _ink        = Color(0xFF111827);
  static const Color _warmWhite  = Color(0xFFFAFAF9);
  static const Color _line       = Color(0xFFE7E5E4);
  static const Color _muted      = Color(0xFF78716C);
  static const Color _mutedSoft  = Color(0xFFA8A29E);

  // ── Deep Blue accent ──
  static const Color _blue       = Color(0xFF1E3A8A);
  static const Color _blueMid    = Color(0xFF2563EB);
  static const Color _blueSoft   = Color(0xFFDBEAFE);

  // ── Reusable input decoration builder ──
  InputDecoration _inputDeco({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: _mutedSoft.withOpacity(0.8),
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Container(
        margin: const EdgeInsets.only(left: 6, right: 4),
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: _blue, size: 20),
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: _warmWhite,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 18,
        horizontal: 16,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _line, width: 1.4),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _yellowDeep, width: 2.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFC23D2C), width: 1.6),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFC23D2C), width: 2),
      ),
    );
  }

  // ── Bolder label with yellow accent bar + blue text ──
  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Container(
              width: 5,
              height: 16,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_yellow, _yellowDeep],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: _blue,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section divider ──
  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_yellow, _yellowDeep],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _charcoal, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: _charcoal,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_yellow.withOpacity(0.6), Colors.transparent],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldGap() => const SizedBox(height: 18);

  // ── Snackbar helper ──
  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: isError
              ? const Color(0xFFC23D2C)
              : const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _warmWhite,
      appBar: AppBar(
        backgroundColor: _charcoal,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Customer Registration",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formkey,
            child: Column(
              children: [
                const SizedBox(height: 4),

                // ── Card ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                        color: _yellow.withOpacity(0.35), width: 1.6),
                    boxShadow: [
                      BoxShadow(
                        color: _charcoal.withOpacity(0.10),
                        blurRadius: 28,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ══════════ BASIC DETAILS ══════════
                      _sectionHeader('BASIC DETAILS', Icons.person_rounded),
                      const SizedBox(height: 4),

                      _label('NAME'),
                      TextFormField(
                        controller: name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                        decoration: _inputDeco(
                          hint: 'Enter your full name',
                          icon: Icons.person_outline_rounded,
                        ),
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) return "Required";
                          if (v.length < 3) {
                            return "Name must be at least 3 characters";
                          }
                          if (!RegExp(r"^[A-Za-z]+(?:[\s.'-][A-Za-z]+)*$")
                              .hasMatch(v)) {
                            return "Only letters, spaces, dots, apostrophes, or hyphens";
                          }
                          return null;
                        },
                      ),
                      _fieldGap(),

                      _label('EMAIL'),
                      TextFormField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                        decoration: _inputDeco(
                          hint: 'you@example.com',
                          icon: Icons.mail_outline_rounded,
                        ),
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) return "Required";
                          if (!RegExp(
                              r"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$")
                              .hasMatch(v)) {
                            return "Enter a valid email address";
                          }
                          return null;
                        },
                      ),
                      _fieldGap(),

                      _label('PHONE'),
                      TextFormField(
                        controller: phone,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                        decoration: _inputDeco(
                          hint: '10-digit mobile number',
                          icon: Icons.phone_outlined,
                        ).copyWith(counterText: ''),
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) return "Required";
                          if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v)) {
                            return "Enter a valid 10-digit mobile number starting with 6-9";
                          }
                          return null;
                        },
                      ),
                      _fieldGap(),

                      const SizedBox(height: 6),
                      // ══════════ ADDRESS ══════════
                      _sectionHeader('ADDRESS DETAILS', Icons.home_rounded),
                      const SizedBox(height: 4),

                      _label('HOUSE'),
                      TextFormField(
                        controller: house,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                        decoration: _inputDeco(
                          hint: 'House name or number',
                          icon: Icons.home_outlined,
                        ),
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) return "Required";
                          if (!RegExp(r"^[A-Za-z0-9][A-Za-z0-9\s.,'/#-]{0,99}$")
                              .hasMatch(v)) {
                            return "Only letters, numbers, spaces, and . , ' / # -";
                          }
                          return null;
                        },
                      ),
                      _fieldGap(),

                      _label('STREET'),
                      TextFormField(
                        controller: street,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                        decoration: _inputDeco(
                          hint: 'Street name',
                          icon: Icons.signpost_outlined,
                        ),
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) return "Required";
                          if (!RegExp(r"^[A-Za-z0-9][A-Za-z0-9\s.,'/#-]{0,99}$")
                              .hasMatch(v)) {
                            return "Only letters, numbers, spaces, and . , ' / # -";
                          }
                          return null;
                        },
                      ),
                      _fieldGap(),

                      _label('PLACE'),
                      TextFormField(
                        controller: place,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                        decoration: _inputDeco(
                          hint: 'City / town / village',
                          icon: Icons.location_city_outlined,
                        ),
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) return "Required";
                          if (v.length < 2) return "At least 2 characters";
                          if (!RegExp(r"^[A-Za-z]+(?:[\s.'-][A-Za-z]+)*$")
                              .hasMatch(v)) {
                            return "Only letters, spaces, dots, apostrophes, or hyphens";
                          }
                          return null;
                        },
                      ),
                      _fieldGap(),

                      _label('POST OFFICE'),
                      TextFormField(
                        controller: post,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                        decoration: _inputDeco(
                          hint: 'Post office name',
                          icon: Icons.local_post_office_outlined,
                        ),
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) return "Required";
                          if (v.length < 2) return "At least 2 characters";
                          if (!RegExp(r"^[A-Za-z]+(?:[\s.'-][A-Za-z]+)*$")
                              .hasMatch(v)) {
                            return "Only letters, spaces, dots, apostrophes, or hyphens";
                          }
                          return null;
                        },
                      ),
                      _fieldGap(),

                      _label('PIN CODE'),
                      TextFormField(
                        controller: pin,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                        decoration: _inputDeco(
                          hint: '6-digit PIN code',
                          icon: Icons.pin_drop_outlined,
                        ).copyWith(counterText: ''),
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) return "Required";
                          if (!RegExp(r'^[1-9]\d{5}$').hasMatch(v)) {
                            return "Enter a valid 6-digit PIN (cannot start with 0)";
                          }
                          return null;
                        },
                      ),
                      _fieldGap(),

                      const SizedBox(height: 6),
                      // ══════════ SECURITY ══════════
                      _sectionHeader('ACCOUNT SECURITY', Icons.lock_rounded),
                      const SizedBox(height: 4),

                      _label('PASSWORD'),
                      TextFormField(
                        controller: password1,
                        obscureText: _obscureText1,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                        decoration: _inputDeco(
                          hint: '••••••••',
                          icon: Icons.key_rounded,
                          suffix: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscureText1 = !_obscureText1;
                              });
                            },
                            icon: Icon(
                              _obscureText1
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: _blue,
                              size: 20,
                            ),
                          ),
                        ),
                        validator: (value) {
                          final v = value ?? '';
                          if (v.isEmpty) return "Required";
                          if (!RegExp(r"^(?=.*\d)(?=.*[a-z])(?=.*[A-Z]).{8,}$")
                              .hasMatch(v)) {
                            return "Min 8 chars with 1 uppercase, 1 lowercase, 1 number";
                          }
                          return null;
                        },
                      ),
                      _fieldGap(),

                      _label('CONFIRM PASSWORD'),
                      TextFormField(
                        controller: password2,
                        obscureText: _obscureText2,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                        decoration: _inputDeco(
                          hint: '••••••••',
                          icon: Icons.key_rounded,
                          suffix: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscureText2 = !_obscureText2;
                              });
                            },
                            icon: Icon(
                              _obscureText2
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: _blue,
                              size: 20,
                            ),
                          ),
                        ),
                        validator: (value) {
                          final v = value ?? '';
                          if (v.isEmpty) return "Required";
                          if (!RegExp(r"^(?=.*\d)(?=.*[a-z])(?=.*[A-Z]).{8,}$")
                              .hasMatch(v)) {
                            return "Min 8 chars with 1 uppercase, 1 lowercase, 1 number";
                          }
                          if (password1.text != password2.text) {
                            return "Password mismatch";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 26),

                      // ── Register button ──
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _yellow,
                            foregroundColor: _charcoal,
                            elevation: 6,
                            shadowColor: _yellow.withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _isSubmitting
                              ? null
                              : () async {
                            if (!_formkey.currentState!.validate()) {
                              return;
                            }

                            setState(() => _isSubmitting = true);

                            try {
                              SharedPreferences prefs =
                              await SharedPreferences.getInstance();

                              var data = await http.post(
                                Uri.parse(
                                    "${prefs.getString("ip")}/user_register"),
                                body: {
                                  "name": name.text,
                                  "email": email.text,
                                  "phone": phone.text,
                                  "house": house.text,
                                  "street": street.text,
                                  "place": place.text,
                                  "post": post.text,
                                  "pin": pin.text,
                                  "password1": password1.text,
                                  "password2": password2.text,
                                },
                              );

                              if (!mounted) return;

                              // ── Interpret server response ──
                              // ── Interpret server response ──
                              final body = data.body.trim();
                              String? status;
                              String? serverMsg;
                              try {
                                final decoded = jsonDecode(body);
                                if (decoded is Map) {
                                  status = decoded['status']?.toString();
                                  serverMsg = decoded['message']?.toString();
                                }
                              } catch (_) {
                                serverMsg = body;
                              }

                              final bool isSuccess = status == 'success' ||
                                  body.toLowerCase() == 'success';

                              if (isSuccess) {
                                _showSnack('Registered successfully! Please login to continue.');

                                await Future.delayed(const Duration(milliseconds: 900));
                                if (!mounted) return;

                                Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => LoginPageSub()));
                              }
// ── Email already exists ──
                              else if (status == 'error' ||
                                  ((serverMsg ?? '').toLowerCase().contains('email') &&
                                      (serverMsg ?? '').toLowerCase().contains('exist'))) {
                                _showSnack('Email already exists. Please login or use another email.',
                                    isError: true);
                                setState(() => _isSubmitting = false);
                              }
// ── Any other error ──
                              else {
                                _showSnack(
                                  serverMsg ?? 'Registration failed. Please try again.',
                                  isError: true,
                                );
                                setState(() => _isSubmitting = false);
                              }
                            } catch (e) {
                              if (!mounted) return;
                              _showSnack(
                                  'Network error. Please check your connection.',
                                  isError: true);
                              setState(() => _isSubmitting = false);
                            }
                          },
                          child: _isSubmitting
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                              AlwaysStoppedAnimation<Color>(_charcoal),
                            ),
                          )
                              : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Register",
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.3,
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

                // ── Back to login ──
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _line, width: 1.2),
                  ),
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => LoginPageSub()));
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      overlayColor: _yellowSoft,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_back_rounded,
                          size: 16,
                          color: _blue,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Back to Login",
                          style: TextStyle(
                            fontSize: 14,
                            color: _blue,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}