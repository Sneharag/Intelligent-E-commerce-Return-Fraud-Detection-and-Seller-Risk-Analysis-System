import 'package:ecommerce_return_fraud_detection/returnrequest.dart';
import 'package:ecommerce_return_fraud_detection/sendreview.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class UserOrderItemsPage extends StatefulWidget {
  const UserOrderItemsPage({super.key});

  @override
  State<UserOrderItemsPage> createState() => _UserOrderItemsPageState();
}

class _UserOrderItemsPageState extends State<UserOrderItemsPage> {
  late Future<List<AllOrderItem>> _orderItemsFuture;

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
  static const Color _greenSoft  = Color(0xFFD1FAE5);
  static const Color _amber      = Color(0xFFF59E0B);
  static const Color _amberSoft  = Color(0xFFFEF3C7);
  static const Color _sky        = Color(0xFF0EA5E9);
  static const Color _skySoft    = Color(0xFFE0F2FE);
  static const Color _purple     = Color(0xFF7C3AED);
  static const Color _purpleSoft = Color(0xFFEDE9FE);

  // ── Return window: 20 days from order date ──
  static const int _returnWindowDays = 20;

  @override
  void initState() {
    super.initState();
    _orderItemsFuture = _getOrderItems();
  }

  Future<List<AllOrderItem>> _getOrderItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var data = await http.post(
      Uri.parse("${prefs.getString("ip")}/user_viewallorderitems"),
      body: {
        "user_id": prefs.getString("user"),
      },
    );
    var jsonData = json.decode(data.body);

