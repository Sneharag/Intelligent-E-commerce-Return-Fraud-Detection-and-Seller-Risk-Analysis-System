import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class OrderDetails extends StatefulWidget {
  final String orderId;

  const OrderDetails({super.key, required this.orderId});

  @override
  State<OrderDetails> createState() => _OrderDetailsState();
}

class _OrderDetailsState extends State<OrderDetails> {

  late Future<List<OrderProduct>> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _detailsFuture = _getOrderDetails();
  }

  Future<List<OrderProduct>> _getOrderDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var data = await http.post(
      Uri.parse("${prefs.getString("ip")}/user_vieworderitems"),
      body: {
        "order_id": prefs.getString("order_id"),
      },
    );
    var jsonData = json.decode(data.body);

    List<OrderProduct> products = [];
    for (var p in jsonData["data"]) {
      OrderProduct newProduct = OrderProduct(
        p["id"].toString(),
        p["name"].toString(),
        p["description"].toString(),
        p["price"].toString(),
        p["quantity"].toString(),
        "${prefs.getString("ip")}${p["image"]}",
      );
      products.add(newProduct);
    }
    return products;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Order #${widget.orderId}"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: FutureBuilder<List<OrderProduct>>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Text("Loading..."));
          }

          if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(child: Text("No products in this order"));
          }

          final products = snapshot.data!;

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              var p = products[index];
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            p.image,
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              height: 100,
                              width: 100,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image_not_supported),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                p.description,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "₹ ${p.price}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Quantity: ${p.quantity}",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
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
          );
        },
      ),
    );
  }
}

class OrderProduct {
  final String id;
  final String name;
  final String description;
  final String price;
  final String quantity;
  final String image;

  OrderProduct(this.id, this.name, this.description, this.price, this.quantity, this.image);
}