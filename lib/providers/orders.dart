import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import './cart.dart';

class OrderItem {
  final String id;
  final double amount;
  final List<CartItem> products;
  final DateTime dateTime;

  OrderItem({
    @required this.id,
    @required this.amount,
    @required this.dateTime,
    @required this.products,
  });
}

class Orders with ChangeNotifier {
  List<OrderItem> _orders = [];
  String authToken;
  String userId;

  List<OrderItem> get orders {
    return [..._orders];
  }

  void setTokenAndUserId(String token, String id) {
    authToken = token;
    userId = id;
    notifyListeners();
  }

  Future<void> fetchAndSetOrders() async {
    final url =
        'https://myshop-1c2cf.firebaseio.com/orders/$userId.json?auth=$authToken';
    final response = await http.get(url);

    final List<OrderItem> loadedOrders = [];
    final extractedData = json.decode(response.body) as Map<String, dynamic>;
    if (extractedData == null) {
      return;
    }
    extractedData.forEach((orderId, orderData) {
      loadedOrders.add(
        OrderItem(
          id: orderId,
          amount: orderData['amount'],
          dateTime: DateTime.parse(orderData['dateTime']),
          products: (orderData['products'] as List<dynamic>)
              .map((item) => CartItem(
                    id: item['id'],
                    price: item['price'],
                    quantity: item['quantity'],
                    title: item['title'],
                  ))
              .toList(),
        ),
      );
    });
    _orders = loadedOrders.reversed.toList();

    print('fetched orders');
    notifyListeners();
  }

  Future<void> addOrder(List<CartItem> cartProducts, double total) async {
    final url =
        'https://myshop-1c2cf.firebaseio.com/orders/$userId.json?auth=$authToken';

    final timestamp = DateTime.now();
    final response = await http.post(url,
        body: json.encode({
          'amount': total,
          'dateTime': timestamp.toIso8601String(),
          'products': cartProducts
              .map((cartProd) => {
                    'id': cartProd.id,
                    'title': cartProd.title,
                    'quantity': cartProd.quantity,
                    'price': cartProd.price,
                  })
              .toList()
        }));

    _orders.insert(
      0,
      OrderItem(
        id: json.decode(response.body)['name'],
        amount: total,
        dateTime: timestamp,
        products: cartProducts,
      ),
    );

    print('added order');
    notifyListeners();
  }
}
