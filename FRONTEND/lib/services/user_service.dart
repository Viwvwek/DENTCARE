import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─── App Roles ────────────────────────────────────────────────────────────────
enum AppRole { admin, doctor, staff, patient, unknown }

extension AppRoleExt on AppRole {
  String get label {
    switch (this) {
      case AppRole.admin:   return 'Admin';
      case AppRole.doctor:  return 'Doctor';
      case AppRole.staff:   return 'Staff';
      case AppRole.patient: return 'Patient';
      default:              return 'Unknown';
    }
  }

  bool get canAccessAdmin    => this == AppRole.admin;
  bool get canManagePatients => this == AppRole.admin || this == AppRole.doctor;
  bool get canScan           => this == AppRole.admin || this == AppRole.doctor || this == AppRole.staff;
}

AppRole roleFromString(String? role) {
  switch (role?.toLowerCase()) {
    case 'admin':   return AppRole.admin;
    case 'doctor':  return AppRole.doctor;
    case 'staff':   return AppRole.staff;
    case 'patient': return AppRole.patient;
    default:        return AppRole.unknown;
  }
}

// ─── User Profile Model ────────────────────────────────────────────────────────
class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final AppRole role;
  final String? clinicId;
  final String? avatarUrl;
  final DateTime createdAt;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.clinicId,
    this.avatarUrl,
    required this.createdAt,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      role: roleFromString(data['role'] as String?),
      clinicId: data['clinicId'] as String?,
      avatarUrl: data['avatarUrl'] as String?,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'role': role.name,
    'clinicId': clinicId,
    'avatarUrl': avatarUrl,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  bool get isAdmin   => role == AppRole.admin;
  bool get isDoctor  => role == AppRole.doctor;
}

// ─── User Service ─────────────────────────────────────────────────────────────
class UserService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static CollectionReference get _users => _firestore.collection('users');

  // Create or update user doc on login/signup
  static Future<void> ensureUserDocument(User firebaseUser, {String? displayName}) async {
    final docRef = _users.doc(firebaseUser.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      // New user — default role is 'doctor'
      await docRef.set({
        'uid': firebaseUser.uid,
        'email': firebaseUser.email ?? '',
        'displayName': displayName ?? firebaseUser.email?.split('@').first ?? 'User',
        'role': 'doctor', // Default: doctor. Admin must be set manually.
        'clinicId': firebaseUser.uid, // Own clinic by default
        'avatarUrl': firebaseUser.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });
    } else {
      // Update last seen
      await docRef.update({'updatedAt': FieldValue.serverTimestamp()});
    }
  }

  // Fetch current user profile (one-time)
  static Future<UserProfile?> getCurrentProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _users.doc(user.uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromFirestore(doc);
  }

  // Stream the current user's profile (real-time)
  static Stream<UserProfile?> watchCurrentProfile() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);
    return _users.doc(user.uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(doc);
    });
  }

  // ── Admin Role Management ─────────────────────────────────────────────────

  /// Promote a user to admin (only callable by existing admin in real app)
  static Future<void> setRole(String uid, AppRole role) async {
    await _users.doc(uid).update({
      'role': role.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Make the CURRENT logged-in user an admin (for development/setup)
  static Future<void> makeCurrentUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in');
    await _users.doc(user.uid).set({
      'uid': user.uid,
      'email': user.email ?? '',
      'displayName': user.email?.split('@').first ?? 'Admin',
      'role': 'admin',
      'clinicId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isActive': true,
    }, SetOptions(merge: true));
  }

  // Fetch all staff for a clinic
  static Stream<QuerySnapshot> watchClinicStaff(String clinicId) {
    return _users
        .where('clinicId', isEqualTo: clinicId)
        .where('isActive', isEqualTo: true)
        .snapshots();
  }
}
