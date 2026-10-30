import 'package:ecommerce_return_fraud_detection/productreviews.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'cart.dart';

class Products extends StatefulWidget {
  const Products({super.key});

  @override
  State<Products> createState() => _ProductsState();
}

class _ProductsState extends State<Products> {

  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

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

  // Future<List<Product>> _getProducts() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   var data = await http.post(Uri.parse("${prefs.getString("ip")}/user_viewproducts"));
  //   var jsonData = json.decode(data.body);
  //
  //   List<Product> products = [];
  //   for (var product in jsonData["data"]) {
  //     Product newProduct = Product(
  //       product["id"].toString(),
  //       product["name"].toString(),
  //       product["description"].toString(),
  //       product["price"].toString(),
  //       product["stock"].toString(),
  //       product["seller"].toString(),
  //       "${prefs.getString("ip")}${product["image"].toString()}",
  //       (product["rating"] ?? 0).toDouble(),
  //       (product["reviews_count"] ?? 0) as int,
  //     );
  //     products.add(newProduct);
  //   }
  //   return products;
  // }

  Future<List<Product>> _getProducts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final url = "${prefs.getString("ip")}/user_viewproducts";
    print("➡️ URL: $url");

    var data = await http.post(Uri.parse(url));
    print("⬅️ STATUS: ${data.statusCode}");
    print("⬅️ BODY: ${data.body}");

    var jsonData = json.decode(data.body);
    print("⬅️ DECODED KEYS: ${jsonData.keys}");

    List<Product> products = [];
    if (jsonData["data"] == null) {
      print("⚠️ jsonData['data'] is NULL");
      return products;
    }

