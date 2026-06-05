import 'package:flutter/material.dart';
import '../utils/size_config.dart';

class ArticleDetailScreen extends StatelessWidget {
  final String title;
  final String description;
  final String readTime;

  const ArticleDetailScreen({
    super.key,
    required this.title,
    required this.description,
    required this.readTime,
  });

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    final content = _getArticleContent(title);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Article',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.0 * vw),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE8DCC8),
              ),
            ),
            SizedBox(height: 1.0 * vh),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 3.5 * vw,
                  color: const Color(0xFFC9A96E),
                ),
                SizedBox(width: 1.0 * vw),
                Text(
                  readTime,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFC9A96E),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.0 * vh),
            Container(
              height: 21.3 * vh,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    content.bannerColor,
                    content.bannerColor.withValues(alpha: 0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(4.0 * vw),
              ),
              child: Center(
                child: Icon(
                  content.bannerIcon,
                  size: 14.0 * vw,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 2.8 * vh),
            // Introduction
            Text(
              content.intro,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[400],
                height: 1.6,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 2.4 * vh),
            // Body sections
            ...content.sections.expand((section) => [
                  Text(
                    section.heading,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE8DCC8),
                    ),
                  ),
                  SizedBox(height: 1.0 * vh),
                  Text(
                    section.body,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[400],
                      height: 1.6,
                    ),
                  ),
                  SizedBox(height: 2.4 * vh),
                ]),
            // Key takeaways
            if (content.takeaways.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(4.0 * vw),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3.0 * vw),
                  border: Border.all(
                    color: const Color(0xFFC9A96E).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: const Color(0xFFE8DCC8),
                          size: 5.0 * vw,
                        ),
                        SizedBox(width: 2.0 * vw),
                        const Text(
                          'Key Takeaways',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE8DCC8),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 1.5 * vh),
                    ...content.takeaways.map((t) => Padding(
                          padding: EdgeInsets.only(bottom: 1.0 * vh),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '•  ',
                                style: TextStyle(
                                  color: Color(0xFFC9A96E),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  t,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[400],
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],
            SizedBox(height: 2.0 * vh),
            // Disclaimer
            Container(
              padding: EdgeInsets.all(3.0 * vw),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(2.0 * vw),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 4.0 * vw,
                    color: Colors.grey[400],
                  ),
                  SizedBox(width: 2.0 * vw),
                  Expanded(
                    child: Text(
                      'This article is for informational purposes only and is not a substitute for professional medical advice.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _ArticleContent _getArticleContent(String title) {
    switch (title) {
      case 'Understanding Your Cycle':
        return _ArticleContent(
          bannerIcon: Icons.favorite,
          bannerColor: const Color(0xFF8B6548),
          intro:
              'Your menstrual cycle is much more than just your period. Understanding the four phases of your cycle can help you work with your body rather than against it.',
          sections: [
            _Section(
              'The Four Phases',
              'Your cycle consists of the menstrual phase (days 1–5), the follicular phase (days 1–13), ovulation (around day 14), and the luteal phase (days 15–28). Each phase brings different hormonal changes that affect your energy, mood, and body.',
            ),
            _Section(
              'Menstrual Phase',
              'This is when your period occurs. Hormone levels are at their lowest, which can lead to fatigue and lower energy. This is a great time for rest, gentle movement like yoga or walking, and reflection.',
            ),
            _Section(
              'Follicular Phase',
              'As estrogen rises, you may notice increased energy and improved mood. This is often a great time to start new projects, try new workouts, and socialize. Your body is preparing for ovulation.',
            ),
            _Section(
              'Ovulation',
              'Estrogen peaks and you may feel your most energetic and confident. This short phase (about 24–48 hours) is when fertility is highest. Many women report feeling more social and creative during this time.',
            ),
            _Section(
              'Luteal Phase',
              'Progesterone rises and you may experience PMS symptoms like bloating, mood changes, and cravings. Focus on nourishing foods, adequate sleep, and stress-reducing activities.',
            ),
          ],
          takeaways: [
            'A typical cycle is 21–35 days, with 28 days being average',
            'Tracking your cycle helps you anticipate energy and mood changes',
            'Each phase offers unique strengths you can leverage',
            'Irregularities lasting several months warrant a doctor visit',
          ],
        );
      case 'Nutrition for Hormonal Balance':
        return _ArticleContent(
          bannerIcon: Icons.restaurant,
          bannerColor: const Color(0xFFC9A96E),
          intro:
              'What you eat plays a significant role in hormonal health. Certain nutrients and dietary patterns can help support balanced hormones throughout your cycle.',
          sections: [
            _Section(
              'Essential Nutrients',
              'Key nutrients for hormonal balance include omega-3 fatty acids (found in salmon, walnuts, and flaxseed), magnesium (dark leafy greens, dark chocolate, avocado), zinc (pumpkin seeds, chickpeas), and B vitamins (whole grains, eggs, legumes).',
            ),
            _Section(
              'Eating for Each Phase',
              'During menstruation, focus on iron-rich foods like spinach and lentils to replenish what you lose. During the follicular phase, lighter foods and fermented vegetables support rising estrogen. Around ovulation, fiber-rich foods help your body process the estrogen peak.',
            ),
            _Section(
              'Foods to Embrace',
              'Cruciferous vegetables (broccoli, cauliflower, kale) contain compounds that support healthy estrogen metabolism. Healthy fats from avocado, olive oil, and nuts provide building blocks for hormone production. Colorful fruits and vegetables deliver antioxidants that reduce inflammation.',
            ),
            _Section(
              'Foods to Limit',
              'Excess sugar can cause blood sugar spikes that stress your hormonal system. Highly processed foods often contain additives that may disrupt endocrine function. Excessive caffeine and alcohol can affect cortisol and estrogen levels.',
            ),
          ],
          takeaways: [
            'Prioritize whole, unprocessed foods rich in fiber and healthy fats',
            'Include omega-3s, magnesium, and zinc daily',
            'Eat iron-rich foods during your period to replenish stores',
            'Limit sugar, processed foods, and excessive caffeine',
          ],
        );
      case 'Getting Started with Mindfulness':
        return _ArticleContent(
          bannerIcon: Icons.self_improvement,
          bannerColor: const Color(0xFFC9A96E),
          intro:
              'Mindfulness is the practice of bringing your full attention to the present moment without judgment. Even a few minutes a day can reduce stress and improve emotional wellbeing.',
          sections: [
            _Section(
              'What Is Mindfulness?',
              'Mindfulness means paying attention to what is happening right now — your breath, your thoughts, your surroundings — without trying to change anything. It is not about clearing your mind, but about noticing what is there.',
            ),
            _Section(
              'A Simple Starting Practice',
              'Find a quiet place and sit comfortably. Close your eyes and focus on your breath. Notice the sensation of air entering and leaving your nostrils. When your mind wanders (it will!), gently bring your attention back to your breath. Start with just 3 minutes.',
            ),
            _Section(
              'Everyday Mindfulness',
              'You do not need to meditate to be mindful. Try eating a meal without your phone, noticing the flavors and textures. Walk outside and pay attention to the sounds around you. Even washing dishes can become a mindful activity when you focus fully on the task.',
            ),
          ],
          takeaways: [
            'Start with just 3 minutes a day and gradually increase',
            'Your mind will wander — that is normal and part of the practice',
            'Mindfulness can be practiced during any daily activity',
            'Consistency matters more than duration',
          ],
        );
      case 'Managing Anxiety Naturally':
        return _ArticleContent(
          bannerIcon: Icons.spa,
          bannerColor: const Color(0xFF6B5220),
          intro:
              'Anxiety is your body\'s natural response to stress, but when it becomes overwhelming, natural techniques can help you regain a sense of calm.',
          sections: [
            _Section(
              'Box Breathing',
              'Breathe in through your nose for 4 counts, hold for 4 counts, exhale through your mouth for 4 counts, and hold for 4 counts. Repeat this cycle 4 times. This technique activates your parasympathetic nervous system, helping your body shift out of fight-or-flight mode.',
            ),
            _Section(
              'The 5-4-3-2-1 Grounding Technique',
              'When anxiety feels overwhelming, engage your senses. Notice 5 things you can see, 4 things you can touch, 3 things you can hear, 2 things you can smell, and 1 thing you can taste. This brings you back to the present moment.',
            ),
            _Section(
              'Movement and Nature',
              'Physical activity releases endorphins that naturally reduce anxiety. Even a 15-minute walk can make a significant difference. Spending time in nature has been shown to lower cortisol levels and reduce rumination.',
            ),
          ],
          takeaways: [
            'Box breathing can calm your nervous system in minutes',
            'Grounding techniques redirect your focus from worry to the present',
            'Regular exercise is one of the most effective natural anxiety reducers',
            'Seek professional help if anxiety significantly impacts your daily life',
          ],
        );
      default:
        return _ArticleContent(
          bannerIcon: Icons.article_outlined,
          bannerColor: const Color(0xFFC9A96E),
          intro: description,
          sections: [
            _Section(
              'Overview',
              'This article provides helpful information and practical tips to support your health and wellbeing journey. Understanding these topics can empower you to make informed decisions about your health.',
            ),
            _Section(
              'Why It Matters',
              'Taking time to learn about your health is one of the most impactful things you can do. Knowledge helps you recognize patterns, communicate better with healthcare providers, and take proactive steps toward wellness.',
            ),
          ],
          takeaways: [
            'Stay curious about your health and wellbeing',
            'Small, consistent changes make the biggest difference',
            'Always consult with a healthcare professional for personalized advice',
          ],
        );
    }
  }
}

class _ArticleContent {
  final IconData bannerIcon;
  final Color bannerColor;
  final String intro;
  final List<_Section> sections;
  final List<String> takeaways;

  const _ArticleContent({
    required this.bannerIcon,
    required this.bannerColor,
    required this.intro,
    required this.sections,
    required this.takeaways,
  });
}

class _Section {
  final String heading;
  final String body;

  const _Section(this.heading, this.body);
}
