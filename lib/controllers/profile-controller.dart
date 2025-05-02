import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        return null;
      }

      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      } else {
        return {
          'displayName': user.displayName ?? '',
          'email': user.email ?? '',
          'phoneNumber': user.phoneNumber ?? '',
          'uid': user.uid,
        };
      }
    } catch (e) {
      print('Error mendapatkan data pengguna: $e');
      return null;
    }
  }

  Future<bool> updateProfile({
    required String displayName,
    required String email,
    required String phoneNumber,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        return false;
      }

      if (user.displayName != displayName) {
        await user.updateDisplayName(displayName);
      }
      if (user.email != email) {
        await user.verifyBeforeUpdateEmail(email);
      }

      await _firestore.collection('users').doc(user.uid).set({
        'displayName': displayName,
        'email': email,
        'phoneNumber': phoneNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }
}