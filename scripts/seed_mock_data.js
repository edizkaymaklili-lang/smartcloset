/**
 * Mock data seeder for Smart Closet — correct Firestore paths & schema.
 * Run: node scripts/seed_mock_data.js
 */

const https = require('https');
const os    = require('os');
const path  = require('path');
const fs    = require('fs');

const PROJECT_ID = 'smartcloset-95789';
const USER_ID    = 'AI1bm9vMtZZCLzCe5KnjeuqkHLa2'; // testuser@smartcloset.app
const DB_ROOT    = `projects/${PROJECT_ID}/databases/(default)/documents`;

const CLIENT_ID     = '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com';
const CLIENT_SECRET = 'j9iVZfS8kkCEFUPaAeJV0sAi';

// ─── Auth ────────────────────────────────────────────────────────────────────
function getRefreshToken() {
  const p = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
  return JSON.parse(fs.readFileSync(p, 'utf8'))?.tokens?.refresh_token;
}
function getAccessToken(rt) {
  return new Promise((res, rej) => {
    const body = new URLSearchParams({ client_id: CLIENT_ID, client_secret: CLIENT_SECRET, refresh_token: rt, grant_type: 'refresh_token' }).toString();
    const req  = https.request({ hostname: 'oauth2.googleapis.com', path: '/token', method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' } }, r => {
      let d = ''; r.on('data', c => d += c); r.on('end', () => { const p = JSON.parse(d); p.access_token ? res(p.access_token) : rej(new Error(d)); });
    });
    req.on('error', rej); req.write(body); req.end();
  });
}

// ─── Firestore REST ───────────────────────────────────────────────────────────
let TOKEN = '';

function fsReq(method, docPath, body) {
  return new Promise((res, rej) => {
    const data = body ? JSON.stringify(body) : null;
    const req  = https.request({
      hostname: 'firestore.googleapis.com',
      path:     `/v1/${DB_ROOT}/${docPath}`,
      method,
      headers:  { 'Authorization': `Bearer ${TOKEN}`, 'Content-Type': 'application/json', ...(data ? { 'Content-Length': Buffer.byteLength(data) } : {}) },
    }, r => {
      let d = ''; r.on('data', c => d += c);
      r.on('end', () => {
        if (r.statusCode >= 200 && r.statusCode < 300) res(d ? JSON.parse(d) : {});
        else rej(new Error(`${method} ${docPath} → ${r.statusCode}: ${d.slice(0,300)}`));
      });
    });
    req.on('error', rej); if (data) req.write(data); req.end();
  });
}

async function clearCollection(col) {
  const r = await new Promise((res, rej) => {
    const req = https.request({
      hostname: 'firestore.googleapis.com',
      path: `/v1/${DB_ROOT}/${col}?pageSize=300`,
      method: 'GET',
      headers: { 'Authorization': `Bearer ${TOKEN}` },
    }, r => { let d = ''; r.on('data', c => d += c); r.on('end', () => res(JSON.parse(d || '{}'))); });
    req.on('error', rej); req.end();
  });
  for (const doc of r.documents || []) {
    const id = doc.name.split('/').pop();
    await fsReq('DELETE', `${col}/${id}`).catch(() => {});
  }
  if ((r.documents || []).length) console.log(`  cleared ${r.documents.length} from ${col}`);
}

// ─── Firestore Value helpers ──────────────────────────────────────────────────
function v(val) {
  if (val === null || val === undefined) return { nullValue: null };
  if (val && val._ts)      return { timestampValue: val.iso };
  if (val && val._geo)     return { geoPointValue: { latitude: val.lat, longitude: val.lng } };
  if (typeof val === 'boolean')  return { booleanValue: val };
  if (typeof val === 'number' && Number.isInteger(val)) return { integerValue: String(val) };
  if (typeof val === 'number')   return { doubleValue: val };
  if (typeof val === 'string')   return { stringValue: val };
  if (Array.isArray(val))        return { arrayValue: { values: val.map(v) } };
  if (typeof val === 'object')   return { mapValue: { fields: fields(val) } };
  return { stringValue: String(val) };
}
function fields(obj) {
  const f = {};
  for (const [k, val] of Object.entries(obj)) if (val !== undefined) f[k] = v(val);
  return f;
}
function ts(daysAgo = 0) { const d = new Date(Date.now() - daysAgo * 86400000); return { _ts: true, iso: d.toISOString() }; }
function geo(lat, lng)   { return { _geo: true, lat, lng }; }
function isoDate(daysAgo = 0) { return new Date(Date.now() - daysAgo * 86400000).toISOString(); }

