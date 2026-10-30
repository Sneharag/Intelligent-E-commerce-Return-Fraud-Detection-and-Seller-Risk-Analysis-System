import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class UserViewReturns extends StatefulWidget {
  const UserViewReturns({super.key});

  @override
  State<UserViewReturns> createState() => _UserViewReturnsState();
}

class _UserViewReturnsState extends State<UserViewReturns> {
  late Future<List<ReturnRequest>> _returnsFuture;

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
  static const Color _amber      = Color(0xFFF59E0B);
  static const Color _amberSoft  = Color(0xFFFEF3C7);
  static const Color _purple     = Color(0xFF7C3AED);

  @override
  void initState() {
    super.initState();
    _returnsFuture = _getReturns();
  }

  Future<List<ReturnRequest>> _getReturns() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var data = await http.post(
      Uri.parse("${prefs.getString("ip")}/user_viewreturns"),
      body: {
        "user_id": prefs.getString("user").toString(),
      },
    );
    var jsonData = json.decode(data.body);

    List<ReturnRequest> returns = [];
    for (var r in jsonData["data"]) {
      ReturnRequest newReturn = ReturnRequest(
        r["id"].toString(),
        r["product_name"].toString(),
        r["return_reason"].toString(),
        "${prefs.getString("ip")}${r["return_image"].toString()}",
        r["return_date"].toString(),
        r["status"].toString(),
      );
      returns.add(newReturn);
    }
    return returns;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Returned':
        return _amber;
      case 'Return Approved':
      case 'Pickuped & Refunded':
        return _green;
      case 'Return Rejected':
        return _warn;
      default:
        return _muted;
    }
  }

  Color _statusSoftColor(String status) {
    switch (status) {
      case 'Returned':
        return _amberSoft;
      case 'Return Approved':
      case 'Pickuped & Refunded':
        return _greenSoft;
      case 'Return Rejected':
        return const Color(0xFFFEE2E2);
      default:
        return _line;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Returned':
        return Icons.access_time_rounded;
      case 'Return Approved':
        return Icons.verified_rounded;
      case 'Pickuped & Refunded':
        return Icons.currency_rupee_rounded;
      case 'Return Rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  String _shortStatus(String status) {
    switch (status) {
      case 'Returned':
        return 'Submitted';
      case 'Return Approved':
        return 'Approved';
      case 'Pickuped & Refunded':
        return 'Refunded';
      case 'Return Rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _warmWhite,
      appBar: AppBar(
        title: const Text(
          "My Returns",
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
      body: FutureBuilder<List<ReturnRequest>>(
        future: _returnsFuture,
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
                      Icons.assignment_return_outlined,
                      size: 52,
                      color: _charcoal,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "No return requests yet",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Your return history will appear here",
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

          final returns = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
            itemCount: returns.length,
            itemBuilder: (context, index) {
              var r = returns[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _line, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: _charcoal.withOpacity(0.07),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ══════════ TOP STATUS STRIP (thin) ══════════
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _statusSoftColor(r.status),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(17),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _statusIcon(r.status),
                              size: 14,
                              color: _statusColor(r.status),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _shortStatus(r.status),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: _statusColor(r.status),
                                letterSpacing: 0.2,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              "#${r.id}",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: _statusColor(r.status).withOpacity(0.75),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ══════════ MAIN BODY: IMAGE LEFT + DETAILS RIGHT ══════════
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── IMAGE (LEFT) ──
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 100,
                                height: 100,
                                color: _warmWhite,
                                child: r.return_image.isNotEmpty
                                    ? Image.network(
                                  r.return_image,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: _line,
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.image_not_supported_outlined,
                                      color: _mutedSoft,
                                      size: 26,
                                    ),
                                  ),
                                )
                                    : Container(
                                  color: _line,
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.image_outlined,
                                    color: _mutedSoft,
                                    size: 26,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // ── DETAILS (RIGHT) ──
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Product name
                                  Text(
                                    r.productName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14.5,
                                      color: _ink,
                                      letterSpacing: -0.3,
                                      height: 1.3,
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  // Reason label
                                  Row(
                                    children: [
                                      Container(
                                        width: 3,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: _yellow,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        "REASON",
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w900,
                                          color: _muted,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),

                                  // Reason text (max 2 lines)
                                  Text(
                                    r.reason,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: _ink,
                                      fontWeight: FontWeight.w600,
                                      height: 1.4,
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  // Date
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_rounded,
                                        size: 11,
                                        color: _mutedSoft,
                                      ),
                                      const SizedBox(width: 5),
                                      Flexible(
                                        child: Text(
                                          r.date,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: _muted,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ReturnRequest {
  final String id;
  final String productName;
  final String reason;
  final String return_image;
  final String date;
  final String status;

  ReturnRequest(
      this.id,
      this.productName,
      this.reason,
      this.return_image,
      this.date,
      this.status,
      );
}