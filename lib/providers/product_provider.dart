import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_shop/models/http_exception.dart';

import 'product.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _items = [
    // Product(
    //   id: 'p1',
    //   title: 'Red Shirt',
    //   description: 'A red shirt - it is pretty red!',
    //   price: 29.99,
    //   imageUrl:
    //       'https://cdn.pixabay.com/photo/2016/10/02/22/17/red-t-shirt-1710578_1280.jpg',
    // ),
    // Product(
    //   id: 'p2',
    //   title: 'Trousers',
    //   description: 'A nice pair of trousers.',
    //   price: 59.99,
    //   imageUrl:
    //       'https://static1.squarespace.com/static/5c832b55af4683b3a857c8ef/t/5e45abf53d753935b30eba07/1581624312694/pant1.jpg',
    // ),
    // Product(
    //   id: 'p3',
    //   title: 'Red Shoes',
    //   description: 'A red Shoes - osm pair of Shoes!',
    //   price: 69.99,
    //   imageUrl:
    //       'https://ae01.alicdn.com/kf/H7af3dd2ec72847b1b97139d34e0510ffi/2019-Hot-Men-Vulcanized-Lovers-Shoes-Black-Red-Sneakers-Man-Lace-up-Casual-Shoes-Breathable-Walking.jpg',
    // ),
    // Product(
    //   id: 'p4',
    //   title: 'ladies Cap',
    //   description: 'A Cap - it has pretty osm Design!',
    //   price: 29.99,
    //   imageUrl:
    //       'https://ae01.alicdn.com/kf/H132feb6e03284e67a0249f7e3340ce75r/Longkeeper-Brand-Autumn-Winter-Hats-For-Women-Plaid-Design-Contrast-Color-Ladies-Cap-Skullies-And-Beanies.jpg_q50.jpg',
    // ),
  ];

  String authToken;
  String userId;

  void update(String token, String userID, List items) {
    authToken = token;
    _items = items;
    userId = userID;
  }

  List<Product> get items {
    return [..._items];
  }

  List<Product> get favoriteItems {
    return _items.where((prodItem) => prodItem.isFavorite).toList();
  }

  Product findById(String id) {
    return _items.firstWhere((prod) => prod.id == id);
  }

  Future<void> fetchAndSetProduct([bool filterByUser = false]) async {
    final filterString =
        filterByUser ? 'orderBy="createrId"&equalTo="$userId"' : '';
    var url =
        'https://my-shop-ba6cf-default-rtdb.firebaseio.com/products.json?auth=$authToken&$filterString';
    try {
      final response = await http.get(url);
      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      if (extractedData == null) {
        return;
      }
      url =
          'https://my-shop-ba6cf-default-rtdb.firebaseio.com/userFavorites/$userId.json?auth=$authToken';

      final favoriteResponse = await http.get(url);
      final favoriteData = json.decode(favoriteResponse.body);
      final List<Product> loadedProducts = [];
      extractedData.forEach((key, value) {
        loadedProducts.add(
          Product(
            id: key,
            title: value['title'],
            description: value['description'],
            price: value['price'],
            imageUrl: value['imageURL'],
            isFavorite:
                favoriteData == null ? false : favoriteData[key] ?? false,
          ),
        );
      });
      _items = loadedProducts;
      notifyListeners();
    } catch (onError) {
      throw (onError);
    }
  }

  Future<void> addProduct(Product product) async {
    final url =
        'https://my-shop-ba6cf-default-rtdb.firebaseio.com/products.json?auth=$authToken';
    try {
      final response = await http.post(
        url,
        body: json.encode({
          'title': product.title,
          'price': product.price,
          'description': product.description,
          'imageURL': product.imageUrl,
          'createrId': userId,
        }),
      );

      final newProduct = Product(
          id: json.decode(response.body)['name'],
          title: product.title,
          description: product.description,
          price: product.price,
          imageUrl: product.imageUrl);
      _items.add(newProduct);
      // _items.insert(0, newProduct);
      notifyListeners();
    } catch (onError) {
      print(onError);
      throw onError;
    }
  }

  Future<void> updateProducts(String id, Product newProduct) async {
    final prodIndex = _items.indexWhere((element) => element.id == id);
    if (prodIndex >= 0) {
      final url =
          'https://my-shop-ba6cf-default-rtdb.firebaseio.com/products/$id.json?auth=$authToken';
      await http.patch(url,
          body: json.encode({
            'title': newProduct.title,
            'description': newProduct.description,
            'price': newProduct.price,
            'imageURL': newProduct.imageUrl,
          }));
      _items[prodIndex] = newProduct;
      notifyListeners();
    } else {}
  }

  Future<void> deleteProduct(String id) async {
    final url =
        'https://my-shop-ba6cf-default-rtdb.firebaseio.com/products/$id.json?auth=$authToken';
    final existingProductIndex =
        _items.indexWhere((element) => element.id == id);
    var existingProduct = _items[existingProductIndex];
    _items.removeAt(existingProductIndex);
    notifyListeners();
    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      _items.insert(existingProductIndex, existingProduct);
      notifyListeners();
      throw HttpException('Could not delete product');
    }
    existingProduct = null;
  }
}
