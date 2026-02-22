import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/style_post.dart';
import '../providers/style_feed_provider.dart';
import '../widgets/map_post_preview_sheet.dart';

class MapViewScreen extends ConsumerStatefulWidget {
  const MapViewScreen({super.key});

  @override
  ConsumerState<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends ConsumerState<MapViewScreen> {
  final MapController _mapController = MapController();
  LatLng _mapCenter = const LatLng(41.0082, 28.9784);
  bool _isLoadingLocation = false;
  String? _selectedFilter;
  StylePost? _selectedPost;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
      _loadPosts();
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    await ref.read(styleFeedProvider.notifier).loadPosts(mode: FeedMode.forYou);
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;
    setState(() => _isLoadingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (mounted) {
        setState(() => _mapCenter = LatLng(position.latitude, position.longitude));
        _mapController.move(_mapCenter, 12);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location error: $e'), duration: const Duration(seconds: 3)),
        );
      }
    } finally {
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

  List<Marker> _buildMarkers(List<StylePost> posts) {
    return posts
        .where((p) =>
            p.location != null &&
            (_selectedFilter == null || p.tags.contains(_selectedFilter!)))
        .map((post) {
          final loc = post.location!;
          final isSelected = _selectedPost?.id == post.id;
          return Marker(
            point: LatLng(loc.coordinates.latitude, loc.coordinates.longitude),
            width: isSelected ? 48 : 40,
            height: isSelected ? 48 : 40,
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
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.checkroom,
                  color: isSelected ? Colors.white : AppColors.primary,
                  size: isSelected ? 24 : 20,
                ),
              ),
            ),
          );
        })
        .toList();
  }

  void _showFilterDialog(List<StylePost> posts) {
    final allTags = posts.expand((p) => p.tags).toSet().toList()..sort();
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filter by Tag',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  if (_selectedFilter != null)
                    TextButton(
                      onPressed: () {
                        setState(() => _selectedFilter = null);
                        Navigator.pop(context);
                      },
                      child: const Text('Clear'),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: allTags.map((tag) {
                  final isSelected = _selectedFilter == tag;
                  return ListTile(
                    leading: Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: isSelected ? AppColors.primary : null,
                    ),
                    title: Text('#$tag'),
                    onTap: () {
                      setState(() => _selectedFilter = isSelected ? null : tag);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(styleFeedProvider);
    final markers = _buildMarkers(feedState.posts);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Style Map'),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            onPressed: () => _showFilterDialog(feedState.posts),
            icon: Badge(
              isLabelVisible: _selectedFilter != null,
              child: const Icon(Icons.filter_list),
            ),
            tooltip: 'Filter by tag',
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _mapCenter,
              initialZoom: 10,
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
                      '${markers.length} posts on map',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const Spacer(),
                    if (_selectedFilter != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '#$_selectedFilter',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
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
              heroTag: 'map_my_location',
              onPressed: _getCurrentLocation,
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
      ),
    );
  }
}
