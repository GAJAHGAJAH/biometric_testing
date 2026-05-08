// lib/pages/login_page.dart
import 'package:flutter/material.dart';
import '../services/biometric_service.dart';
import '../services/biometric_exception.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

enum _AuthMethod { face, fingerprint, password }

class _LoginPageState extends State<LoginPage> {
  final BiometricService _service = BiometricService();
  _AuthMethod? _activeMethod;
  bool _isLoading = false;
  String? _errorMessage;
  List<_AuthMethod> _availableMethods = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final available = await _service.isBiometricAvailable();
    if (!available) {
      setState(() => _availableMethods = [_AuthMethod.password]);
      return;
    }
    final types = await _service.getAvailableBiometrics();
    final hasFace = types.contains(BiometricType.face) || types.contains(BiometricType.weak);
    final hasFingerprint = types.contains(BiometricType.fingerprint) || types.contains(BiometricType.strong);
    
    setState(() {
      if (hasFace) _availableMethods.add(_AuthMethod.face);
      if (hasFingerprint) _availableMethods.add(_AuthMethod.fingerprint);
      _availableMethods.add(_AuthMethod.password);
    });
  }

  Future<void> _selectMethod(_AuthMethod method) async {
    if (method == _AuthMethod.password) {
      setState(() => _activeMethod = _AuthMethod.password);
      return;
    }
    setState(() {
      _activeMethod = method;
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final reason = method == _AuthMethod.face ? 'Verifikasi dengan Face ID' : 'Verifikasi dengan Sidik Jari';
      await _service.authenticate(reason: reason);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on BiometricException catch (e) {
      _handleError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleError(BiometricException e) {
    setState(() {
      _errorMessage = e.userMessage;
      if (e.requiresFallback) _activeMethod = _AuthMethod.password;
    });
  }

  Future<void> _loginWithPassword() async {
    // TODO: Implement password login logic
    if (mounted) Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Biometric Auth - Dimas Prasetyo')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_activeMethod == _AuthMethod.password) {
      return _buildPasswordForm();
    }
    if (_activeMethod != null) {
      return _buildBiometricScreen();
    }
    return _buildSelectionScreen();
  }

  Widget _buildSelectionScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Pilih Metode Login', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 32),
        if (_availableMethods.contains(_AuthMethod.face))
          _methodCard(Icons.face, 'Face ID', _AuthMethod.face),
        if (_availableMethods.contains(_AuthMethod.fingerprint))
          _methodCard(Icons.fingerprint, 'Sidik Jari', _AuthMethod.fingerprint),
        _methodCard(Icons.password, 'Password', _AuthMethod.password),
      ],
    );
  }

  Widget _methodCard(IconData icon, String label, _AuthMethod method) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _selectMethod(method),
      ),
    );
  }

  Widget _buildBiometricScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            _activeMethod == _AuthMethod.face ? Icons.face : Icons.fingerprint,
            size: 80,
            color: Colors.teal,
          ),
        ),
        const SizedBox(height: 24),
        if (_isLoading)
          const Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Menunggu verifikasi...'),
            ],
          ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(_errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          if (BiometricException(code: BiometricErrorCode.unknown, message: '', userMessage: '').isRetryable)
            ElevatedButton(onPressed: () => _selectMethod(_activeMethod!), child: const Text('Coba Lagi')),
        ],
        const SizedBox(height: 24),
        TextButton(onPressed: () => setState(() => _activeMethod = null), child: const Text('Kembali')),
      ],
    );
  }

  Widget _buildPasswordForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock, size: 64, color: Colors.teal),
        const SizedBox(height: 24),
        const Text('Login dengan Password', style: TextStyle(fontSize: 18)),
        const SizedBox(height: 16),
        TextField(decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: _loginWithPassword, child: const Text('Login')),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() => _activeMethod = null),
          child: const Text('Gunakan metode lain'),
        ),
      ],
    );
  }
}