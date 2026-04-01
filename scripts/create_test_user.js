/**
 * Creates a test user via Firebase Identity Toolkit Admin API
 * (bypasses sign-in method restrictions — works even if email/password is disabled).
 *
 * Run: node scripts/create_test_user.js
 */

const https = require('https');
const os    = require('os');
const path  = require('path');
const fs    = require('fs');

const PROJECT_ID    = 'smartcloset-95789';
const CLIENT_ID     = '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com';
const CLIENT_SECRET = 'j9iVZfS8kkCEFUPaAeJV0sAi';

// Test account credentials
const TEST_EMAIL    = 'testuser@smartcloset.app';
const TEST_PASSWORD = 'SmartCloset2024!';
const TEST_NAME     = 'Test User';

function getRefreshToken() {
  const p   = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
  const cfg = JSON.parse(fs.readFileSync(p, 'utf8'));
  return cfg?.tokens?.refresh_token;
}

function getAccessToken(refreshToken) {
  return new Promise((resolve, reject) => {
    const body = new URLSearchParams({
      client_id: CLIENT_ID, client_secret: CLIENT_SECRET,
      refresh_token: refreshToken, grant_type: 'refresh_token',
    }).toString();
    const req = https.request({
      hostname: 'oauth2.googleapis.com', path: '/token', method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    }, res => {
      let d = '';
      res.on('data', c => d += c);
      res.on('end', () => {
        const p = JSON.parse(d);
        p.access_token ? resolve(p.access_token) : reject(new Error(d));
      });
    });
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

function apiRequest(accessToken, method, hostname, urlPath, body) {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : null;
    const req  = https.request({
      hostname, path: urlPath, method,
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
        ...(data ? { 'Content-Length': Buffer.byteLength(data) } : {}),
      },
    }, res => {
      let d = '';
      res.on('data', c => d += c);
      res.on('end', () => {
        const parsed = JSON.parse(d || '{}');
        if (res.statusCode >= 200 && res.statusCode < 300) resolve(parsed);
        else reject(new Error(JSON.stringify(parsed, null, 2)));
      });
    });
    req.on('error', reject);
    if (data) req.write(data);
    req.end();
  });
}

(async () => {
  try {
    process.stdout.write('🔑 Getting access token... ');
    const token = await getAccessToken(getRefreshToken());
    console.log('✅');

    // Try to create user via Identity Toolkit Admin API
    process.stdout.write('👤 Creating test user... ');
    let uid;
    try {
      const result = await apiRequest(
        token, 'POST',
        'identitytoolkit.googleapis.com',
        `/v1/projects/${PROJECT_ID}/accounts`,
        {
          email:         TEST_EMAIL,
          password:      TEST_PASSWORD,
          displayName:   TEST_NAME,
          emailVerified: true,
        }
      );
      uid = result.localId;
      console.log('✅ Created!');
    } catch (err) {
      // If user already exists, look it up
      if (err.message.includes('EMAIL_EXISTS') || err.message.includes('DUPLICATE_EMAIL')) {
        console.log('already exists, looking up UID...');
        const lookup = await apiRequest(
          token, 'POST',
          'identitytoolkit.googleapis.com',
          `/v1/projects/${PROJECT_ID}/accounts:lookup`,
          { email: [TEST_EMAIL] }
        );
        uid = lookup.users?.[0]?.localId;
        if (!uid) throw new Error('Could not find existing user');
        console.log('✅ Found existing user');
      } else {
        throw err;
      }
    }

    console.log('\n✅ Test account ready!\n');
    console.log('  Email:    ' + TEST_EMAIL);
    console.log('  Password: ' + TEST_PASSWORD);
    console.log('  UID:      ' + uid);
    console.log('\nNext: run seed_mock_data.js with this UID to populate test data.');

    // Write UID to a temp file for use by seed script
    fs.writeFileSync(path.join(__dirname, '.test_user_uid'), uid);
    console.log('\n  UID saved to scripts/.test_user_uid');

    process.exit(0);
  } catch (err) {
    console.error('\n❌', err.message);
    process.exit(1);
  }
})();
