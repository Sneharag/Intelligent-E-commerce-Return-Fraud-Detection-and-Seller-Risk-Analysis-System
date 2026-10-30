import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'login.dart';

class Changepassword extends StatefulWidget {
  const Changepassword({super.key});

  @override
  State<Changepassword> createState() => _ChangepasswordState();
}

class _ChangepasswordState extends State<Changepassword> {
  final _formkey = GlobalKey<FormState>();

  final TextEditingController currentpswd = TextEditingController();
  final TextEditingController newpswd     = TextEditingController();
  final TextEditingController confirmpswd = TextEditingController();

  bool _obscureText1 = true;
  bool _obscureText2 = true;
  bool _obscureText3 = true;
  bool _isLoading   = false;

  // ── E-commerce palette (yellow · charcoal · deep blue) ──
  static const Color _yellow     = Color(0xFFFACC15);
  static const Color _yellowDeep = Color(0xFFEAB308);
  static const Color _yellowSoft = Color(0xFFFEF9C3);

  static const Color _charcoal   = Color(0xFF1F2937);
  static const Color _charcoalDk = Color(0xFF111827);
  static const Color _ink        = Color(0xFF111827);
  static const Color _warmWhite  = Color(0xFFFAFAF9);
  static const Color _line       = Color(0xFFE7E5E4);
  static const Color _muted      = Color(0xFF78716C);
  static const Color _mutedSoft  = Color(0xFFA8A29E);

  static const Color _blue       = Color(0xFF1E3A8A);
  static const Color _blueMid    = Color(0xFF2563EB);
  static const Color _blueSoft   = Color(0xFFDBEAFE);

  static const Color _warn       = Color(0xFFC23D2C);
  static const Color _green      = Color(0xFF059669);
  static const Color _greenSoft  = Color(0xFFD1FAE5);

  @override
  void dispose() {
    currentpswd.dispose();
    newpswd.dispose();
    confirmpswd.dispose();
    super.dispose();
  }

