import 'package:flutter/material.dart';
import '../data/articles_data.dart';
import '../models/article.dart';
import '../repositories/reads_repository.dart';
import 'category_detail_screen.dart';
import 'article_detail_screen.dart';
import '../utils/size_config.dart';

const _kPageSize = 5;

// ---------------------------------------------------------------------------
// Root screen (stateless)
// ---------------------------------------------------------------------------

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Learn',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.0 * vw),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Featured article card carousel ──────────────────────────
            const Text(
              'Recommended for you',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE8DCC8),
              ),
            ),
            SizedBox(height: 2.0 * vh),
            const _ArticleCardCarousel(),
            SizedBox(height: 2.8 * vh),

            // ── Category navigation ─────────────────────────────────────
            const Text(
              'Browse by Category',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE8DCC8),
              ),
            ),
            SizedBox(height: 2.0 * vh),
            _buildCategoryCard(
              context,
              'Mental Health',
              'Learn about mindfulness, stress management, and emotional wellbeing',
              Icons.psychology,
            ),
            SizedBox(height: 1.5 * vh),
            _buildCategoryCard(
              context,
              'Physical Wellness',
              'Exercise tips, nutrition guidance, and body care',
              Icons.fitness_center,
            ),
            SizedBox(height: 1.5 * vh),
            _buildCategoryCard(
              context,
              'Reproductive Health',
              'Cycle tracking, fertility, and reproductive wellness',
              Icons.favorite,
            ),
            SizedBox(height: 1.5 * vh),
            _buildCategoryCard(
              context,
              'Sleep & Rest',
              'Improve sleep quality and establish healthy routines',
              Icons.bedtime,
            ),
            SizedBox(height: 2.8 * vh),

            // ── Previous reads (self-managing) ──────────────────────────
            const _PreviousReadsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
  ) {
    final vw = SizeConfig.vw;
    final vh = SizeConfig.vh;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CategoryDetailScreen(
              title: title,
              description: description,
              icon: icon,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1E1E1E).withValues(alpha: 0.3),
              const Color(0xFF6B5220).withValues(alpha: 0.2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(4.0 * vw),
          border: Border.all(
            color: const Color(0xFFC9A96E).withValues(alpha: 0.3),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(4.0 * vw),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(3.0 * vw),
                decoration: BoxDecoration(
                  color: const Color(0xFF252525),
                  borderRadius: BorderRadius.circular(3.0 * vw),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFFE8DCC8),
                  size: 7.0 * vw,
                ),
              ),
              SizedBox(width: 4.0 * vw),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE8DCC8),
                      ),
                    ),
                    SizedBox(height: 0.5 * vh),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[400],
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

// ---------------------------------------------------------------------------
// Article card carousel
// ---------------------------------------------------------------------------

class _ArticleCardCarousel extends StatefulWidget {
  const _ArticleCardCarousel();

  @override
  State<_ArticleCardCarousel> createState() => _ArticleCardCarouselState();
}

class _ArticleCardCarouselState extends State<_ArticleCardCarousel> {
  late final PageController _controller;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.88);
    _controller.addListener(() {
      final page = _controller.page?.round() ?? 0;
      if (page != _currentPage) {
        setState(() => _currentPage = page);
      }
    });
    // Load persisted reads into the notifier (idempotent)
    // ignore: unawaited_futures
    ReadsRepository.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onCardTapped(BuildContext context, Article article) {
    // Record read (updates notifier synchronously, persists in background)
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
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final vw = SizeConfig.vw;
    final vh = SizeConfig.vh;
    final cardHeight = 52.0 * vh;

    return Column(
      children: [
        SizedBox(
          height: cardHeight,
          child: PageView.builder(
            controller: _controller,
            itemCount: featuredArticles.length,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  double pageOffset = 0;
                  if (_controller.hasClients && _controller.page != null) {
                    pageOffset = (_controller.page! - index).abs();
                  }
                  final scale = (1.0 - pageOffset * 0.04).clamp(0.96, 1.0);
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: _ArticleCard(
                  article: featuredArticles[index],
                  onTap: () =>
                      _onCardTapped(context, featuredArticles[index]),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 1.5 * vh),
        // Dot indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(featuredArticles.length, (index) {
            final isActive = index == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.symmetric(horizontal: 1.0 * vw),
              width: isActive ? 5.0 * vw : 2.0 * vw,
              height: 1.0 * vw,
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFFC9A96E)
                    : const Color(0xFF2A2520),
                borderRadius: BorderRadius.circular(1.0 * vw),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Single article card
// ---------------------------------------------------------------------------

class _ArticleCard extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;

  const _ArticleCard({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final vw = SizeConfig.vw;
    final vh = SizeConfig.vh;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 1.5 * vw),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(5.0 * vw),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner
            Expanded(
              flex: 48,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      article.color,
                      article.color.withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    article.icon,
                    size: 18.0 * vw,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ),
            // Text section
            Expanded(
              flex: 52,
              child: Padding(
                padding: EdgeInsets.all(4.0 * vw),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category label
                    Text(
                      article.category,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFC9A96E),
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 1.0 * vh),
                    // Title
                    Text(
                      article.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE8DCC8),
                        height: 1.25,
                      ),
                    ),
                    SizedBox(height: 0.8 * vh),
                    // Description
                    Expanded(
                      child: Text(
                        article.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[400],
                          height: 1.4,
                        ),
                      ),
                    ),
                    // Footer row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 12,
                              color: Color(0xFFC9A96E),
                            ),
                            SizedBox(width: 1.0 * vw),
                            Text(
                              article.readTime,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFC9A96E),
                              ),
                            ),
                          ],
                        ),
                        const Text(
                          'Whelbeing',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B5220),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Previous reads section
// ---------------------------------------------------------------------------

class _PreviousReadsSection extends StatefulWidget {
  const _PreviousReadsSection();

  @override
  State<_PreviousReadsSection> createState() => _PreviousReadsSectionState();
}

class _PreviousReadsSectionState extends State<_PreviousReadsSection> {
  late List<Article> _articles;
  int _visibleCount = _kPageSize;

  @override
  void initState() {
    super.initState();
    _articles = List.from(previousReadsNotifier.value);
    previousReadsNotifier.addListener(_onNotifierChanged);
  }

  @override
  void dispose() {
    previousReadsNotifier.removeListener(_onNotifierChanged);
    super.dispose();
  }

  void _onNotifierChanged() {
    setState(() {
      _articles = List.from(previousReadsNotifier.value);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_articles.isEmpty) return const SizedBox.shrink();

    SizeConfig.init(context);
    final vh = SizeConfig.vh;

    final visible = _articles.take(_visibleCount).toList();
    final hasMore = _articles.length > _visibleCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Previous Reads',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE8DCC8),
          ),
        ),
        SizedBox(height: 2.0 * vh),
        ...visible.map((article) => Padding(
              padding: EdgeInsets.only(bottom: 1.5 * vh),
              child: _buildArticleRow(context, article),
            )),
        if (hasMore)
          TextButton(
            onPressed: () => setState(() => _visibleCount += _kPageSize),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 1.2 * vh),
              foregroundColor: const Color(0xFFC9A96E),
            ),
            child: const Text(
              'Load more',
              style: TextStyle(fontSize: 13, letterSpacing: 0.4),
            ),
          ),
      ],
    );
  }

  Widget _buildArticleRow(BuildContext context, Article article) {
    final vw = SizeConfig.vw;
    final vh = SizeConfig.vh;
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
          border: Border.all(
            color: const Color(0xFF2A2520),
          ),
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
