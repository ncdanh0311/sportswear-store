import 'package:flutter/material.dart';

class KpiModel {
  final String title;
  final String value;
  final String change;
  final String icon;
  final bool isUp;
  final Color accent;
  final List<double> spark;

  const KpiModel(
    this.title,
    this.value,
    this.change,
    this.icon,
    this.isUp,
    this.accent,
    this.spark,
  );
}

class CategoryModel {
  final String name;
  final String emoji;
  final int sold;
  final String revenue;
  final double pct;
  final Color color;

  const CategoryModel(
    this.name,
    this.emoji,
    this.sold,
    this.revenue,
    this.pct,
    this.color,
  );
}

class TopProductModel {
  final int rank;
  final String name;
  final String emoji;
  final String variants;
  final int sold;
  final String revenue;

  const TopProductModel(
    this.rank,
    this.name,
    this.emoji,
    this.sold,
    this.variants,
    this.revenue,
  );
}
