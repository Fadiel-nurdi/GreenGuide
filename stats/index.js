const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

/**
 * 🔥 AUTO HITUNG ULANG STATISTIK TESTIMONI
 * Trigger setiap:
 * - tambah
 * - edit
 * - hapus testimoni
 */
exports.syncTestimonialStats = onDocumentWritten(
  "testimonials/{id}",
  async () => {
    const snap = await db.collection("testimonials").get();

    let totalReviews = 0;
    let totalRating = 0;
    const stars = {
      star1: 0,
      star2: 0,
      star3: 0,
      star4: 0,
      star5: 0,
    };

    snap.forEach((doc) => {
      const rating = doc.data().rating;
      if (typeof rating === "number") {
        totalReviews++;
        totalRating += rating;
        stars[`star${rating}`]++;
      }
    });

    const average =
      totalReviews === 0 ? 0 : totalRating / totalReviews;

    await db
      .collection("testimonial_stats")
      .doc("global")
      .set(
        {
          totalReviews,
          totalRating,
          average,
          ...stars,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
  }
);
