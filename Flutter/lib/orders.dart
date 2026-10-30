import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'orderitems.dart';

class Orders extends StatefulWidget {
  const Orders({super.key});

  @override
  State<Orders> createState() => _OrdersState();
}

class _OrdersState extends State<Orders> {

  late Future<List<OrderItem>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _getOrders();
  }

  Future<List<OrderItem>> _getOrders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var data = await http.post(
      Uri.parse("${prefs.getString("ip")}/user_vieworders"),
      body: {
        "user_id": prefs.getString("user"),
      },
    );
    var jsonData = json.decode(data.body);

    List<OrderItem> orders = [];
    for (var order in jsonData["data"]) {
      OrderItem newOrder = OrderItem(
        order["id"].toString(),
        order["total_amount"].toString(),
        order["status"].toString(),
        order["payment_status"].toString(),
        order["payment_method"].toString(),
        order["date"].toString(),
      );
      orders.add(newOrder);
    }
    return orders;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Orders"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: FutureBuilder<List<OrderItem>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Text("Loading..."));
          }

          if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(child: Text("No orders yet"));
          }

          final orders = snapshot.data!;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              var o = orders[index];
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Order #${o.id}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            _statusChip(o.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildRow("Date:", o.date),
                        _buildRow("Amount:", "₹ ${o.total_amount}"),
                        _buildRow("Payment:", o.payment_method),
                        _buildRow("Paid:", o.payment_status),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () async{
                              SharedPreferences prefs = await SharedPreferences.getInstance();
                              await prefs.setString("order_id", o.id);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => OrderDetails(orderId: o.id),
                                ),
                              );
                            },
                            child: const Text(
                              "View",
                              style: TextStyle(color: Colors.white, fontSize: 15),
                            ),
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

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    Color bg;
    switch (status.toLowerCase()) {
      case "pending":
        bg = Colors.orange;
        break;
      case "delivered":
      case "completed":
        bg = Colors.green;
        break;
      case "cancelled":
        bg = Colors.red;
        break;
      default:
        bg = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bg),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: bg,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class OrderItem {
  final String id;
  final String total_amount;
  final String status;
  final String payment_status;
  final String payment_method;
  final String date;

  OrderItem(this.id, this.total_amount, this.status, this.payment_status, this.payment_method, this.date);
}