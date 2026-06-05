import 'package:flutter/material.dart';
import '../data/articles_data.dart';
import '../models/article.dart';
import '../repositories/reads_repository.dart';
import '../widgets/gold_shimmer.dart';
import 'article_detail_screen.dart';
import '../utils/size_config.dart';

class CategoryDetailScreen extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const CategoryDetailScreen({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    final articles = articlesForCategory(title);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.0 * vw),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GoldShimmerContainer(
              borderRadius: BorderRadius.circular(4.0 * vw),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 10.0 * vw),
                  SizedBox(width: 4.0 * vw),
                  Expanded(
                    child: Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.8 * vh),
            const Text(
              'Articles',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE8DCC8),
              ),
            ),
            SizedBox(height: 2.0 * vh),
            ...articles.map((article) => Padding(
                  padding: EdgeInsets.only(bottom: 1.5 * vh),
                  child: _buildArticleCard(context, article),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleCard(BuildContext context, Article article) {
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    return GestureDetector(
      onTap: () {
        ReadsRepository.recordRead(article);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ArticleDetailScreen(
              title: article.title,
              description: article.description,
              readTime: article.readTime,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(3.0 * vw),
          border: Border.all(color: const Color(0xFF2A2520)),
        ),
        child: Padding(
          padding: EdgeInsets.all(4.0 * vw),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE8DCC8),
                      ),
                    ),
                    SizedBox(height: 0.5 * vh),
                    Text(
                      article.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[400],
                      ),
                    ),
                    SizedBox(height: 1.0 * vh),
                    Text(
                      article.readTime,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFC9A96E),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: const Color(0xFFC9A96E),
                size: 4.0 * vw,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
