import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'RazorpayScreen.dart';

class Cart extends StatefulWidget {
  const Cart({super.key});

  @override
  State<Cart> createState() => _CartState();
}

class _CartState extends State<Cart> {

  late Future<List<CartItem>> _cartFuture;

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

  // ── Safe parsers (prevent FormatException: null) ──
  int _safeInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    return int.tryParse(value.toString()) ?? fallback;
  }

  double _safeDouble(dynamic value, {double fallback = 0}) {
    if (value == null) return fallback;
    return double.tryParse(value.toString()) ?? fallback;
  }

  @override
  void initState() {
    super.initState();
    _cartFuture = _getCart();
  }

  Future<List<CartItem>> _getCart() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var data = await http.post(
      Uri.parse("${prefs.getString("ip")}/user_viewcart"),
      body: {
        "user_id": prefs.getString("user"),
      },
    );
    var jsonData = json.decode(data.body);

    List<CartItem> items = [];
    for (var item in jsonData["data"]) {
      CartItem newItem = CartItem(
        item["id"]?.toString() ?? "",
        item["product_id"]?.toString() ?? "",
        item["name"]?.toString() ?? "",
        item["description"]?.toString() ?? "",
        item["price"]?.toString() ?? "0",
        item["quantity"]?.toString() ?? "1",
        "${prefs.getString("ip")}${item["image"]?.toString() ?? ""}",
        item["seller"]?.toString() ?? "",
        item["stock"]?.toString() ?? "0",
      );
      items.add(newItem);
    }
    return items;
  }

  void _refresh() {
    setState(() {
      _cartFuture = _getCart();
    });
  }

  // Pass type: "+" or "-"
  Future<void> _updateQuantity(String cartId, String type) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    var data = await http.post(
      Uri.parse("${prefs.getString("ip")}/user_updatecart"),
      body: {
        "cart_id": cartId,
        "type": type,
      },
    );

    final jsonData = json.decode(data.body);
    final status = jsonData["status"];

    if (!mounted) return;

    if (status == "success") {
      _refresh();
    } else if (status == "out_of_stock") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(jsonData["message"] ?? "Not enough stock available"),
          backgroundColor: _warn,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // don't refresh — cart quantity didn't change
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(jsonData["message"] ?? "Could not update quantity"),
          backgroundColor: _warn,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _refresh();
    }
  }

  Future<void> _removeItem(String cartId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await http.post(
      Uri.parse("${prefs.getString("ip")}/user_removecartitem"),
      body: {
        "cart_id": cartId,
      },
    );
    _refresh();
  }

  Future<void> _buyNow(CartItem item) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString("user_id", prefs.getString("user").toString());
    await prefs.setString("product_id", item.product_id);
    await prefs.setString("quantity", item.quantity);
    await prefs.setString("price", item.price);
    await prefs.setString("type", "single");

    double buyNowTotal = _safeDouble(item.price) * _safeInt(item.quantity);
    await prefs.setString("total", buyNowTotal.toStringAsFixed(0));

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RazorpayScreen()),
    );
  }

  Future<void> _placeOrder(List<CartItem> items) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Save the cart total FIRST (RazorpayScreen reads this in initState)
    double cartTotal = _calculateTotal(items);
    await prefs.setString("total", cartTotal.toStringAsFixed(0));

    // Mark this as a multi-item (cart) payment
    await prefs.setString("type", "multiple");
    await prefs.setString("user_id", prefs.getString("user").toString());

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RazorpayScreen()),
    );
  }

  double _calculateTotal(List<CartItem> items) {
    double total = 0;
    for (var item in items) {
      total += _safeDouble(item.price) * _safeInt(item.quantity);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _warmWhite,
      appBar: AppBar(
        title: const Text(
          "My Cart",
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
      body: FutureBuilder<List<CartItem>>(
        future: _cartFuture,
        builder: (BuildContext context, AsyncSnapshot<List<CartItem>> snapshot) {
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
                    decoration: const BoxDecoration(
                      color: _yellowSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_cart_outlined,
                      size: 52,
                      color: _charcoal,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Your cart is empty",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Add some products to get started",
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

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  itemCount: items.length,
                  itemBuilder: (BuildContext context, int index) {
                    var i = items[index];
                    final qty   = _safeInt(i.quantity);
                    final stock = _safeInt(i.stock);
                    final canInc = qty < stock;
                    final canDec = qty > 1;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
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
                                      i.image,
                                      height: 88,
                                      width: 88,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stack) {
                                        return Container(
                                          height: 88,
                                          width: 88,
                                          color: _line,
                                          child: const Center(
                                            child: Icon(
                                              Icons.image_not_supported_outlined,
                                              color: _mutedSoft,
                                              size: 28,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // ── Details ──
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        i.name,
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

                                      // ── Seller line ──
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
                                              i.seller,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: _blueMid,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),

                                      Text(
                                        i.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: _muted,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "₹ ${i.price}",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: _ink,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // ── Quantity stepper + Buy Now ──
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: _warmWhite,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: _line, width: 1.2),
                                  ),
                                  child: Row(
                                    children: [
                                      // Minus
                                      InkWell(
                                        borderRadius: const BorderRadius.horizontal(
                                          left: Radius.circular(10),
                                        ),
                                        onTap: canDec
                                            ? () async {
                                          await _updateQuantity(i.id, "-");
                                        }
                                            : null,
                                        child: Container(
                                          width: 36,
                                          height: 36,
                                          alignment: Alignment.center,
                                          child: Icon(
                                            Icons.remove_rounded,
                                            size: 18,
                                            color: canDec ? _charcoal : _mutedSoft,
                                          ),
                                        ),
                                      ),

                                      // Value
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        alignment: Alignment.center,
                                        child: Text(
                                          i.quantity,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w900,
                                            color: _ink,
                                          ),
                                        ),
                                      ),

                                      // Plus
                                      InkWell(
                                        borderRadius: const BorderRadius.horizontal(
                                          right: Radius.circular(10),
                                        ),
                                        onTap: canInc
                                            ? () async {
                                          await _updateQuantity(i.id, "+");
                                        }
                                            : null,
                                        child: Container(
                                          width: 36,
                                          height: 36,
                                          alignment: Alignment.center,
                                          child: Icon(
                                            Icons.add_rounded,
                                            size: 18,
                                            color: canInc ? _charcoal : _mutedSoft,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),

                                // ── Buy Now ──
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _yellow,
                                    foregroundColor: _charcoal,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () async {
                                    await _buyNow(i);
                                  },
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.bolt_rounded,
                                        size: 16,
                                        color: _charcoal,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        "Buy Now",
                                        style: TextStyle(
                                          color: _charcoal,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // ── Remove button ──
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  side: const BorderSide(color: _line, width: 1.4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  foregroundColor: _warn,
                                ),
                                onPressed: () async {
                                  await _removeItem(i.id);
                                },
                                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                                label: const Text(
                                  "Remove from cart",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
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

              // ── Bottom bar: total + place order ──
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: const Border(top: BorderSide(color: _line, width: 1.2)),
                  boxShadow: [
                    BoxShadow(
                      color: _charcoal.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          "Total",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _muted,
                          ),
                        ),
                        Text(
                          "₹ ${_calculateTotal(items).toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: _ink,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 12,
                          color: _mutedSoft,
                        ),
                        SizedBox(width: 4),
                        Text(
                          "Inclusive of all taxes",
                          style: TextStyle(
                            fontSize: 11.5,
                            color: _mutedSoft,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _charcoal,
                          foregroundColor: _yellow,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          await _placeOrder(items);
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 18,
                              color: _yellow,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Place Order",
                              style: TextStyle(
                                color: _yellow,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CartItem {
  final String id;
  final String product_id;
  final String name;
  final String description;
  final String price;
  final String quantity;
  final String image;
  final String seller;
  final String stock;

  CartItem(
      this.id,
      this.product_id,
      this.name,
      this.description,
      this.price,
      this.quantity,
      this.image,
      this.seller,
      this.stock,
      );
}