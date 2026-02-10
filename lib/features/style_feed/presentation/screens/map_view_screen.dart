import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  final Completer<GoogleMapController> _mapController = Completer();
  Set<Marker> _markers = {};
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  String? _selectedFilter; // For tag filtering
  StylePost? _selectedPost;

  // Default map center (Istanbul, Turkey)
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(41.0082, 28.9784),
    zoom: 10,
  );

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _getCurrentLocation();
  }

  Future<void> _loadPosts() async {
    // Load all posts with location data
    await ref.read(styleFeedProvider.notifier).loadPosts(mode: FeedMode.forYou);
    _buildMarkers();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      final hasPermission = await Geolocator.checkPermission();
      if (hasPermission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() => _currentPosition = position);

        // Move camera to user location
        final controller = await _mapController.future;
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 12,
            ),
          ),
        );
      }
    } catch (e) {
      // Silently fail
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  void _buildMarkers() {
    final feedState = ref.read(styleFeedProvider);
    final posts = feedState.posts.where((post) => post.location != null);

    // Apply filter if active
    final filteredPosts = _selectedFilter != null
        ? posts.where((post) => post.tags.contains(_selectedFilter!))
        : posts;

    final markers = <Marker>{};

    for (final post in filteredPosts) {
      final location = post.location!;
      markers.add(
        Marker(
          markerId: MarkerId(post.id),
          position: LatLng(
            location.coordinates.latitude,
            location.coordinates.longitude,
          ),
          onTap: () => _onMarkerTap(post),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _selectedPost?.id == post.id
                ? BitmapDescriptor.hueRose
                : BitmapDescriptor.hueViolet,
          ),
          infoWindow: InfoWindow(
            title: post.userDisplayName,
            snippet: location.city,
          ),
        ),
      );
    }

    setState(() => _markers = markers);
  }

  void _onMarkerTap(StylePost post) {
    setState(() => _selectedPost = post);
    _buildMarkers(); // Rebuild to highlight selected marker

    // Show bottom sheet with post preview
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
      setState(() => _selectedPost = null);
      _buildMarkers();
    });
  }

  Future<void> _centerOnUserLocation() async {
    if (_currentPosition == null) {
      await _getCurrentLocation();
      return;
    }

    final controller = await _mapController.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          zoom: 12,
        ),
      ),
    );
  }

  void _showFilterDialog() {
    final feedState = ref.read(styleFeedProvider);
    final allTags = feedState.posts
        .expand((post) => post.tags)
        .toSet()
        .toList()
      ..sort();

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
                  const Text(
                    'Filter by Tag',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_selectedFilter != null)
                    TextButton(
                      onPressed: () {
                        setState(() => _selectedFilter = null);
                        _buildMarkers();
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
                      isSelected
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      color: isSelected ? AppColors.primary : null,
                    ),
                    title: Text('#$tag'),
                    onTap: () {
                      setState(() {
                        _selectedFilter = isSelected ? null : tag;
                      });
                      _buildMarkers();
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
    ref.listen(styleFeedProvider, (previous, next) {
      // Rebuild markers when posts change
      if (previous?.posts != next.posts) {
        _buildMarkers();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Style Map'),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            onPressed: _showFilterDialog,
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
          // Google Map
          GoogleMap(
            initialCameraPosition: _initialPosition,
            markers: _markers,
            onMapCreated: (controller) {
              _mapController.complete(controller);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // We'll add custom button
            mapType: MapType.normal,
            zoomControlsEnabled: false,
            compassEnabled: true,
          ),

          // Stats overlay
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      Icons.location_on,
                      '${_markers.length}',
                      'Posts',
                    ),
                    if (_selectedFilter != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '#$_selectedFilter',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Location button
          Positioned(
            bottom: 24,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'my_location',
                  onPressed: _centerOnUserLocation,
                  backgroundColor: Colors.white,
                  child: _isLoadingLocation
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.my_location,
                          color: AppColors.primary,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
