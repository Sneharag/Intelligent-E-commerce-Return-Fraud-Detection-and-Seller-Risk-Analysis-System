import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'forgotemail.dart';
import 'forgotpass.dart';

void main() {
  runApp(forgototp());
}

class forgototp extends StatelessWidget {
  const forgototp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: forgototpsub(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFACC15)),
        fontFamily: 'Roboto',
      ),
    );
  }
}

class forgototpsub extends StatefulWidget {
  const forgototpsub({Key? key}) : super(key: key);

  @override
  State<forgototpsub> createState() => _forgototpsubState();
}

class _forgototpsubState extends State<forgototpsub> {
  // List of 6 TextEditingController for each OTP digit
  List<TextEditingController> otpControllers = List.generate(6, (index) => TextEditingController());
  List<FocusNode> focusNodes = List.generate(6, (index) => FocusNode());

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isResending = false;
  int _resendCooldown = 0;
  int _otpExpirySeconds = 600; // 10 minutes = 600 seconds
  Timer? _resendTimer;
  Timer? _expiryTimer;
  DateTime? _otpGeneratedTime;
  bool _isOtpExpired = false;

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

  @override
  void initState() {
    super.initState();
    _loadOtpGenerationTime();
    _startResendCooldown();
    _startOtpExpiryTimer();

    // Set up focus listeners for auto-navigation
    for (int i = 0; i < focusNodes.length; i++) {
      focusNodes[i].addListener(() {
        if (!focusNodes[i].hasFocus && i < 5 && otpControllers[i].text.isNotEmpty) {
          FocusScope.of(context).requestFocus(focusNodes[i + 1]);
        }
      });
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _expiryTimer?.cancel();
    for (var controller in otpControllers) {
      controller.dispose();
    }
    for (var focusNode in focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  // Get the complete OTP from all boxes
  String getCompleteOTP() {
    return otpControllers.map((controller) => controller.text).join();
  }

  // Clear all OTP boxes
  void clearOTP() {
    for (var controller in otpControllers) {
      controller.clear();
    }
    FocusScope.of(context).requestFocus(focusNodes[0]);
  }

  // Handle text input for each OTP box
  void _handleOTPInput(String value, int index) {
    if (value.length == 1 && index < 5) {
      // Move to next box
      FocusScope.of(context).requestFocus(focusNodes[index + 1]);
    } else if (value.isEmpty && index > 0) {
      // Move to previous box on backspace
      FocusScope.of(context).requestFocus(focusNodes[index - 1]);
    }
  }

  Future<void> _loadOtpGenerationTime() async {
    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String? timestamp = sh.getString('otp_generated_time');
      if (timestamp != null) {
        _otpGeneratedTime = DateTime.parse(timestamp);
        _updateOtpExpiryStatus();
      }
    } catch (e) {
      print("Error loading OTP time: $e");
    }
  }

  void _updateOtpExpiryStatus() {
    if (_otpGeneratedTime != null) {
      DateTime now = DateTime.now();
      Duration difference = now.difference(_otpGeneratedTime!);
      int remainingSeconds = 600 - difference.inSeconds;

      remainingSeconds = remainingSeconds.clamp(0, 600);

      setState(() {
        _otpExpirySeconds = remainingSeconds;
        _isOtpExpired = remainingSeconds <= 0;
      });
    }
  }

  void _startOtpExpiryTimer() {
    _expiryTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_otpExpirySeconds > 0) {
        setState(() {
          _otpExpirySeconds--;
          if (_otpExpirySeconds <= 0) {
            _isOtpExpired = true;
          }
        });
      } else {
        setState(() {
          _isOtpExpired = true;
        });
        timer.cancel();
      }
    });
  }

  void _startResendCooldown() {
    setState(() {
      _resendCooldown = 30;
    });

    _resendTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() {
          _resendCooldown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  String _formatTime(int totalSeconds) {
    if (totalSeconds.isNaN || totalSeconds < 0) {
      return "00:00";
    }

    totalSeconds = totalSeconds.clamp(0, 600);

    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _verifyOTP() async {
    String otp = getCompleteOTP();

    if (otp.length != 6) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            "Incomplete OTP",
            style: TextStyle(
              color: _ink,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "Please enter all 6 digits of the OTP.",
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
                FocusScope.of(context).requestFocus(focusNodes[0]);
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
      return;
    }

    if (_isOtpExpired) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            "OTP Expired",
            style: TextStyle(
              color: _warn,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "This OTP has expired. Please request a new one.",
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
                _resendOTP();
              },
              child: Text(
                "GET NEW OTP",
                style: TextStyle(
                  color: _charcoal,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      // await http.post(
      //   Uri.parse("${sh.getString("ip")}/forgototp"),
      //   body: {'otp': otp},
      // );

      String? otpp = sh.getString('otpp');
      if (otp == otpp) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP verified successfully!'),
            backgroundColor: _charcoal,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.push(context, MaterialPageRoute(builder: (context) => forgotpass()));
      } else {
        // Shake animation or clear OTP for wrong input
        clearOTP();
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              "Invalid OTP",
              style: TextStyle(
                color: _warn,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              "The OTP you entered is incorrect. Please check and try again.",
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
                  FocusScope.of(context).requestFocus(focusNodes[0]);
                },
                child: Text(
                  "TRY AGAIN",
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
            "Verification Failed",
            style: TextStyle(
              color: _warn,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "Unable to verify OTP. Please check your connection and try again.",
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

  Future<void> _resendOTP() async {
    setState(() {
      _isResending = true;
    });

    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String? email = sh.getString("email");

      if (email != null) {
        var res = await http.post(
          Uri.parse("${sh.getString("ip")}/forgotemail"),
          body: {'email': email},
        );

        var decode = json.decode(res.body);
        if (decode["status"] == "ok") {
          sh.setString("otpp", decode['otpp'].toString());
          sh.setString("otp_generated_time", DateTime.now().toIso8601String());

          setState(() {
            _otpGeneratedTime = DateTime.now();
            _isOtpExpired = false;
            _otpExpirySeconds = 600;
          });

          _resendTimer?.cancel();
          _expiryTimer?.cancel();
          _startResendCooldown();
          _startOtpExpiryTimer();

          // Clear OTP boxes when new OTP is sent
          clearOTP();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('New OTP sent to your email!'),
              backgroundColor: _charcoal,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to resend OTP. Please try again.'),
          backgroundColor: _warn,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isResending = false;
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
            Navigator.push(context, MaterialPageRoute(builder: (context) => forgotemail()));
          },
        ),
        centerTitle: true,
        title: const Text(
          "Verify OTP",
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
          padding: EdgeInsets.all(20),
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
                  Icons.verified_user_rounded,
                  size: 42,
                  color: _charcoal,
                ),
              ),
              const SizedBox(height: 20),

              // ── Heading ──
              const Text(
                'Enter OTP',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "We've sent a 6-digit verification code to your email",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: _muted,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // ── Expiry Timer ──
              if (_otpExpirySeconds >= 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: _isOtpExpired ? _yellowSoft : _warmWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isOtpExpired
                          ? _warn.withOpacity(0.4)
                          : _yellow.withOpacity(0.5),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isOtpExpired ? Icons.warning_amber_rounded : Icons.timer_outlined,
                        color: _isOtpExpired ? _warn : _charcoal,
                        size: 18,
                      ),
                      SizedBox(width: 10),
                      Text(
                        _isOtpExpired
                            ? 'OTP Expired!'
                            : 'Expires in ${_formatTime(_otpExpirySeconds)}',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: _isOtpExpired ? _warn : _charcoal,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // ── OTP Card ──
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(22),
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
                          'VERIFICATION CODE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _muted,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── OTP Boxes Row ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: 44,
                          height: 58,
                          child: Container(
                            decoration: BoxDecoration(
                              color: _warmWhite,
                              border: Border.all(
                                color: focusNodes[index].hasFocus
                                    ? _yellowDeep
                                    : _line,
                                width: focusNodes[index].hasFocus ? 2 : 1.2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: TextFormField(
                                controller: otpControllers[index],
                                focusNode: focusNodes[index],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                maxLength: 1,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: _ink,
                                ),
                                decoration: const InputDecoration(
                                  counterText: '',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (value) {
                                  _handleOTPInput(value, index);
                                  setState(() {});
                                },
                              ),
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 20),

                    // ── Clear OTP ──
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton(
                        onPressed: clearOTP,
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: _line, width: 1.4),
                          foregroundColor: _muted,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.clear_rounded, size: 16, color: _muted),
                            SizedBox(width: 8),
                            Text(
                              'Clear OTP',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'Tap each box to enter the 6-digit code',
                        style: TextStyle(
                          fontSize: 12,
                          color: _mutedSoft.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ── Verify Button ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (_isLoading || _isOtpExpired) ? null : _verifyOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isOtpExpired ? _mutedSoft : _yellow,
                    foregroundColor: _charcoal,
                    disabledBackgroundColor: _mutedSoft.withOpacity(0.5),
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
                      valueColor: AlwaysStoppedAnimation<Color>(_charcoal),
                    ),
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isOtpExpired ? Icons.timer_off_rounded : Icons.verified_rounded,
                        size: 18,
                        color: _charcoal,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isOtpExpired ? 'OTP Expired' : 'Verify OTP',
                        style: const TextStyle(
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

              // ── Resend Section ──
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _line, width: 1.2),
                ),
                child: Column(
                  children: [
                    Text(
                      "Didn't receive the code?",
                      style: TextStyle(
                        fontSize: 13.5,
                        color: _muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _resendCooldown > 0
                        ? Column(
                      children: [
                        Text(
                          "Resend available in $_resendCooldown s",
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: _charcoal,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: LinearProgressIndicator(
                            value: _resendCooldown / 30,
                            backgroundColor: _line,
                            color: _yellow,
                            minHeight: 5,
                          ),
                        ),
                      ],
                    )
                        : SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton(
                        onPressed: _isResending ? null : _resendOTP,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _charcoal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: _yellowDeep, width: 1.4),
                          ),
                        ),
                        child: _isResending
                            ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                            AlwaysStoppedAnimation<Color>(_yellowDeep),
                          ),
                        )
                            : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.refresh_rounded, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Resend OTP',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ── Help Note ──
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _yellowSoft,
                  borderRadius: BorderRadius.circular(16),
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
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "OTP Information",
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: _charcoal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "• Each OTP is valid for 10 minutes only\n"
                          "• Request a new OTP if it expires\n"
                          "• Make sure to enter the code exactly as it appears\n"
                          "• Use clear button to reset all boxes",
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

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}