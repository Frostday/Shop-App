import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/http_exception.dart';
import './product.dart';

class Products with ChangeNotifier {
  List<Product> _items = [];
  String authToken;
  String userId;

  void assignTokenAndUserId(String token, String id) {
    authToken = token;
    userId = id;
    notifyListeners();
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

  Future<void> fetchAndSetProducts([bool filterByUser = false]) async {
    final filterString =
        filterByUser ? 'orderBy="creatorId"&equalTo="$userId"' : '';
    var url =
        'https://myshop-1c2cf.firebaseio.com/products.json?auth=$authToken&$filterString';
    final response = await http.get(url);

    final extractedData = json.decode(response.body) as Map<String, dynamic>;

    url =
        'https://myshop-1c2cf.firebaseio.com/userFavorites/$userId.json?auth=$authToken';
    final favoriteResponse = await http.get(url);
    final favoriteData = json.decode(favoriteResponse.body);

    final List<Product> loadedProducts = [];
    if (extractedData == null) {
      return;
    }
    extractedData.forEach((prodId, prodData) {
      loadedProducts.add(Product(
        id: prodId,
        title: prodData['title'],
        description: prodData['description'],
        price: prodData['price'],
        imageUrl: prodData['imageUrl'],
        isFavorite:
            favoriteData == null ? false : favoriteData[prodId] ?? false,
      ));
    });
    _items = loadedProducts;
    print('fetched products');
    notifyListeners();
  }

  Future<void> addProduct(Product product) async {
    final url =
        'https://myshop-1c2cf.firebaseio.com/products.json?auth=$authToken';

    try {
      final response = await http.post(
        url,
        body: json.encode(
          {
            'title': product.title,
            'description': product.description,
            'imageUrl': product.imageUrl,
            'price': product.price,
            'creatorId': userId,
          },
        ),
      );

      final newProduct = Product(
        title: product.title,
        description: product.description,
        imageUrl: product.imageUrl,
        price: product.price,
        id: json.decode(response.body)['name'],
      );
      _items.add(newProduct);
      print('added product');
      notifyListeners();
    } catch (error) {
      throw error;
    }
  }

  Future<void> updateProduct(String id, Product newProduct) async {
    final prodIndex = _items.indexWhere((prod) => prod.id == id);
    if (prodIndex >= 0) {
      final url =
          'https://myshop-1c2cf.firebaseio.com/products/$id.json?auth=$authToken';

      await http.patch(url,
          body: json.encode({
            'title': newProduct.title,
            'description': newProduct.description,
            'imageUrl': newProduct.imageUrl,
            'price': newProduct.price,
          }));

      _items[prodIndex] = newProduct;

      print('updated product');
      notifyListeners();
    } else {
      print('Id not found');
    }
  }

  Future<void> deleteProduct(String id) async {
    final url =
        'https://myshop-1c2cf.firebaseio.com/products/$id.json?auth=$authToken';
    final existingProductIndex = _items.indexWhere((prod) => prod.id == id);
    var existingProduct = _items[existingProductIndex];

    _items.removeAt(existingProductIndex);
    notifyListeners();
    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      _items.insert(existingProductIndex, existingProduct);

      notifyListeners();
      throw HttpException('Could not delete product.');
    } else {
      existingProduct = null;
      print('deleted product');
    }
  }
}
