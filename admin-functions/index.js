const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();


// ================= CREATE ADMIN =================
exports.createAdmin = onCall(
  { region: "us-central1" },   // ✅ WAJIB TAMBAH REGION
  async (request) => {

    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Belum login");
    }

    const callerUid = request.auth.uid;

    // ✅ CEK ROLE SUPER ADMIN
    const callerDoc = await admin
      .firestore()
      .collection("admins")
      .doc(callerUid)
      .get();

if (!callerDoc.exists || callerDoc.data().role !== "super_admin") {
      throw new HttpsError(
        "permission-denied",
        "Hanya super admin yang boleh membuat admin"
      );
    }

    const { email, name } = request.data;

    if (!email || !name) {
      throw new HttpsError("invalid-argument", "Data tidak lengkap");
    }

    try {
      console.log("CREATE ADMIN DIPANGGIL DENGAN EMAIL:", email);

      const user = await admin.auth().createUser({
        email: email.toLowerCase(),
        emailVerified: false,
      });

      console.log("USER BERHASIL DIBUAT UID:", user.uid);

      // 🔥 Generate password reset link
      const resetLink = await admin
        .auth()
        .generatePasswordResetLink(email.toLowerCase());

      console.log("RESET PASSWORD LINK:", resetLink);

      await admin.firestore().collection("admins").doc(user.uid).set({
        name,
        email: email.toLowerCase(),
        role: "admin",
        active: true,
        isOnline: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        lastOnline: null,
      });

      return {
        success: true,
        message: "Admin dibuat dan link reset password sudah dibuat",
        resetLink, // sementara kirim ke client untuk testing
      };

    } catch (error) {
      console.error("CREATE ADMIN ERROR:", error);
      throw new HttpsError("internal", error.message);
    }
  }
);


// ================= DELETE ADMIN =================
exports.deleteAdmin = onCall(
  { region: "us-central1" },   // ✅ WAJIB TAMBAH REGION
  async (request) => {

    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Belum login");
    }

    const callerUid = request.auth.uid;

    // ✅ CEK ROLE SUPER ADMIN
    const callerDoc = await admin
      .firestore()
      .collection("admins")
      .doc(callerUid)
      .get();

    if (!callerDoc.exists || callerDoc.data().role !== "super_admin") {
      throw new HttpsError(
        "permission-denied",
        "Hanya super admin yang boleh menghapus admin"
      );
    }

    const { uid } = request.data;

    if (!uid) {
      throw new HttpsError("invalid-argument", "UID wajib dikirim");
    }

    try {
      await admin.auth().deleteUser(uid);
      await admin.firestore().collection("admins").doc(uid).delete();
      return { success: true };

    } catch (error) {
      throw new HttpsError("internal", error.message);
    }
  }
);
