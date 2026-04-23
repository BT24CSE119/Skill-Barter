/**
 * Firebase Cloud Functions
 */

const { setGlobalOptions } = require("firebase-functions/v2");
const { onCall } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

// ✅ AGORA TOKEN
const { RtcTokenBuilder, RtcRole } = require("agora-access-token");

// ✅ EMAIL (NODEMAILER)
const nodemailer = require("nodemailer");

// ============================================================
// 🔥 CONFIG (IMPORTANT)
// ============================================================

// ⚠️ REPLACE THESE WITH YOUR REAL VALUES
const APP_ID = "5aa36229235f45e9b9b60594dbcada33";
const APP_CERTIFICATE = "YOUR_AGORA_APP_CERTIFICATE"; // ❗ REQUIRED

// Gmail config (use App Password)
const EMAIL = "your_email@gmail.com";
const PASSWORD = "your_app_password";

// ============================================================
// 🔥 GLOBAL OPTIONS
// ============================================================

setGlobalOptions({ maxInstances: 10 });

admin.initializeApp();

async function sendPushToUser({ userId, title, body, data = {} }) {
  if (!userId) return;

  const userSnap = await admin.firestore().collection("users").doc(userId).get();
  const token = userSnap.exists ? userSnap.data().fcmToken : null;

  // Always write in-app notification
  await admin.firestore().collection("notifications").add({
    title: title || "Notification",
    message: body || "",
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    read: false,
    userId,
    data,
  });

  if (!token) {
    logger.info("No FCM token for user:", userId);
    return;
  }

  try {
    await admin.messaging().send({
      token,
      notification: { title: title || "SkillBarter", body: body || "" },
      data: Object.fromEntries(
        Object.entries(data).map(([k, v]) => [String(k), String(v)])
      ),
      android: { priority: "high" },
    });
  } catch (e) {
    logger.error("FCM send failed:", e);
  }
}

// ============================================================
// 🚀 1. AGORA TOKEN GENERATOR
// ============================================================

exports.generateAgoraToken = onCall((request) => {
  try {
    const { channelName, uid = 0 } = request.data;

    if (!channelName) {
      throw new Error("channelName is required");
    }

    const role = RtcRole.PUBLISHER;
    const expireTime = 3600;

    const currentTime = Math.floor(Date.now() / 1000);
    const privilegeExpireTime = currentTime + expireTime;

    const token = RtcTokenBuilder.buildTokenWithUid(
      APP_ID,
      APP_CERTIFICATE,
      channelName,
      uid,
      role,
      privilegeExpireTime
    );

    return { token };
  } catch (error) {
    logger.error("Agora token error:", error);
    throw new Error(error.message);
  }
});

// ============================================================
// 🚀 2. EMAIL SENDER FOR FEEDBACK
// ============================================================

// Nodemailer transporter
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: EMAIL,
    pass: PASSWORD,
  },
});

// 🔥 TRIGGER WHEN NEW REPORT IS ADDED
exports.sendFeedbackEmail = onDocumentCreated(
  "reports/{id}",
  async (event) => {
    const data = event.data.data();

    // Only send email for feedback
    if (data.type !== "feedback") return;

    try {
      const mailOptions = {
        from: `"SkillBarter" <${EMAIL}>`,
        to: EMAIL, // admin email

        subject: "📢 New Feedback Received",

        text: `
User ID: ${data.userId}

Category: ${data.category || "N/A"}
Rating: ${data.rating || "N/A"}
Recommended: ${data.recommend ? "Yes" : "No"}

Message:
${data.message}

----------------------------
SkillBarter App
        `,
      };

      await transporter.sendMail(mailOptions);

      logger.info("✅ Feedback email sent");
    } catch (error) {
      logger.error("❌ Email sending failed:", error);
    }
  }
);

// ============================================================
// 🔔 3. PUSH NOTIFICATIONS FOR REQUESTS / CALLS
// ============================================================

exports.onSessionRequestCreated = onDocumentCreated(
  "sessionRequests/{id}",
  async (event) => {
    const data = event.data.data();
    if (!data) return;

    const toUserId = data.toUserId;
    const fromUserId = data.fromUserId;
    const sessionId = data.sessionId;

    await sendPushToUser({
      userId: toUserId,
      title: "Session request",
      body: "Someone wants to start a session with you.",
      data: { type: "session_request", sessionId: sessionId || "", fromUserId: fromUserId || "" },
    });
  }
);

exports.onConnectionRequestCreated = onDocumentCreated(
  "connectionRequests/{id}",
  async (event) => {
    const data = event.data.data();
    if (!data) return;

    const toUserId = data.toUserId;
    const fromUserId = data.fromUserId;

    await sendPushToUser({
      userId: toUserId,
      title: "Connection request",
      body: "You received a new connection request.",
      data: { type: "connection_request", fromUserId: fromUserId || "" },
    });
  }
);

exports.onCallCreated = onDocumentCreated(
  "calls/{id}",
  async (event) => {
    const data = event.data.data();
    if (!data) return;

    if (data.status && data.status !== "calling") return;

    const receiverId = data.receiverId;
    const callerId = data.callerId;
    const sessionId = data.sessionId;

    await sendPushToUser({
      userId: receiverId,
      title: "Incoming call",
      body: "You have an incoming video call.",
      data: { type: "call", callId: event.params.id, sessionId: sessionId || "", fromUserId: callerId || "" },
    });
  }
);