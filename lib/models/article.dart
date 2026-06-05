import 'package:flutter/material.dart';

/// A single piece of learning content with a stable UUID identifier.
class Article {
  final String id;
  final String title;
  final String description;
  final String readTime;
  final String category;
  final IconData icon;
  final Color color;

  const Article({
    required this.id,
    required this.title,
    required this.description,
    required this.readTime,
    required this.category,
    required this.icon,
    required this.color,
  });
}
