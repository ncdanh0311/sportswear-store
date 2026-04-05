const admin = require('firebase-admin');
const path = require('path');

const serviceAccountPath =
  process.argv[2] || process.env.GOOGLE_APPLICATION_CREDENTIALS;

if (!serviceAccountPath) {
  console.error(
    'Missing service account JSON. Pass path as arg or set GOOGLE_APPLICATION_CREDENTIALS.'
  );
  process.exit(1);
}

// eslint-disable-next-line import/no-dynamic-require, global-require
const serviceAccount = require(path.resolve(serviceAccountPath));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

const collections = [
  'users',
  'addresses',
  'roles',
  'staff',
  'categories',
  'brands',
  'sports',
  'materials',
  'colors',
  'neck_styles',
  'sleeve_styles',
  'products',
  'product_images',
  'product_variants',
  'inventory',
  'product_specs',
  'product_materials',
  'product_neck_styles',
  'product_sleeve_styles',
  'import_requests',
  'import_items',
  'carts',
  'cart_items',
  'orders',
  'order_items',
  'vouchers',
  'order_voucher',
  'events',
  'event_products',
  'membership_levels',
  'returns',
  'chat_messages',
];

async function init() {
  const batch = db.batch();
  const now = admin.firestore.FieldValue.serverTimestamp();
  collections.forEach((col) => {
    const ref = db.collection(col).doc('_init');
    batch.set(ref, { _init: true, createdAt: now }, { merge: true });
  });
  await batch.commit();
  console.log('Initialized collections.');
}

init().then(() => process.exit(0)).catch((err) => {
  console.error(err);
  process.exit(1);
});