async function set(col, id, data) {
  await fsReq('PATCH', `${col}/${id}`, { fields: fields(data) });
}

// ─── Wardrobe ─────────────────────────────────────────────────────────────────
// Path: wardrobe/{itemId}  •  Fields match ClothingItem.fromJson()
// category must be exact enum name: tops|bottoms|skirts|dresses|outerwear|suits|sportswear|swimwear|shoes|bags|accessories
// addedAt: ISO string (DateTime.parse)
// storageImageUrl: image field name the app uses
async function seedWardrobe() {
  process.stdout.write('\n[Wardrobe] ');
  await clearCollection('wardrobe');

  const items = [
    { id:'w1',  category:'tops',        name:'White Basic T-Shirt',    color:'white',  seasons:['spring','summer'],          occasions:['casual'],          weatherSuitability:['hot','mild'],         storageImageUrl:'https://images.unsplash.com/photo-1581655353564-df123a1eb820?w=400&bg=white', isFavorite:true,  addedAt:isoDate(30) },
    { id:'w2',  category:'tops',        name:'Navy Blue Shirt',         color:'navy',   seasons:['spring','autumn'],          occasions:['casual','work'],    weatherSuitability:['mild','cool'],        storageImageUrl:'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=400', isFavorite:false, addedAt:isoDate(25) },
    { id:'w3',  category:'tops',        name:'Black Turtleneck',        color:'black',  seasons:['autumn','winter'],          occasions:['casual','work'],    weatherSuitability:['cool','cold'],        storageImageUrl:'https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=400', isFavorite:true,  addedAt:isoDate(20) },
    { id:'w4',  category:'tops',        name:'Pink Oversized Hoodie',   color:'pink',   seasons:['autumn','winter'],          occasions:['casual'],          weatherSuitability:['mild','cool','cold'], storageImageUrl:'https://images.unsplash.com/photo-1556821840-3a63f15732ce?w=400', isFavorite:false, addedAt:isoDate(15) },
    { id:'w5',  category:'bottoms',     name:'Slim Fit Blue Jeans',     color:'blue',   seasons:['spring','autumn','winter'], occasions:['casual'],          weatherSuitability:['mild','cool','cold'], storageImageUrl:'https://images.unsplash.com/photo-1604176354204-9268737828e4?w=400', isFavorite:true,  addedAt:isoDate(45) },
    { id:'w6',  category:'bottoms',     name:'Black Slim Trousers',     color:'black',  seasons:['spring','autumn','winter'], occasions:['work','formal'],    weatherSuitability:['mild','cool','cold'], storageImageUrl:'https://images.unsplash.com/photo-1624378439575-d8705ad7ae80?w=400', isFavorite:false, addedAt:isoDate(40) },
    { id:'w7',  category:'bottoms',     name:'Beige Chinos',            color:'beige',  seasons:['spring','summer','autumn'], occasions:['casual','work'],    weatherSuitability:['mild','hot'],         storageImageUrl:'https://images.unsplash.com/photo-1560243563-062bfc001d68?w=400', isFavorite:false, addedAt:isoDate(35) },
    { id:'w8',  category:'dresses',     name:'Floral Midi Dress',       color:'floral', seasons:['spring','summer'],          occasions:['casual','party'],   weatherSuitability:['hot','mild'],         storageImageUrl:'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=400', isFavorite:true,  addedAt:isoDate(10) },
    { id:'w9',  category:'dresses',     name:'Little Black Dress',      color:'black',  seasons:['spring','summer','autumn'], occasions:['party','formal'],   weatherSuitability:['mild','cool'],        storageImageUrl:'https://images.unsplash.com/photo-1550639525-c97d455acf70?w=400', isFavorite:false, addedAt:isoDate(8)  },
    { id:'w10', category:'outerwear',   name:'Camel Wool Coat',         color:'camel',  seasons:['autumn','winter'],          occasions:['casual','work'],    weatherSuitability:['cool','cold'],        storageImageUrl:'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=400', isFavorite:true,  addedAt:isoDate(60) },
    { id:'w11', category:'outerwear',   name:'Denim Jacket',            color:'blue',   seasons:['spring','autumn'],          occasions:['casual'],          weatherSuitability:['mild','cool'],        storageImageUrl:'https://images.unsplash.com/photo-1601333144130-8cbb312386b6?w=400', isFavorite:false, addedAt:isoDate(55) },
    { id:'w12', category:'outerwear',   name:'Black Leather Jacket',    color:'black',  seasons:['spring','autumn'],          occasions:['casual','party'],   weatherSuitability:['mild','cool'],        storageImageUrl:'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=400', isFavorite:true,  addedAt:isoDate(50) },
    { id:'w13', category:'shoes',       name:'White Sneakers',          color:'white',  seasons:['spring','summer','autumn'], occasions:['casual','sport'],   weatherSuitability:['hot','mild'],         storageImageUrl:'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400', isFavorite:true,  addedAt:isoDate(70) },
    { id:'w14', category:'shoes',       name:'Black Oxford Shoes',      color:'black',  seasons:['autumn','winter'],          occasions:['work','formal'],    weatherSuitability:['mild','cool','cold'], storageImageUrl:'https://images.unsplash.com/photo-1533867617858-e7b97e060509?w=400', isFavorite:false, addedAt:isoDate(65) },
    { id:'w15', category:'shoes',       name:'Brown Chelsea Boots',     color:'brown',  seasons:['autumn','winter'],          occasions:['casual','work'],    weatherSuitability:['cool','cold'],        storageImageUrl:'https://images.unsplash.com/photo-1638247025967-b4e38f787b76?w=400', isFavorite:false, addedAt:isoDate(62) },
    { id:'w16', category:'accessories', name:'Gold Watch',              color:'gold',   seasons:['spring','summer','autumn','winter'], occasions:['casual','work','formal'], weatherSuitability:['hot','mild','cool','cold'], storageImageUrl:'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400', isFavorite:true, addedAt:isoDate(90) },
    { id:'w17', category:'accessories', name:'White Silk Scarf',        color:'white',  seasons:['autumn','winter'],          occasions:['casual','work'],    weatherSuitability:['cool','cold'],        storageImageUrl:'https://images.unsplash.com/photo-1584589167171-541ce45f1eea?w=400', isFavorite:false, addedAt:isoDate(85) },
    { id:'w18', category:'bags',        name:'Tan Leather Tote',        color:'tan',    seasons:['spring','summer','autumn','winter'], occasions:['casual','work'], weatherSuitability:['hot','mild','cool','cold'], storageImageUrl:'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=400', isFavorite:true, addedAt:isoDate(80) },
    { id:'w19', category:'bags',        name:'Black Crossbody Bag',     color:'black',  seasons:['spring','summer','autumn'], occasions:['casual'],          weatherSuitability:['hot','mild','cool'],  storageImageUrl:'https://images.unsplash.com/photo-1590739293931-a4db4b07e7ce?w=400', isFavorite:false, addedAt:isoDate(75) },
    { id:'w20', category:'skirts',      name:'Pleated Midi Skirt',      color:'beige',  seasons:['spring','summer'],          occasions:['casual','work'],    weatherSuitability:['mild','hot'],         storageImageUrl:'https://images.unsplash.com/photo-1583496661160-fb5886a0aaaa?w=400', isFavorite:true,  addedAt:isoDate(5)  },
  ];

  for (const item of items) {
    process.stdout.write('.');
    await set('wardrobe', item.id, { ...item, userId: USER_ID, localImagePath: null, lastWorn: null });
  }
  console.log(` ${items.length} items`);
}

