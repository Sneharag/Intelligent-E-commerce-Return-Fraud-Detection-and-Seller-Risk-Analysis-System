import 'forgotemail.dart';
import 'login.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(forgotpass());
}

class forgotpass extends StatelessWidget {
  const forgotpass({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: forgotpasssub(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFACC15)),
        fontFamily: 'Roboto',
      ),
    );
  }
}

class forgotpasssub extends StatefulWidget {
  const forgotpasssub({Key? key}) : super(key: key);

  @override
  State<forgotpasssub> createState() => _forgotpasssubState();
}

class _forgotpasssubState extends State<forgotpasssub> {
  TextEditingController password = TextEditingController();
  TextEditingController confirmpassword = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
  static const Color _warn       = Color(0xFFC23D2C);

  InputDecoration _inputDeco({
    required String hint,
    required IconData icon,
    required bool obscured,
    required VoidCallback onToggle,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: _mutedSoft.withOpacity(0.7),
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: Icon(icon, color: _charcoal, size: 20),
      suffixIcon: IconButton(
        onPressed: onToggle,
        icon: Icon(
          obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
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
        borderSide: const BorderSide(color: _line, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _yellowDeep, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _warn, width: 1.4),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _warn, width: 1.6),
      ),
    );
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (password.text != confirmpassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: _warn,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      await http.post(
        Uri.parse("${sh.getString("ip")}/forgotpass"),
        body: {
          'email': sh.getString('email'),
          'password': password.text,
          'confirmpassword': confirmpassword.text
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset successfully!'),
          backgroundColor: _charcoal,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => LoginPageSub()),
            (route) => false,);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reset password. Please try again.'),
          backgroundColor: _warn,
          behavior: SnackBarBehavior.floating,
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
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => forgotemail()));
          },
        ),
        centerTitle: true,
        title: const Text(
          "Reset Password",
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
                  'Reset Password',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Create a new password for your account",
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
                      // ── New Password label ──
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
                            'NEW PASSWORD',
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
                        controller: password,
                        obscureText: _obscurePassword,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _ink,
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
                        decoration: _inputDeco(
                          hint: '••••••••',
                          icon: Icons.lock_outline_rounded,
                          obscured: _obscurePassword,
                          onToggle: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ── Confirm Password label ──
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
                            'CONFIRM NEW PASSWORD',
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
                        controller: confirmpassword,
                        obscureText: _obscureConfirmPassword,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _ink,
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
                        decoration: _inputDeco(
                          hint: '••••••••',
                          icon: Icons.lock_outline_rounded,
                          obscured: _obscureConfirmPassword,
                          onToggle: () {
                            setState(() {
                              _obscureConfirmPassword =
                              !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ── Password Requirements ──
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _yellowSoft,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _yellow.withOpacity(0.5),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  color: _charcoal,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Password Requirements',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: _charcoal,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '• At least 8 characters long\n'
                                  '• Include 1 uppercase letter (A–Z)\n'
                                  '• Include 1 lowercase letter (a–z)\n'
                                  '• Include 1 number (0–9)\n'
                                  '• Make sure both passwords match',
                              style: TextStyle(
                                fontSize: 12,
                                color: _ink.withOpacity(0.85),
                                fontWeight: FontWeight.w500,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // ── Reset Password Button ──
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _yellow,
                      foregroundColor: _charcoal,
                      disabledBackgroundColor: _yellow.withOpacity(0.6),
                      elevation: 0,
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
                        Icon(Icons.lock_reset_rounded,
                            size: 18, color: _charcoal),
                        SizedBox(width: 8),
                        Text(
                          'Reset Password',
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

                const SizedBox(height: 18),

                // ── Security Info ──
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _warmWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _yellow.withOpacity(0.5),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.security_rounded,
                        color: _charcoal,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Your password will be securely updated. You can then log in with your new password.",
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