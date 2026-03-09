import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_home_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailC = TextEditingController();
  final _passC = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  Future<void> _loginAdmin() async {
    if (_emailC.text.trim().isEmpty || _passC.text.isEmpty) {
      setState(() => _error = 'Email dan password wajib diisi');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // ================= AUTH =================
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailC.text.trim(),
        password: _passC.text,
      );

      final user = cred.user;
      if (user == null) {
        throw FirebaseAuthException(code: 'user-not-found');
      }
      // TAMBAHKAN DI SINI
      print("LOGIN UID: ${user.uid}");

// WAJIB DI SINI
      await user.getIdToken(true);


      // ================= FIRESTORE ADMIN =================
      final adminRef =
      FirebaseFirestore.instance.collection('admins').doc(user.uid);

      final adminSnap = await adminRef.get();
      if (!adminSnap.exists) {
        await FirebaseAuth.instance.signOut();
        setState(() => _error = 'Akun ini bukan admin');
        return;
      }

      final data = adminSnap.data() as Map<String, dynamic>;

      // ================= CEK 1 DEVICE =================
      if (data['isOnline'] == true) {
        final force = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Sesi Aktif Ditemukan'),
            content: const Text(
              'Akun sedang digunakan di perangkat lain. Paksa login?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Paksa Login'),
              ),
            ],
          ),
        );

        if (force != true) {
          await FirebaseAuth.instance.signOut();
          setState(() => _error = 'Akun sedang digunakan di perangkat lain');
          return;
        }
      }


      // ================= VALIDASI AKTIF (FIX FINAL) =================
      final bool active = data['active'] == true;

      if (!active) {
        await FirebaseAuth.instance.signOut();
        setState(() => _error = 'Akun admin dinonaktifkan');
        return;
      }

      // ================= SET ONLINE =================
      // Mark user online (write both key names and timestamps)
      await adminRef.update({
        'isOnline': true,
        'lastOnline': FieldValue.serverTimestamp(),
      });

      // ================= ROLE =================
      final String role = (data['role'] ?? 'admin').toString();

      if (!mounted) return;

      if (role == 'super_admin') {
        Navigator.pushReplacementNamed(context, '/super/home');
      }
      else {
        Navigator.pushReplacementNamed(
          context,
          AdminHomeScreen.routeName,
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Email tidak terdaftar';
          break;
        case 'wrong-password':
          message = 'Password salah';
          break;
        case 'invalid-email':
          message = 'Format email tidak valid';
          break;
        case 'user-disabled':
          message = 'Akun telah dinonaktifkan';
          break;
        case 'too-many-requests':
          message = 'Terlalu banyak percobaan login, coba lagi nanti';
          break;
        default:
          message = 'Login gagal, silakan coba lagi';
      }
      setState(() => _error = message);
    } catch (e) {
      print("ERROR ASLI LOGIN: $e");
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailC.dispose();
    _passC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false, // ⛔ cegah pop default (anti layar hitam)
      onPopInvoked: (didPop) {
        if (didPop) return;

        // ⛔ CEGAH STACK KOSONG (LAYAR HITAM)
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/onboarding', // ✅ TIDAK refer ke class → ERROR HILANG
              (route) => false,
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Login Admin'),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),

                Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.shield_rounded,
                      size: 120,
                      color: Colors.green.withOpacity(0.15),
                    ),
                    Image.asset(
                      'assets/Images/Logo.png',
                      width: 64,
                      height: 64,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Text(
                  'Admin GreenGuide',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 32),

                TextField(
                  controller: _emailC,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Admin',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.email),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: _passC,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _loginAdmin,
                    child: _loading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : const Text('Login'),
                  ),
                ),

                const SizedBox(height: 12),

                // ✅ KEMBALI KE ONBOARDING (AMAN, TANPA ERROR)
                TextButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/onboarding', // ✅ STRING ROUTE
                          (route) => false,
                    );
                  },
                  child: const Text('Kembali'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
