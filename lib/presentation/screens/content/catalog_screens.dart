import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/models/care_models.dart';
import '../../../domain/repositories/care_repository.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({required this.user, required this.services, super.key});
  final AppUser user;
  final AppServices services;

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  String _query = '';
  String? _category;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.cream,
    appBar: AppBar(title: const Text('Pet Store')),
    body: StreamBuilder<List<ProductItem>>(
      stream: widget.services.care.watchProducts(),
      builder: (context, productSnapshot) {
        if (productSnapshot.hasError) return _error(productSnapshot.error);
        if (!productSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final products = productSnapshot.data!;
        final categories =
            products.map((item) => item.category).toSet().toList()..sort();
        return StreamBuilder<Set<String>>(
          stream: widget.services.care.watchWishlist(widget.user.uid),
          builder: (context, savedSnapshot) {
            final saved = savedSnapshot.data ?? const <String>{};
            final query = _query.trim().toLowerCase();
            final visible = products.where((item) {
              return (_category == null || item.category == _category) &&
                  (item.name.toLowerCase().contains(query) ||
                      item.description.toLowerCase().contains(query));
            }).toList();
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: TextField(
                    onChanged: (value) => setState(() => _query = value),
                    decoration: const InputDecoration(
                      hintText: 'Search products',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),
                SizedBox(
                  height: 46,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: _category == null,
                        onSelected: (_) => setState(() => _category = null),
                      ),
                      const SizedBox(width: 8),
                      ...categories.map(
                        (category) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(category),
                            selected: _category == category,
                            onSelected: (_) =>
                                setState(() => _category = category),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: visible.isEmpty
                      ? const Center(child: Text('No matching products.'))
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 310,
                                mainAxisExtent: 360,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                          itemCount: visible.length,
                          itemBuilder: (context, index) {
                            final product = visible[index];
                            return _ProductCard(
                              product: product,
                              saved: saved.contains(product.id),
                              onSave: () => widget.services.care.setWishlist(
                                uid: widget.user.uid,
                                productId: product.id,
                                saved: !saved.contains(product.id),
                              ),
                              onBuy: () => _openPurchase(product),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    ),
  );

  Widget _error(Object? error) => Center(
    child: Text(
      error is CareFailure ? error.message : 'Products could not be loaded.',
    ),
  );

  Future<void> _openPurchase(ProductItem product) async {
    final uri = Uri.tryParse(product.purchaseUrl);
    if (uri == null || uri.scheme != 'https') {
      _show('This product does not have a valid secure purchase link.');
      return;
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      _show('The purchase link could not be opened.');
    }
  }

  void _show(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

class CareTipsScreen extends StatefulWidget {
  const CareTipsScreen({required this.user, required this.services, super.key});
  final AppUser user;
  final AppServices services;

  @override
  State<CareTipsScreen> createState() => _CareTipsScreenState();
}

class _CareTipsScreenState extends State<CareTipsScreen> {
  String _query = '';
  String? _category;
  bool _offlineOnly = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.cream,
    appBar: AppBar(
      title: const Text('Pet Care Tips'),
      actions: [
        IconButton(
          tooltip: 'Offline articles',
          onPressed: () => setState(() => _offlineOnly = !_offlineOnly),
          icon: Icon(
            _offlineOnly
                ? Icons.cloud_done_rounded
                : Icons.offline_pin_outlined,
          ),
        ),
      ],
    ),
    body: _offlineOnly
        ? FutureBuilder<List<BlogArticle>>(
            future: widget.services.offlineArticles.loadAll(),
            builder: (context, snapshot) => _articlesBody(
              snapshot.data ?? const [],
              const <String>{},
              offline: true,
            ),
          )
        : StreamBuilder<List<BlogArticle>>(
            stream: widget.services.care.watchBlogs(),
            builder: (context, articleSnapshot) {
              if (articleSnapshot.hasError) {
                return FutureBuilder<List<BlogArticle>>(
                  future: widget.services.offlineArticles.loadAll(),
                  builder: (context, cached) => _articlesBody(
                    cached.data ?? const [],
                    const <String>{},
                    offline: true,
                  ),
                );
              }
              if (!articleSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return StreamBuilder<Set<String>>(
                stream: widget.services.care.watchBookmarks(widget.user.uid),
                builder: (context, bookmarkSnapshot) => _articlesBody(
                  articleSnapshot.data!,
                  bookmarkSnapshot.data ?? const <String>{},
                ),
              );
            },
          ),
  );

  Widget _articlesBody(
    List<BlogArticle> articles,
    Set<String> bookmarks, {
    bool offline = false,
  }) {
    final categories = articles.map((item) => item.category).toSet().toList()
      ..sort();
    final query = _query.trim().toLowerCase();
    final visible = articles
        .where(
          (item) =>
              (_category == null || item.category == _category) &&
              (item.title.toLowerCase().contains(query) ||
                  item.summary.toLowerCase().contains(query) ||
                  item.content.toLowerCase().contains(query)),
        )
        .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              hintText: 'Search article keywords',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
        ),
        SizedBox(
          height: 46,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _category == null,
                onSelected: (_) => setState(() => _category = null),
              ),
              const SizedBox(width: 8),
              ...categories.map(
                (category) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: _category == category,
                    onSelected: (_) => setState(() => _category = category),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? Center(
                  child: Text(
                    offline
                        ? 'No articles saved for offline reading.'
                        : 'No matching articles.',
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final article = visible[index];
                    return _ArticleCard(
                      article: article,
                      bookmarked: bookmarks.contains(article.id),
                      offline: offline,
                      onOpen: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => ArticleScreen(
                            article: article,
                            user: widget.user,
                            services: widget.services,
                          ),
                        ),
                      ),
                      onBookmark: offline
                          ? null
                          : () => widget.services.care.setBookmark(
                              uid: widget.user.uid,
                              blogId: article.id,
                              saved: !bookmarks.contains(article.id),
                            ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class ArticleScreen extends StatefulWidget {
  const ArticleScreen({
    required this.article,
    required this.user,
    required this.services,
    super.key,
  });
  final BlogArticle article;
  final AppUser user;
  final AppServices services;

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    widget.services.offlineArticles.contains(widget.article.id).then((value) {
      if (mounted) setState(() => _offline = value);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.cream,
    appBar: AppBar(
      title: const Text('Care Guide'),
      actions: [
        IconButton(
          tooltip: _offline ? 'Remove offline copy' : 'Save offline',
          onPressed: _toggleOffline,
          icon: Icon(
            _offline
                ? Icons.offline_pin_rounded
                : Icons.download_for_offline_outlined,
          ),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
      children: [
        Text(
          widget.article.category.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: AppColors.orangeDeep,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.article.title,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 8),
        Text(DateFormat.yMMMd().format(widget.article.publishedAt)),
        const SizedBox(height: 22),
        Text(
          widget.article.summary,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 18),
        Text(
          widget.article.content,
          style: const TextStyle(fontSize: 16, height: 1.6),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.yellow,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Educational content does not replace examination or treatment by a qualified veterinarian.',
          ),
        ),
      ],
    ),
  );

  Future<void> _toggleOffline() async {
    if (_offline) {
      await widget.services.offlineArticles.remove(widget.article.id);
    } else {
      await widget.services.offlineArticles.save(widget.article);
    }
    if (mounted) setState(() => _offline = !_offline);
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.saved,
    required this.onSave,
    required this.onBuy,
  });
  final ProductItem product;
  final bool saved;
  final VoidCallback onSave;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? Image.network(
                        product.imageUrl!,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const _ProductImageFallback(),
                      )
                    : const _ProductImageFallback(),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              onPressed: onSave,
              icon: Icon(
                saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: saved ? AppColors.danger : AppColors.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          product.category,
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        Text(
          product.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 5),
        Text(product.description, maxLines: 2, overflow: TextOverflow.ellipsis),
        const Spacer(),
        Text(
          '\$${product.price.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onBuy,
            child: const Text('Open Purchase Link'),
          ),
        ),
      ],
    ),
  );
}

class _ProductImageFallback extends StatelessWidget {
  const _ProductImageFallback();

  @override
  Widget build(BuildContext context) => Container(
    height: 100,
    color: AppColors.yellow,
    alignment: Alignment.center,
    child: const Icon(Icons.shopping_bag_outlined, size: 34),
  );
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({
    required this.article,
    required this.bookmarked,
    required this.offline,
    required this.onOpen,
    this.onBookmark,
  });
  final BlogArticle article;
  final bool bookmarked;
  final bool offline;
  final VoidCallback onOpen;
  final VoidCallback? onBookmark;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onOpen,
    borderRadius: BorderRadius.circular(24),
    child: Ink(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.peachLight,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.surface,
            child: Icon(Icons.auto_stories_outlined),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  '${article.category} · ${article.summary}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (offline)
            const Icon(Icons.offline_pin_rounded)
          else
            IconButton(
              onPressed: onBookmark,
              icon: Icon(
                bookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
              ),
            ),
        ],
      ),
    ),
  );
}
