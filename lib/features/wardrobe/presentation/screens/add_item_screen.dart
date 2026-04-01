import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/enums/clothing_category.dart';
import '../../domain/entities/clothing_item.dart';
import '../../../../services/storage_service.dart';
import '../../../../services/settings_service.dart';
import '../../../../services/background_removal_service.dart';
import '../../../../services/gemini_service.dart';
import '../providers/wardrobe_provider.dart';
import '../../../style_feed/presentation/providers/style_feed_provider.dart';

class AddItemScreen extends ConsumerStatefulWidget {
  final ClothingItem? itemToEdit;

  const AddItemScreen({super.key, this.itemToEdit});

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _colorController = TextEditingController();
  final _storage = StorageService();
  final _settingsService = SettingsService();
  final _backgroundRemovalService = BackgroundRemovalService();
  final _geminiService = GeminiService();
  final _picker = ImagePicker();

  dynamic _imageFile; // XFile on web, File on mobile
  ClothingCategory _category = ClothingCategory.tops;
  final Set<String> _seasons = {};
  final Set<String> _occasions = {};
  final Set<String> _weatherSuitability = {};
  bool _saving = false;
  bool _aiAnalyzing = false;

  static const _seasonOptions = ['Spring', 'Summer', 'Autumn', 'Winter'];
  static const _occasionOptions = ['Office', 'Casual', 'Night'];
  static const _weatherOptions = ['Hot', 'Mild', 'Cool', 'Cold', 'Rainy', 'Windy'];

