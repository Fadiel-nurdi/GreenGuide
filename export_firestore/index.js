const admin = require("firebase-admin");
const fs = require("fs");

// 🔐 init firebase admin
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function exportEcosystems() {
  const snapshot = await db.collection("ecosystems").get();

  const result = {
    mangrove: [],
    dataran_rendah: [],
  };

  snapshot.forEach((doc) => {
    const data = doc.data();

    // clone biar aman
    const item = { ...data };

    // hapus field internal yg tidak perlu di JSON
    delete item.createdAt;
    delete item.updatedAt;
    delete item.ecoNumber;

    if (data.ecosystem === "Mangrove") {
      result.mangrove.push(item);
    } else if (data.ecosystem === "Dataran Rendah") {
      result.dataran_rendah.push(item);
    }
  });

  // simpan ke file json
  fs.writeFileSync(
    "ecosystems_export.json",
    JSON.stringify(result, null, 2),
    "utf8"
  );

  console.log("✅ Export selesai → ecosystems_export.json");
}

exportEcosystems().catch(console.error);
