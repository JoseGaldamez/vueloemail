import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../services/mail_service.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final MailService _mailService = MailService();
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  User? _currentUser;
  User? get currentUser => _currentUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _currentUser != null;

  Future<void> init() async {
    final email = await _secureStorage.read(key: 'user_email');
    final password = await _secureStorage.read(key: 'user_password');

    if (email != null && password != null) {
      _currentUser = User(id: 'local_id', email: email, passwordHash: password);
      notifyListeners();
    }
  }

  Future<bool> register(String username, String password) async {
    _setLoading(true);
    _clearError();

    try {
      // Call real API endpoint POST /api/users
      await _apiService.registerUser(username, password);

      // Registration succeeded — now log in with the same credentials
      final email = '$username@vuelo.email';
      final loginSuccess = await _mailService.login(email, password);

      if (loginSuccess) {
        _currentUser = User(
          id: 'logged_in_id',
          email: email,
          passwordHash: password,
        );
        await _saveSessionSecurely(email, password);
        _setLoading(false);
        return true;
      } else {
        // Account created but login failed — inform user to log in manually
        _setError('Cuenta creada. Por favor inicia sesión.');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    if (email.isEmpty || password.isEmpty) {
      _setError('El correo y la contraseña no pueden estar vacíos.');
      _setLoading(false);
      return false;
    }

    try {
      final success = await _mailService.login(email, password);
      if (success) {
        _currentUser = User(
          id: 'logged_in_id',
          email: email,
          passwordHash: password,
        );
        await _saveSessionSecurely(email, password);
        _setLoading(false);
        return true;
      } else {
        _setError('Credenciales incorrectas');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: 'user_email');
    await _secureStorage.delete(key: 'user_password');
    _currentUser = null;
    notifyListeners();
  }

  Future<void> _saveSessionSecurely(String email, String password) async {
    await _secureStorage.write(key: 'user_email', value: email);
    await _secureStorage.write(key: 'user_password', value: password);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
