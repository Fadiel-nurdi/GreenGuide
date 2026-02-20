const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Create Admin Account + Send Reset Password Email
 * Dipanggil oleh Super Admin dari Flutter
 */
exports.createAdmin = functions.https.onCall(async (data, context) => {
  // 🔐 WAJIB login
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Harus login sebagai super admin"
    );
  }

  const { email, name } = data;

  if (!email || !name) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Email dan nama wajib diisi"
    );
  }

  try {
    // 1️⃣ Buat akun Auth dengan password sementara
    const userRecord = await admin.auth().createUser({
      email: email,
      password: "Temp123456", // sementara
      displayName: name,
      emailVerified: false,
    });

    // 2️⃣ Simpan ke Firestore (admins)
    await admin.firestore().collection("admins").doc(userRecord.uid).set({
      name: name,
      email: email,
      role: "admin",
      isActive: true,
      isOnline: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 3️⃣ Kirim email reset password
    const resetLink = await admin.auth().generatePasswordResetLink(email);

    return {
      success: true,
      message: "Admin berhasil dibuat",
      resetLink: resetLink,
    };
  } catch (error) {
    console.error(error);
    throw new functions.https.HttpsError(
      "internal",
      error.message || "Gagal membuat admin"
    );
  }
});
