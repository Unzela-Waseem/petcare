import '../models/care_models.dart';

abstract interface class OfflineArticleService {
  Future<void> save(BlogArticle article);
  Future<void> remove(String articleId);
  Future<bool> contains(String articleId);
  Future<List<BlogArticle>> loadAll();
}
