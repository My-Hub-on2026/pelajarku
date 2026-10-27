const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue, Timestamp} = require("firebase-admin/firestore");
const crypto = require("node:crypto");
initializeApp();
const db = getFirestore();
const emailApiKey = defineSecret("RESEND_API_KEY");
const verificationSalt = defineSecret("OTP_HMAC_SECRET");
const fromAddress = "PelajarKu <notifikasi@YOUR_VERIFIED_DOMAIN>";
const region = "asia-southeast2";

function requireUid(request) {
  if (!request.auth?.uid) throw new HttpsError("unauthenticated", "Masuk terlebih dahulu");
  return request.auth.uid;
}
function validEmail(v) {
  return typeof v === "string" && v.length <= 254 &&
    /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v);
}
function digest(uid, value) {
  return crypto.createHmac("sha256", verificationSalt.value())
    .update(uid + ":" + value).digest("hex");
}
async function sendMail(to, subject, body) {
  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {"authorization": "Bearer " + emailApiKey.value(),
      "content-type": "application/json"},
    body: JSON.stringify({from: fromAddress, to: [to], subject, text: body})
  });
  if (!response.ok) {
    throw new HttpsError("unavailable", "Email gagal dikirim. Coba lagi.");
  }
}

exports.requestParentEmailVerification = onCall(
 {region, secrets:[emailApiKey, verificationSalt], enforceAppCheck: true},
 async request => {
  const uid = requireUid(request);
  const email = String(request.data?.email || "").trim().toLowerCase();
  if (!validEmail(email)) throw new HttpsError("invalid-argument", "Email tidak valid");
  const ref = db.doc("parentMailLinks/" + uid);
  const old = await ref.get();
  const previous = old.data() || {};
  if (previous.requestedAt?.toMillis &&
      Date.now() - previous.requestedAt.toMillis() < 120000) {
    throw new HttpsError("resource-exhausted", "Tunggu 2 menit");
  }
  const code = crypto.randomInt(100000, 1000000).toString();
  const payload = {
    email, verified: false, attempts: 0,
    hash: digest(uid, code), expiresAt: Timestamp.fromMillis(Date.now() + 600000),
    requestedAt: FieldValue.serverTimestamp(),
  };
  await ref.set(payload);
  try {
    await sendMail(email, "Verifikasi email orang tua PelajarKu",
      "Kode verifikasi: " + code + "\nBerlaku selama 10 menit. Abaikan jika Anda tidak meminta.");
  } catch(e) {
    await ref.delete();
    throw e;
  }
  return {sent:true};
});

exports.confirmParentEmailVerification = onCall(
 {region, secrets:[verificationSalt], enforceAppCheck: true},
 async request => {
  const uid = requireUid(request);
  const code = String(request.data?.code || "");
  if (!/^\d{6}$/.test(code)) throw new HttpsError("invalid-argument", "Kode harus 6 digit");
  const ref = db.doc("parentMailLinks/" + uid);
  await db.runTransaction(async tx => {
    const snap = await tx.get(ref);
    const data = snap.data();
    if (!data || !data.expiresAt || data.expiresAt.toMillis() < Date.now())
      throw new HttpsError("failed-precondition", "Kode kedaluwarsa");
    if ((data.attempts || 0) >= 5)
      throw new HttpsError("resource-exhausted", "Terlalu banyak percobaan");
    const actual = Buffer.from(digest(uid,code));
    const expected = Buffer.from(data.hash);
    if (actual.length !== expected.length ||
        !crypto.timingSafeEqual(actual, expected)) {
      tx.update(ref,{attempts:FieldValue.increment(1)});
      return;
    }
    tx.update(ref,{verified:true, hash:FieldValue.delete(),
      expiresAt:FieldValue.delete(), verifiedAt:FieldValue.serverTimestamp()});
  });
  const now = await ref.get();
  if (!now.data()?.verified)
    throw new HttpsError("permission-denied", "Kode salah");
  return {verified:true};
});

const allowedTypes = new Set([
  "jadwal","tugas","nilai","kehadiran","catatan","profil"
]);
const allowedActions = new Set(["ditambah","diubah","dihapus","diselesaikan"]);
exports.notifyParentOfChange = onCall(
 {region, secrets:[emailApiKey], enforceAppCheck: true},
 async request => {
  const uid = requireUid(request);
  const {eventId, type, action, summary} = request.data || {};
  if (typeof eventId !== "string" || !/^[a-zA-Z0-9_-]{8,80}$/.test(eventId) ||
      !allowedTypes.has(type) || !allowedActions.has(action) ||
      typeof summary !== "string" || summary.length > 160) {
    throw new HttpsError("invalid-argument", "Event tidak valid");
  }
  const link = (await db.doc("parentMailLinks/" + uid).get()).data();
  if (!link?.verified) return {sent:false, reason:"unverified"};
  const ref = db.doc("parentMailEvents/" + uid + "_" + eventId);
  // Server-side idempotency & simple daily quota. Further abuse prevention
  // is necessary before public deployment.
  const quotaRef = db.doc("parentMailQuotas/" + uid + "_" +
    new Date().toISOString().slice(0,10));
  let accepted = false;
  await db.runTransaction(async tx => {
    const [existing,quota] = await Promise.all([tx.get(ref),tx.get(quotaRef)]);
    if (existing.exists) return;
    if ((quota.data()?.count || 0) >= 40)
      throw new HttpsError("resource-exhausted","Batas email harian tercapai");
    tx.create(ref,{uid,type,action,summary,to:link.email,
      status:"queued",createdAt:FieldValue.serverTimestamp()});
    tx.set(quotaRef,{count:FieldValue.increment(1)},{merge:true});
    accepted = true;
  });
  if (!accepted) return {sent:false,reason:"duplicate"};
  try {
    await sendMail(link.email,"Aktivitas PelajarKu: " + type,
      "Ada perubahan pada PelajarKu.\nJenis: " + type +
      "\nTindakan: " + action + "\nRingkasan: " + summary +
      "\nJika Anda bukan wali siswa, abaikan pesan ini.");
    await ref.update({status:"sent",sentAt:FieldValue.serverTimestamp()});
    return {sent:true};
  } catch(error) {
    await ref.update({status:"failed"});
    throw error;
  }
});

exports.disconnectParentEmail = onCall({region,enforceAppCheck:true},
 async request => {
  await db.doc("parentMailLinks/" + requireUid(request)).delete();
  return {disconnected:true};
});
