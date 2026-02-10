import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

/// Script to upload mock data to Firestore
/// Run with: dart run lib/scripts/upload_mock_data.dart
void main() async {
  print('🚀 Starting mock data upload...\n');

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('✅ Firebase initialized\n');

  final firestore = FirebaseFirestore.instance;

  try {
    // 1. Create mock users
    print('📝 Creating mock users...');
    await createMockUsers(firestore);
    print('✅ Mock users created\n');

    // 2. Create mock wardrobe items
    print('👔 Creating mock wardrobe items...');
    await createMockWardrobeItems(firestore);
    print('✅ Mock wardrobe items created\n');

    // 3. Create mock recommendations
    print('💡 Creating mock recommendations...');
    await createMockRecommendations(firestore);
    print('✅ Mock recommendations created\n');

    print('🎉 All mock data uploaded successfully!');
  } catch (e) {
    print('❌ Error: $e');
  }
}

Future<void> createMockUsers(FirebaseFirestore firestore) async {
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
    await firestore.collection('users').doc(user['userId'] as String).set(user);
    print('  ✓ Created user: ${user['displayName']}');
  }
}

Future<void> createMockWardrobeItems(FirebaseFirestore firestore) async {
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
      'lastWorn': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
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
      'lastWorn': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
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
      'lastWorn': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
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
      'lastWorn': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7))),
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
      'lastWorn': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
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
      'lastWorn': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 4))),
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
      'lastWorn': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
    },
  ];

  for (var item in items) {
    await firestore
        .collection('wardrobe')
        .doc(item['id'] as String)
        .set(item);
    print('  ✓ Created wardrobe item: ${item['name']}');
  }
}

Future<void> createMockRecommendations(FirebaseFirestore firestore) async {
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
              'Perfect for office meetings - elegant yet comfortable for all-day wear',
        },
        {
          'occasion': 'casual',
          'items': [
            {
              'category': 'tops',
              'description': 'Striped Navy T-Shirt',
              'wardrobeItemId': 'item_3',
            },
            {
              'category': 'bottoms',
              'description': 'Dark Blue Jeans',
              'wardrobeItemId': 'item_4',
            },
            {
              'category': 'shoes',
              'description': 'White Sneakers',
              'wardrobeItemId': 'item_11',
            },
          ],
          'accessories': ['Simple stud earrings', 'Canvas tote bag'],
          'makeup': {
            'foundation': 'Light BB cream',
            'lips': 'Tinted lip balm',
            'eyes': 'Just mascara and filled brows',
            'tip': 'Fresh and natural daytime look',
          },
          'smartTip':
              'Comfortable for weekend activities or casual lunch with friends',
        },
      ],
      'tips': [
        'Layer with the Camel Trench Coat if it gets cooler',
        'Temperature may drop in the evening - bring an extra layer',
        'Perfect weather for outdoor activities',
      ],
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'id': 'rec_2',
      'userId': 'user_mock_1',
      'date': Timestamp.fromDate(DateTime.now().add(const Duration(days: 1))),
      'weather': {
        'temperature': 22,
        'condition': 'sunny',
        'description': 'Sunny and warm',
      },
      'outfits': [
        {
          'occasion': 'casual',
          'items': [
            {
              'category': 'dresses',
              'description': 'Floral Summer Dress',
              'wardrobeItemId': 'item_8',
            },
            {
              'category': 'shoes',
              'description': 'White Sneakers',
              'wardrobeItemId': 'item_11',
            },
          ],
          'accessories': ['Sunglasses', 'Woven straw bag'],
          'makeup': {
            'foundation': 'Lightweight tinted moisturizer with SPF',
            'lips': 'Coral or peach lip tint',
            'eyes': 'Bronze eyeshadow with waterproof mascara',
            'tip': 'Use waterproof products for hot weather',
          },
          'smartTip':
              'Perfect for a sunny day out - comfortable and stylish',
        },
      ],
      'tips': [
        'Don\'t forget sunscreen!',
        'Stay hydrated',
        'Great day for outdoor dining',
      ],
      'createdAt': FieldValue.serverTimestamp(),
    },
  ];

  for (var rec in recommendations) {
    await firestore
        .collection('recommendations')
        .doc(rec['id'] as String)
        .set(rec);
    print('  ✓ Created recommendation: ${rec['id']}');
  }
}
