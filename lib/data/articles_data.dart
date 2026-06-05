import 'package:flutter/material.dart';
import '../models/article.dart';

// ---------------------------------------------------------------------------
// Individual article definitions with stable UUIDs
// ---------------------------------------------------------------------------

const _kUnderstandingYourCycle = Article(
  id: 'a1e7f3b0-1001-4a11-8011-000000000001',
  title: 'Understanding Your Cycle',
  description: 'Learn about the phases of your menstrual cycle',
  readTime: '5 min read',
  category: 'REPRODUCTIVE HEALTH',
  icon: Icons.favorite,
  color: Color(0xFF8B6548),
);

const _kNutritionForHormonalBalance = Article(
  id: 'a1e7f3b0-1001-4a11-8011-000000000002',
  title: 'Nutrition for Hormonal Balance',
  description: 'Foods that support hormonal health',
  readTime: '7 min read',
  category: 'PHYSICAL WELLNESS',
  icon: Icons.restaurant,
  color: Color(0xFFC9A96E),
);

const _kGettingStartedWithMindfulness = Article(
  id: 'a1e7f3b0-1001-4a11-8011-000000000003',
  title: 'Getting Started with Mindfulness',
  description: 'Simple techniques to bring awareness to your daily life',
  readTime: '4 min read',
  category: 'MENTAL HEALTH',
  icon: Icons.self_improvement,
  color: Color(0xFFC9A96E),
);

const _kManagingAnxietyNaturally = Article(
  id: 'a1e7f3b0-1001-4a11-8011-000000000004',
  title: 'Managing Anxiety Naturally',
  description: 'Breathing exercises and grounding techniques',
  readTime: '6 min read',
  category: 'MENTAL HEALTH',
  icon: Icons.spa,
  color: Color(0xFF6B5220),
);

const _kThePowerOfJournaling = Article(
  id: 'a1e7f3b0-1001-4a11-8011-000000000005',
  title: 'The Power of Journaling',
  description: 'How writing can improve your emotional wellbeing',
  readTime: '5 min read',
  category: 'MENTAL HEALTH',
  icon: Icons.edit_note,
  color: Color(0xFF8B6548),
);

const _kBuildingAWorkoutRoutine = Article(
  id: 'a1e7f3b0-1001-4a11-8011-000000000006',
  title: 'Building a Workout Routine',
  description: 'How to create a sustainable exercise habit',
  readTime: '5 min read',
  category: 'PHYSICAL WELLNESS',
  icon: Icons.fitness_center,
  color: Color(0xFFC9A96E),
);

const _kNutritionBasics = Article(
  id: 'a1e7f3b0-1001-4a11-8011-000000000007',
  title: 'Nutrition Basics',
  description: 'Understanding macros and balanced meals',
  readTime: '7 min read',
  category: 'PHYSICAL WELLNESS',
  icon: Icons.restaurant_menu,
  color: Color(0xFF6B5220),
);

const _kStretchingForDeskWorkers = Article(
  id: 'a1e7f3b0-1001-4a11-8011-000000000008',
  title: 'Stretching for Desk Workers',
  description: 'Quick stretches to relieve tension throughout the day',
  readTime: '3 min read',
  category: 'PHYSICAL WELLNESS',
  icon: Icons.accessibility_new,
  color: Color(0xFF8B6548),
);

const _kWhenToSeeASpecialist = Article(
  id: 'a1e7f3b0-1001-4a11-8011-000000000009',
  title: 'When to See a Specialist',
  description: 'Signs that it may be time to consult a professional',
  readTime: '4 min read',
  category: 'REPRODUCTIVE HEALTH',
  icon: Icons.local_hospital,
  color: Color(0xFF6B5220),
);

const _kBuildingASleepRoutine = Article(
  id: 'a1e7f3b0-1001-4a11-8011-000000000010',
  title: 'Building a Sleep Routine',
  description: 'Habits that promote restful, quality sleep',
  readTime: '5 min read',
  category: 'SLEEP & REST',
  icon: Icons.bedtime,
  color: Color(0xFF8B6548),
);

const _kScreenTimeAndSleep = Article(
  id: 'a1e7f3b0-1001-4a11-8011-000000000011',
  title: 'Screen Time and Sleep',
  description: 'How blue light affects your circadian rhythm',
  readTime: '4 min read',
  category: 'SLEEP & REST',
  icon: Icons.phone_android,
  color: Color(0xFFC9A96E),
);

const _kRelaxationTechniques = Article(
  id: 'a1e7f3b0-1001-4a11-8011-000000000012',
  title: 'Relaxation Techniques',
  description: 'Wind-down practices for better rest',
  readTime: '3 min read',
  category: 'SLEEP & REST',
  icon: Icons.self_improvement,
  color: Color(0xFF6B5220),
);

// ---------------------------------------------------------------------------
// Collections
// ---------------------------------------------------------------------------

/// Articles shown in the "Recommended for you" carousel.
const featuredArticles = <Article>[
  _kUnderstandingYourCycle,
  _kNutritionForHormonalBalance,
  _kGettingStartedWithMindfulness,
  _kManagingAnxietyNaturally,
];

const _mentalHealthArticles = <Article>[
  _kGettingStartedWithMindfulness,
  _kManagingAnxietyNaturally,
  _kThePowerOfJournaling,
];

const _physicalWellnessArticles = <Article>[
  _kBuildingAWorkoutRoutine,
  _kNutritionBasics,
  _kStretchingForDeskWorkers,
];

const _reproductiveHealthArticles = <Article>[
  _kUnderstandingYourCycle,
  _kNutritionForHormonalBalance,
  _kWhenToSeeASpecialist,
];

const _sleepAndRestArticles = <Article>[
  _kBuildingASleepRoutine,
  _kScreenTimeAndSleep,
  _kRelaxationTechniques,
];

/// Every article across all categories, deduplicated.
const allArticles = <Article>[
  _kUnderstandingYourCycle,
  _kNutritionForHormonalBalance,
  _kGettingStartedWithMindfulness,
  _kManagingAnxietyNaturally,
  _kThePowerOfJournaling,
  _kBuildingAWorkoutRoutine,
  _kNutritionBasics,
  _kStretchingForDeskWorkers,
  _kWhenToSeeASpecialist,
  _kBuildingASleepRoutine,
  _kScreenTimeAndSleep,
  _kRelaxationTechniques,
];

/// Look up any article by its UUID.
final articlesById = <String, Article>{
  for (final a in allArticles) a.id: a,
};

/// Returns the articles for a given category name.
List<Article> articlesForCategory(String category) {
  switch (category) {
    case 'Mental Health':
      return _mentalHealthArticles;
    case 'Physical Wellness':
      return _physicalWellnessArticles;
    case 'Reproductive Health':
      return _reproductiveHealthArticles;
    case 'Sleep & Rest':
      return _sleepAndRestArticles;
    default:
      return const [];
  }
}
