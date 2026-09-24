const DB_NAME = "ponto-eletronico";
const DB_VERSION = 1;
const STORE_NAME = "attendance_queue";

let databasePromise;

function openDatabase() {
  if (databasePromise) {
    return databasePromise;
  }

  databasePromise = new Promise((resolve, reject) => {
    const request = indexedDB.open(DB_NAME, DB_VERSION);

    request.onerror = () => reject(request.error);

    request.onupgradeneeded = () => {
      const db = request.result;

      if (!db.objectStoreNames.contains(STORE_NAME)) {
        const store = db.createObjectStore(STORE_NAME, {
          keyPath: "id"
        });

        store.createIndex("sync_status", "sync_status");
        store.createIndex("created_at", "created_at");
      }
    };

    request.onsuccess = () => resolve(request.result);
  });

  return databasePromise;
}

export async function queueAttendance(record) {
  const db = await openDatabase();

  return new Promise((resolve, reject) => {
    const transaction = db.transaction(STORE_NAME, "readwrite");
    const store = transaction.objectStore(STORE_NAME);

    const request = store.put({
      ...record,
      sync_status: "pending",
      created_at: new Date().toISOString()
    });

    request.onsuccess = () => resolve(record);
    request.onerror = () => reject(request.error);
  });
}

export async function getPendingAttendance() {
  const db = await openDatabase();

  return new Promise((resolve, reject) => {
    const transaction = db.transaction(STORE_NAME, "readonly");
    const store = transaction.objectStore(STORE_NAME);
    const index = store.index("sync_status");

    const request = index.getAll("pending");

    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}

export async function markAttendanceSynced(id) {
  const db = await openDatabase();

  return new Promise((resolve, reject) => {
    const transaction = db.transaction(STORE_NAME, "readwrite");
    const store = transaction.objectStore(STORE_NAME);

    const request = store.get(id);

    request.onsuccess = () => {
      const record = request.result;

      if (!record) {
        resolve();
        return;
      }

      record.sync_status = "synced";
      record.synced_at = new Date().toISOString();

      const updateRequest = store.put(record);

      updateRequest.onsuccess = () => resolve();
      updateRequest.onerror = () => reject(updateRequest.error);
    };

    request.onerror = () => reject(request.error);
  });
}
