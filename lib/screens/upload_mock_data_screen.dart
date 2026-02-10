import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Screen to upload mock data to Firestore
/// Navigate to this screen to populate your database with test data
class UploadMockDataScreen extends StatefulWidget {
  const UploadMockDataScreen({super.key});

  @override
  State<UploadMockDataScreen> createState() => _UploadMockDataScreenState();
}

class _UploadMockDataScreenState extends State<UploadMockDataScreen> {
  final List<String> _logs = [];
  bool _isUploading = false;

  void _log(String message) {
    setState(() {
      _logs.add(message);
    });
  }

  Future<void> _uploadMockData() async {
    setState(() {
      _isUploading = true;
      _logs.clear();
    });

    final firestore = FirebaseFirestore.instance;

    try {
      _log('🚀 Starting mock data upload...\n');

      // 1. Create mock users
      _log('📝 Creating mock users...');
      await _createMockUsers(firestore);
      _log('✅ Mock users created\n');

      // 2. Create mock wardrobe items
      _log('👔 Creating mock wardrobe items...');
      await _createMockWardrobeItems(firestore);
      _log('✅ Mock wardrobe items created\n');

      // 3. Create mock recommendations
      _log('💡 Creating mock recommendations...');
      await _createMockRecommendations(firestore);
      _log('✅ Mock recommendations created\n');

      _log('🎉 All mock data uploaded successfully!');
    } catch (e) {
      _log('❌ Error: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _createMockUsers(FirebaseFirestore firestore) async {
    final users = [
      {
        'userId': 'user_mock_1',
        'displayName': 'Ayşe Yılmaz',
        'age': 28,
        'stylePreference': 'elegant',
        'workStatus': 'office',
        'city': 'Istanbul',
        'notificationEnabled': true,
        'bodyType': 'hourglass',
        'heightRange': 'medium',
        'workType': 'office',
        'hobbies': ['reading', 'traveling'],
        'colorSeason': 'spring',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'userId': 'user_mock_2',
        'displayName': 'Zeynep Demir',
        'age': 24,
        'stylePreference': 'sporty',
        'workStatus': 'hybrid',
        'city': 'Ankara',
        'notificationEnabled': true,
        'bodyType': 'athletic',
        'heightRange': 'tall',
        'workType': 'remote',
        'hobbies': ['sports', 'music'],
        'colorSeason': 'autumn',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'userId': 'user_mock_3',
        'displayName': 'Elif Kaya',
        'age': 32,
        'stylePreference': 'classic',
        'workStatus': 'office',
        'city': 'Izmir',
        'notificationEnabled': false,
        'bodyType': 'pear',
        'heightRange': 'petite',
        'workType': 'office',
        'hobbies': ['art', 'cooking'],
        'colorSeason': 'winter',
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    for (var user in users) {
      await firestore
          .collection('users')
          .doc(user['userId'] as String)
          .set(user);
      _log('  ✓ Created user: ${user['displayName']}');
    }
  }

  Future<void> _createMockWardrobeItems(FirebaseFirestore firestore) async {
    final items = [
      // Tops
      {
        'id': 'item_1',
        'userId': 'user_mock_1',
        'name': 'White Cotton Blouse',
        'category': 'tops',
        'color': 'White',
        'seasons': ['spring', 'summer', 'autumn'],
        'occasions': ['work', 'casual', 'date'],
        'weatherSuitability': ['mild', 'cool'],
        'storageImageUrl': null,
        'isFavorite': true,
        'addedAt': Timestamp.now(),
        'lastWorn': null,
      },
      {
        'id': 'item_2',
        'userId': 'user_mock_1',
        'name': 'Black Turtleneck',
        'category': 'tops',
        'color': 'Black',
        'seasons': ['autumn', 'winter'],
        'occasions': ['work', 'casual', 'evening'],
        'weatherSuitability': ['cool', 'cold'],
        'storageImageUrl': null,
        'isFavorite': true,
        'addedAt': Timestamp.now(),
        'lastWorn': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 3))),
      },
      {
        'id': 'item_3',
        'userId': 'user_mock_1',
        'name': 'Striped Navy T-Shirt',
        'category': 'tops',
        'color': 'Navy Blue',
        'seasons': ['spring', 'summer'],
        'occasions': ['casual', 'weekend'],
        'weatherSuitability': ['hot', 'mild'],
        'storageImageUrl': null,
        'isFavorite': false,
        'addedAt': Timestamp.now(),
        'lastWorn': null,
      },
      // Bottoms
      {
        'id': 'item_4',
        'userId': 'user_mock_1',
        'name': 'Dark Blue Jeans',
        'category': 'bottoms',
        'color': 'Dark Blue',
        'seasons': ['spring', 'autumn', 'winter'],
        'occasions': ['casual', 'work', 'date'],
        'weatherSuitability': ['mild', 'cool', 'cold'],
        'storageImageUrl': null,
        'isFavorite': true,
        'addedAt': Timestamp.now(),
        'lastWorn': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 1))),
      },
      {
        'id': 'item_5',
        'userId': 'user_mock_1',
        'name': 'Black Pencil Skirt',
        'category': 'bottoms',
        'color': 'Black',
        'seasons': ['spring', 'summer', 'autumn'],
        'occasions': ['work', 'formal', 'date'],
        'weatherSuitability': ['hot', 'mild'],
        'storageImageUrl': null,
        'isFavorite': true,
        'addedAt': Timestamp.now(),
        'lastWorn': null,
      },
      // Outerwear
      {
        'id': 'item_6',
        'userId': 'user_mock_1',
        'name': 'Camel Trench Coat',
        'category': 'outerwear',
        'color': 'Camel',
        'seasons': ['autumn', 'winter', 'spring'],
        'occasions': ['work', 'formal', 'casual'],
        'weatherSuitability': ['cool', 'cold', 'rainy'],
        'storageImageUrl': null,
        'isFavorite': true,
        'addedAt': Timestamp.now(),
        'lastWorn': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 2))),
      },
      {
        'id': 'item_7',
        'userId': 'user_mock_1',
        'name': 'Leather Jacket',
        'category': 'outerwear',
        'color': 'Black',
        'seasons': ['autumn', 'winter'],
        'occasions': ['casual', 'date', 'evening'],
        'weatherSuitability': ['cool', 'cold', 'windy'],
        'storageImageUrl': null,
        'isFavorite': false,
        'addedAt': Timestamp.now(),
        'lastWorn': null,
      },
      // Dresses
      {
        'id': 'item_8',
        'userId': 'user_mock_1',
        'name': 'Floral Summer Dress',
        'category': 'dresses',
        'color': 'Multicolor',
        'seasons': ['spring', 'summer'],
        'occasions': ['casual', 'date', 'wedding'],
        'weatherSuitability': ['hot', 'mild'],
        'storageImageUrl': null,
        'isFavorite': true,
        'addedAt': Timestamp.now(),
        'lastWorn': null,
      },
      {
        'id': 'item_9',
        'userId': 'user_mock_1',
        'name': 'Little Black Dress',
        'category': 'dresses',
        'color': 'Black',
        'seasons': ['spring', 'summer', 'autumn', 'winter'],
        'occasions': ['evening', 'formal', 'date'],
        'weatherSuitability': ['hot', 'mild', 'cool'],
        'storageImageUrl': null,
        'isFavorite': true,
        'addedAt': Timestamp.now(),
        'lastWorn': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 7))),
      },
      // Shoes
      {
        'id': 'item_10',
        'userId': 'user_mock_1',
        'name': 'Black Ankle Boots',
        'category': 'shoes',
        'color': 'Black',
        'seasons': ['autumn', 'winter', 'spring'],
        'occasions': ['work', 'casual', 'date'],
        'weatherSuitability': ['cool', 'cold', 'rainy'],
        'storageImageUrl': null,
        'isFavorite': true,
        'addedAt': Timestamp.now(),
        'lastWorn': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 1))),
      },
      {
        'id': 'item_11',
        'userId': 'user_mock_1',
        'name': 'White Sneakers',
        'category': 'shoes',
        'color': 'White',
        'seasons': ['spring', 'summer', 'autumn'],
        'occasions': ['casual', 'weekend', 'sports'],
        'weatherSuitability': ['hot', 'mild'],
        'storageImageUrl': null,
        'isFavorite': true,
        'addedAt': Timestamp.now(),
        'lastWorn': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 4))),
      },
      // Accessories
      {
        'id': 'item_12',
        'userId': 'user_mock_1',
        'name': 'Gold Hoop Earrings',
        'category': 'accessories',
        'color': 'Gold',
        'seasons': ['spring', 'summer', 'autumn', 'winter'],
        'occasions': ['work', 'date', 'evening', 'formal'],
        'weatherSuitability': ['hot', 'mild', 'cool', 'cold'],
        'storageImageUrl': null,
        'isFavorite': true,
        'addedAt': Timestamp.now(),
        'lastWorn': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 2))),
      },
    ];

    for (var item in items) {
      await firestore.collection('wardrobe').doc(item['id'] as String).set(item);
      _log('  ✓ Created: ${item['name']}');
    }
  }

  Future<void> _createMockRecommendations(FirebaseFirestore firestore) async {
    final recommendations = [
      {
        'id': 'rec_1',
        'userId': 'user_mock_1',
        'date': Timestamp.now(),
        'weather': {
          'temperature': 18,
          'condition': 'partly_cloudy',
          'description': 'Partly cloudy with mild temperatures',
        },
        'outfits': [
          {
            'occasion': 'work',
            'items': [
              {
                'category': 'tops',
                'description': 'White Cotton Blouse',
                'wardrobeItemId': 'item_1',
              },
              {
                'category': 'bottoms',
                'description': 'Black Pencil Skirt',
                'wardrobeItemId': 'item_5',
              },
              {
                'category': 'shoes',
                'description': 'Black Ankle Boots',
                'wardrobeItemId': 'item_10',
              },
            ],
            'accessories': ['Gold Hoop Earrings', 'Black Leather Bag'],
            'makeup': {
              'foundation': 'Natural coverage, matte finish',
              'lips': 'Nude or soft pink lip color',
              'eyes': 'Light brown eyeshadow with mascara',
              'tip': 'Keep it professional and polished',
            },
            'smartTip':
                'Perfect for office meetings - elegant yet comfortable',
          },
        ],
        'tips': [
          'Layer with the Camel Trench Coat if it gets cooler',
          'Perfect weather for outdoor activities',
        ],
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    for (var rec in recommendations) {
      await firestore
          .collection('recommendations')
          .doc(rec['id'] as String)
          .set(rec);
      _log('  ✓ Created recommendation: ${rec['id']}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Mock Data'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isUploading ? null : _uploadMockData,
              child: _isUploading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Uploading...'),
                      ],
                    )
                  : const Text('Upload Mock Data to Firebase'),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _logs.isEmpty
                    ? const Center(
                        child: Text(
                          'Press the button to upload mock data to Firestore',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : SingleChildScrollView(
                        child: Text(
                          _logs.join('\n'),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
