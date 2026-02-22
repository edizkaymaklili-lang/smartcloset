import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/style_feed_provider.dart';
import '../widgets/style_post_card.dart';
import '../widgets/map_post_preview_sheet.dart';
import '../../domain/entities/style_post.dart';

class StyleFeedScreen extends ConsumerStatefulWidget {
  const StyleFeedScreen({super.key});

  @override
  ConsumerState<StyleFeedScreen> createState() => _StyleFeedScreenState();
}

class _StyleFeedScreenState extends ConsumerState<StyleFeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  int _currentTabIndex = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChange);
    _scrollController.addListener(_onScroll);

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
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChange() {
    if (!_tabController.indexIsChanging) return;
    setState(() => _currentTabIndex = _tabController.index);

    final mode = switch (_tabController.index) {
      0 => FeedMode.forYou,
      1 => FeedMode.trending,
      2 => FeedMode.nearby,
      _ => FeedMode.forYou,
    };

    ref.read(styleFeedProvider.notifier).loadPosts(mode: mode);
  }

  void _onScroll() {
    if (_currentTabIndex == 2) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
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
          if (_currentTabIndex != 2)
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
      body: _currentTabIndex == 2
          ? _NearbyMapView(feedState: feedState, onRetry: _refresh)
          : RefreshIndicator(
              onRefresh: _refresh,
              child: _buildPostsContent(feedState),
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

  Widget _buildPostsContent(StyleFeedState feedState) {
    if (feedState.isLoading && feedState.posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (feedState.errorMessage != null && feedState.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text('Failed to load posts',
                style: Theme.of(context).textTheme.titleMedium),
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
      );
    }

    if (feedState.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.photo_camera_outlined,
                size: 80, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text('No posts yet', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Be the first to share your style!',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/style-feed/create'),
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Share Your Style'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    // Apply search filter
    final filteredPosts = _searchQuery.isEmpty
        ? feedState.posts
        : feedState.posts.where((post) {
            final query = _searchQuery.toLowerCase();
            return post.userDisplayName.toLowerCase().contains(query) ||
                   (post.description?.toLowerCase().contains(query) ?? false) ||
                   (post.location?.city.toLowerCase().contains(query) ?? false);
          }).toList();

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search posts, users, locations...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppColors.background,
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        // Posts List
        Expanded(
          child: filteredPosts.isEmpty && _searchQuery.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off, size: 64, color: AppColors.textHint),
                      const SizedBox(height: 16),
                      Text('No posts found', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        'Try a different search term',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  itemCount: filteredPosts.length + (feedState.isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == filteredPosts.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    final post = filteredPosts[index];
                    return StylePostCard(
                      post: post,
                      onTap: () => context.push('/style-feed/post', extra: post),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ─── Nearby Map Tab ──────────────────────────────────────────────────────────

class _NearbyMapView extends ConsumerStatefulWidget {
  final StyleFeedState feedState;
  final VoidCallback onRetry;

  const _NearbyMapView({required this.feedState, required this.onRetry});

  @override
  ConsumerState<_NearbyMapView> createState() => _NearbyMapViewState();
}

class _NearbyMapViewState extends ConsumerState<_NearbyMapView> {
  final MapController _mapController = MapController();
  LatLng _mapCenter = const LatLng(41.0082, 28.9784);
  bool _isLoadingLocation = true;
  StylePost? _selectedPost;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    if (!mounted) return;
    setState(() => _isLoadingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (mounted) setState(() => _isLoadingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (mounted) {
        setState(() {
          _mapCenter = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
        _mapController.move(_mapCenter, 12);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _onMarkerTap(StylePost post) {
    setState(() => _selectedPost = post);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => MapPostPreviewSheet(
        post: post,
        onViewFull: () {
          Navigator.pop(context);
          context.push('/style-feed/post', extra: post);
        },
      ),
    ).whenComplete(() {
      if (mounted) setState(() => _selectedPost = null);
    });
  }

  List<Marker> _buildMarkers() {
    return widget.feedState.posts
        .where((p) => p.location != null)
        .map((post) {
          final loc = post.location!;
          final isSelected = _selectedPost?.id == post.id;
          return Marker(
            point: LatLng(loc.coordinates.latitude, loc.coordinates.longitude),
            width: isSelected ? 52 : 44,
            height: isSelected ? 52 : 44,
            child: GestureDetector(
              onTap: () => _onMarkerTap(post),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary,
                    width: isSelected ? 3 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.checkroom,
                  color: isSelected ? Colors.white : AppColors.primary,
                  size: isSelected ? 28 : 22,
                ),
              ),
            ),
          );
        })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final feedState = widget.feedState;
    final markers = _buildMarkers();
    final postCount = feedState.posts.where((p) => p.location != null).length;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _mapCenter,
            initialZoom: 12,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'app.stilasist',
            ),
            MarkerLayer(markers: markers),
          ],
        ),

        // Stats card
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.location_on, size: 18, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    postCount == 0
                        ? 'No nearby posts yet'
                        : '$postCount nearby post${postCount == 1 ? '' : 's'}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const Spacer(),
                  if (feedState.isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Error / location-denied overlay
        if (feedState.errorMessage != null && !feedState.isLoading)
          Positioned(
            bottom: 100,
            left: 24,
            right: 24,
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_off,
                        color: AppColors.error, size: 40),
                    const SizedBox(height: 10),
                    Text(
                      feedState.errorMessage!.toLowerCase().contains('location')
                          ? 'Location access required'
                          : 'Could not load nearby posts',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Enable location to see posts near you',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: widget.onRetry,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // My location FAB
        Positioned(
          bottom: 24,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'nearby_my_location',
            onPressed: _initLocation,
            backgroundColor: Colors.white,
            elevation: 4,
            child: _isLoadingLocation
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  )
                : const Icon(Icons.my_location, color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}
