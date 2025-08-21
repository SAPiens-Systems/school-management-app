import * as logger from "firebase-functions/logger";
import {onDocumentWritten} from "firebase-functions/v2/firestore";
import {initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {getFirestore, FieldValue} from "firebase-admin/firestore";

// Type definitions
interface UserDocument {
  role: 'admin' | 'teacher';
  schoolId: string;
  status?: 'pending' | 'approved' | 'rejected';
  [key: string]: any; // For other potential fields
}

// Initialize Firebase Admin
initializeApp();

export const manageUserPrivileges = onDocumentWritten(
  "school_admins/{schoolDoc}/users/{userId}",
  async (event) => {
    // Safe data access with type checking
    if (!event.data || !event.data.after.exists) {
      logger.log("Document deleted or no data");
      await getAuth().setCustomUserClaims(event.params.userId, null);
      return;
    }

    // Type-safe data extraction
    const userData = event.data.after.data() as UserDocument | undefined;
    const { userId } = event.params;
    const schoolDoc = event.params.schoolDoc; // Now properly typed from path params

    if (!userData) {
      logger.error("User data is undefined");
      return;
    }

    // Validate required fields
    if (typeof userData.role !== 'string' || typeof userData.schoolId !== 'string') {
      logger.error("Invalid user document structure");
      return;
    }

    try {
      const cleanSchoolId = schoolDoc.replace('_admins', '');

      // Set custom claims with all required fields
      await getAuth().setCustomUserClaims(userId, {
        admin: userData.role === 'admin',
        schoolId: cleanSchoolId,
        status: userData.status || 'pending',
        role: userData.role
      });

      // Update verification timestamp
      await getFirestore()
        .doc(event.data.after.ref.path)
        .update({
          lastVerified: FieldValue.serverTimestamp()
        });

      logger.log(`Updated privileges for ${userId}`, {
        schoolId: cleanSchoolId,
        role: userData.role
      });

    } catch (error) {
      logger.error("Error updating user claims:", error);
      throw new Error(`Failed to update claims for ${userId}`);
    }
  }
);