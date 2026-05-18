import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  TokenStorage(this._prefs);

  final SharedPreferences _prefs;

  static const String _accessTokenKey = 'wask_access_token';
  static const String _refreshTokenKey = 'wask_refresh_token';

  Future<String?> getAccessToken() async {
    return _prefs.getString(_accessTokenKey);
  }

  Future<void> saveAccessToken(String token) async {
    await _prefs.setString(_accessTokenKey, token);
  }

  Future<String?> getRefreshToken() async {
    return _prefs.getString(_refreshTokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    await _prefs.setString(_refreshTokenKey, token);
  }

  Future<void> clearTokens() async {
    await _prefs.remove(_accessTokenKey);
    await _prefs.remove(_refreshTokenKey);
  }
}