// ─── Style Feed ───────────────────────────────────────────────────────────────
// Path: style_posts/{id}  •  Fields match StylePost.fromJson()
// photoUrl (not imageUrl), userDisplayName (not userName), description (not caption)
// location: nested map with coordinates (GeoPoint), city, country, isExactLocation
// likes: integer count, likedBy: array of UIDs
// createdAt/updatedAt: Firestore Timestamp
async function seedStyleFeed() {
  process.stdout.write('\n[Style Feed] ');
  await clearCollection('style_posts');
  await clearCollection('posts'); // also clear old wrong-path data

  const U = [
    { id:'user_ayse',  name:'Ayşe Kaya',      avatar:'https://ui-avatars.com/api/?name=Ayse+Kaya&background=F48FB1&color=fff&size=150' },
    { id:'user_merve', name:'Merve Demir',     avatar:'https://ui-avatars.com/api/?name=Merve+Demir&background=CE93D8&color=fff&size=150' },
    { id:'user_elif',  name:'Elif Yılmaz',     avatar:'https://ui-avatars.com/api/?name=Elif+Yilmaz&background=80CBC4&color=fff&size=150' },
    { id:USER_ID,      name:'Test User',        avatar:'https://ui-avatars.com/api/?name=Test+User&background=90CAF9&color=fff&size=150' },
  ];

  const posts = [
    { id:'sp1', userId:U[0].id, userDisplayName:U[0].name, userAvatar:U[0].avatar, photoUrl:'https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=600', description:'Perfect spring outfit 🌸 loving this floral combo!', tags:['spring','floral','ootd'],           location:{ coordinates:geo(41.0082,28.9784), city:'Istanbul', country:'Turkey', isExactLocation:false }, likes:3, likedBy:[U[1].id,U[2].id,USER_ID], createdAt:ts(1), updatedAt:ts(1) },
    { id:'sp2', userId:U[1].id, userDisplayName:U[1].name, userAvatar:U[1].avatar, photoUrl:'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=600', description:'Monday office look 💼 keeping it minimal and chic',  tags:['officewear','minimal','chic'],      location:{ coordinates:geo(39.9334,32.8597), city:'Ankara',   country:'Turkey', isExactLocation:false }, likes:2, likedBy:[U[0].id,USER_ID],       createdAt:ts(2), updatedAt:ts(2) },
    { id:'sp3', userId:USER_ID, userDisplayName:U[3].name, userAvatar:U[3].avatar, photoUrl:'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=600', description:'Black on black never fails ✨',                     tags:['allblack','monochrome','street'],    location:{ coordinates:geo(41.0082,28.9784), city:'Istanbul', country:'Turkey', isExactLocation:false }, likes:2, likedBy:[U[0].id,U[1].id],       createdAt:ts(3), updatedAt:ts(3) },
    { id:'sp4', userId:U[2].id, userDisplayName:U[2].name, userAvatar:U[2].avatar, photoUrl:'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?w=600', description:'Summer vibes all day every day ☀️',                 tags:['summer','casual','ootd'],            location:{ coordinates:geo(38.4189,27.1287), city:'İzmir',    country:'Turkey', isExactLocation:false }, likes:2, likedBy:[USER_ID,U[1].id],       createdAt:ts(4), updatedAt:ts(4) },
    { id:'sp5', userId:U[0].id, userDisplayName:U[0].name, userAvatar:U[0].avatar, photoUrl:'https://images.unsplash.com/photo-1550614000-4895a10e1bfd?w=600', description:'Cozy winter look 🧥 camel coat season!',              tags:['winter','camelcoat','cozy'],         location:{ coordinates:geo(41.0082,28.9784), city:'Istanbul', country:'Turkey', isExactLocation:false }, likes:3, likedBy:[U[2].id,USER_ID,U[1].id], createdAt:ts(5), updatedAt:ts(5) },
    { id:'sp6', userId:U[1].id, userDisplayName:U[1].name, userAvatar:U[1].avatar, photoUrl:'https://images.unsplash.com/photo-1434389677669-e08b4cac3105?w=600', description:'Weekend brunch outfit inspo 🥐',                    tags:['brunch','weekend','casual'],         location:{ coordinates:geo(39.9334,32.8597), city:'Ankara',   country:'Turkey', isExactLocation:false }, likes:1, likedBy:[USER_ID],               createdAt:ts(6), updatedAt:ts(6) },
  ];

  for (const p of posts) {
    process.stdout.write('.');
    await set('style_posts', p.id, p);
  }

  // Comments subcollection: style_posts/{postId}/comments/{commentId}
  const comments = [
    { postId:'sp1', id:'c1a', userId:U[1].id, userDisplayName:U[1].name, userAvatar:U[1].avatar, text:'Love this look! Where is the blouse from?', createdAt:ts(0.9) },
    { postId:'sp1', id:'c1b', userId:U[2].id, userDisplayName:U[2].name, userAvatar:U[2].avatar, text:'So cute! 😍', createdAt:ts(0.8) },
    { postId:'sp1', id:'c1c', userId:USER_ID,  userDisplayName:U[3].name, userAvatar:U[3].avatar, text:'Gorgeous outfit!', createdAt:ts(0.7) },
    { postId:'sp3', id:'c3a', userId:U[0].id, userDisplayName:U[0].name, userAvatar:U[0].avatar, text:'All black is always a good idea!', createdAt:ts(2.5) },
    { postId:'sp3', id:'c3b', userId:U[1].id, userDisplayName:U[1].name, userAvatar:U[1].avatar, text:'What brand are the boots?', createdAt:ts(2.4) },
  ];
  for (const c of comments) {
    process.stdout.write('.');
    const { postId, id, ...data } = c;
    await set(`style_posts/${postId}/comments`, id, data);
  }
  console.log(` ${posts.length} posts + ${comments.length} comments`);
}

