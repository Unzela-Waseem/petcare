import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/care_models.dart';
import '../../domain/repositories/offline_article_service.dart';

class SharedPreferencesOfflineArticleService implements OfflineArticleService {
  static const _key = 'pawfectcare.offline_articles';

  @override
  Future<bool> contains(String articleId) async =>
      (await _read()).containsKey(articleId);

  @override
  Future<List<BlogArticle>> loadAll() async {
    final values = await _read();
    final articles = <BlogArticle>[];
    for (final value in values.values) {
      final article = _decode(value);
      if (article != null) articles.add(article);
    }
    return articles..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
  }

  @override
  Future<void> remove(String articleId) async {
    final values = await _read()
      ..remove(articleId);
    await _write(values);
  }

  @override
  Future<void> save(BlogArticle article) async {
    final values = await _read();
    values[article.id] = jsonEncode({
      'id': article.id,
      'title': article.title,
      'category': article.category,
      'summary': article.summary,
      'content': article.content,
      'publishedAt': article.publishedAt.toIso8601String(),
      'imageUrl': article.imageUrl,
    });
    await _write(values);
  }

  Future<Map<String, String>> _read() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, value as String));
    } on Object {
      await preferences.remove(_key);
      return {};
    }
  }

  Future<void> _write(Map<String, String> values) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, jsonEncode(values));
  }

  BlogArticle? _decode(String value) {
    try {
      final data = jsonDecode(value) as Map<String, dynamic>;
      return BlogArticle(
        id: data['id'] as String,
        title: data['title'] as String,
        category: data['category'] as String,
        summary: data['summary'] as String,
        content: data['content'] as String,
        publishedAt: DateTime.parse(data['publishedAt'] as String),
        imageUrl: data['imageUrl'] as String?,
      );
    } on Object {
      return null;
    }
  }
}