  @override
  void initState() {
    super.initState();
    // Pre-populate form if editing
    if (widget.itemToEdit != null) {
      final item = widget.itemToEdit!;
      _nameController.text = item.name;
      _colorController.text = item.color;
      _category = item.category;
      // Capitalize first letter to match FilterChip option labels (e.g. "spring" → "Spring")
      _seasons.addAll(item.seasons.map(_capitalize));
      _occasions.addAll(item.occasions.map(_capitalize));
      _weatherSuitability.addAll(item.weatherSuitability.map(_capitalize));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 75,
    );
    if (picked == null) return;

    final bgEnabled = await _settingsService.getBackgroundRemovalEnabled();
    final removeBgKey = await _settingsService.getRemoveBgApiKey();

    Uint8List? processedBytes;
    final imageBytes = await picked.readAsBytes();

    // Process if background removal is enabled.
    // On web, only process when we have an API key (no blocking local algo).
    final shouldProcess = bgEnabled && (!kIsWeb || removeBgKey.isNotEmpty);

    if (shouldProcess) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Removing background...', textAlign: TextAlign.center),
              ],
            ),
          ),
        );
        // Yield to event loop so dialog route is pushed before we await work
        await Future.delayed(Duration.zero);
      }
      try {
        processedBytes = await _backgroundRemovalService.removeBackgroundAsync(
          imageFile: picked,
          apiKey: removeBgKey,
          cachedBytes: imageBytes,
        ).timeout(const Duration(seconds: 10));
      } catch (_) {}

      if (!mounted) return;
      Navigator.pop(context);
    }

    // Apply image (processed or original).
    // Processed bytes are always PNG; original bytes keep the source format.
    final finalBytes = processedBytes ?? imageBytes;
    if (kIsWeb) {
      final baseName = picked.name.replaceAll(RegExp(r'\.\w+$'), '');
      final isProcessed = processedBytes != null;
      final mimeType = isProcessed ? 'image/png' : (picked.mimeType ?? 'image/jpeg');
      final ext = mimeType.contains('png') ? 'png' : 'jpg';
      setState(() {
        _imageFile = XFile.fromData(
          finalBytes,
          name: '$baseName.$ext',
          mimeType: mimeType,
        );
      });
    } else {
      // Delete previous temp file before creating a new one
      await _deleteTempFile(_imageFile);
      final tempFile = await _saveProcessedImage(finalBytes);
      if (mounted) setState(() => _imageFile = tempFile);
    }

    // Fire AI analysis in background — don't await so the image shows immediately.
    // Uses original imageBytes for best colour/detail recognition.
    unawaited(_autoFillFromGemini(imageBytes));
  }

  /// Calls Gemini Vision to auto-fill name, colour and category.
  /// Only fills fields that the user hasn't typed into yet.
  Future<void> _autoFillFromGemini(Uint8List imageBytes) async {
    final geminiKey = await _settingsService.getGeminiApiKey();
    if (geminiKey.isEmpty || !mounted) return;

    setState(() => _aiAnalyzing = true);
    try {
      final analysis = await _geminiService
          .analyzeClothing(imageBytes, geminiKey)
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;
      setState(() {
        if (_nameController.text.isEmpty) _nameController.text = analysis.name;
        if (_colorController.text.isEmpty) _colorController.text = analysis.color;
        _category = _mapCategory(analysis.category);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✨ AI filled in the details — review and edit if needed'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (_) {
      // Gemini failed — user fills manually, no error shown
    } finally {
      if (mounted) setState(() => _aiAnalyzing = false);
    }
  }

  /// Maps Gemini's category string to [ClothingCategory].
  ClothingCategory _mapCategory(String raw) {
    return switch (raw.toLowerCase().trim()) {
      'tops' => ClothingCategory.tops,
      'bottoms' => ClothingCategory.bottoms,
      'skirts' => ClothingCategory.skirts,
      'dresses' => ClothingCategory.dresses,
      'outerwear' => ClothingCategory.outerwear,
      'suits' => ClothingCategory.suits,
      'sportswear' => ClothingCategory.sportswear,
      'swimwear' => ClothingCategory.swimwear,
      'shoes' => ClothingCategory.shoes,
      'bags' => ClothingCategory.bags,
      'accessories' => ClothingCategory.accessories,
      _ => ClothingCategory.tops,
    };
  }

  /// Opens the crop/rotate editor on the currently selected image.
  Future<void> _cropCurrentImage() async {
    if (_imageFile == null || !mounted) return;

    try {
      String sourcePath;
      if (kIsWeb) {
        // Web: XFile.fromData has empty path — encode bytes as base64 data URL.
        // Blob URLs are preferred but require dart:html; data URLs work for
        // typical wardrobe images (<2 MB after picker compression).
        final bytes = await (_imageFile as XFile).readAsBytes();
        final b64 = base64Encode(bytes);
        sourcePath = 'data:image/png;base64,$b64';
      } else {
        sourcePath = (_imageFile as File).path;
      }

      if (!mounted) return;
      final uiSettings = <PlatformUiSettings>[
        AndroidUiSettings(
          toolbarTitle: 'Crop & Rotate',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: 'Crop & Rotate'),
        WebUiSettings(
          context: context,
          presentStyle: WebPresentStyle.dialog,
          zoomable: true,
        ),
      ];
      final cropped = await ImageCropper().cropImage(
        sourcePath: sourcePath,
        uiSettings: uiSettings,
      );

      if (cropped == null || !mounted) return;

      final croppedBytes = await cropped.readAsBytes();
      if (kIsWeb) {
        setState(() {
          _imageFile = XFile.fromData(
            croppedBytes,
            name: 'cropped.png',
            mimeType: 'image/png',
          );
        });
      } else {
        final oldFile = _imageFile;
        final savedFile = await _saveProcessedImage(croppedBytes);
        await _deleteTempFile(oldFile);
        if (mounted) setState(() => _imageFile = savedFile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Crop failed: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';

  Future<File> _saveProcessedImage(Uint8List bytes) async {
    final tempDir = await getApplicationDocumentsDirectory();
    final tempFile = File('${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.png');
    await tempFile.writeAsBytes(bytes);
    return tempFile;
  }

  /// Deletes a temporary image file created by [_saveProcessedImage].
  /// Safe to call with null or non-File values; silently ignores errors.
  Future<void> _deleteTempFile(dynamic imageFile) async {
    if (kIsWeb || imageFile is! File) return;
    try {
      await imageFile.delete();
    } catch (_) {}
  }

  Widget _buildImagePreview() {
    if (_imageFile == null) return const SizedBox.shrink();

    if (kIsWeb) {
      // Web: _imageFile is XFile
      final xFile = _imageFile as XFile;
      return FutureBuilder<Uint8List>(
        future: xFile.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      );
    } else {
      // Mobile: _imageFile is File
      return Image.file(
        _imageFile as File,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
      );
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // White background tip
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFD54F)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.tips_and_updates_outlined, color: Color(0xFFF9A825), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'For best results, photograph your clothing on a white or plain background.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF5D4037)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child: Icon(Icons.camera_alt_outlined, color: AppColors.primary),
              ),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child: Icon(Icons.photo_library_outlined, color: AppColors.primary),
              ),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final isEditing = widget.itemToEdit != null;
      final id = isEditing ? widget.itemToEdit!.id : const Uuid().v4();
      final userId = ref.read(currentUserIdProvider);
      if (userId.isEmpty) throw Exception('Not logged in');

      String? localPath = isEditing ? widget.itemToEdit!.localImagePath : null;
      String? storageUrl = isEditing ? widget.itemToEdit!.storageImageUrl : null;

      // Save new image if selected
      if (_imageFile != null) {
        final savedImageFile = _imageFile;
        final result = await _storage.saveImage(
          imageFile: _imageFile!,
          userId: userId,
          itemId: id,
        );
        localPath = result.localPath;
        storageUrl = result.firebaseUrl;
        // Clean up the temporary file now that it's been copied to the wardrobe dir
        await _deleteTempFile(savedImageFile);
      }

      final item = ClothingItem(
        id: id,
        name: _nameController.text.trim(),
        category: _category,
        color: _colorController.text.trim(),
        seasons: _seasons.map((s) => s.toLowerCase()).toList(),
        occasions: _occasions.map((s) => s.toLowerCase()).toList(),
        weatherSuitability: _weatherSuitability.map((s) => s.toLowerCase()).toList(),
        localImagePath: localPath,
        storageImageUrl: storageUrl,
        isFavorite: isEditing ? widget.itemToEdit!.isFavorite : false,
        lastWorn: isEditing ? widget.itemToEdit!.lastWorn : null,
        addedAt: isEditing ? widget.itemToEdit!.addedAt : DateTime.now(),
      );

      if (isEditing) {
        ref.read(wardrobeProvider.notifier).updateItem(item);
      } else {
        ref.read(wardrobeProvider.notifier).addItem(item);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing
              ? '${item.name} updated!'
              : '${item.name} added to your wardrobe!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving item: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.itemToEdit != null ? 'Edit Item' : 'Add Clothing Item'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Photo picker - 1:1 square standard
            GestureDetector(
              onTap: _showImageSourceSheet,
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _buildImagePreview(),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              size: 56,
                              color: AppColors.primary.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Add Photo',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.primary,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap to take a photo or choose from gallery',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            if (_imageFile != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: _cropCurrentImage,
                    icon: const Icon(Icons.crop, size: 16),
                    label: const Text('Crop & Rotate'),
                  ),
                  TextButton.icon(
                    onPressed: _showImageSourceSheet,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Change Photo'),
                  ),
                ],
              ),
            const SizedBox(height: 20),

            // Name field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Item Name *',
                hintText: 'e.g. White Linen Blouse',
                prefixIcon: const Icon(Icons.label_outline),
                suffixIcon: _aiAnalyzing
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Please enter a name' : null,
            ),
            const SizedBox(height: 16),

            // Category dropdown
            DropdownButtonFormField<ClothingCategory>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category *',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: ClothingCategory.values.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child: Row(children: [
                    Text(c.icon),
                    const SizedBox(width: 8),
                    Text(c.displayName),
                  ]),
                );
              }).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),

            // Color field
            TextFormField(
              controller: _colorController,
              decoration: const InputDecoration(
                labelText: 'Color',
                hintText: 'e.g. White, Navy Blue',
                prefixIcon: Icon(Icons.palette_outlined),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 20),

            _MultiSelectSection(
              title: 'Seasons',
              options: _seasonOptions,
              selected: _seasons,
              onToggle: (s) => setState(() {
                _seasons.contains(s) ? _seasons.remove(s) : _seasons.add(s);
              }),
            ),
            const SizedBox(height: 16),

            _MultiSelectSection(
              title: 'Occasions',
              options: _occasionOptions,
              selected: _occasions,
              onToggle: (s) => setState(() {
                _occasions.contains(s)
                    ? _occasions.remove(s)
                    : _occasions.add(s);
              }),
            ),
            const SizedBox(height: 16),

            _MultiSelectSection(
              title: 'Weather Suitability',
              options: _weatherOptions,
              selected: _weatherSuitability,
              onToggle: (s) => setState(() {
                _weatherSuitability.contains(s)
                    ? _weatherSuitability.remove(s)
                    : _weatherSuitability.add(s);
              }),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(_saving ? 'Saving...' : 'Add to Wardrobe'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _MultiSelectSection extends StatelessWidget {
  final String title;
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _MultiSelectSection({
    required this.title,
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) {
            final isSelected = selected.contains(opt);
            return FilterChip(
              label: Text(opt),
              selected: isSelected,
              onSelected: (_) => onToggle(opt),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              checkmarkColor: Colors.white,
            );
          }).toList(),
        ),
      ],
    );
  }
}
