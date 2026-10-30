import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'userdashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'mobile_razorpay_helper.dart'
if (dart.library.js) 'web_razorpay_helper.dart' as razorpay_helper;
import 'package:razorpay_flutter/razorpay_flutter.dart' as razorpay_flutter;

class RazorpayScreen extends StatefulWidget {
  const RazorpayScreen({super.key});

  @override
  State<RazorpayScreen> createState() => _RazorpayScreenState();
}

class _RazorpayScreenState extends State<RazorpayScreen> {
  razorpay_flutter.Razorpay? _razorpay;

  String fee = "0";
  String _paymentMode = "online";

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
  static const Color _green      = Color(0xFF059669);

  @override
  void initState() {
    loadfee();
    super.initState();

    if (!kIsWeb) {
      _razorpay = razorpay_flutter.Razorpay();

      _razorpay?.on(
        razorpay_flutter.Razorpay.EVENT_PAYMENT_SUCCESS,
        _handlePaymentSuccess,
      );

      _razorpay?.on(
        razorpay_flutter.Razorpay.EVENT_PAYMENT_ERROR,
        _handlePaymentError,
      );

      _razorpay?.on(
        razorpay_flutter.Razorpay.EVENT_EXTERNAL_WALLET,
        _handleExternalWallet,
      );
    }
  }

  Future<void> loadfee() async {
    SharedPreferences sh = await SharedPreferences.getInstance();

    setState(() {
      fee = sh.getString("total") ?? "0";
    });
  }

  void _openCheckout() {
    var options = {
      'key': 'rzp_test_HKCAwYtLt0rwQe',
      'amount': '${int.parse(fee) * 100}',
      'name': 'ReturnGuard',
      'description': 'Payment',
      'prefill': {
        'contact': '8888888888',
        'email': 'trend@returnguard.com',
      },
      'theme': {'color': '#FACC15'}
    };

    if (kIsWeb) {
      razorpay_helper.openRazorpayWeb(
        options,
        onSuccess: (paymentId) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment Successful: $paymentId'),
              backgroundColor: _green,
            ),
          );

          updatepaymentstatus();
        },
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment Failed: $error'),
              backgroundColor: _warn,
            ),
          );
        },
      );
    } else {
      _razorpay?.open(options);
    }
  }

  void _handlePaymentSuccess(
      razorpay_flutter.PaymentSuccessResponse response,
      ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Payment Successful: ${response.paymentId}"),
        backgroundColor: _green,
      ),
    );

    updatepaymentstatus();
  }

  void _handlePaymentError(
      razorpay_flutter.PaymentFailureResponse response,
      ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Payment Failed: ${response.message}"),
        backgroundColor: _warn,
      ),
    );
  }

  void _handleExternalWallet(
      razorpay_flutter.ExternalWalletResponse response,
      ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Wallet Selected: ${response.walletName}"),
        backgroundColor: _charcoal,
      ),
    );
  }

  Future<void> updatepaymentstatus() async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    String type = sh.getString("type").toString();

    if (type == 'single') {
      await http.post(
        Uri.parse("${sh.getString("ip")}/user_buynow"),
        body: {
          "user_id": sh.getString("user"),
          "amount": sh.getString("total"),
          "mode": _paymentMode,
          "product_id": sh.getString("product_id"),
          "quantity": sh.getString("quantity"),
          "price": sh.getString("price"),
        },
      );
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => const Userdashboard()));
    } else {
      await http.post(
        Uri.parse("${sh.getString("ip")}/user_placeorder"),
        body: {
          "user": sh.getString("user"),
          "amount": sh.getString("total"),
          "mode": _paymentMode,
        },
      );
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => const Userdashboard()));
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      _razorpay?.clear();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isOnline = _paymentMode == "online";

    return Scaffold(
      backgroundColor: _charcoal,
      appBar: AppBar(
        title: const Text(
          "Payment",
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 50,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ══════════ TOP AMOUNT HERO ══════════
                    Text(
                      "Total to pay",
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.7),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "₹$fee",
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: _yellow,
                        letterSpacing: -1.5,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 13,
                          color: Colors.white.withOpacity(0.6),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          "Secure checkout",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // ══════════ CENTERED CARD ══════════
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 32,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Card title ──
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: _yellow,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "PAYMENT METHOD",
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                  color: _ink,
                                  letterSpacing: 1.4,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // ── Online option ──
                          _buildPaymentOption(
                            title: "Online Payment",
                            subtitle: "Pay securely via Razorpay",
                            icon: Icons.account_balance_wallet_rounded,
                            value: "online",
                            selected: isOnline,
                          ),

                          const SizedBox(height: 10),

                          // ── Offline option ──
                          _buildPaymentOption(
                            title: "Cash on Delivery",
                            subtitle: "Confirm & pay on delivery",
                            icon: Icons.payments_rounded,
                            value: "offline",
                            selected: !isOnline,
                          ),

                          const SizedBox(height: 22),

                          // ── Pay button ──
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: () {
                                if (_paymentMode == 'online') {
                                  _openCheckout();
                                } else {
                                  updatepaymentstatus();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _charcoal,
                                foregroundColor: _yellow,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isOnline
                                        ? Icons.lock_rounded
                                        : Icons.check_circle_outline_rounded,
                                    size: 18,
                                    color: _yellow,
                                  ),
                                  const SizedBox(width: 9),
                                  Text(
                                    isOnline
                                        ? "Pay ₹$fee Securely"
                                        : "Confirm Offline Booking",
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: _yellow,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // ── Trust row ──
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.verified_user_outlined,
                                  size: 13,
                                  color: _mutedSoft,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  "256-bit encrypted · PCI DSS compliant",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _mutedSoft,
                                    fontWeight: FontWeight.w600,
                                  ),
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
        ),
      ),
    );
  }

  // ── Compact payment option tile ──
  Widget _buildPaymentOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
    required bool selected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _paymentMode = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? _yellowSoft.withOpacity(0.7) : _warmWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _yellowDeep : _line,
            width: selected ? 2 : 1.2,
          ),
        ),
        child: Row(
          children: [
            // ── Icon chip ──
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: selected ? _charcoal : Colors.white,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: selected ? _charcoal : _line,
                  width: 1.2,
                ),
              ),
              child: Icon(
                icon,
                color: selected ? _yellow : _muted,
                size: 21,
              ),
            ),

            const SizedBox(width: 12),

            // ── Text ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: _muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // ── Custom radio ──
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 22,
              width: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? _yellow : Colors.transparent,
                border: Border.all(
                  color: selected ? _yellowDeep : _mutedSoft,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Center(
                child: Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: _charcoal,
                ),
              )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}