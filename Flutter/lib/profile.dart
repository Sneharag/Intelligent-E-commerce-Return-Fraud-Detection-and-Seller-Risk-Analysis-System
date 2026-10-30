import 'dart:convert';

import 'package:ecommerce_return_fraud_detection/userdashboard.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  @override

  var _formkey = GlobalKey<FormState>();
  TextEditingController name = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController phone = TextEditingController();
  TextEditingController house = TextEditingController();
  TextEditingController street = TextEditingController();
  TextEditingController place = TextEditingController();
  TextEditingController post = TextEditingController();
  TextEditingController pin = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingData = true;

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

  InputDecoration _inputDeco({
    required String hint,
    required IconData icon,
    bool readOnly = false,
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
        child: Icon(
          icon,
          color: readOnly ? _mutedSoft : _blue,
          size: 20,
        ),
      ),
      filled: true,
      fillColor: readOnly ? _line.withOpacity(0.35) : _warmWhite,
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
        borderSide: const BorderSide(color: _warn, width: 1.6),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _warn, width: 2),
      ),
    );
  }

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

  // ── Hero header card ──
  Widget _heroHeader() {
    final initial = (name.text.isNotEmpty)
        ? name.text.trim()[0].toUpperCase()
        : 'U';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_charcoal, Color(0xFF374151)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _charcoal.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Avatar ──
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_yellow, _yellowDeep],
              ),
              boxShadow: [
                BoxShadow(
                  color: _yellow.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _charcoal,
                border: Border.all(color: _charcoal, width: 3),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: _yellow,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ── Name ──
          Text(
            name.text.isNotEmpty ? name.text : 'Loading…',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          // ── Email ──
          Text(
            email.text.isNotEmpty ? email.text : '',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),

          // ── Verified pill ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _yellow.withOpacity(0.15),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: _yellow.withOpacity(0.5), width: 1),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded, size: 14, color: _yellow),
                SizedBox(width: 6),
                Text(
                  'Verified Account',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: _yellow,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stat chip row ──
  Widget _statChip({
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _line, width: 1.2),
        ),
        child: Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 17, color: accent),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: _ink,
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: _muted,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> getData() async {
    setState(() {
      _isLoadingData = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var data = await http.post(
        Uri.parse("${prefs.getString("ip")}/flutter_user"),
        body: {"user": prefs.getString("user")});

    var jsonData = json.decode(data.body);
    name.text   = jsonData['name'].toString();
    email.text  = jsonData['email'].toString();
    phone.text  = jsonData['phone'].toString();
    house.text  = jsonData['house'].toString();
    street.text = jsonData['street']?.toString() ?? "";
    place.text  = jsonData['place'].toString();
    post.text   = jsonData['post'].toString();
    pin.text    = jsonData['pin'].toString();

    setState(() {
      _isLoadingData = false;
    });
  }

  @override
  void initState() {
    super.initState();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _warmWhite,
      appBar: AppBar(
        title: const Text(
          "My Profile",
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
      body: _isLoadingData
          ? const Center(
        child: CircularProgressIndicator(color: _yellowDeep),
      )
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: _formkey,
            child: Column(
              children: [
                const SizedBox(height: 4),

                // ══════════ HERO HEADER ══════════
                _heroHeader(),
                const SizedBox(height: 16),

                // ══════════ STAT CHIPS ══════════
                Row(
                  children: [
                    _statChip(
                      icon: Icons.person_rounded,
                      label: 'NAME',
                      value: name.text.isNotEmpty
                          ? name.text.split(' ').first
                          : '—',
                      accent: _blue,
                    ),
                    const SizedBox(width: 10),
                    _statChip(
                      icon: Icons.phone_rounded,
                      label: 'PHONE',
                      value: phone.text.isNotEmpty ? phone.text : '—',
                      accent: _yellowDeep,
                    ),
                    const SizedBox(width: 10),
                    _statChip(
                      icon: Icons.pin_drop_rounded,
                      label: 'PIN',
                      value: pin.text.isNotEmpty ? pin.text : '—',
                      accent: _charcoal,
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // ══════════ FORM CARD ══════════
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: _yellow.withOpacity(0.35),
                      width: 1.6,
                    ),
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
                        keyboardType: TextInputType.name,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                        validator: (value) {
                          if (value == null) {
                            return "Required";
                          }
                          if (!RegExp(r"^[a-zA-Z]+(?:[\s.'-][a-zA-Z]+)*$")
                              .hasMatch(value)) {
                            return "Only letters, spaces, dots, apostrophes, or hyphens";
                          }
                          return null;
                        },
                        decoration: _inputDeco(
                          hint: 'Enter your name',
                          icon: Icons.person_outline_rounded,
                        ),
                      ),
                      const SizedBox(height: 18),

                      _label('EMAIL'),
                      TextFormField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        readOnly: true,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _mutedSoft,
                        ),
                        validator: (value) {
                          if (value == null) {
                            return "Required";
                          }
                          if (!RegExp(
                              r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
                              .hasMatch(value)) {
                            return "Enter a valid email address";
                          }
                          return null;
                        },
                        decoration: _inputDeco(
                          hint: 'you@example.com',
                          icon: Icons.mail_outline_rounded,
                          readOnly: true,
                        ),
                      ),
                      const SizedBox(height: 18),

                      _label('PHONE'),
                      TextFormField(
                        controller: phone,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                        validator: (value) {
                          if (value == null) {
                            return "Required";
                          }
                          if (!RegExp(r"^\+?[\d\s-]{8,15}$").hasMatch(value)) {
                            return "Enter a valid phone number (8–15 digits)";
                          }
                          return null;
                        },
                        decoration: _inputDeco(
                          hint: '10-digit mobile number',
                          icon: Icons.phone_outlined,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ══════════ ADDRESS DETAILS ══════════
                      _sectionHeader('ADDRESS DETAILS', Icons.home_rounded),
                      const SizedBox(height: 4),

                      _label('HOUSE'),
                      TextFormField(
                        controller: house,
                        keyboardType: TextInputType.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                        validator: (value) {
                          if (value == null) {
                            return "Required";
                          }
                          if (!RegExp(r"^[a-zA-Z]+(?:[\s.'-][a-zA-Z]+)*$")
                              .hasMatch(value)) {
                            return "Only letters, spaces, dots, apostrophes, or hyphens";
                          }
                          return null;
                        },
                        decoration: _inputDeco(
                          hint: 'House name or number',
                          icon: Icons.home_outlined,
                        ),
                      ),
                      const SizedBox(height: 18),

                      _label('STREET'),
                      TextFormField(
                        controller: street,
                        keyboardType: TextInputType.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                        validator: (value) {
                          if (value == null) {
                            return "Required";
                          }
                          if (!RegExp(r"^[a-zA-Z]+(?:[\s.'-][a-zA-Z]+)*$")
                              .hasMatch(value)) {
                            return "Only letters, spaces, dots, apostrophes, or hyphens";
                          }
                          return null;
                        },
                        decoration: _inputDeco(
                          hint: 'Street name',
                          icon: Icons.signpost_outlined,
                        ),
                      ),
                      const SizedBox(height: 18),

                      _label('PLACE'),
                      TextFormField(
                        controller: place,
                        keyboardType: TextInputType.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                        validator: (value) {
                          if (value == null) {
                            return "Required";
                          }
                          if (!RegExp(r"^[a-zA-Z]+(?:[\s.'-][a-zA-Z]+)*$")
                              .hasMatch(value)) {
                            return "Only letters, spaces, dots, apostrophes, or hyphens";
                          }
                          return null;
                        },
                        decoration: _inputDeco(
                          hint: 'City / town / village',
                          icon: Icons.location_city_outlined,
                        ),
                      ),
                      const SizedBox(height: 18),

                      _label('POST OFFICE'),
                      TextFormField(
                        controller: post,
                        keyboardType: TextInputType.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                        validator: (value) {
                          if (value == null) {
                            return "Required";
                          }
                          if (!RegExp(r"^[a-zA-Z]+(?:[\s.'-][a-zA-Z]+)*$")
                              .hasMatch(value)) {
                            return "Only letters, spaces, dots, apostrophes, or hyphens";
                          }
                          return null;
                        },
                        decoration: _inputDeco(
                          hint: 'Post office name',
                          icon: Icons.local_post_office_outlined,
                        ),
                      ),
                      const SizedBox(height: 18),

                      _label('PIN CODE'),
                      TextFormField(
                        controller: pin,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                        validator: (value) {
                          if (value == null) {
                            return "Required";
                          }
                          if (!RegExp(r"^\d{6}$").hasMatch(value)) {
                            return "Enter a 6-digit PIN";
                          }
                          return null;
                        },
                        decoration: _inputDeco(
                          hint: '6-digit PIN code',
                          icon: Icons.pin_drop_outlined,
                        ),
                      ),
                      const SizedBox(height: 26),

                      // ── Update button ──
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () async {
                            if (_formkey.currentState!.validate()) {
                              setState(() {
                                _isLoading = true;
                              });

                              try {
                                SharedPreferences prefs =
                                await SharedPreferences
                                    .getInstance();

                                var data = await http.post(
                                  Uri.parse(
                                      "${prefs.getString("ip")}/user_profile"),
                                  body: {
                                    "user_id": prefs.getString("user").toString(),
                                    "name": name.text.toString(),
                                    "email": email.text.toString(),
                                    "phone": phone.text.toString(),
                                    "house": house.text.toString(),
                                    "street": street.text.toString(),
                                    "place": place.text.toString(),
                                    "post": post.text.toString(),
                                    "pin": pin.text.toString(),
                                  },
                                );

                                var decodeddata =
                                json.decode(data.body);
                                print("$decodeddata vggvgv");

                                if (decodeddata["status"] ==
                                    "no changes") {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              Userdashboard()));
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                          "No changes made"),
                                      duration:
                                      const Duration(seconds: 5),
                                      backgroundColor: _blue,
                                      behavior: SnackBarBehavior
                                          .floating,
                                    ),
                                  );
                                } else {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              Userdashboard()));
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                          "Updated Successfully"),
                                      duration:
                                      const Duration(seconds: 5),
                                      backgroundColor: _charcoal,
                                      behavior: SnackBarBehavior
                                          .floating,
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                        "Failed to update. Please try again."),
                                    duration:
                                    const Duration(seconds: 5),
                                    backgroundColor: _warn,
                                    behavior:
                                    SnackBarBehavior.floating,
                                  ),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _isLoading = false;
                                  });
                                }
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _yellow,
                            foregroundColor: _charcoal,
                            disabledBackgroundColor:
                            _yellow.withOpacity(0.6),
                            elevation: 6,
                            shadowColor: _yellow.withOpacity(0.5),
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
                              AlwaysStoppedAnimation<Color>(
                                  _charcoal),
                            ),
                          )
                              : const Row(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              Text(
                                "Save Changes",
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.3,
                                  color: _charcoal,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.check_circle_outline_rounded,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}