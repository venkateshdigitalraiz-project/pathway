import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/domain/entities/user_profile.dart';

/// Service for persisting authentication session data, tokens, and user details
/// using SharedPreferences.
class AuthLocalStorage {
  static final AuthLocalStorage _instance = AuthLocalStorage._internal();
  factory AuthLocalStorage() => _instance;
  AuthLocalStorage._internal();

  static const String keyToken = 'auth_token';
  static const String keyAccessToken = 'auth_access_token';
  static const String keyRefreshToken = 'auth_refresh_token';
  static const String keyExpiresIn = 'auth_expires_in';
  static const String keyRefreshExpiresAt = 'auth_refresh_expires_at';
  static const String keyUserJson = 'auth_user_json';
  static const String keyWholeAuthData = 'auth_whole_data';
  static const String keyIsProfileCompleted = 'auth_profile_completed';
  static const String keyFullName = 'user_full_name';
  static const String keyEmail = 'user_email';
  static const String keyReference = 'user_reference';
  static const String keyGender = 'user_gender';
  static const String keyDriverOnline = 'carpool_driver_online';

  SharedPreferences? _prefs;

  /// Initialize SharedPreferences instance
  Future<SharedPreferences> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    try {
      await _prefs?.reload();
    } catch (_) {}
    return _prefs!;
  }

  SharedPreferences? get preferences => _prefs;

  /// Store the whole data payload from the login response
  Future<void> saveAuthData(Map<String, dynamic> data) async {
    final sp = _prefs ?? await init();

    // 1. Store whole response data as JSON
    await sp.setString(keyWholeAuthData, jsonEncode(data));

    // Handle nested payload if data is wrapped in {"data": { ... }}
    Map<String, dynamic> payload = data;
    if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
      payload = data['data'] as Map<String, dynamic>;
    }

    // 2. Store tokens and expiration fields
    final rawToken = payload['token'] ?? data['token'];
    final rawAccessToken = payload['accessToken'] ?? data['accessToken'] ?? rawToken;
    final rawRefreshToken = payload['refreshToken'] ?? data['refreshToken'];
    final rawExpiresIn = payload['expiresIn'] ?? data['expiresIn'];
    final rawRefreshExpiresAt = payload['refreshExpiresAt'] ?? data['refreshExpiresAt'];

    if (rawToken != null) {
      final t = _cleanBearer(rawToken.toString());
      await sp.setString(keyToken, t);
      await sp.setString('token', t);
    }
    if (rawAccessToken != null) {
      final at = _cleanBearer(rawAccessToken.toString());
      await sp.setString(keyAccessToken, at);
      await sp.setString('accessToken', at);
      await sp.setString('access_token', at);
    }
    if (rawRefreshToken != null) {
      final rt = _cleanBearer(rawRefreshToken.toString());
      await sp.setString(keyRefreshToken, rt);
      await sp.setString('refreshToken', rt);
      await sp.setString('refresh_token', rt);
    }
    if (rawExpiresIn != null) {
      await sp.setString(keyExpiresIn, rawExpiresIn.toString());
    }
    if (rawRefreshExpiresAt != null) {
      await sp.setString(keyRefreshExpiresAt, rawRefreshExpiresAt.toString());
    }

    // 3. Store user details
    final userMap = payload['user'] ?? data['user'];
    if (userMap is Map<String, dynamic>) {
      await sp.setString(keyUserJson, jsonEncode(userMap));
    }

    debugPrint('\n==================== [LOCAL STORAGE: AUTH DATA STORED] ====================');
    debugPrint('USER_ID: ${userMap?['id'] ?? userMap?['_id']}');
    debugPrint('USER_NAME: ${userMap?['name']}');
    debugPrint('USER_PHONE: ${userMap?['phone']}');
    debugPrint('TOKEN: $rawToken');
    debugPrint('ACCESS_TOKEN: $rawAccessToken');
    debugPrint('SHARED_PREFERENCES: Whole response map saved to key "$keyWholeAuthData"');
    debugPrint('============================================================================\n');
  }

  /// Store or update UserProfile and individual profile keys in SharedPreferences
  Future<void> saveUserProfile(UserProfile user, {String? phone}) async {
    final sp = _prefs ?? await init();
    await sp.setString(keyUserJson, jsonEncode(user.toJson()));

    final trimmedName = user.fullName.trim();
    final bool hasValidName = trimmedName.isNotEmpty &&
        trimmedName.toLowerCase() != 'user' &&
        !trimmedName.toLowerCase().startsWith('user ') &&
        !RegExp(r'^user[\s_-]*\d*$', caseSensitive: false)
            .hasMatch(trimmedName);

    if (hasValidName) {
      await sp.setString(keyFullName, trimmedName);
      await sp.setBool(keyIsProfileCompleted, true);
    }
    if (user.email.isNotEmpty && !user.email.contains('@pathway.com')) {
      await sp.setString(keyEmail, user.email);
    }
    if (user.gender != null && user.gender!.isNotEmpty) {
      await sp.setString(keyGender, user.gender!);
    }
    if (user.reference != null && user.reference!.isNotEmpty) {
      await sp.setString(keyReference, user.reference!);
    }

    // Also persist per-phone if available so any phone login remembers its details
    final p = phone ?? user.phoneNumber;
    final cleanPhone = p.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.isNotEmpty) {
      if (hasValidName) {
        await sp.setString('phone_${cleanPhone}_fullName', trimmedName);
        await sp.setBool('phone_${cleanPhone}_completed', true);
      }
      if (user.email.isNotEmpty && !user.email.contains('@pathway.com')) {
        await sp.setString('phone_${cleanPhone}_email', user.email);
      }
      if (user.gender != null && user.gender!.isNotEmpty) {
        await sp.setString('phone_${cleanPhone}_gender', user.gender!);
      }
      if (user.reference != null && user.reference!.isNotEmpty) {
        await sp.setString('phone_${cleanPhone}_reference', user.reference!);
      }
    }

    debugPrint('[LOCAL STORAGE: USER PROFILE PERSISTED] ${user.id} - ${user.fullName} (hasValidName: $hasValidName)');
  }

  /// Explicitly save custom user details entered in UserDetailsPage
  Future<void> saveCustomUserDetails({
    required String fullName,
    required String email,
    String? reference,
    required String gender,
    String? phone,
  }) async {
    final sp = _prefs ?? await init();
    final trimmedName = fullName.trim();
    final trimmedEmail = email.trim();
    final trimmedGender = gender.trim();
    final trimmedRef = reference?.trim();

    await sp.setString(keyFullName, trimmedName);
    await sp.setString(keyEmail, trimmedEmail);
    await sp.setString(keyGender, trimmedGender);
    if (trimmedRef != null && trimmedRef.isNotEmpty) {
      await sp.setString(keyReference, trimmedRef);
    } else {
      await sp.remove(keyReference);
    }
    await sp.setBool(keyIsProfileCompleted, true);

    // Save under phone key as well
    if (phone != null) {
      final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanPhone.isNotEmpty) {
        await sp.setString('phone_${cleanPhone}_fullName', trimmedName);
        await sp.setString('phone_${cleanPhone}_email', trimmedEmail);
        await sp.setString('phone_${cleanPhone}_gender', trimmedGender);
        if (trimmedRef != null && trimmedRef.isNotEmpty) {
          await sp.setString('phone_${cleanPhone}_reference', trimmedRef);
        }
        await sp.setBool('phone_${cleanPhone}_completed', true);
      }
    }

    debugPrint('[LOCAL STORAGE: CUSTOM DETAILS STORED] Name: $trimmedName | Email: $trimmedEmail | Gender: $trimmedGender | Ref: $trimmedRef');
  }

  /// Retrieve the stored full name
  String? getFullName([String? phone]) {
    if (phone != null) {
      final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
      final pName = _prefs?.getString('phone_${clean}_fullName');
      if (pName != null &&
          pName.trim().isNotEmpty &&
          !pName.toLowerCase().startsWith('user')) {
        return pName.trim();
      }
    }
    final name = _prefs?.getString(keyFullName);
    if (name != null &&
        name.trim().isNotEmpty &&
        !name.toLowerCase().startsWith('user')) {
      return name.trim();
    }
    return null;
  }

  /// Retrieve the stored email
  String? getEmail([String? phone]) {
    if (phone != null) {
      final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
      final pEmail = _prefs?.getString('phone_${clean}_email');
      if (pEmail != null && pEmail.trim().isNotEmpty) return pEmail.trim();
    }
    return _prefs?.getString(keyEmail);
  }

  /// Retrieve the stored reference code
  String? getReference([String? phone]) {
    if (phone != null) {
      final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
      final pRef = _prefs?.getString('phone_${clean}_reference');
      if (pRef != null && pRef.trim().isNotEmpty) return pRef.trim();
    }
    return _prefs?.getString(keyReference);
  }

  /// Retrieve the stored gender
  String? getGender([String? phone]) {
    if (phone != null) {
      final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
      final pGender = _prefs?.getString('phone_${clean}_gender');
      if (pGender != null && pGender.trim().isNotEmpty) return pGender.trim();
    }
    return _prefs?.getString(keyGender);
  }

  /// Retrieve the token
  String? getToken() {
    return _extractToken(_prefs);
  }

  /// Retrieve the accessToken synchronously
  String? getAccessToken() {
    return _extractToken(_prefs);
  }

  /// Retrieve the accessToken asynchronously ensuring prefs are initialized and reloaded
  Future<String?> getAccessTokenAsync() async {
    final sp = await init();
    return _extractToken(sp);
  }

  String? _extractToken(SharedPreferences? sp) {
    if (sp == null) return null;

    // 1. Direct candidate keys
    const candidateKeys = [
      keyAccessToken, // 'auth_access_token'
      keyToken,       // 'auth_token'
      'accessToken',
      'token',
      'access_token',
      'authToken',
      'jwt',
      'jwt_token',
      'bearer_token',
    ];

    for (final key in candidateKeys) {
      final val = sp.getString(key);
      if (val != null && val.trim().isNotEmpty && val != 'null') {
        return _cleanBearer(val);
      }
    }

    // 2. Check in whole auth data JSON ('auth_whole_data')
    final rawWhole = sp.getString(keyWholeAuthData);
    if (rawWhole != null && rawWhole.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawWhole);
        if (decoded is Map<String, dynamic>) {
          final t = decoded['accessToken'] ??
              decoded['token'] ??
              decoded['data']?['accessToken'] ??
              decoded['data']?['token'];
          if (t != null && t.toString().trim().isNotEmpty && t.toString() != 'null') {
            return _cleanBearer(t.toString());
          }
        }
      } catch (_) {}
    }

    // 3. Check in user JSON ('auth_user_json')
    final rawUser = sp.getString(keyUserJson);
    if (rawUser != null && rawUser.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawUser);
        if (decoded is Map<String, dynamic>) {
          final t = decoded['token'] ?? decoded['accessToken'];
          if (t != null && t.toString().trim().isNotEmpty && t.toString() != 'null') {
            return _cleanBearer(t.toString());
          }
        }
      } catch (_) {}
    }

    return null;
  }

  String _cleanBearer(String token) {
    final trimmed = token.trim();
    if (trimmed.toLowerCase().startsWith('bearer ')) {
      return trimmed.substring(7).trim();
    }
    return trimmed;
  }

  /// Retrieve the refreshToken
  String? getRefreshToken() {
    return _prefs?.getString(keyRefreshToken);
  }

  /// Retrieve the expiresIn
  String? getExpiresIn() {
    return _prefs?.getString(keyExpiresIn);
  }

  /// Retrieve the refreshExpiresAt
  String? getRefreshExpiresAt() {
    return _prefs?.getString(keyRefreshExpiresAt);
  }

  /// Retrieve the raw user data map
  Map<String, dynamic>? getUserData() {
    final raw = _prefs?.getString(keyUserJson);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }

  /// Retrieve the UserProfile object
  UserProfile? getUserProfile([String? phone]) {
    final userMap = getUserData();
    final savedFullName = getFullName(phone);
    final savedEmail = getEmail(phone);
    final savedGender = getGender(phone);
    final savedReference = getReference(phone);

    if (userMap == null && savedFullName == null) return null;

    try {
      String firstName = userMap?['firstName'] as String? ?? '';
      String lastName = userMap?['lastName'] as String? ?? '';

      if (savedFullName != null &&
          savedFullName.trim().isNotEmpty &&
          !savedFullName.toLowerCase().startsWith('user')) {
        final parts = savedFullName.trim().split(' ');
        firstName = parts.first;
        lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      } else if (firstName.isEmpty && userMap?['name'] != null) {
        final fullName = (userMap!['name'] as String).trim();
        final parts = fullName.split(' ');
        firstName = parts.isNotEmpty ? parts.first : fullName;
        lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      }

      final effectiveEmail = (savedEmail != null && savedEmail.isNotEmpty)
          ? savedEmail
          : (userMap?['email']?.toString() ?? '');

      final effectiveGender = (savedGender != null && savedGender.isNotEmpty)
          ? savedGender
          : userMap?['gender']?.toString();

      final effectiveReference = (savedReference != null && savedReference.isNotEmpty)
          ? savedReference
          : (userMap?['reference']?.toString() ?? userMap?['referralCode']?.toString());

      return UserProfile(
        id: userMap?['id']?.toString() ??
            userMap?['_id']?.toString() ??
            'usr_${DateTime.now().millisecondsSinceEpoch}',
        firstName: firstName.isNotEmpty ? firstName : 'User',
        lastName: lastName,
        email: effectiveEmail,
        phoneNumber: userMap?['phone']?.toString() ??
            userMap?['phoneNumber']?.toString() ??
            phone ??
            '',
        role: userMap?['role']?.toString() ?? 'user',
        authProvider: userMap?['authProvider']?.toString() ?? 'phone',
        gender: effectiveGender,
        reference: effectiveReference,
      );
    } catch (_) {
      return null;
    }
  }

  /// Check if user has completed profile details
  bool isProfileCompleted([String? phone]) {
    final name = getFullName(phone);
    final bool hasValidName = name != null &&
        name.trim().isNotEmpty &&
        name.trim().toLowerCase() != 'user' &&
        !name.trim().toLowerCase().startsWith('user ') &&
        !RegExp(r'^user[\s_-]*\d*$', caseSensitive: false)
            .hasMatch(name.trim());

    if (!hasValidName) return false;

    if (phone != null) {
      final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
      if (clean.isNotEmpty &&
          _prefs?.getBool('phone_${clean}_completed') == true) {
        return true;
      }
    }
    return _prefs?.getBool(keyIsProfileCompleted) == true;
  }

  /// Mark profile as completed or incomplete
  Future<void> setProfileCompleted(bool completed, {String? phone}) async {
    final sp = _prefs ?? await init();
    await sp.setBool(keyIsProfileCompleted, completed);
    if (phone != null) {
      final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
      if (clean.isNotEmpty) {
        await sp.setBool('phone_${clean}_completed', completed);
      }
    }
  }

  /// Check whether driver is online (defaults to true)
  bool isDriverOnline() {
    return _prefs?.getBool(keyDriverOnline) ?? true;
  }

  /// Persist driver online/offline state
  Future<void> setDriverOnline(bool online) async {
    final sp = _prefs ?? await init();
    await sp.setBool(keyDriverOnline, online);
  }

  /// Retrieve the whole data object stored during login
  Map<String, dynamic>? getWholeAuthData() {
    final raw = _prefs?.getString(keyWholeAuthData);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }

  /// Check whether an authenticated session exists
  bool isLoggedIn() {
    final token = getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear all stored authentication session tokens upon logout.
  /// User profile details (full name, email, gender, reference) and completion flag
  /// are preserved so that subsequent logins do not repeatedly prompt for UserDetailsPage.
  Future<void> clearAuthData() async {
    final sp = _prefs ?? await init();
    await sp.remove(keyToken);
    await sp.remove('token');
    await sp.remove(keyAccessToken);
    await sp.remove('accessToken');
    await sp.remove('access_token');
    await sp.remove(keyRefreshToken);
    await sp.remove('refreshToken');
    await sp.remove('refresh_token');
    await sp.remove(keyExpiresIn);
    await sp.remove(keyRefreshExpiresAt);
    await sp.remove(keyUserJson);
    await sp.remove(keyWholeAuthData);

    // Note: DO NOT delete keyFullName, keyEmail, keyGender, keyReference,
    // keyIsProfileCompleted, or phone-specific profile keys!
    // DO NOT call sp.clear()!
    debugPrint('\n==================== [LOCAL STORAGE: AUTH SESSION CLEARED] ====================');
    debugPrint('Auth tokens removed. User profile details preserved for subsequent logins.');
    debugPrint('================================================================================\n');
  }
}

