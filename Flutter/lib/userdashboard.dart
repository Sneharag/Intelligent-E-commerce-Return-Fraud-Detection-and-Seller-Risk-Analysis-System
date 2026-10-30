import 'package:ecommerce_return_fraud_detection/login.dart';
import 'package:ecommerce_return_fraud_detection/products.dart';
import 'package:ecommerce_return_fraud_detection/profile.dart';
import 'package:ecommerce_return_fraud_detection/userorderitems.dart';
import 'package:ecommerce_return_fraud_detection/view_returns.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'cart.dart';
import 'change_password.dart';
import 'sendfeedback.dart';

class Userdashboard extends StatefulWidget {
  const Userdashboard({super.key});

  @override
  State<Userdashboard> createState() => _UserdashboardState();
}

class _UserdashboardState extends State<Userdashboard> {
  String userName = "User";
  String ip = "";

  int totalOrders = 0;
  double totalSpent = 0;
  int returnsCount = 0;
  int inTransit = 0;

  List<dynamic> recentOrders = [];
  List<dynamic> products = [];
  List<dynamic> reviews = [];

  bool isLoading = true;
  int currentIndex = 0;

  final PageController _heroController = PageController(viewportFraction: 0.9);
  int _heroIndex = 0;

  // ── Palette ──
  static const Color _yellow     = Color(0xFFFACC15);
  static const Color _yellowDeep = Color(0xFFEAB308);
  static const Color _yellowSoft = Color(0xFFFEF9C3);

  static const Color _navy       = Color(0xFF0F172A);
  static const Color _navy2      = Color(0xFF1E293B);
  static const Color _navy3      = Color(0xFF334155);
  static const Color _navySoft   = Color(0xFFE2E8F0);

  static const Color _ink        = Color(0xFF0F172A);
  static const Color _warmWhite  = Color(0xFFF8FAFC);
  static const Color _line       = Color(0xFFE2E8F0);
  static const Color _muted      = Color(0xFF64748B);
  static const Color _mutedSoft  = Color(0xFF94A3B8);

