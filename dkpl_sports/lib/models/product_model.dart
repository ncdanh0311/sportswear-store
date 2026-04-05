import 'package:flutter/material.dart';

class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final double rating;
  final List<String> images;
  final Color themeColor;
  final String category;
  final String weight; // 👈 THÊM

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.rating,
    required this.images,
    required this.themeColor,
    required this.category,
    required this.weight, // 👈 THÊM
  });
}
