import 'package:ecommerce_return_fraud_detection/userdashboard.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'Orders.dart';

class Sendreview extends StatefulWidget {
  const Sendreview({super.key});

  @override
  State<Sendreview> createState() => _SendreviewState();
}

class _SendreviewState extends State<Sendreview> {
  final _formkey = GlobalKey<FormState>();
  TextEditingController review = TextEditingController();
  int ratings = 3;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _warmWhite,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _charcoal,
        foregroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Write a Review",
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formkey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ------------------------------------------------
                // HEADER SECTION
                // ------------------------------------------------
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _line, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: _charcoal.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 72,
                        width: 72,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [_yellow, _yellowDeep],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _yellow.withOpacity(0.4),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.rate_review_rounded,
                          size: 32,
                          color: _charcoal,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        "How was your order?",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          color: _ink,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Your feedback helps others choose the best products!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: _muted,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ------------------------------------------------
                // RATING SECTION
                // ------------------------------------------------
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _line, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: _charcoal.withOpacity(0.06),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                            "TAP TO RATE",
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: _blue,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      RatingBar.builder(
                        initialRating: ratings.toDouble(),
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: false,
                        itemCount: 5,
                        itemSize: 44,
                        unratedColor: _line,
                        itemPadding: const EdgeInsets.symmetric(horizontal: 4),
                        itemBuilder: (context, _) => const Icon(
                          Icons.star_rounded,
                          color: _yellowDeep,
                        ),
                        onRatingUpdate: (rating) {
                          setState(() {
                            ratings = rating.toInt();
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      // ── Rating text feedback ──
                      Text(
                        _ratingLabel(ratings),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _muted,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ------------------------------------------------
                // REVIEW TEXT SECTION
                // ------------------------------------------------
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _line, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: _charcoal.withOpacity(0.06),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
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
                            "SHARE MORE DETAILS",
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: _blue,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: review,
                        maxLines: 5,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: _ink,
                          height: 1.5,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please write something";
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText:
                          "What did you like or dislike about the product?",
                          hintStyle: const TextStyle(
                            color: _mutedSoft,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                          filled: true,
                          fillColor: _warmWhite,
                          contentPadding: const EdgeInsets.all(16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: _line, width: 1.2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: _yellowDeep, width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: _warn, width: 1.4),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: _warn, width: 1.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),

                // ------------------------------------------------
                // SUBMIT BUTTON
                // ------------------------------------------------
                SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formkey.currentState!.validate()) {
                        SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                        var data = await http.post(
                          Uri.parse("${prefs.getString("ip")}/user_sendreview"),
                          body: {
                            "rating": ratings.toString(),
                            "review": review.text,
                            "user": prefs.getString("user"),
                            "ordersub_id": prefs.getString("ordersub_id"),
                          },
                        );

                        var jsonData = json.decode(data.body);

                        if (jsonData['status'] == 'success') {
                          if (mounted) {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => Userdashboard(),));
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  "Review already submitted for this item",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                  ),
                                ),
                                backgroundColor: _charcoal,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.all(14),
                              ),
                            );
                          }
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _charcoal,
                      foregroundColor: _yellow,
                      elevation: 6,
                      shadowColor: _charcoal.withOpacity(0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send_rounded, size: 18, color: _yellow),
                        SizedBox(width: 10),
                        Text(
                          "Submit Review",
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
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Rating label helper ──
  String _ratingLabel(int rating) {
    switch (rating) {
      case 1:
        return "Poor — We'll do better";
      case 2:
        return "Fair — Room for improvement";
      case 3:
        return "Good — Happy to hear!";
      case 4:
        return "Very Good — Thanks for sharing";
      case 5:
        return "Excellent — You made our day!";
      default:
        return "Tap a star to rate";
    }
  }
}