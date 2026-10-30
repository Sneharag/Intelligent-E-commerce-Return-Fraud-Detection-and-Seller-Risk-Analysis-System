import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'userdashboard.dart';

class Sendfeedback extends StatefulWidget {
  const Sendfeedback({super.key});

  @override
  State<Sendfeedback> createState() => _SendfeedbackState();
}

class _SendfeedbackState extends State<Sendfeedback> {

  final TextEditingController _feedbackController = TextEditingController();
  bool _submitting = false;

  // ── E-commerce palette (yellow · charcoal · deep blue) ──
  static const Color _yellow     = Color(0xFFFACC15);
  static const Color _yellowDeep = Color(0xFFEAB308);
  static const Color _yellowSoft = Color(0xFFFEF9C3);

  static const Color _charcoal   = Color(0xFF1F2937);
  static const Color _ink        = Color(0xFF111827);
  static const Color _warmWhite  = Color(0xFFFAFAF9);
  static const Color _line       = Color(0xFFE7E5E4);
  static const Color _muted      = Color(0xFF78716C);
  static const Color _mutedSoft  = Color(0xFFA8A29E);

  static const Color _blue       = Color(0xFF1E3A8A);
  static const Color _blueMid    = Color(0xFF2563EB);
  static const Color _blueSoft   = Color(0xFFDBEAFE);

  static const Color _warn       = Color(0xFFC23D2C);

  Future<void> _sendFeedback() async {
    final text = _feedbackController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter your feedback"),
          backgroundColor: _warn,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var data = await http.post(
      Uri.parse("${prefs.getString("ip")}/user_sendfeedback"),
      body: {
        "user": prefs.getString("user"),
        "feedback": text,
      },
    );

    var jsonData = json.decode(data.body);
    setState(() => _submitting = false);

    if (jsonData["status"] == "success" || jsonData["status"] == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Feedback sent successfully"),
          backgroundColor: _charcoal,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _feedbackController.clear();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Userdashboard()),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(jsonData["message"] ?? "Failed to send feedback"),
          backgroundColor: _warn,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _warmWhite,
      appBar: AppBar(
        title: const Text(
          "Feedback",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
        ),
        backgroundColor: _charcoal,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero icon ──
              Center(
                child: Container(
                  width: 84,
                  height: 84,
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
                    Icons.forum_rounded,
                    size: 40,
                    color: _charcoal,
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // ── Heading ──
              const Center(
                child: Text(
                  "We value your feedback",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                    letterSpacing: -0.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  "Tell us what you think about ReturnGuard.\nYour feedback helps us improve.",
                  style: TextStyle(
                    fontSize: 13.5,
                    color: _muted,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 28),

              // ── Card ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _line, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: _charcoal.withOpacity(0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Label ──
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
                          "YOUR FEEDBACK",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: _blue,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── Text area ──
                    TextField(
                      controller: _feedbackController,
                      maxLines: 7,
                      maxLength: 500,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                        height: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText: "Write your feedback here...",
                        hintStyle: TextStyle(
                          color: _mutedSoft.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: _warmWhite,
                        counterStyle: const TextStyle(
                          color: _mutedSoft,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _line, width: 1.2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _line, width: 1.2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _yellowDeep, width: 2),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Send button ──
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _yellow,
                    foregroundColor: _charcoal,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _submitting ? null : _sendFeedback,
                  child: _submitting
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: _charcoal,
                      strokeWidth: 2.5,
                    ),
                  )
                      : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.send_rounded,
                        size: 18,
                        color: _charcoal,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Send Feedback",
                        style: TextStyle(
                          color: _charcoal,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Trust note ──
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 13,
                      color: _mutedSoft,
                    ),
                    SizedBox(width: 5),
                    Text(
                      "Your feedback is kept confidential",
                      style: TextStyle(
                        fontSize: 11.5,
                        color: _mutedSoft,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}