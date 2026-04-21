import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Future<void> signUpPatient({
    required String fullName,
    required String email,
    required String password,
    required String phone,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    final displayId = await _claimDisplayId(uid);
    await _db.collection('users').doc(uid).set({
      'role': 'patient',
      'displayId': displayId,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'photoURL': null,
      'age': null,
      'tzIana': 'Africa/Accra',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> signUpCaregiver({
    required String fullName,
    required String email,
    required String password,
    required String phone,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    final displayId = await _claimDisplayId(uid);
    await _db.collection('users').doc(uid).set({
      'role': 'caregiver',
      'displayId': displayId,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'photoURL': null,
      'age': null,
      'tzIana': 'Africa/Accra',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
    required String expectedRole,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final doc = await _db.collection('users').doc(cred.user!.uid).get();
    if (!doc.exists) throw Exception('User profile not found.');
    final data = doc.data()!;
    if (data['role'] != expectedRole) {
      await _auth.signOut();
      throw Exception(
        expectedRole == 'patient'
            ? 'This account belongs to a caregiver. Use the caregiver login.'
            : 'This account belongs to a patient. Use the patient login.',
      );
    }
    return data;
  }

  Future<void> signOut() async {
    await NotificationService.deleteCurrentToken();
    await _auth.signOut();
  }

  Future<String> _claimDisplayId(String uid) async {
    final rng = Random.secure();
    for (var i = 0; i < 5; i++) {
      final id = (1000 + rng.nextInt(9000)).toString();
      final idxRef = _db.collection('displayIdIndex').doc(id);
      try {
        await _db.runTransaction((tx) async {
          final snap = await tx.get(idxRef);
          if (snap.exists) throw _Collision();
          tx.set(idxRef, {'uid': uid});
        });
        return id;
      } on _Collision {
        continue;
      }
    }
    throw Exception('Could not allocate a unique display ID. Please try again.');
  }
}

class _Collision implements Exception {}
