// Node.js script to upload mock data to Firestore using Firebase Admin SDK
// Run with: node upload_mock_data.js

const admin = require('firebase-admin');

// Initialize Firebase Admin with project ID
admin.initializeApp({
  projectId: 'smartcloset-95789',
});

const db = admin.firestore();

async function uploadMockData() {
  console.log('🚀 Starting mock data upload...\n');

  try {
    // 1. Create mock users
    console.log('📝 Creating mock users...');
    await createMockUsers();
    console.log('✅ Mock users created\n');

    // 2. Create mock wardrobe items
    console.log('👔 Creating mock wardrobe items...');
    await createMockWardrobeItems();
    console.log('✅ Mock wardrobe items created\n');

    // 3. Create mock recommendations
    console.log('💡 Creating mock recommendations...');
    await createMockRecommendations();
    console.log('✅ Mock recommendations created\n');

    console.log('🎉 All mock data uploaded successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

async function createMockUsers() {
  const users = [
    {
      userId: 'user_mock_1',
      displayName: 'Ayşe Yılmaz',
      age: 28,
      stylePreference: 'elegant',
      workStatus: 'office',
      city: 'Istanbul',
      notificationEnabled: true,
      bodyType: 'hourglass',
      heightRange: 'medium',
      workType: 'office',
      hobbies: ['reading', 'traveling'],
      colorSeason: 'spring',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    {
      userId: 'user_mock_2',
      displayName: 'Zeynep Demir',
      age: 24,
      stylePreference: 'sporty',
      workStatus: 'hybrid',
      city: 'Ankara',
      notificationEnabled: true,
      bodyType: 'athletic',
      heightRange: 'tall',
      workType: 'remote',
      hobbies: ['sports', 'music'],
      colorSeason: 'autumn',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    {
      userId: 'user_mock_3',
      displayName: 'Elif Kaya',
      age: 32,
      stylePreference: 'classic',
      workStatus: 'office',
      city: 'Izmir',
      notificationEnabled: false,
      bodyType: 'pear',
      heightRange: 'petite',
      workType: 'office',
      hobbies: ['art', 'cooking'],
      colorSeason: 'winter',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
  ];

  for (const user of users) {
    await db.collection('users').doc(user.userId).set(user);
    console.log(`  ✓ Created user: ${user.displayName}`);
  }
}

async function createMockWardrobeItems() {
  const now = admin.firestore.Timestamp.now();
  const daysAgo = (days) => admin.firestore.Timestamp.fromDate(
    new Date(Date.now() - days * 24 * 60 * 60 * 1000)
  );

  const items = [
    // Tops
    {
      id: 'item_1',
      userId: 'user_mock_1',
      name: 'White Cotton Blouse',
      category: 'tops',
      color: 'White',
      seasons: ['spring', 'summer', 'autumn'],
      occasions: ['work', 'casual', 'date'],
      weatherSuitability: ['mild', 'cool'],
      storageImageUrl: null,
      isFavorite: true,
      addedAt: now,
      lastWorn: null,
    },
    {
      id: 'item_2',
      userId: 'user_mock_1',
      name: 'Black Turtleneck',
      category: 'tops',
      color: 'Black',
      seasons: ['autumn', 'winter'],
      occasions: ['work', 'casual', 'evening'],
      weatherSuitability: ['cool', 'cold'],
      storageImageUrl: null,
      isFavorite: true,
      addedAt: now,
      lastWorn: daysAgo(3),
    },
    {
      id: 'item_3',
      userId: 'user_mock_1',
      name: 'Striped Navy T-Shirt',
      category: 'tops',
      color: 'Navy Blue',
      seasons: ['spring', 'summer'],
      occasions: ['casual', 'weekend'],
      weatherSuitability: ['hot', 'mild'],
      storageImageUrl: null,
      isFavorite: false,
      addedAt: now,
      lastWorn: null,
    },
    // Bottoms
    {
      id: 'item_4',
      userId: 'user_mock_1',
      name: 'Dark Blue Jeans',
      category: 'bottoms',
      color: 'Dark Blue',
      seasons: ['spring', 'autumn', 'winter'],
      occasions: ['casual', 'work', 'date'],
      weatherSuitability: ['mild', 'cool', 'cold'],
      storageImageUrl: null,
      isFavorite: true,
      addedAt: now,
      lastWorn: daysAgo(1),
    },
    {
      id: 'item_5',
      userId: 'user_mock_1',
      name: 'Black Pencil Skirt',
      category: 'bottoms',
      color: 'Black',
      seasons: ['spring', 'summer', 'autumn'],
      occasions: ['work', 'formal', 'date'],
      weatherSuitability: ['hot', 'mild'],
      storageImageUrl: null,
      isFavorite: true,
      addedAt: now,
      lastWorn: null,
    },
    // Outerwear
    {
      id: 'item_6',
      userId: 'user_mock_1',
      name: 'Camel Trench Coat',
      category: 'outerwear',
      color: 'Camel',
      seasons: ['autumn', 'winter', 'spring'],
      occasions: ['work', 'formal', 'casual'],
      weatherSuitability: ['cool', 'cold', 'rainy'],
      storageImageUrl: null,
      isFavorite: true,
      addedAt: now,
      lastWorn: daysAgo(2),
    },
    {
      id: 'item_7',
      userId: 'user_mock_1',
      name: 'Leather Jacket',
      category: 'outerwear',
      color: 'Black',
      seasons: ['autumn', 'winter'],
      occasions: ['casual', 'date', 'evening'],
      weatherSuitability: ['cool', 'cold', 'windy'],
      storageImageUrl: null,
      isFavorite: false,
      addedAt: now,
      lastWorn: null,
    },
    // Dresses
    {
      id: 'item_8',
      userId: 'user_mock_1',
      name: 'Floral Summer Dress',
      category: 'dresses',
      color: 'Multicolor',
      seasons: ['spring', 'summer'],
      occasions: ['casual', 'date', 'wedding'],
      weatherSuitability: ['hot', 'mild'],
      storageImageUrl: null,
      isFavorite: true,
      addedAt: now,
      lastWorn: null,
    },
    {
      id: 'item_9',
      userId: 'user_mock_1',
      name: 'Little Black Dress',
      category: 'dresses',
      color: 'Black',
      seasons: ['spring', 'summer', 'autumn', 'winter'],
      occasions: ['evening', 'formal', 'date'],
      weatherSuitability: ['hot', 'mild', 'cool'],
      storageImageUrl: null,
      isFavorite: true,
      addedAt: now,
      lastWorn: daysAgo(7),
    },
    // Shoes
    {
      id: 'item_10',
      userId: 'user_mock_1',
      name: 'Black Ankle Boots',
      category: 'shoes',
      color: 'Black',
      seasons: ['autumn', 'winter', 'spring'],
      occasions: ['work', 'casual', 'date'],
      weatherSuitability: ['cool', 'cold', 'rainy'],
      storageImageUrl: null,
      isFavorite: true,
      addedAt: now,
      lastWorn: daysAgo(1),
    },
    {
      id: 'item_11',
      userId: 'user_mock_1',
      name: 'White Sneakers',
      category: 'shoes',
      color: 'White',
      seasons: ['spring', 'summer', 'autumn'],
      occasions: ['casual', 'weekend', 'sports'],
      weatherSuitability: ['hot', 'mild'],
      storageImageUrl: null,
      isFavorite: true,
      addedAt: now,
      lastWorn: daysAgo(4),
    },
    // Accessories
    {
      id: 'item_12',
      userId: 'user_mock_1',
      name: 'Gold Hoop Earrings',
      category: 'accessories',
      color: 'Gold',
      seasons: ['spring', 'summer', 'autumn', 'winter'],
      occasions: ['work', 'date', 'evening', 'formal'],
      weatherSuitability: ['hot', 'mild', 'cool', 'cold'],
      storageImageUrl: null,
      isFavorite: true,
      addedAt: now,
      lastWorn: daysAgo(2),
    },
  ];

  for (const item of items) {
    await db.collection('wardrobe').doc(item.id).set(item);
    console.log(`  ✓ Created: ${item.name}`);
  }
}

async function createMockRecommendations() {
  const recommendations = [
    {
      id: 'rec_1',
      userId: 'user_mock_1',
      date: admin.firestore.Timestamp.now(),
      weather: {
        temperature: 18,
        condition: 'partly_cloudy',
        description: 'Partly cloudy with mild temperatures',
      },
      outfits: [
        {
          occasion: 'work',
          items: [
            {
              category: 'tops',
              description: 'White Cotton Blouse',
              wardrobeItemId: 'item_1',
            },
            {
              category: 'bottoms',
              description: 'Black Pencil Skirt',
              wardrobeItemId: 'item_5',
            },
            {
              category: 'shoes',
              description: 'Black Ankle Boots',
              wardrobeItemId: 'item_10',
            },
          ],
          accessories: ['Gold Hoop Earrings', 'Black Leather Bag'],
          makeup: {
            foundation: 'Natural coverage, matte finish',
            lips: 'Nude or soft pink lip color',
            eyes: 'Light brown eyeshadow with mascara',
            tip: 'Keep it professional and polished',
          },
          smartTip: 'Perfect for office meetings - elegant yet comfortable',
        },
        {
          occasion: 'casual',
          items: [
            {
              category: 'tops',
              description: 'Striped Navy T-Shirt',
              wardrobeItemId: 'item_3',
            },
            {
              category: 'bottoms',
              description: 'Dark Blue Jeans',
              wardrobeItemId: 'item_4',
            },
            {
              category: 'shoes',
              description: 'White Sneakers',
              wardrobeItemId: 'item_11',
            },
          ],
          accessories: ['Simple stud earrings'],
          makeup: {
            foundation: 'Light BB cream',
            lips: 'Tinted lip balm',
            eyes: 'Just mascara',
            tip: 'Fresh and natural',
          },
          smartTip: 'Comfortable for weekend activities',
        },
      ],
      tips: [
        'Layer with the Camel Trench Coat if it gets cooler',
        'Perfect weather for outdoor activities',
      ],
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
  ];

  for (const rec of recommendations) {
    await db.collection('recommendations').doc(rec.id).set(rec);
    console.log(`  ✓ Created recommendation: ${rec.id}`);
  }
}

// Run the upload
uploadMockData();
