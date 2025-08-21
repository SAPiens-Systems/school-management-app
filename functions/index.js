const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.setAdminClaims = functions.firestore
  .document('school_admins/{schoolDoc}/users/{userId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();
    
    // Only process when status changes to approved
    if (newData.status === 'approved' && oldData.status !== 'approved') {
      const userId = context.params.userId;
      
      // Set custom claims
      await admin.auth().setCustomUserClaims(userId, {
        admin: true,
        schoolId: newData.schoolId
      });
      
      // Update user display name
      await admin.auth().updateUser(userId, {
        displayName: newData.name
      });
      
      console.log(`Set admin claims for ${userId}`);
    }
  });

exports.handleUserApproval = functions.firestore
  .document('school_admins/{schoolId}_admins/users/{userId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();
    const { userId, schoolId } = context.params;

    // Check if status changed to approved
    if (newData.status === 'approved' && oldData.status !== 'approved') {
      try {
        // Enable user in Auth
        await admin.auth().updateUser(userId, {
          disabled: false
        });

        // Set admin claims if user is admin
        if (newData.role === 'admin') {
          await admin.auth().setCustomUserClaims(userId, {
            admin: true,
            schoolId: schoolId.replace('_admins', '')
          });
        }

        console.log(`User ${userId} approved and enabled`);
      } catch (error) {
        console.error('Error enabling user:', error);
      }
    }
  });