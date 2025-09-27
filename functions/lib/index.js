"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.createStudent = exports.manageUserPrivileges = void 0;
const logger = __importStar(require("firebase-functions/logger"));
const firestore_1 = require("firebase-functions/v2/firestore");
const app_1 = require("firebase-admin/app");
const auth_1 = require("firebase-admin/auth");
const firestore_2 = require("firebase-admin/firestore");
const https_1 = require("firebase-functions/v2/https");
// Initialize Firebase Admin
(0, app_1.initializeApp)();
exports.manageUserPrivileges = (0, firestore_1.onDocumentWritten)("schools/{schoolDoc}/users/{userId}", async (event) => {
    // Safe data access with type checking
    if (!event.data || !event.data.after.exists) {
        logger.log("Document deleted or no data");
        // 🔹 Clear claims with {} instead of null
        await (0, auth_1.getAuth)().setCustomUserClaims(event.params.userId, {});
        return;
    }
    const beforeData = event.data.before?.data();
    const afterData = event.data.after.data();
    const { userId } = event.params;
    const schoolDoc = event.params.schoolDoc;
    // 🔹 Prevent infinite loop when only lastVerified changes
    if (beforeData &&
        afterData &&
        JSON.stringify({ ...beforeData, lastVerified: undefined }) ===
            JSON.stringify({ ...afterData, lastVerified: undefined })) {
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
        await (0, auth_1.getAuth)().setCustomUserClaims(userId, {
            admin: afterData.role === 'admin',
            schoolId: cleanSchoolId,
            status: afterData.status || 'pending',
            role: afterData.role
        });
        await (0, firestore_2.getFirestore)()
            .doc(event.data.after.ref.path)
            .update({
            lastVerified: firestore_2.FieldValue.serverTimestamp()
        });
        logger.log(`Updated privileges for ${userId}`, {
            schoolId: cleanSchoolId,
            role: afterData.role
        });
    }
    catch (error) {
        logger.error("Error updating user claims:", error);
        throw new Error(`Failed to update claims for ${userId}`);
    }
});
function randomPassword(len = 12) {
    const chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()";
    let out = "";
    for (let i = 0; i < len; i++) {
        out += chars[Math.floor(Math.random() * chars.length)];
    }
    return out;
}
function calcAge(dob) {
    const now = new Date();
    let age = now.getUTCFullYear() - dob.getUTCFullYear();
    const m = now.getUTCMonth() - dob.getUTCMonth();
    if (m < 0 || (m === 0 && now.getUTCDate() < dob.getUTCDate()))
        age--;
    return age;
}
/**
 * Callable to create a student (admin only).
 * Validates caller is admin of the same school, creates Auth user,
 * sets student custom claims, and writes Firestore docs in one atomic flow.
 */
exports.createStudent = (0, https_1.onCall)({ region: "asia-south1" }, // pick your closest region
async (request) => {
    // 1) Auth check
    const auth = request.auth;
    if (!auth) {
        throw new https_1.HttpsError("unauthenticated", "You must be signed in.");
    }
    const claims = auth.token;
    if (!claims.admin || !claims.schoolId) {
        throw new https_1.HttpsError("permission-denied", "Admin privileges required.");
    }
    // 2) Input
    const data = request.data || {};
    const schoolId = String(data.schoolId || "").trim();
    const name = String(data.name || "").trim();
    const email = String(data.email || "").trim();
    const gender = String(data.gender || "").trim();
    const klass = String(data.classId || "").trim(); // "Class 6A"
    const address = String(data.address || "").trim();
    const phone = String(data.phone || "").trim();
    const dobStr = String(data.dateOfBirth || "").trim(); // "YYYY-MM-DD"
    if (!schoolId || !name || !email || !gender || !klass || !address || !phone || !dobStr) {
        throw new https_1.HttpsError("invalid-argument", "Missing required fields.");
    }
    if (claims.schoolId !== schoolId) {
        throw new https_1.HttpsError("permission-denied", "You can only create students for your own school.");
    }
    const dob = new Date(dobStr);
    if (isNaN(dob.getTime())) {
        throw new https_1.HttpsError("invalid-argument", "Invalid dateOfBirth format.");
    }
    const age = calcAge(dob);
    const classId = klass.replace(/\s+/g, "_").toLowerCase();
    // 3) Create Auth user with temp password
    const tempPassword = randomPassword(12);
    let uid;
    try {
        logger.log("Creating Firebase Auth user...");
        const userRecord = await (0, auth_1.getAuth)().createUser({
            email,
            password: tempPassword,
            displayName: name,
            emailVerified: false,
            disabled: false,
        });
        logger.log("Auth user created:", userRecord.uid);
        uid = userRecord.uid;
    }
    catch (err) {
        logger.error("Auth createUser failed", err);
        // map common codes
        if (err?.code === "auth/email-already-exists") {
            throw new https_1.HttpsError("already-exists", "Email already in use.");
        }
        throw new https_1.HttpsError("internal", "Failed to create Auth user.");
    }
    logger.log("Setting custom claims...");
    // 4) Set student claims
    try {
        await (0, auth_1.getAuth)().setCustomUserClaims(uid, {
            admin: false,
            role: "student",
            schoolId,
            status: "approved",
        });
        logger.log("Custom claims set for:", uid);
    }
    catch (err) {
        logger.error("setCustomUserClaims failed", err);
        // continue but log; we still write Firestore so admin can see the record
    }
    // 5) Firestore writes (service account bypasses rules)
    const db = (0, firestore_2.getFirestore)();
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
        createdAt: firestore_2.FieldValue.serverTimestamp(),
        updatedAt: firestore_2.FieldValue.serverTimestamp(),
    };
    logger.log("Writing to Firestore...");
    const batch = db.batch();
    //batch.set(db.collection("students").doc(uid), studentData);
    batch.set(db.collection("schools").doc(schoolId).collection("students").doc(uid), studentData);
    batch.set(db.collection("schools").doc(schoolId).collection("classes").doc(classId).collection("students").doc(uid), studentData);
    try {
        await batch.commit();
        logger.log(`Created student ${uid} in school ${schoolId}`);
        logger.log("Batch committed successfully for student:", uid);
    }
    catch (err) {
        logger.error("Firestore student writes failed", err);
        // cleanup auth user if writes fail
        try {
            await (0, auth_1.getAuth)().deleteUser(uid);
        }
        catch { }
        throw new https_1.HttpsError("internal", "Failed to save student data.");
    }
    logger.log("Returning credentials", { uid, tempPassword });
    // 6) Return credentials for the admin to share
    return { uid, tempPassword };
});
