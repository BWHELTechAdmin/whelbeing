import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/articles_data.dart';
import '../models/article.dart';

/// Global notifier for the ordered list of previously read articles (most recent first).
/// Populated on [ReadsRepository.init] and updated by [ReadsRepository.recordRead].
final previousReadsNotifier = ValueNotifier<List<Article>>([]);

/// Manages the user's article read history via SharedPreferences.
class ReadsRepository {
  ReadsRepository._();

  static const _kKey = 'previous_reads_v1';
  static bool _initialized = false;

  /// Loads the persisted read history into [previousReadsNotifier].
  /// Idempotent — subsequent calls are no-ops.
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_kKey) ?? [];
    previousReadsNotifier.value =
        ids.map((id) => articlesById[id]).whereType<Article>().toList();
  }

  /// Marks [article] as read, prepending it to the history (most recent first).
  /// Deduplicates by [Article.id] so each article appears at most once.
  /// Updates [previousReadsNotifier] synchronously for immediate UI response,
  /// then persists to SharedPreferences in the background.
  static Future<void> recordRead(Article article) async {
    final current = List<Article>.from(previousReadsNotifier.value);
    current.removeWhere((a) => a.id == article.id);
    previousReadsNotifier.value = [article, ...current];

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _kKey,
      previousReadsNotifier.value.map((a) => a.id).toList(),
    );
  }
}
