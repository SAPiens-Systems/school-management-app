import * as logger from "firebase-functions/logger";
import {onDocumentWritten} from "firebase-functions/v2/firestore";
import {initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {getFirestore, FieldValue} from "firebase-admin/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";

// Type definitions
interface UserDocument {
  role: 'admin' | 'teacher';
  schoolId: string;
  status?: 'pending' | 'approved' | 'rejected';
  [key: string]: any; // For other potential fields
}

interface StudentDocument {
  schoolId: string;
  email: string;
  name: string;
  [key: string]: any; // For other potential fields
}

// Initialize Firebase Admin
initializeApp();

export const manageUserPrivileges = onDocumentWritten(
  "schools/{schoolDoc}/users/{userId}",
  async (event) => {
    // Safe data access with type checking
    if (!event.data || !event.data.after.exists) {
      logger.log("Document deleted or no data");
      // 🔹 Clear claims with {} instead of null
      await getAuth().setCustomUserClaims(event.params.userId, {});
      return;
    }

    const beforeData = event.data.before?.data();
    const afterData = event.data.after.data() as UserDocument;
    const { userId } = event.params;
    const schoolDoc = event.params.schoolDoc;

    // 🔹 Prevent infinite loop when only lastVerified changes
    if (
      beforeData &&
      afterData &&
      JSON.stringify({ ...beforeData, lastVerified: undefined }) ===
        JSON.stringify({ ...afterData, lastVerified: undefined })
    ) {
      logger.log("Skipping update triggered only by lastVerified");
      return;
    }

    if (!afterData) {
      logger.error("User data is undefined");
      return;
    }

    if (typeof afterData.role !== 'string' || typeof afterData.schoolId !== 'string') {
      logger.error("Invalid user document structure");
      return;
    }

    try {
      const cleanSchoolId = schoolDoc;

      await getAuth().setCustomUserClaims(userId, {
        admin: afterData.role === 'admin',
        schoolId: cleanSchoolId,
        status: afterData.status || 'pending',
        role: afterData.role
      });

      await getFirestore()
        .doc(event.data.after.ref.path)
        .update({
          lastVerified: FieldValue.serverTimestamp()
        });

      logger.log(`Updated privileges for ${userId}`, {
        schoolId: cleanSchoolId,
        role: afterData.role
      });

    } catch (error) {
      logger.error("Error updating user claims:", error);
      throw new Error(`Failed to update claims for ${userId}`);
    }
  }
);


function randomPassword(len = 12) {
  const chars =
    "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()";
  let out = "";
  for (let i = 0; i < len; i++) {
    out += chars[Math.floor(Math.random() * chars.length)];
  }
  return out;
}

function calcAge(dob: Date) {
  const now = new Date();
  let age = now.getUTCFullYear() - dob.getUTCFullYear();
  const m = now.getUTCMonth() - dob.getUTCMonth();
  if (m < 0 || (m === 0 && now.getUTCDate() < dob.getUTCDate())) age--;
  return age;
}

/**
 * Callable to create a student (admin only).
 * Validates caller is admin of the same school, creates Auth user,
 * sets student custom claims, and writes Firestore docs in one atomic flow.
 */
export const createStudent = onCall(
  { region: "asia-south1" }, // pick your closest region
  async (request) => {
    // 1) Auth check
    const auth = request.auth;
    if (!auth) {
      throw new HttpsError("unauthenticated", "You must be signed in.");
    }
    const claims = auth.token as any;
    if (!claims.admin || !claims.schoolId) {
      throw new HttpsError("permission-denied", "Admin privileges required.");
    }

    // 2) Input
    const data = request.data || {};
    const schoolId: string = String(data.schoolId || "").trim();
    const name: string = String(data.name || "").trim();
    const email: string = String(data.email || "").trim();
    const gender: string = String(data.gender || "").trim();
    const klass: string = String(data.classId || "").trim(); // "Class 6A"
    const address: string = String(data.address || "").trim();
    const phone: string = String(data.phone || "").trim();
    const dobStr: string = String(data.dateOfBirth || "").trim(); // "YYYY-MM-DD"

    if (!schoolId || !name || !email || !gender || !klass || !address || !phone || !dobStr) {
      throw new HttpsError("invalid-argument", "Missing required fields.");
    }
    if (claims.schoolId !== schoolId) {
      throw new HttpsError(
        "permission-denied",
        "You can only create students for your own school."
      );
    }

    const dob = new Date(dobStr);
    if (isNaN(dob.getTime())) {
      throw new HttpsError("invalid-argument", "Invalid dateOfBirth format.");
    }
    const age = calcAge(dob);
    const classId = klass.replace(/\s+/g, "_").toLowerCase();

    // 3) Create Auth user with temp password
    const tempPassword = randomPassword(12);
    let uid: string;
    try {
      logger.log("Creating Firebase Auth user...");
      const userRecord = await getAuth().createUser({
        email,
        password: tempPassword,
        displayName: name,
        emailVerified: false,
        disabled: false,
      });
      logger.log("Auth user created:", userRecord.uid);
      uid = userRecord.uid;
    } catch (err: any) {
      logger.error("Auth createUser failed", err);
      // map common codes
      if (err?.code === "auth/email-already-exists") {
        throw new HttpsError("already-exists", "Email already in use.");
      }
      throw new HttpsError("internal", "Failed to create Auth user.");
    }

    logger.log("Setting custom claims...");
    // 4) Set student claims
    try {
      await getAuth().setCustomUserClaims(uid, {
        admin: false,
        role: "student",
        schoolId,
        status: "approved",
      });
      logger.log("Custom claims set for:", uid);
    } catch (err) {
      logger.error("setCustomUserClaims failed", err);
      // continue but log; we still write Firestore so admin can see the record
    }


    // 5) Firestore writes (service account bypasses rules)
    const db = getFirestore();
    const studentData = {
      id: uid,
      name,
      schoolId,
      age,
      gender,
      dateOfBirth: dobStr, // store ISO string, or use FieldValue.serverTimestamp() + another field for dob
      classId,
      email,
      address,
      phone,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    };

    logger.log("Writing to Firestore...");
    const batch = db.batch();
    //batch.set(db.collection("students").doc(uid), studentData);
    batch.set(db.collection("schools").doc(schoolId).collection("students").doc(uid), studentData);
    batch.set(
      db.collection("schools").doc(schoolId).collection("classes").doc(classId).collection("students").doc(uid),
      studentData
    );

    try {
      await batch.commit();
      logger.log(`Created student ${uid} in school ${schoolId}`);
      logger.log("Batch committed successfully for student:", uid);
    } catch (err) {
      logger.error("Firestore student writes failed", err);
      // cleanup auth user if writes fail
      try { await getAuth().deleteUser(uid); } catch {}
      throw new HttpsError("internal", "Failed to save student data.");
    }
    
    logger.log("Returning credentials", { uid, tempPassword });
    // 6) Return credentials for the admin to share
    return { uid, tempPassword };
  }
);