import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/models/care_models.dart';
import '../../../domain/models/user_role.dart';
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

  bool get _canManageBlogs =>
      widget.user.role == UserRole.veterinarian ||
      widget.user.role == UserRole.shelterAdmin;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.cream,
    appBar: AppBar(
      title: const Text('Pet Care Tips & Guides'),
      actions: [
        IconButton(
          tooltip: _offlineOnly ? 'Show all tips' : 'Offline articles',
          onPressed: () => setState(() => _offlineOnly = !_offlineOnly),
          icon: Icon(
            _offlineOnly
                ? Icons.cloud_done_rounded
                : Icons.offline_pin_outlined,
          ),
        ),
        if (_canManageBlogs)
          IconButton(
            tooltip: 'Write new tip',
            onPressed: () => _openBlogEditor(context),
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
      ],
    ),
    floatingActionButton: _canManageBlogs
        ? FloatingActionButton.extended(
            onPressed: () => _openBlogEditor(context),
            backgroundColor: AppColors.orangeDeep,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.edit_note_rounded),
            label: const Text('Write Tip'),
          )
        : null,
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
    const predefinedCategories = [
      'All',
      'Training',
      'Nutrition',
      'First Aid',
      'Pet Care',
      'Grooming',
      'Health',
    ];
    final dynamicCategories =
        articles.map((item) => item.category).toSet().toList()..sort();
    final allCategories = {
      ...predefinedCategories,
      ...dynamicCategories,
    }.toList();

    final query = _query.trim().toLowerCase();
    final visible = articles.where((item) {
      final matchesCategory = _category == null ||
          _category == 'All' ||
          item.category.toLowerCase() == _category!.toLowerCase();
      final matchesQuery = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.summary.toLowerCase().contains(query) ||
          item.content.toLowerCase().contains(query) ||
          item.tags.any((tag) => tag.toLowerCase().contains(query));
      return matchesCategory && matchesQuery;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'Search title, keyword, or tag (#nutrition, #firstaid)',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => setState(() => _query = ''),
                    )
                  : null,
            ),
          ),
        ),
        SizedBox(
          height: 46,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: allCategories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final cat = allCategories[i];
              final isSelected =
                  (_category == null && cat == 'All') || _category == cat;
              return ChoiceChip(
                label: Text(cat),
                selected: isSelected,
                onSelected: (_) => setState(
                  () => _category = cat == 'All' ? null : cat,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: visible.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_stories_outlined,
                          size: 48,
                          color: AppColors.muted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          offline
                              ? 'No articles saved for offline reading.'
                              : 'No matching care tips found.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 80),
                  itemCount: visible.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
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

  void _openBlogEditor(BuildContext context, [BlogArticle? initial]) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BlogEditorSheet(
        initial: initial,
        user: widget.user,
        services: widget.services,
      ),
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
  late BlogArticle _currentArticle;

  bool get _canEdit =>
      widget.user.role == UserRole.shelterAdmin ||
      (widget.user.role == UserRole.veterinarian &&
          (widget.article.authorId == null ||
              widget.article.authorId == widget.user.uid));

  @override
  void initState() {
    super.initState();
    _currentArticle = widget.article;
    widget.services.offlineArticles
        .contains(_currentArticle.id)
        .then((value) {
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
          tooltip: 'Share article',
          onPressed: () => _shareArticle(context),
          icon: const Icon(Icons.share_outlined),
        ),
        IconButton(
          tooltip: _offline ? 'Remove offline copy' : 'Save offline',
          onPressed: _toggleOffline,
          icon: Icon(
            _offline
                ? Icons.offline_pin_rounded
                : Icons.download_for_offline_outlined,
          ),
        ),
        if (_canEdit)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (action) {
              if (action == 'edit') {
                _editArticle(context);
              } else if (action == 'delete') {
                _deleteArticle(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Edit Article'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline,
                        color: AppColors.danger, size: 18),
                    SizedBox(width: 10),
                    Text(
                      'Delete Article',
                      style: TextStyle(color: AppColors.danger),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 36),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.peachLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _currentArticle.category.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  color: AppColors.orangeDeep,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            Text(
              DateFormat.yMMMd().format(_currentArticle.publishedAt),
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _currentArticle.title,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        if (_currentArticle.authorName != null &&
            _currentArticle.authorName!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline_rounded,
                  size: 16, color: AppColors.muted),
              const SizedBox(width: 6),
              Text(
                'By ${_currentArticle.authorName}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ],
        if (_currentArticle.tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _currentArticle.tags.map((tag) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '#$tag',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            _currentArticle.summary,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _currentArticle.content,
          style: const TextStyle(fontSize: 16, height: 1.65),
        ),
        const SizedBox(height: 26),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.yellow,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded,
                  color: AppColors.ink, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Educational content does not replace examination or treatment by a qualified veterinarian.',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => _shareArticle(context),
          icon: const Icon(Icons.share_outlined),
          label: const Text('Share Article with Pet Parents'),
        ),
      ],
    ),
  );

  Future<void> _toggleOffline() async {
    if (_offline) {
      await widget.services.offlineArticles.remove(_currentArticle.id);
    } else {
      await widget.services.offlineArticles.save(_currentArticle);
    }
    if (!mounted) return;
    setState(() => _offline = !_offline);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _offline
              ? 'Saved to offline library! 📥'
              : 'Removed from offline library.',
        ),
      ),
    );
  }

  void _shareArticle(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Share "${_currentArticle.title}"',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.mint,
                child: Icon(Icons.chat_bubble_outline, color: AppColors.ink),
              ),
              title: const Text('Share via WhatsApp'),
              subtitle: const Text('Send article summary & advice to a friend'),
              onTap: () async {
                Navigator.of(context).pop();
                final text =
                    '🐾 *${_currentArticle.title}*\n\n${_currentArticle.summary}\n\nRead more on PawfectCare!';
                final url = Uri.parse(
                    'https://wa.me/?text=${Uri.encodeComponent(text)}');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.lavender,
                child: Icon(Icons.email_outlined, color: AppColors.ink),
              ),
              title: const Text('Share via Email'),
              subtitle: const Text('Email article to your family or client'),
              onTap: () async {
                Navigator.of(context).pop();
                final uri = Uri(
                  scheme: 'mailto',
                  queryParameters: {
                    'subject': '🐾 PawfectCare: ${_currentArticle.title}',
                    'body':
                        '${_currentArticle.title}\n\n${_currentArticle.summary}\n\n${_currentArticle.content}',
                  },
                );
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editArticle(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BlogEditorSheet(
        initial: _currentArticle,
        user: widget.user,
        services: widget.services,
        onSaved: (saved) => setState(() => _currentArticle = saved),
      ),
    );
  }

  Future<void> _deleteArticle(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Care Tip?'),
        content: const Text(
          'This article will be removed for all users.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await widget.services.care.deleteBlogArticle(_currentArticle.id);
    navigator.pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Article deleted successfully.')),
    );
  }
}

class _BlogEditorSheet extends StatefulWidget {
  const _BlogEditorSheet({
    required this.user,
    required this.services,
    this.initial,
    this.onSaved,
  });

  final AppUser user;
  final AppServices services;
  final BlogArticle? initial;
  final ValueChanged<BlogArticle>? onSaved;

  @override
  State<_BlogEditorSheet> createState() => _BlogEditorSheetState();
}

class _BlogEditorSheetState extends State<_BlogEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _summaryController;
  late final TextEditingController _contentController;
  late final TextEditingController _tagsController;
  late String _category;
  bool _published = true;
  bool _saving = false;

  static const _categories = [
    'Training',
    'Nutrition',
    'First Aid',
    'Pet Care',
    'Grooming',
    'Health',
  ];

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _titleController = TextEditingController(text: init?.title ?? '');
    _summaryController = TextEditingController(text: init?.summary ?? '');
    _contentController = TextEditingController(text: init?.content ?? '');
    _tagsController = TextEditingController(
      text: init?.tags.join(', ') ?? '',
    );
    _category = init?.category ?? 'Pet Care';
    _published = init?.published ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 20 + bottomInset),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.initial == null
                  ? 'Write Pet Care Tip 📝'
                  : 'Edit Care Tip 📝',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Article Title',
                hintText: 'e.g. Caring for Puppies During Monsoon',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) => setState(() => _category = val ?? 'Pet Care'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (comma-separated)',
                hintText: 'e.g. puppies, diet, emergency',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _summaryController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Short Summary',
                hintText: 'One or two sentences highlighting main point.',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Summary is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contentController,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Full Content & Advice',
                hintText: 'Detailed veterinary or shelter guidance...',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Content is required' : null,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Published immediately'),
              subtitle: const Text('Toggle off to save as draft/archive'),
              value: _published,
              activeColor: AppColors.orangeDeep,
              onChanged: (v) => setState(() => _published = v),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ink,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      widget.initial == null
                          ? 'Publish Care Tip'
                          : 'Save Changes',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final tags = _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final article = BlogArticle(
        id: widget.initial?.id ?? '',
        title: _titleController.text.trim(),
        category: _category,
        summary: _summaryController.text.trim(),
        content: _contentController.text.trim(),
        publishedAt: widget.initial?.publishedAt ?? DateTime.now(),
        authorId: widget.user.uid,
        authorName: widget.user.name.isEmpty
            ? (widget.user.role == UserRole.veterinarian
                ? 'Dr. Veterinarian'
                : 'Shelter Team')
            : widget.user.name,
        tags: tags,
        published: _published,
      );

      final id = await widget.services.care.saveBlogArticle(article);
      final savedArticle = article.copyWith(id: id);
      widget.onSaved?.call(savedArticle);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.initial == null
                  ? 'Care tip published! 🐾'
                  : 'Care tip updated! ✨',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save article: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
                        errorBuilder: (context, error, stackTrace) =>
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