// ─── Notifications ────────────────────────────────────────────────────────────
// Path: notifications/{id}  (root collection, NOT subcollection)
// createdAt: Firestore Timestamp (app does: (data['createdAt'] as Timestamp?)?.toDate())
async function seedNotifications() {
  process.stdout.write('\n[Notifications] ');
  await clearCollection('notifications');

  const notifs = [
    { id:'n1', userId:USER_ID, type:'like',    fromUserId:'user_ayse',  fromUserName:'Ayşe Kaya',   fromUserAvatar:'https://ui-avatars.com/api/?name=Ayse+Kaya&background=F48FB1&color=fff&size=150', postId:'sp3', postImageUrl:'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400', commentText:null, read:false, createdAt:ts(0.1) },
    { id:'n2', userId:USER_ID, type:'comment', fromUserId:'user_merve', fromUserName:'Merve Demir', fromUserAvatar:'https://ui-avatars.com/api/?name=Merve+Demir&background=CE93D8&color=fff&size=150', postId:'sp3', postImageUrl:'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400', commentText:'All black is always a good idea!', read:false, createdAt:ts(0.2) },
    { id:'n3', userId:USER_ID, type:'follow',  fromUserId:'user_elif',  fromUserName:'Elif Yılmaz', fromUserAvatar:'https://ui-avatars.com/api/?name=Elif+Yilmaz&background=80CBC4&color=fff&size=150', postId:null, postImageUrl:null, commentText:null, read:false, createdAt:ts(0.5) },
    { id:'n4', userId:USER_ID, type:'like',    fromUserId:'user_merve', fromUserName:'Merve Demir', fromUserAvatar:'https://ui-avatars.com/api/?name=Merve+Demir&background=CE93D8&color=fff&size=150', postId:'sp3', postImageUrl:'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400', commentText:null, read:true, createdAt:ts(1) },
    { id:'n5', userId:USER_ID, type:'comment', fromUserId:'user_ayse',  fromUserName:'Ayşe Kaya',   fromUserAvatar:'https://ui-avatars.com/api/?name=Ayse+Kaya&background=F48FB1&color=fff&size=150', postId:'sp3', postImageUrl:'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400', commentText:'What brand are the boots?', read:true, createdAt:ts(2) },
  ];

  for (const n of notifs) {
    process.stdout.write('.');
    const { id, ...data } = n;
    await set('notifications', id, data);
  }
  console.log(` ${notifs.length} notifs (3 unread)`);
}

