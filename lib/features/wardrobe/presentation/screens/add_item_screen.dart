import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/enums/clothing_category.dart';
import '../../domain/entities/clothing_item.dart';
import '../../../../services/storage_service.dart';
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
  final _picker = ImagePicker();

  File? _imageFile;
  ClothingCategory _category = ClothingCategory.tops;
  final Set<String> _seasons = {};
  final Set<String> _occasions = {};
  final Set<String> _weatherSuitability = {};
  bool _saving = false;

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
      _seasons.addAll(item.seasons.map((s) => s.toLowerCase()));
      _occasions.addAll(item.occasions.map((o) => o.toLowerCase()));
      _weatherSuitability.addAll(item.weatherSuitability.map((w) => w.toLowerCase()));
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
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
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

      String? localPath = isEditing ? widget.itemToEdit!.localImagePath : null;
      String? storageUrl = isEditing ? widget.itemToEdit!.storageImageUrl : null;

      // Save new image if selected
      if (_imageFile != null) {
        final result = await _storage.saveImage(
          imageFile: _imageFile!,
          userId: userId,
          itemId: id,
        );
        localPath = result.localPath;
        storageUrl = result.firebaseUrl;
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
            // Photo picker
            GestureDetector(
              onTap: _showImageSourceSheet,
              child: Container(
                height: 220,
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
                        child: Image.file(
                          _imageFile!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
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
            if (_imageFile != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _showImageSourceSheet,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Change Photo'),
                ),
              ),
            const SizedBox(height: 20),

            // Name field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name *',
                hintText: 'e.g. White Linen Blouse',
                prefixIcon: Icon(Icons.label_outline),
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
