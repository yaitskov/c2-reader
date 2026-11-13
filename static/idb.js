const DB_NAME = "c2reader";
const DB_VERSION = 1;
const STORE_NAME = "stack";

function openDatabase() {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(DB_NAME, DB_VERSION);

    request.onupgradeneeded = () => {
      const db = request.result;
      if (!db.objectStoreNames.contains(STORE_NAME)) {
        db.createObjectStore(STORE_NAME, { autoIncrement: true });
      }
    };

    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}

function readStack(db) {
  return new Promise((resolve, reject) => {
    const transaction = db.transaction(STORE_NAME, "readonly");
    const request = transaction.objectStore(STORE_NAME).getAll();

    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}

function writeStack(db, operation) {
  return new Promise((resolve, reject) => {
    const transaction = db.transaction(STORE_NAME, "readwrite");
    const store = transaction.objectStore(STORE_NAME);
    let result = null;

    operation(store, (value) => {
      result = value;
    });

    transaction.oncomplete = () => resolve(result);
    transaction.onerror = () => reject(transaction.error);
    transaction.onabort = () => reject(transaction.error);
  });
}

export async function load() {
  let db;
  try {
    db = await openDatabase();
    return { ok: true, value: null, stack: await readStack(db) };
  } catch (error) {
    console.error("c2reader memory load failed", error);
    return { ok: false, value: null, stack: [] };
  } finally {
    db?.close();
  }
}

export async function push(value) {
  let db;
  try {
    db = await openDatabase();
    await writeStack(db, (store) => {
      store.add(value);
    });
    return { ok: true, value: null, stack: await readStack(db) };
  } catch (error) {
    console.error("c2reader memory push failed", error);
    return { ok: false, value: null, stack: [] };
  } finally {
    db?.close();
  }
}

export async function pop() {
  let db;
  try {
    db = await openDatabase();
    const value = await writeStack(db, (store, setPopped) => {
      const request = store.openCursor(null, "prev");

      request.onsuccess = () => {
        const cursor = request.result;
        if (!cursor) return;
        setPopped(cursor.value);
        cursor.delete();
      };
    });

    return { ok: true, value, stack: await readStack(db) };
  } catch (error) {
    console.error("c2reader memory pop failed", error);
    return { ok: false, value: null, stack: [] };
  } finally {
    db?.close();
  }
}