// ─── User Profile ─────────────────────────────────────────────────────────────
async function seedUserProfile() {
  process.stdout.write('\n[User Profile] ');
  await set('users', USER_ID, {
    uid: USER_ID, email: 'testuser@smartcloset.app', displayName: 'Test User',
    photoUrl: 'https://ui-avatars.com/api/?name=Test+User&background=90CAF9&color=fff&size=150',
    bio: 'Fashion enthusiast & minimalist ✨ | Istanbul',
    city: 'Istanbul', followersCount: 42, followingCount: 28,
    postsCount: 1, wardrobeCount: 20,
    createdAt: ts(90), updatedAt: ts(0),
  });
  console.log('done');
}

// ─── Main ─────────────────────────────────────────────────────────────────────
(async () => {
  try {
    process.stdout.write('🔑 Token... ');
    TOKEN = await getAccessToken(getRefreshToken());
    console.log('✅');
    console.log(`\n🚀 Seeding ${PROJECT_ID} | user: ${USER_ID}\n`);

    await seedUserProfile();
    await seedWardrobe();
    await seedStyleFeed();
    await seedNotifications();

    console.log('\n\n✅ Done!\n');
    process.exit(0);
  } catch (e) {
    console.error('\n❌', e.message);
    process.exit(1);
  }
})();