    for (var product in jsonData["data"]) {
      try {
        Product newProduct = Product(
          product["id"].toString(),
          product["name"].toString(),
          product["description"].toString(),
          product["price"].toString(),
          product["stock"].toString(),
          product["seller"].toString(),
          "${prefs.getString("ip")}${product["image"].toString()}",
          (product["rating"] ?? 0).toDouble(),
          (product["reviews_count"] ?? 0) as int,
        );
        products.add(newProduct);
      } catch (e) {
        print("❌ Failed to parse product: $product — $e");
      }
    }
    print("✅ Parsed ${products.length} products");
    return products;
  }

  Future<void> _addToCart(BuildContext context, String productId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    var data = await http.post(
      Uri.parse("${prefs.getString("ip")}/user_addtocart"),
      body: {
        "product_id": productId,
        // "quantity": "1",
        "user_id": prefs.getString("user"),
      },
    );

    var jsonData = json.decode(data.body);

    if (!mounted) return;
    if (jsonData["status"] == "success") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Added to cart"),
          backgroundColor: _charcoal,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Cart()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(jsonData["message"] ?? "Failed to add to cart"),
          backgroundColor: _warn,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Bottom sheet popup ──
  void _showProductSheet(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.78,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // ── Drag handle ──
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 6),
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: _line,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ══════════ IMAGE ══════════
                          Stack(
                            children: [
                              Container(
                                width: double.infinity,
                                height: 280,
                                color: _warmWhite,
                                padding: const EdgeInsets.all(20),
                                child: Image.network(
                                  product.image,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stack) {
                                    return Container(
                                      color: _line,
                                      child: const Center(
                                        child: Icon(
                                          Icons.image_not_supported_outlined,
                                          size: 40,
                                          color: _mutedSoft,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: InkWell(
                                  onTap: () => Navigator.pop(sheetContext),
                                  borderRadius: BorderRadius.circular(100),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: _charcoal.withOpacity(0.12),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: _charcoal,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // ══════════ DETAILS ══════════
                          Padding(
                            padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: _ink,
                                    letterSpacing: -0.3,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // ── Seller line ──
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _blueSoft,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        "SOLD BY",
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w900,
                                          color: _blue,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      product.seller,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: _ink,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 4,
                                      height: 4,
                                      decoration: const BoxDecoration(
                                        color: _mutedSoft,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      int.parse(product.stock) > 0
                                          ? "In stock"
                                          : "Out of stock",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: int.parse(product.stock) > 0
                                            ? _green
                                            : _warn,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),

                                // ══════════ PRICE ══════════
                                Text(
                                  "₹${product.price}",
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: _ink,
                                    letterSpacing: -0.6,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  "Inclusive of all taxes",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _muted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // ══════════ RATING ══════════
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: product.reviewsCount > 0
                                            ? _green
                                            : _mutedSoft,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            product.reviewsCount > 0
                                                ? product.rating.toStringAsFixed(1)
                                                : "—",
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 3),
                                          const Icon(
                                            Icons.star_rounded,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      product.reviewsCount > 0
                                          ? "${product.reviewsCount} rating${product.reviewsCount == 1 ? '' : 's'}"
                                          : "No ratings yet",
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: _blueMid,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // ══════════ DESCRIPTION ══════════
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      top: BorderSide(color: _line, width: 1),
                                      bottom: BorderSide(color: _line, width: 1),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "About this item",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: _ink,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      _buildBulletPoint(product.description),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // ══════════ ACTION BUTTONS ══════════
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: int.parse(product.stock) > 0
                                          ? ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _yellow,
                                          foregroundColor: _charcoal,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(12),
                                          ),
                                        ),
                                        onPressed: () async {
                                          await _addToCart(
                                              context, product.id);
                                        },
                                        child: const Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.shopping_cart_outlined,
                                              size: 18,
                                              color: _charcoal,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              "Add to Cart",
                                              style: TextStyle(
                                                color: _charcoal,
                                                fontSize: 15,
                                                fontWeight:
                                                FontWeight.w800,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                          : ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _line,
                                          padding:
                                          const EdgeInsets.symmetric(
                                              vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(12),
                                          ),
                                        ),
                                        onPressed: null,
                                        child: const Text(
                                          "Out of Stock",
                                          style: TextStyle(
                                            color: _mutedSoft,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),

                                    Expanded(
                                      flex: 2,
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          Navigator.pop(sheetContext);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ProductReviews(
                                                    productId: product.id,
                                                    productName: product.name,
                                                  ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.star_outline_rounded,
                                          size: 18,
                                        ),
                                        label: const Text(
                                          "Reviews",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: _yellowDeep,
                                          side: const BorderSide(
                                              color: _yellowDeep, width: 1.6),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: _ink,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _ink,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Small product card for the grid ──
  Widget _productCard(Product product) {
    final inStock = int.parse(product.stock) > 0;

    return GestureDetector(
      onTap: () => _showProductSheet(context, product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _line, width: 1),
          boxShadow: [
            BoxShadow(
              color: _charcoal.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image with bottom shadow ──
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(11),
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Image.network(
                      product.image,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stack) {
                        return Container(
                          color: _warmWhite,
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: _mutedSoft,
                              size: 32,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            _charcoal.withOpacity(0.06),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (!inStock)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _warn,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "OUT OF STOCK",
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Details ──
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),

                  Text(
                    "by ${product.seller}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _blueMid,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    "₹${product.price}",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                      letterSpacing: -0.3,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ══════════ RATING BADGE ══════════
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: product.reviewsCount > 0 ? _green : _mutedSoft,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          product.reviewsCount > 0
                              ? product.rating.toStringAsFixed(1)
                              : "New",
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.star_rounded,
                          size: 11,
                          color: Colors.white,
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
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Products",
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
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: _charcoal,
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase().trim();
                });
              },
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
              decoration: InputDecoration(
                hintText: "Search products...",
                hintStyle: TextStyle(
                  color: _mutedSoft.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: _mutedSoft,
                  size: 22,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 20),
                  color: _muted,
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = "";
                    });
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _yellow, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
            ),
          ),

          Expanded(
            child: FutureBuilder<List<Product>>(
              future: _getProducts(),
              builder: (BuildContext context,
                  AsyncSnapshot<List<Product>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _yellowDeep),
                  );
                }

                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(child: Text("No products available"));
                }

                final allProducts = snapshot.data!;
                final filtered = _searchQuery.isEmpty
                    ? allProducts
                    : allProducts.where((p) {
                  return p.name.toLowerCase().contains(_searchQuery) ||
                      p.description.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: _yellowSoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.search_off_rounded,
                            size: 40,
                            color: _charcoal,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "No products found",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Try a different search term",
                          style: TextStyle(
                            fontSize: 13,
                            color: _muted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.58,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (BuildContext context, int index) {
                    return _productCard(filtered[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Product {
  final String id;
  final String name;
  final String description;
  final String price;
  final String stock;
  final String seller;
  final String image;
  final double rating;
  final int reviewsCount;

  Product(
      this.id,
      this.name,
      this.description,
      this.price,
      this.stock,
      this.seller,
      this.image,
      this.rating,
      this.reviewsCount,
      );
}