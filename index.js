const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const firestore = admin.firestore();

// Cloud Function triggered when a new RFID tap event is written to Realtime Database
exports.processRFIDTap = functions.database.ref('/rfid_events/{eventId}')
    .onCreate(async (snapshot, context) => {
      // Extract event data from the Realtime Database
      const eventData = snapshot.val();
      const rfidUid = eventData.uid;  // e.g., "123456"
      const fareAmount = eventData.fareAmount || 20; // default fare amount if not provided

      // References to the corresponding documents in Firestore
      const userRef = firestore.collection('users').doc(rfidUid);
      const busOperatorRef = firestore.collection('bus_operators').doc('operator'); // using a fixed ID for operator

      try {
        // Run a Firestore transaction to ensure atomicity
        await firestore.runTransaction(async (transaction) => {
          // Retrieve the user document
          const userDoc = await transaction.get(userRef);
          if (!userDoc.exists) {
            throw new Error(`User not found for RFID UID: ${rfidUid}`);
          }
          const userBalance = userDoc.data().balance;
          if (userBalance < fareAmount) {
            throw new Error(`Insufficient balance for user with RFID UID: ${rfidUid}`);
          }

          // Deduct fare from the user's balance
          transaction.update(userRef, {
            balance: admin.firestore.FieldValue.increment(-fareAmount)
          });

          // Credit fare to the bus operator's balance
          transaction.update(busOperatorRef, {
            balance: admin.firestore.FieldValue.increment(fareAmount)
          });

          // Optionally, log the transaction in a subcollection under the user document
          const userTransactionRef = userRef.collection('transactions').doc();
          transaction.set(userTransactionRef, {
            type: 'fare_payment',
            amount: fareAmount,
            operator: 'Dummy Bus Operator',
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
          });

          // Optionally, log the transaction under the bus operator's document as well
          const operatorTransactionRef = busOperatorRef.collection('transactions').doc();
          transaction.set(operatorTransactionRef, {
            type: 'fare_credit',
            amount: fareAmount,
            userUid: rfidUid,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
          });
        });
        console.log(`Processed fare for RFID UID: ${rfidUid}`);
      } catch (error) {
        console.error(`Transaction failure for RFID UID: ${rfidUid}:`, error);
      }
    });
