import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Return Fraud Detection',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFACC15)),
      ),
      home: const MyHomePage(title: 'IP Settings'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController ip = TextEditingController(text: '192.168.29.137');
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _savedIp = '';

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
  void dispose() {
    ip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _warmWhite,
      appBar: AppBar(
        backgroundColor: _charcoal,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Big Logo ──
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      // border: Border.all(color: _line, width: 1.2),
                      // boxShadow: [
                      //   BoxShadow(
                      //     color: _yellow.withOpacity(0.35),
                      //     blurRadius: 24,
                      //     offset: const Offset(0, 12),
                      //   ),
                      // ],
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Image.asset(
                      'assets/images/returnlogo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.shield_rounded,
                          size: 42,
                          color: _charcoal,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 22),

                  // ── Project Name ──
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                        letterSpacing: -0.6,
                      ),
                      children: [
                        TextSpan(text: 'Return'),
                        TextSpan(
                          text: 'Guard',
                          style: TextStyle(color: _yellowDeep),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter the server address to connect',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: _muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),

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
                              'SERVER IP',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: _muted,
                                letterSpacing: 1.4,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // ── IP Field ──
                        TextFormField(
                          controller: ip,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _ink,
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g. 192.168.1.100',
                            hintStyle: TextStyle(
                              color: _mutedSoft.withOpacity(0.7),
                              fontWeight: FontWeight.w400,
                            ),
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(left: 4, right: 4),
                              child: Icon(
                                Icons.dns_rounded,
                                color: _charcoal,
                                size: 20,
                              ),
                            ),
                            filled: true,
                            fillColor: _warmWhite,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 18,
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
                            if (value == null || value.isEmpty) {
                              return "Required";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 22),

                        // ── Button ──
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (!_formKey.currentState!.validate()) return;

                              SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                              await prefs.setString(
                                  "ip", "http://${ip.text}:8000/myapp");

                              setState(() {
                                _savedIp = "http://${ip.text}:8000/myapp";
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('IP set to: $_savedIp'),
                                  backgroundColor: _charcoal,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );

                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => LoginPageSub()));
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
                                  "Save & Continue",
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

                  const SizedBox(height: 24),

                  // ── Footer note ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 13,
                        color: _mutedSoft.withOpacity(0.8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Your IP is stored locally on this device',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: _mutedSoft.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}