  static const Color _green      = Color(0xFF059669);
  static const Color _greenSoft  = Color(0xFFD1FAE5);
  static const Color _warn       = Color(0xFFC23D2C);
  static const Color _amberSoft  = Color(0xFFFEF3C7);

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadDashboardData();
  }

  Future<void> _loadUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      userName = prefs.getString("name") ?? "Guest";
    });
  }

  Future<void> _loadDashboardData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    ip = prefs.getString("ip") ?? "";
    final userIdStr = prefs.getString("user") ?? "";

    try {
      final response = await http.get(Uri.parse("$ip/user_dashboard"));
      debugPrint("DASHBOARD RAW: ${response.body}");

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result["status"] == "success") {
          List<dynamic> productData = result["products"] ?? [];
          for (var p in productData) {
            final img = p["image"]?.toString() ?? "";
            if (img.isNotEmpty && !img.startsWith("http")) {
              p["image"] = "$ip$img";
            }
          }

          List<dynamic> allOrders = result["orders"] ?? [];
          List<dynamic> myOrders = allOrders
              .where((o) => o["customer_id"].toString() == userIdStr)
              .toList();

          final Set<String> orderIds = {};
          double spent = 0;
          int transit = 0;
          int returns = 0;

          for (var o in myOrders) {
            orderIds.add(o["order_id"].toString());
            try {
              spent += double.parse(o["price"].toString()) *
                  int.parse(o["quantity"].toString());
            } catch (_) {}
            final st = (o["order_status"] ?? "").toString().toLowerCase();
            if (st == "pending" || st == "shipped" || st == "pickup") transit++;
            final ist = (o["item_status"] ?? "").toString().toLowerCase();
            if (ist.contains("return") || ist.contains("refund")) returns++;
          }

          final Map<String, Map<String, dynamic>> orderMap = {};
          for (var o in myOrders) {
            final oid = o["order_id"].toString();
            if (!orderMap.containsKey(oid)) {
              orderMap[oid] = {
                "id": oid,
                "total": 0.0,
                "status": o["order_status"] ?? "Pending",
                "date": o["date"] ?? "",
              };
            }
            try {
              orderMap[oid]!["total"] =
                  (orderMap[oid]!["total"] as double) +
                      double.parse(o["price"].toString()) *
                          int.parse(o["quantity"].toString());
            } catch (_) {}
          }

          final sortedOrders = orderMap.values.toList()
            ..sort((a, b) =>
                (b["date"] as String).compareTo(a["date"] as String));

          List<dynamic> reviewData = result["reviews"] ?? [];

          if (!mounted) return;
          setState(() {
            totalOrders = orderIds.length;
            totalSpent = spent;
            returnsCount = returns;
            inTransit = transit;
            recentOrders = sortedOrders.take(3).toList();
            products = productData;
            reviews = reviewData.reversed.take(5).toList();
            isLoading = false;
          });
        } else {
          if (!mounted) return;
          setState(() => isLoading = false);
        }
      } else {
        if (!mounted) return;
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Dashboard Error: $e");
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _warmWhite,
      drawer: _buildModernDrawer(),
      body: SafeArea(
        top: false,
        child: isLoading
            ? const Center(
          child: CircularProgressIndicator(color: _yellowDeep),
        )
            : _buildDashboard(),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // ══════════════════════════════════════════════════
  // MAIN DASHBOARD
  // ══════════════════════════════════════════════════
  Widget _buildDashboard() {
    return RefreshIndicator(
      color: _yellowDeep,
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroHeader(),
            const SizedBox(height: 18),
            _buildHeroCarousel(),
            const SizedBox(height: 22),
            _buildStatsStrip(),
            const SizedBox(height: 24),
            _sectionHeader("Popular Products", "See All", () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (c) => Products()));
            }),
            const SizedBox(height: 14),
            _buildPopularProducts(),
            const SizedBox(height: 26),
            _sectionHeader("Quick Actions", "", () {}),
            const SizedBox(height: 14),
            _buildQuickActions(),
            const SizedBox(height: 26),
            _sectionHeader("Recent Orders", "See All", () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (c) => UserOrderItemsPage()));
            }),
            const SizedBox(height: 14),
            _buildRecentOrders(),
            const SizedBox(height: 26),
            _sectionHeader("What Customers Say", "", () {}),
            const SizedBox(height: 14),
            _buildReviews(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // HERO HEADER (navy gradient with yellow accents)
  // ══════════════════════════════════════════════════
  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 14,
        left: 20,
        right: 20,
        bottom: 62,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_navy, _navy2, _navy3],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top bar ──
          Row(
            children: [
              Builder(
                builder: (context) => GestureDetector(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  child: Container(
                    height: 42, width: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                    child: const Icon(Icons.menu_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                height: 42, width: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(7),
                child: Image.asset(
                  'assets/images/returnlogo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                  const Icon(Icons.shield_rounded,
                      color: _navy, size: 20),
                ),
              ),
              const SizedBox(width: 10),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
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
              const Spacer(),
              _heroTopIcon(Icons.notifications_none_rounded, () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (c) => UserOrderItemsPage()));
              }),
              const SizedBox(width: 8),
              _heroTopIcon(Icons.shopping_cart_outlined, () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (c) => Cart()));
              }),
            ],
          ),
          const SizedBox(height: 24),

          // ── Welcome block ──
          Text(
            "Welcome back,",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Flexible(
                child: Text(
                  userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text("👋", style: TextStyle(fontSize: 24)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Discover what's trending today",
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),

          // ── Search bar inside hero ──
          GestureDetector(
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (c) => Products()));
            },
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(Icons.search, color: _navy, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      "Search products, brands...",
                      style: TextStyle(color: _mutedSoft, fontSize: 13.5),
                    ),
                  ),
                  Container(
                    height: 36, width: 36,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_yellow, _yellowDeep],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.tune, color: _navy, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroTopIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42, width: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // HERO CAROUSEL (sliding ecommerce banners)
  // ══════════════════════════════════════════════════
  Widget _buildHeroCarousel() {
    final List<Map<String, dynamic>> slides = [
      {
        "tag": "TRENDING NOW",
        "title": "Smart\nWatches",
        "sub": "Up to 40% off",
        "img": "https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=800&q=80",
        "color": _yellow,
      },
      {
        "tag": "NEW ARRIVALS",
        "title": "Sneakers\nCollection",
        "sub": "Fresh drops weekly",
        "img": "https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800&q=80",
        "color": _yellow,
      },
      {
        "tag": "DEAL OF THE DAY",
        "title": "Studio\nHeadphones",
        "sub": "Premium sound quality",
        "img": "https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800&q=80",
        "color": _yellow,
      },
    ];

    return Column(
      children: [
        SizedBox(
          height: 222,
          child: PageView.builder(
            controller: _heroController,
            onPageChanged: (i) => setState(() => _heroIndex = i),
            itemCount: slides.length,
            itemBuilder: (context, index) {
              final s = slides[index];
              final isActive = _heroIndex == index;

              return AnimatedPadding(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(
                  left: 4,
                  right: 4,
                  top: isActive ? 0 : 8,
                  bottom: isActive ? 0 : 8,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: _navy.withOpacity(0.18),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          s["img"] as String,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: _navy),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                _navy.withOpacity(0.92),
                                _navy.withOpacity(0.6),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: s["color"] as Color,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  s["tag"] as String,
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    color: _navy,
                                    letterSpacing: 0.9,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                s["title"] as String,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.1,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                s["sub"] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: s["color"] as Color,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Shop Now",
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w900,
                                        color: _navy,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    SizedBox(width: 5),
                                    Icon(Icons.arrow_forward_rounded,
                                        size: 12, color: _navy),
                                  ],
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
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(slides.length, (i) {
            final active = i == _heroIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 22 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? _yellow : _line,
                borderRadius: BorderRadius.circular(100),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════
  // STATS STRIP (overlapping hero)
  // ══════════════════════════════════════════════════
  Widget _buildStatsStrip() {
    final stats = [
      {"value": "$totalOrders", "label": "Orders",
        "icon": Icons.shopping_bag_rounded},
      {"value": "₹${totalSpent.toStringAsFixed(0)}", "label": "Spent",
        "icon": Icons.currency_rupee_rounded},
      {"value": "$inTransit", "label": "In Transit",
        "icon": Icons.local_shipping_rounded},
      {"value": "$returnsCount", "label": "Returns",
        "icon": Icons.rotate_left_rounded},
    ];

    return Transform.translate(
      offset: const Offset(0, -48),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _navy.withOpacity(0.1),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: stats.map((s) {
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_yellow, _yellowDeep],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(s["icon"] as IconData,
                          color: _navy, size: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s["value"] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: _ink,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s["label"] as String,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // SECTION HEADER
  // ══════════════════════════════════════════════════
  Widget _sectionHeader(String title, String action, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 4, height: 18,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_yellow, _yellowDeep],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: _ink,
              letterSpacing: -0.4,
            ),
          ),
          const Spacer(),
          if (action.isNotEmpty)
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _yellowSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Text(
                      action,
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(Icons.arrow_forward_rounded,
                        color: _navy, size: 13),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // POPULAR PRODUCTS
  // ══════════════════════════════════════════════════
  Widget _buildPopularProducts() {
    if (products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _emptyCard("No products available"),
      );
    }

    return SizedBox(
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: products.length,
        itemBuilder: (context, i) {
          final p = products[i];
          final imgUrl = p["image"]?.toString() ?? "";

          return GestureDetector(
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (c) => Products()));
            },
            child: Container(
              width: 175,
              margin: EdgeInsets.only(right: i == products.length - 1 ? 0 : 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _navy.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Image with navy tint overlay ──
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        child: Container(
                          height: 140,
                          width: double.infinity,
                          color: _warmWhite,
                          padding: const EdgeInsets.all(12),
                          child: Image.network(
                            imgUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: _mutedSoft,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Rating chip
                      Positioned(
                        top: 10, left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(
                            color: _navy,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded,
                                  color: _yellow, size: 11),
                              SizedBox(width: 3),
                              Text("4.8",
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                      // Add button
                      Positioned(
                        top: 10, right: 10,
                        child: Container(
                          height: 34, width: 34,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_yellow, _yellowDeep],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: _yellow.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.add,
                              color: _navy, size: 20),
                        ),
                      ),
                    ],
                  ),
                  // ── Details ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${p["name"]}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            color: _ink,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "by ${p["seller"]}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: _muted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _yellowSoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "₹${p["price"]}",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: _navy,
                              letterSpacing: -0.3,
                            ),
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
    );
  }

  // ══════════════════════════════════════════════════
  // QUICK ACTIONS (navy cards)
  // ══════════════════════════════════════════════════
  Widget _buildQuickActions() {
    final actions = [
      {"label": "Products", "icon": Icons.grid_view_rounded, "route": Products()},
      {"label": "Cart", "icon": Icons.shopping_cart_rounded, "route": Cart()},
      {"label": "Orders", "icon": Icons.receipt_long_rounded, "route": UserOrderItemsPage()},
      {"label": "Returns", "icon": Icons.rotate_left_rounded, "route": UserViewReturns()},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: actions.map((a) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: a == actions.last ? 0 : 10),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => a["route"] as Widget),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_navy, _navy2],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _navy.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_yellow, _yellowDeep],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(a["icon"] as IconData,
                            color: _navy, size: 20),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        a["label"] as String,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // RECENT ORDERS
  // ══════════════════════════════════════════════════
  Widget _buildRecentOrders() {
    if (recentOrders.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _emptyCard("No orders yet"),
      );
    }

    return SizedBox(
      height: 155,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: recentOrders.length,
        itemBuilder: (context, i) {
          final o = recentOrders[i];
          final status = (o["status"] ?? "Pending").toString();
          final statusColor = status.toLowerCase().contains("deliver")
              ? _green
              : status.toLowerCase().contains("ship")
              ? _yellowDeep
              : _yellowDeep;
          final statusSoft = status.toLowerCase().contains("deliver")
              ? _greenSoft
              : _amberSoft;

          return Container(
            width: 220,
            margin: EdgeInsets.only(right: i == recentOrders.length - 1 ? 0 : 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _line, width: 1),
              boxShadow: [
                BoxShadow(
                  color: _navy.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: _navy,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(Icons.receipt_long_rounded,
                          size: 13, color: _yellow),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        "#${o["id"]}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: _ink,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  "Total amount",
                  style: TextStyle(
                    fontSize: 10.5,
                    color: _muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "₹${(o["total"] as double).toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                    letterSpacing: -0.4,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusSoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      color: statusColor == _yellowDeep ? _navy : statusColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // REVIEWS
  // ══════════════════════════════════════════════════
  Widget _buildReviews() {
    if (reviews.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _emptyCard("No reviews yet"),
      );
    }

    return SizedBox(
      height: 165,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: reviews.length,
        itemBuilder: (context, i) {
          final r = reviews[i];
          final rating = int.tryParse("${r["rating"]}") ?? 5;
          final name = "${r["customer_name"] ?? "Customer"}";

          return Container(
            width: 260,
            margin: EdgeInsets.only(right: i == reviews.length - 1 ? 0 : 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _line, width: 1),
              boxShadow: [
                BoxShadow(
                  color: _navy.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_yellow, _yellowDeep],
                        ),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : "C",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: _navy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: List.generate(5, (j) {
                              return Icon(
                                j < rating
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 12,
                                color: j < rating ? _yellowDeep : _line,
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  "${r["review"]}",
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _ink,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "${r["date"]}",
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: _mutedSoft,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _emptyCard(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line, width: 1),
      ),
      child: Center(
        child: Text(
          msg,
          style: const TextStyle(
            color: _muted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // BOTTOM NAV
  // ══════════════════════════════════════════════════
  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        selectedItemColor: _yellowDeep,
        unselectedItemColor: _mutedSoft,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        elevation: 0,
        onTap: (index) {
          setState(() => currentIndex = index);
          if (index == 0) return;
          if (index == 1) {
            Navigator.push(context,
                MaterialPageRoute(builder: (c) => UserOrderItemsPage()));
          }
          if (index == 2) {
            Navigator.push(
                context, MaterialPageRoute(builder: (c) => Profile()));
          }
          if (index == 3) {
            Navigator.push(context,
                MaterialPageRoute(builder: (c) => UserViewReturns()));
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: "Orders",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Profile",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.rotate_left_outlined),
            activeIcon: Icon(Icons.rotate_left),
            label: "Returns",
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // DRAWER
  // ══════════════════════════════════════════════════
  Widget _buildModernDrawer() {
    final items = [
      {"icon": Icons.dashboard_rounded, "label": "Home", "route": Userdashboard()},
      {"icon": Icons.person_rounded, "label": "Profile", "route": Profile()},
      {"icon": Icons.grid_view_rounded, "label": "Products", "route": Products()},
      {"icon": Icons.shopping_cart_rounded, "label": "Cart", "route": Cart()},
      {"icon": Icons.receipt_long_rounded, "label": "Orders", "route": UserOrderItemsPage()},
      {"icon": Icons.rotate_left_rounded, "label": "Returns", "route": UserViewReturns()},
      {"icon": Icons.rate_review_rounded, "label": "Feedback", "route": Sendfeedback()},
      {"icon": Icons.password_rounded, "label": "Change Password", "route": Changepassword()},
    ];

    return Drawer(
      backgroundColor: _warmWhite,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
                top: 55, bottom: 26, left: 20, right: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_navy, _navy2, _navy3],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [_yellow, _yellowDeep]),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: _yellow.withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : "U",
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Customer Account",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                ...items.map((it) {
                  final isHome = it["label"] == "Home";
                  return ListTile(
                    leading: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: isHome ? _yellowSoft : _warmWhite,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isHome
                              ? _yellow.withOpacity(0.5)
                              : _line,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        it["icon"] as IconData,
                        color: isHome ? _navy : _muted,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      it["label"] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isHome ? FontWeight.w900 : FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => it["route"] as Widget),
                      );
                    },
                  );
                }),
                const Divider(),
                ListTile(
                  leading: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: _warn.withOpacity(0.3), width: 1),
                    ),
                    child: const Icon(Icons.logout_rounded,
                        color: _warn, size: 18),
                  ),
                  title: const Text(
                    "Logout",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _warn,
                    ),
                  ),
                  onTap: _handleLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await http.post(Uri.parse("${prefs.getString("ip")}/user_logout"));
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (c) => LoginPageSub()),
          (r) => false,
    );
  }
}