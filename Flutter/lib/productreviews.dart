import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ProductReviews extends StatefulWidget {
  final String productId;
  final String productName;

  const ProductReviews({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  State<ProductReviews> createState() => _ProductReviewsState();
}

class _ProductReviewsState extends State<ProductReviews> {
  late Future<List<ProductReview>> _reviewsFuture;

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

  static const Color _green      = Color(0xFF059669);

  @override
  void initState() {
    super.initState();
    _reviewsFuture = _getReviews();
  }

  Future<List<ProductReview>> _getReviews() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var data = await http.post(
      Uri.parse("${prefs.getString("ip")}/user_viewproductreviews"),
      body: {
        "product_id": widget.productId,
      },
    );
    var jsonData = json.decode(data.body);

    List<ProductReview> reviews = [];
    for (var r in jsonData["data"]) {
      ProductReview newReview = ProductReview(
        r["customer_name"].toString(),
        r["rating"].toString(),
        r["review"].toString(),
        r["date"].toString(),
      );
      reviews.add(newReview);
    }
    return reviews;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _warmWhite,
      appBar: AppBar(
        title: Text(
          widget.productName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16,
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
      body: FutureBuilder<List<ProductReview>>(
        future: _reviewsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _yellowDeep),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _yellowSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.star_outline_rounded,
                      size: 52,
                      color: _charcoal,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "No reviews yet",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Be the first to share your thoughts",
                    style: TextStyle(
                      fontSize: 13.5,
                      color: _muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          final reviews = snapshot.data!;

          // Compute average rating for the header
          double totalRating = 0;
          for (var r in reviews) {
            totalRating += int.tryParse(r.rating) ?? 0;
          }
          final avgRating = reviews.isEmpty ? 0 : totalRating / reviews.length;

          return Column(
            children: [
              // ══════════ SUMMARY HEADER ══════════
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_charcoalDk, _charcoal, Color(0xFF374151)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: _charcoal.withOpacity(0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // ── Big average ──
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          avgRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: _yellow,
                            letterSpacing: -1.5,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: List.generate(5, (i) {
                            return Icon(
                              i < avgRating.round()
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: _yellow,
                              size: 14,
                            );
                          }),
                        ),
                      ],
                    ),

                    const SizedBox(width: 22),

                    // ── Divider ──
                    Container(
                      width: 1,
                      height: 60,
                      color: Colors.white.withOpacity(0.15),
                    ),

                    const SizedBox(width: 22),

                    // ── Total reviews + subtitle ──
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${reviews.length} ${reviews.length == 1 ? 'Review' : 'Reviews'}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Based on verified purchases",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.65),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ══════════ REVIEWS LIST ══════════
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 20),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    var r = reviews[index];
                    final int rating = int.tryParse(r.rating) ?? 0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _line, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: _charcoal.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Customer row ──
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── Avatar ──
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [_yellow, _yellowDeep],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    r.customerName.isNotEmpty
                                        ? r.customerName[0].toUpperCase()
                                        : "?",
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      color: _charcoal,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r.customerName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: _ink,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          // ── Star row ──
                                          Row(
                                            children: List.generate(5, (i) {
                                              return Icon(
                                                i < rating
                                                    ? Icons.star_rounded
                                                    : Icons.star_outline_rounded,
                                                color: i < rating
                                                    ? _yellowDeep
                                                    : _line,
                                                size: 15,
                                              );
                                            }),
                                          ),
                                          const SizedBox(width: 8),
                                          // ── Verified badge ──
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _green.withOpacity(0.12),
                                              borderRadius:
                                              BorderRadius.circular(4),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.verified_rounded,
                                                  size: 10,
                                                  color: _green,
                                                ),
                                                SizedBox(width: 3),
                                                Text(
                                                  "VERIFIED",
                                                  style: TextStyle(
                                                    fontSize: 8.5,
                                                    fontWeight: FontWeight.w900,
                                                    color: _green,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // ── Date ──
                                Text(
                                  r.date,
                                  style: const TextStyle(
                                    color: _mutedSoft,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // ── Review text ──
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: _warmWhite,
                                borderRadius: BorderRadius.circular(10),
                                border: const Border(
                                  left: BorderSide(
                                    color: _yellow,
                                    width: 3,
                                  ),
                                ),
                              ),
                              child: Text(
                                r.review,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  color: _ink,
                                  height: 1.55,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ProductReview {
  final String customerName;
  final String rating;
  final String review;
  final String date;

  ProductReview(this.customerName, this.rating, this.review, this.date);
}