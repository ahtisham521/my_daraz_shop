import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:my_shop/models/card_item.dart';
import 'package:my_shop/models/order_item.dart';

class Orders with ChangeNotifier {
  List<OrderItem> _orders = [];
  String authToken;
  String orderId;
  List<OrderItem> get orders {
    return [..._orders];
  }

  void update(String token, String orderID, List order) {
    authToken = token;
    _orders = order;
    orderId = orderID;
  }

  Future<void> fetchAndSetOrder() async {
    final url =
        'https://my-shop-ba6cf-default-rtdb.firebaseio.com/ordered-products/$orderId.json?auth=$authToken';
    final resposne = await http.get(url);
    print(resposne.body);
    final List<OrderItem> loadedOrders = [];
    final extractedData = json.decode(resposne.body) as Map<String, dynamic>;
    if (extractedData == null) {
      return;
    }
    extractedData.forEach((orderId, orderData) {
      loadedOrders.add(OrderItem(
          id: orderId,
          amount: orderData['amount'],
          products: (orderData['products'] as List<dynamic>)
              .map((item) => CartItem(
                  id: item['id'],
                  title: item['title'],
                  quantity: item['quantity'],
                  price: item['price']))
              .toList(),
          dateTime: DateTime.parse(orderData['dateTime'])));
    });
    _orders = loadedOrders.reversed.toList();
    notifyListeners();
  }

  Future<void> addOrder(List<CartItem> cartProducts, double total) async {
    final url =
        'https://my-shop-ba6cf-default-rtdb.firebaseio.com/ordered-products/$orderId.json?auth=$authToken';
    final timeStamp = DateTime.now();
    final response = await http.post(
      url,
      body: json.encode(
        {
          'amount': total,
          'dateTime': timeStamp.toIso8601String(),
          'products': cartProducts
              .map(
                (cp) => {
                  'id': cp.id,
                  'title': cp.title,
                  'quantity': cp.quantity,
                  'price': cp.price,
                },
              )
              .toList(),
        },
      ),
    );

    _orders.insert(
      0,
      OrderItem(
        id: json.decode(response.body)['name'],
        amount: total,
        products: cartProducts,
        dateTime: DateTime.now(),
      ),
    );
    notifyListeners();
  }
}