    List<AllOrderItem> items = [];
    for (var i in jsonData["data"]) {
      AllOrderItem newItem = AllOrderItem(
        i["id"].toString(),
        i["product_id"].toString(),
        i["order_id"].toString(),
        i["name"].toString(),
        i["description"].toString(),
        i["price"].toString(),
        i["quantity"].toString(),
        "${prefs.getString("ip")}${i["image"]}",
        i["payment_method"].toString(),
        i["payment_status"].toString(),
        i["status"].toString(),
        i["order_status"].toString(),
        i["date"].toString(),
        i["seller_name"].toString(),
      );
      items.add(newItem);
    }
    return items;
  }

  // ── Return window helpers ──
  DateTime? _parseOrderDate(String raw) {
    if (raw.isEmpty || raw == "null") return null;

    // Try ISO first (Django default: "2025-01-15T10:30:00Z" or "2025-01-15")
    try {
      return DateTime.parse(raw);
    } catch (_) {}

    // Fallbacks for common non-ISO formats
    final formats = [
      RegExp(r'^(\d{2})-(\d{2})-(\d{4})$'), // 15-01-2025
      RegExp(r'^(\d{2})/(\d{2})/(\d{4})$'), // 15/01/2025
      RegExp(r'^(\d{4})/(\d{2})/(\d{2})$'), // 2025/01/15
    ];

    for (final re in formats) {
      final m = re.firstMatch(raw);
      if (m != null) {
        try {
          final g = m.groups([1, 2, 3]);
          if (g[0]!.length == 4) {
            return DateTime(
              int.parse(g[0]!),
              int.parse(g[1]!),
              int.parse(g[2]!),
            );
          }
          return DateTime(
            int.parse(g[2]!),
            int.parse(g[1]!),
            int.parse(g[0]!),
          );
        } catch (_) {}
      }
    }

    return null;
  }

  bool _isReturnWindowOpen(String rawDate) {
    final orderDate = _parseOrderDate(rawDate);
    if (orderDate == null) return false;

    final expiry = orderDate.add(const Duration(days: _returnWindowDays));
    return DateTime.now().isBefore(expiry);
  }

  Future<void> _cancelItem(String itemId) async {
    // 1. Show confirmation dialog before cancelling
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text(
          "Cancel Order Item",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        content: const Text(
          "Are you sure you want to cancel this item?",
          style: TextStyle(
            fontSize: 14,
            color: _muted,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "No",
              style: TextStyle(
                color: _muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Yes, Cancel",
              style: TextStyle(
                color: _warn,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );

    // 2. If user confirmed, send HTTP request
    if (confirm == true) {
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        var response = await http.post(
          Uri.parse("${prefs.getString("ip")}/user_cancelorderitem"),
          body: {"item_id": itemId},
        );
        var jsonData = json.decode(response.body);

        if (jsonData["status"] == "success") {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Item cancelled successfully"),
              backgroundColor: _charcoal,
              behavior: SnackBarBehavior.floating,
            ),
          );
          // Refresh the list data
          setState(() {
            _orderItemsFuture = _getOrderItems();
          });
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(jsonData["message"] ?? "Failed to cancel item"),
              backgroundColor: _warn,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Network error. Please try again."),
            backgroundColor: _warn,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _warmWhite,
      appBar: AppBar(
        title: const Text(
          "My Ordered Items",
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
      body: FutureBuilder<List<AllOrderItem>>(
        future: _orderItemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _yellowDeep),
            );
          }

          if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
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
                      Icons.inventory_2_outlined,
                      size: 52,
                      color: _charcoal,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "No ordered items found",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Your purchased items will appear here",
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

          final items = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
            itemCount: items.length,
            itemBuilder: (context, index) {
              var item = items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _line, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: _charcoal.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header row: Order ID & Order-level status ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: _yellowSoft,
                                  borderRadius: BorderRadius.circular(9),
                                  border: Border.all(
                                    color: _yellow.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.receipt_long_rounded,
                                  size: 14,
                                  color: _charcoal,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Order #${item.orderId}",
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w900,
                                  color: _ink,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                          // 👇 Order-level status
                          _statusChip(item.orderStatus, label: "Order"),
                        ],
                      ),

                      const SizedBox(height: 12),
                      Container(height: 1, color: _line),
                      const SizedBox(height: 12),

                      // Product info (Image + Name + Seller + Price)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Image ──
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              color: _warmWhite,
                              padding: const EdgeInsets.all(6),
                              child: Image.network(
                                item.image,
                                height: 84,
                                width: 84,
                                fit: BoxFit.contain,
                                errorBuilder: (c, e, s) => Container(
                                  height: 84,
                                  width: 84,
                                  color: _line,
                                  child: const Center(
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      color: _mutedSoft,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // ── Details ──
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: _ink,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 5),

                                // ── Seller chip ──
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _blueSoft,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        "SOLD BY",
                                        style: TextStyle(
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w900,
                                          color: _blue,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        item.sellerName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: _blueMid,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // ── Price x Qty ──
                                Row(
                                  children: [
                                    Text(
                                      "₹ ${item.price}",
                                      style: const TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w900,
                                        color: _ink,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "× ${item.quantity}",
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: _muted,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),

                                // ── Item status chip ──
                                if (item.status != "null") ...[
                                  Row(
                                    children: [
                                      const Text(
                                        "Item: ",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _muted,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      _statusChip(item.status, label: ""),
                                    ],
                                  ),
                                ]
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ── Additional details panel ──
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _warmWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _line, width: 1),
                        ),
                        child: Column(
                          children: [
                            _buildRow("Date", item.date),
                            const SizedBox(height: 8),
                            _buildRow("Payment Method", item.paymentMethod),
                            const SizedBox(height: 8),
                            _buildRow("Payment Status", item.paymentStatus),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 3 Action Buttons: Return, Cancel, Review
                      Row(
                        children: [
                          // Return button — only when delivered AND within 20-day window
                          if (item.orderStatus == "Delivered" &&
                              item.status != "Returned" &&
                              item.status != "Pickuped & Refunded" &&
                              _isReturnWindowOpen(item.date))
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ReturnRequest(orderItemId: item.id),
                                    ),
                                  );
                                  if (result == true) {
                                    setState(() {
                                      _orderItemsFuture = _getOrderItems();
                                    });
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _amber,
                                  side: BorderSide(
                                    color: _amber.withOpacity(0.5),
                                    width: 1.4,
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.assignment_return_outlined,
                                      size: 14,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      "Return",
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          if (item.orderStatus == "Delivered")
                            const SizedBox(width: 8),

                          // Cancel button — only when Pending
                          if (item.orderStatus == "Pending" && item.status != "Cancelled")
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _cancelItem(item.id),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _warn,
                                  side: BorderSide(
                                    color: _warn.withOpacity(0.5),
                                    width: 1.4,
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.cancel_outlined,
                                      size: 14,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      "Cancel",
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          if (item.orderStatus == "Pending")
                            const SizedBox(width: 8),

                          // Review button — Delivered or Completed
                          if (item.orderStatus == "Delivered" &&
                              item.status != "Returned" &&
                              item.status != "Pickuped & Refunded")
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  SharedPreferences prefs =
                                  await SharedPreferences.getInstance();

                                  await prefs.setString("product_id", item.productId);
                                  await prefs.setString("ordersub_id", item.id);
                                  if (!mounted) return;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => Sendreview()),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _yellow,
                                  foregroundColor: _charcoal,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.star_outline_rounded,
                                      size: 14,
                                      color: _charcoal,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      "Review",
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w900,
                                        color: _charcoal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
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

  Widget _buildRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _muted,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusChip(String status, {String? label}) {
    Color bg;
    Color fg;
    Color border;
    IconData icon;

    switch (status) {
      case "Pending":
        bg = _amberSoft;
        fg = _amber;
        border = _amber;
        icon = Icons.access_time_rounded;
        break;
      case "Shipped":
        bg = _skySoft;
        fg = _sky;
        border = _sky;
        icon = Icons.local_shipping_outlined;
        break;
      case "Delivered":
      case "Completed":
        bg = _greenSoft;
        fg = _green;
        border = _green;
        icon = Icons.check_circle_rounded;
        break;
      case "Cancelled":
        bg = const Color(0xFFFEE2E2);
        fg = _warn;
        border = _warn;
        icon = Icons.cancel_outlined;
        break;
      case "Returned":
        bg = _purpleSoft;
        fg = _purple;
        border = _purple;
        icon = Icons.assignment_return_rounded;
        break;
      default:
        bg = _line;
        fg = _muted;
        border = _mutedSoft;
        icon = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(
            label != null ? "$label: $status" : status,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class AllOrderItem {
  final String id;
  final String productId;
  final String orderId;
  final String name;
  final String description;
  final String price;
  final String quantity;
  final String image;
  final String paymentMethod;
  final String paymentStatus;
  final String status;
  final String orderStatus;
  final String date;
  final String sellerName;

  AllOrderItem(
      this.id,
      this.productId,
      this.orderId,
      this.name,
      this.description,
      this.price,
      this.quantity,
      this.image,
      this.paymentMethod,
      this.paymentStatus,
      this.status,
      this.orderStatus,
      this.date,
      this.sellerName,
      );
}