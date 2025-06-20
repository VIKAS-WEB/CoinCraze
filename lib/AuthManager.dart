import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthManager {
  static final AuthManager _instance = AuthManager._internal();
  factory AuthManager() => _instance;
  AuthManager._internal();

  final _storage = const FlutterSecureStorage();
  late Box _hiveBox; // Hive box for non-sensitive data

  // Personal Info
  String? _FirstName;
  String? _LastName;
  String? _dob;
  String? _phone;

  // ID Proof
  String? _country;
  String? _documentType;
  String? _frontImagePath;
  String? _backImagePath;

  // Bank Details
  String? _bankName;
  String? _accountNumber;
  String? _ifsc;

  // General User Info
  String? _userId;
  String? _email;
  String? _phoneNumber;
  bool? _kycCompleted;
  bool _isLoggedIn = false;

  // Profile Picture
  String? _profilePicture; // Added for profile picture path

  // Non-sensitive extra data (e.g., cached settings)
  String? _lastLoginTime;
  int? _loginCount;

  // Getters
  String? get FirstName => _FirstName;
  String? get LastName => _LastName;
  String? get dob => _dob;
  String? get phone => _phone;
  String? get country => _country;
  String? get documentType => _documentType;
  String? get frontImagePath => _frontImagePath;
  String? get backImagePath => _backImagePath;
  String? get bankName => _bankName;
  String? get accountNumber => _accountNumber;
  String? get ifsc => _ifsc;
  String? get userId => _userId;
  String? get email => _email;
  String? get phoneNumber => _phoneNumber;
  bool? get kycCompleted => _kycCompleted;
  bool get isLoggedIn => _isLoggedIn;
  String? get lastLoginTime => _lastLoginTime;
  int? get loginCount => _loginCount;
  String? get profilePicture => _profilePicture;

  // Initialize Hive
  Future<void> init() async {
    await Hive.initFlutter();
    _hiveBox = await Hive.openBox('authBox');
    await loadSavedDetails();
  }

  Future<void> saveLoginDetails(Map<String, dynamic> loginResponse) async {
    final user = loginResponse['user'];
    final kyc = user?['kyc'];
    final personalInfo = kyc?['personalInfo'];
    final idProof = kyc?['idProof'];
    final bankDetails = kyc?['bankDetails'];

    // Assign values with null checks
    _FirstName = personalInfo?['FirstName']?.toString();
    _LastName = personalInfo?['LastName']?.toString();
    _dob = personalInfo?['dob']?.toString();
    _phone = personalInfo?['phone']?.toString();
    _country = idProof?['country']?.toString();
    _documentType = idProof?['documentType']?.toString();
    _frontImagePath = idProof?['frontImagePath']?.toString();
    _backImagePath = idProof?['backImagePath']?.toString();
    _bankName = bankDetails?['bankName']?.toString();
    _accountNumber = bankDetails?['accountNumber']?.toString();
    _ifsc = bankDetails?['ifsc']?.toString();
    _userId = user?['_id']?.toString();
    _email = user?['email']?.toString();
    _phoneNumber = user?['phoneNumber']?.toString();
    _kycCompleted = kyc?['kycCompleted'] as bool? ?? false;
    _profilePicture = user?['profilePicture']?.toString();
    _isLoggedIn = true;

    // Save sensitive data to Secure Storage
    await _storage.write(key: 'FirstName', value: _FirstName);
    await _storage.write(key: 'LastName', value: _LastName);
    await _storage.write(key: 'dob', value: _dob);
    await _storage.write(key: 'phone', value: _phone);
    await _storage.write(key: 'country', value: _country);
    await _storage.write(key: 'documentType', value: _documentType);
    await _storage.write(key: 'frontImagePath', value: _frontImagePath);
    await _storage.write(key: 'backImagePath', value: _backImagePath);
    await _storage.write(key: 'bankName', value: _bankName);
    await _storage.write(key: 'accountNumber', value: _accountNumber);
    await _storage.write(key: 'ifsc', value: _ifsc);
    await _storage.write(key: 'userId', value: _userId);
    await _storage.write(key: 'email', value: _email);
    await _storage.write(key: 'phoneNumber', value: _phoneNumber);
    await _storage.write(key: 'kycCompleted', value: _kycCompleted.toString());
    await _storage.write(key: 'profilePicture', value: _profilePicture);
    await _storage.write(key: 'isLoggedIn', value: _isLoggedIn.toString());

    // Save non-sensitive data to Hive
    _lastLoginTime = DateTime.now().toIso8601String();
    _loginCount = (_hiveBox.get('loginCount') as int? ?? 0) + 1;
    await _hiveBox.put('lastLoginTime', _lastLoginTime);
    await _hiveBox.put('loginCount', _loginCount);
  }

  Future<void> loadSavedDetails() async {
    // Load sensitive data from Secure Storage
    _FirstName = await _storage.read(key: 'FirstName');
    _LastName = await _storage.read(key: 'LastName');
    _dob = await _storage.read(key: 'dob');
    _phone = await _storage.read(key: 'phone');
    _country = await _storage.read(key: 'country');
    _documentType = await _storage.read(key: 'documentType');
    _frontImagePath = await _storage.read(key: 'frontImagePath');
    _backImagePath = await _storage.read(key: 'backImagePath');
    _bankName = await _storage.read(key: 'bankName');
    _accountNumber = await _storage.read(key: 'accountNumber');
    _ifsc = await _storage.read(key: 'ifsc');
    _userId = await _storage.read(key: 'userId');
    _email = await _storage.read(key: 'email');
    _phoneNumber = await _storage.read(key: 'phoneNumber');
    _kycCompleted = await _storage.read(key: 'kycCompleted') == 'true';
    _profilePicture = await _storage.read(key: 'profilePicture');
    _isLoggedIn = await _storage.read(key: 'isLoggedIn') == 'true';

    // Load non-sensitive data from Hive
    _lastLoginTime = _hiveBox.get('lastLoginTime') as String?;
    _loginCount = _hiveBox.get('loginCount') as int?;
  }

  Future<void> clearUserData() async {
    await _storage.deleteAll();
    await _hiveBox.clear();
    _FirstName = null;
    _LastName = null;
    _dob = null;
    _phone = null;
    _country = null;
    _documentType = null;
    _frontImagePath = null;
    _backImagePath = null;
    _bankName = null;
    _accountNumber = null;
    _ifsc = null;
    _userId = null;
    _email = null;
    _phoneNumber = null;
    _kycCompleted = null;
    _profilePicture = null;
    _isLoggedIn = false;
    _lastLoginTime = null;
    _loginCount = null;
  }

  Future<String?> uploadProfilePicture(String userId, String filePath) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://10.0.2.2:3000/upload-profile-picture'),
    );
    request.fields['userId'] = userId;
    request.files.add(
      await http.MultipartFile.fromPath('profilePicture', filePath),
    );
    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await http.Response.fromStream(response);
        final jsonData = jsonDecode(responseData.body);
        final profilePicturePath = jsonData['profilePicturePath'];
        _profilePicture = profilePicturePath;
        await _storage.write(key: 'profilePicture', value: profilePicturePath);
        return profilePicturePath;
      } else {
        print('Upload failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error uploading profile picture: $e');
      return null;
    }
  }
}