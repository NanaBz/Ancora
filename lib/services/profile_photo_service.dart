import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Uploads a profile image to Storage, updates [users/{uid}.photoURL], optional Auth profile,
/// and denormalised [users/{caregiverUid}/patients/{uid}.photoURL] for linked caregivers.
class ProfilePhotoService {
  static const int _maxBytes = 2 * 1024 * 1024;

  static String _contentTypeForFile(String name) {
    final ext = name.split('.').last.toLowerCase();
    if (ext == 'png') return 'image/png';
    if (ext == 'webp') return 'image/webp';
    return 'image/jpeg';
  }

  static Future<String> uploadAndSyncProfileImage({
    required String uid,
    required XFile file,
  }) async {
    final bytes = await file.readAsBytes();
    if (bytes.length > _maxBytes) {
      throw Exception('Image must be under 2 MB.');
    }
    final ref = FirebaseStorage.instance.ref('profileImages/$uid/profile');
    final contentType = _contentTypeForFile(file.name);
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    final url = await ref.getDownloadURL();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.uid == uid) {
      try {
        await user.updatePhotoURL(url);
      } on FirebaseAuthException {
        // Some providers may reject; Firestore is still the source of truth in Ancora.
      }
    }

    final db = FirebaseFirestore.instance;
    await db.collection('users').doc(uid).update({'photoURL': url});

    final cgSnap = await db.collection('users').doc(uid).collection('caregivers').get();
    if (cgSnap.docs.isNotEmpty) {
      final batch = db.batch();
      for (final d in cgSnap.docs) {
        final pRef = db.collection('users').doc(d.id).collection('patients').doc(uid);
        batch.set(pRef, {'photoURL': url}, SetOptions(merge: true));
      }
      await batch.commit();
    }

    return url;
  }
}
