import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/style_feed_provider.dart';
import '../widgets/style_post_card.dart';

class StyleFeedScreen extends ConsumerStatefulWidget {
  const StyleFeedScreen({super.key});

  @override
  ConsumerState<StyleFeedScreen> createState() => _StyleFeedScreenState();
}

class _StyleFeedScreenState extends ConsumerState<StyleFeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChange);
    _scrollController.addListener(_onScroll);

    // Load initial posts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(styleFeedProvider.notifier).loadPosts();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChange);
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChange() {
    if (!_tabController.indexIsChanging) return;

    final mode = switch (_tabController.index) {
      0 => FeedMode.forYou,
      1 => FeedMode.trending,
      2 => FeedMode.nearby,
      _ => FeedMode.forYou,
    };

    ref.read(styleFeedProvider.notifier).loadPosts(mode: mode);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Near bottom, load more
      ref.read(styleFeedProvider.notifier).loadMorePosts();
    }
  }

  Future<void> _refresh() async {
    await ref.read(styleFeedProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(styleFeedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Style Feed'),
        backgroundColor: AppColors.surface,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'For You'),
            Tab(text: 'Trending 🔥'),
            Tab(text: 'Nearby 📍'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/style-feed/map'),
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Map View',
          ),
          IconButton(
            onPressed: () => context.push('/style-feed/create'),
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Share Your Style',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: feedState.isLoading && feedState.posts.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : feedState.errorMessage != null && feedState.posts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load posts',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          feedState.errorMessage!,
                          style: const TextStyle(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : feedState.posts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.photo_camera_outlined,
                              size: 80,
                              color: AppColors.textHint,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No posts yet',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Be the first to share your style!',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () =>
                                  context.push('/style-feed/create'),
                              icon: const Icon(Icons.add_photo_alternate),
                              label: const Text('Share Your Style'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: feedState.posts.length +
                            (feedState.isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == feedState.posts.length) {
                            // Loading indicator at bottom
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final post = feedState.posts[index];
                          return StylePostCard(
                            post: post,
                            onTap: () {
                              context.push('/style-feed/post', extra: post);
                            },
                          );
                        },
                      ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/style-feed/create'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Share Style'),
      ),
    );
  }
}
