import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:invist_bh/models/user_model.dart';
import 'package:invist_bh/utils/validators.dart';
import 'package:uuid/uuid.dart';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _usersCollection = 'users';
  final String _otpCollection = 'otps';
  final _uuid = const Uuid();

  Future<UserModel?> getUserByPhone(String phoneNumber) async {
    final formattedNumber = Validators.formatBahrainPhoneNumber(phoneNumber);
    final snapshot = await _firestore
        .collection(_usersCollection)
        .where('phoneNumber', isEqualTo: formattedNumber)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final userData = snapshot.docs.first.data();
    userData['id'] = snapshot.docs.first.id;
    return UserModel.fromJson(userData);
  }

  Future<String> generateAndSaveOTP(String phoneNumber) async {
    final formattedNumber = Validators.formatBahrainPhoneNumber(phoneNumber);
    // Generate a 6-digit OTP
    final otp = (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();
    
    await _firestore.collection(_otpCollection).doc(formattedNumber).set({
      'otp': otp,
      'createdAt': FieldValue.serverTimestamp(),
      'attempts': 0,
    });

    return otp;
  }

  Future<bool> verifyOTP(String phoneNumber, String otp) async {
    final formattedNumber = Validators.formatBahrainPhoneNumber(phoneNumber);
    final otpDoc = await _firestore.collection(_otpCollection).doc(formattedNumber).get();

    if (!otpDoc.exists) {
      return false;
    }

    final otpData = otpDoc.data()!;
    final storedOTP = otpData['otp'] as String;
    final createdAt = (otpData['createdAt'] as Timestamp).toDate();
    final attempts = (otpData['attempts'] as int?) ?? 0;

    // Check if OTP is expired (5 minutes)
    if (DateTime.now().difference(createdAt).inMinutes > 5) {
      await otpDoc.reference.delete();
      return false;
    }

    // Check if too many attempts (max 3)
    if (attempts >= 3) {
      await otpDoc.reference.delete();
      return false;
    }

    // Increment attempts
    await otpDoc.reference.update({'attempts': FieldValue.increment(1)});

    // Verify OTP
    if (storedOTP == otp) {
      await otpDoc.reference.delete();
      return true;
    }

    return false;
  }

  Future<UserModel> createUser({
    required String phoneNumber,
    required String name,
    required UserRole role,
  }) async {
    final formattedNumber = Validators.formatBahrainPhoneNumber(phoneNumber);
    
    // Check if user already exists
    final existingUser = await getUserByPhone(formattedNumber);
    if (existingUser != null) {
      throw Exception('User with this phone number already exists');
    }

    final user = UserModel(
      id: _uuid.v4(),
      name: name,
      phoneNumber: formattedNumber,
      role: role,
    );

    await _firestore
        .collection(_usersCollection)
        .doc(user.id)
        .set(user.toJson());

    return user;
  }
}