  InputDecoration _inputDeco({
    required String hint,
    required IconData icon,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: _mutedSoft,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 6, right: 4),
        child: Icon(icon, color: _charcoal, size: 20),
      ),
      suffixIcon: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: IconButton(
          onPressed: onToggle,
          splashRadius: 20,
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: _muted,
            size: 20,
          ),
        ),
      ),
      filled: true,
      fillColor: _warmWhite,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
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
        borderSide: const BorderSide(color: _warn, width: 1.6),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _warn, width: 2),
      ),
    );
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return "Required";
    if (!RegExp(r"^(?=.*\d)(?=.*[a-z])(?=.*[A-Z]).{8,}$").hasMatch(value)) {
      return "Min 8 chars, at least 1 number, 1 lowercase, 1 uppercase";
    }
    return null;
  }

  // ── Password strength calculation for the meter ──
  int _strengthScore(String pw) {
    int score = 0;
    if (pw.length >= 8) score++;
    if (RegExp(r"[A-Z]").hasMatch(pw)) score++;
    if (RegExp(r"[a-z]").hasMatch(pw)) score++;
    if (RegExp(r"\d").hasMatch(pw)) score++;
    if (RegExp(r"[^A-Za-z0-9]").hasMatch(pw)) score++;
    return score;
  }

  Future<void> _submit() async {
    if (!_formkey.currentState!.validate()) return;

    if (newpswd.text != confirmpswd.text) {
      _showSnack("New password and confirm password do not match", _warn);
      return;
    }
    if (newpswd.text == currentpswd.text) {
      _showSnack("New password must differ from current password", _warn);
      return;
    }

    setState(() => _isLoading = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      var response = await http.post(
        Uri.parse("${prefs.getString("ip")}/user_change_password"),
        body: {
          "currentpassword": currentpswd.text,
          "newpassword":     newpswd.text,
          "user":            prefs.getString("user"),
        },
      );

      debugPrint("PSWD status=${response.statusCode} body=${response.body}");

      if (response.statusCode != 200) {
        _showSnack("Server error. Please try again.", _warn);
        return;
      }

      final jsonData = json.decode(response.body);
      final status   = jsonData['status']?.toString();

      if (status == 'incorrect') {
        _showSnack("Current password is incorrect", _warn);
        return;
      }

      if (status == 'success') {
        if (!mounted) return;
        _showSnack("Password updated successfully", _green);

        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => LoginPageSub()),
                (route) => false);
      } else {
        _showSnack(
          jsonData['message']?.toString() ?? "Failed to update password",
          _warn,
        );
      }
    } catch (e) {
      debugPrint("Change password error: $e");
      _showSnack("Failed to update password. Please try again.", _warn);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          ),
        ),
        duration: const Duration(seconds: 4),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _warmWhite,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ══════════ HERO HEADER ══════════
            // ══════════ HERO HEADER ══════════
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_charcoalDk, _charcoal, Color(0xFF374151)],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top row: back arrow + SECURE badge ──
                  Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // ── Title inline with back arrow ──
                      const Expanded(
                        child: Text(
                          "Change Password",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                      ),

                      // ── SECURE pill ──
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _yellow.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: _yellow.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: _yellow,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              "SECURE",
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: _yellow,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ── Compact icon + subtitle row ──
                  Row(
                    children: [
                      // ── Small yellow icon chip ──
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [_yellow, _yellowDeep],
                          ),
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: [
                            BoxShadow(
                              color: _yellow.withOpacity(0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_reset_rounded,
                          size: 22,
                          color: _charcoal,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // ── Subtitle ──
                      Expanded(
                        child: Text(
                          "Update your account password to keep it safe & secure.",
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.white.withOpacity(0.65),
                            fontWeight: FontWeight.w500,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ══════════ FORM ══════════
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Form(
                  key: _formkey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Section label ──
                      _sectionLabel(
                        icon: Icons.shield_outlined,
                        text: "SECURITY",
                      ),
                      const SizedBox(height: 14),

                      // ── Current password ──
                      _fieldLabel("Current Password"),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: currentpswd,
                        obscureText: _obscureText1,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                        validator: _validatePassword,
                        decoration: _inputDeco(
                          hint: 'Enter current password',
                          icon: Icons.lock_outline_rounded,
                          obscure: _obscureText1,
                          onToggle: () =>
                              setState(() => _obscureText1 = !_obscureText1),
                        ),
                      ),
                      const SizedBox(height: 20),

                      _sectionLabel(
                        icon: Icons.key_rounded,
                        text: "NEW PASSWORD",
                      ),
                      const SizedBox(height: 14),

                      // ── New password ──
                      _fieldLabel("New Password"),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: newpswd,
                        obscureText: _obscureText2,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                        validator: _validatePassword,
                        decoration: _inputDeco(
                          hint: 'Enter new password',
                          icon: Icons.lock_person_outlined,
                          obscure: _obscureText2,
                          onToggle: () =>
                              setState(() => _obscureText2 = !_obscureText2),
                        ),
                      ),

                      // ── Live strength meter ──
                      if (newpswd.text.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _strengthMeter(newpswd.text),
                      ],

                      const SizedBox(height: 16),

                      // ── Confirm password ──
                      _fieldLabel("Confirm New Password"),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: confirmpswd,
                        obscureText: _obscureText3,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                        validator: (value) {
                          final base = _validatePassword(value);
                          if (base != null) return base;
                          if (value != newpswd.text) {
                            return "Passwords do not match";
                          }
                          return null;
                        },
                        decoration: _inputDeco(
                          hint: 'Re-enter new password',
                          icon: Icons.lock_person_outlined,
                          obscure: _obscureText3,
                          onToggle: () =>
                              setState(() => _obscureText3 = !_obscureText3),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ══════════ UPDATE BUTTON ══════════
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _charcoal,
                            foregroundColor: _yellow,
                            disabledBackgroundColor: _charcoal.withOpacity(0.6),
                            elevation: 6,
                            shadowColor: _charcoal.withOpacity(0.35),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  _yellow),
                            ),
                          )
                              : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 18,
                                color: _yellow,
                              ),
                              SizedBox(width: 10),
                              Text(
                                "Update Password",
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.3,
                                  color: _yellow,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ── Help note ──
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _yellowSoft.withOpacity(0.6),
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
                              size: 16,
                              color: _charcoal,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "After updating your password, you'll be signed out and asked to log in again for security.",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _ink.withOpacity(0.85),
                                  fontWeight: FontWeight.w600,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section label (uppercase, small, with icon) ──
  Widget _sectionLabel({required IconData icon, required String text}) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: _yellowSoft,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _yellow.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Icon(icon, size: 13, color: _charcoal),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: _charcoal,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _yellow.withOpacity(0.5),
                  _yellow.withOpacity(0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Field label (small above input) ──
  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: _ink,
        letterSpacing: 0.2,
      ),
    );
  }

  // ── Strength meter ──
  Widget _strengthMeter(String pw) {
    final score = _strengthScore(pw);

    String label;
    Color color;
    int bars;

    if (score <= 2) {
      label = "Weak";
      color = _warn;
      bars = 1;
    } else if (score == 3) {
      label = "Fair";
      color = _yellowDeep;
      bars = 2;
    } else if (score == 4) {
      label = "Good";
      color = _blueMid;
      bars = 3;
    } else {
      label = "Strong";
      color = _green;
      bars = 4;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _line, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "Strength: ",
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: _muted,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(4, (i) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 3 ? 5 : 0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 5,
                    decoration: BoxDecoration(
                      color: i < bars ? color : _line,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}