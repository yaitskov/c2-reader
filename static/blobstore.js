const DB_NAME = "c2reader-blobs";
const DB_VERSION = 1;
const STORE_NAME = "entries";
const STORE_INDEX = "by_store";

function openDatabase() {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(DB_NAME, DB_VERSION);

    request.onupgradeneeded = () => {
      const db = request.result;
      if (!db.objectStoreNames.contains(STORE_NAME)) {
        const store = db.createObjectStore(STORE_NAME, { keyPath: ["store", "key"] });
        store.createIndex(STORE_INDEX, "store");
      }
    };

    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}

function requestToPromise(request) {
  return new Promise((resolve, reject) => {
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}

function transactionDone(transaction) {
  return new Promise((resolve, reject) => {
    transaction.oncomplete = () => resolve();
    transaction.onerror = () => reject(transaction.error);
    transaction.onabort = () => reject(transaction.error);
  });
}

async function withDatabase(work) {
  const db = await openDatabase();
  try {
    return await work(db);
  } finally {
    db.close();
  }
}

async function sha1Hex(buffer) {
  const digest = await crypto.subtle.digest("SHA-1", buffer);
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

export function persist(store, name, buffer) {
  return withDatabase(async (db) => {
    const key = await sha1Hex(buffer);
    const transaction = db.transaction(STORE_NAME, "readwrite");
    transaction.objectStore(STORE_NAME).put({
      store,
      key,
      name,
      uploadedAt: Date.now(),
      data: buffer,
    });
    await transactionDone(transaction);
    return key;
  });
}

export function list(store) {
  return withDatabase(async (db) => {
    const transaction = db.transaction(STORE_NAME, "readonly");
    const index = transaction.objectStore(STORE_NAME).index(STORE_INDEX);
    const records = await requestToPromise(index.getAll(store));
    return records.map((record) => [record.key, record.name, record.uploadedAt]);
  });
}

export function get(store, key) {
  return withDatabase(async (db) => {
    const transaction = db.transaction(STORE_NAME, "readonly");
    const record = await requestToPromise(transaction.objectStore(STORE_NAME).get([store, key]));
    if (!record) {
      throw new Error(`blob not found: ${key}`);
    }
    return record.data;
  });
}

export function remove(store, key) {
  return withDatabase(async (db) => {
    const transaction = db.transaction(STORE_NAME, "readwrite");
    transaction.objectStore(STORE_NAME).delete([store, key]);
    await transactionDone(transaction);
  });
}
