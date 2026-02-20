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

// 🔥 CEK SUDAH ONLINE DI DEVICE LAIN BELUM
      // Support both 'isOnline' and legacy 'isonline' keys.
      final bool alreadyOnline =
          ((data['isOnline'] is bool && data['isOnline'] == true) ||
              (data['isonline'] is bool && data['isonline'] == true));

      // Prefer 'lastSeen', fall back to 'lastOnline' for older records.
      final Timestamp? lastSeenTsRaw =
          (data['lastSeen'] is Timestamp)
              ? data['lastSeen'] as Timestamp
              : (data['lastOnline'] is Timestamp ? data['lastOnline'] as Timestamp : null);

      bool sessionMasihAktif = false;

      // Conservative rule:
      // - Only consider a session active if we have a timestamp (lastSeen/lastOnline)
      //   and it's recent (within 5 minutes).
      // - Legacy flags without timestamps should NOT cause a popup.
      try {
        final now = DateTime.now();
        if (lastSeenTsRaw != null) {
          final lastSeen = lastSeenTsRaw.toDate();
          final diffMinutes = now.difference(lastSeen).inMinutes;
          if (diffMinutes < 5) sessionMasihAktif = true;
        } else {
          // No timestamp → do not treat as active
          sessionMasihAktif = false;
        }

        // If lastAction indicates a recent explicit logout, prefer that and
        // treat as not active (avoid race when logout/write occurs just now).
        final lastAction = data['lastAction']?.toString();
        final Timestamp? lastActionAtTs = data['lastActionAt'] is Timestamp ? data['lastActionAt'] as Timestamp : null;
        if (lastAction != null && lastAction == 'logout' && lastActionAtTs != null) {
          final lastActionAt = lastActionAtTs.toDate();
          final diffSeconds = now.difference(lastActionAt).inSeconds;
          if (diffSeconds < 120) {
            sessionMasihAktif = false;
          }
        }
      } catch (e) {
        print('Session detection error: $e');
      }

      // Debug: log session detection decision with more details
      print('AdminLogin: isOnline=${data['isOnline']}, isonline=${data['isonline']}, lastSeen=${lastSeenTsRaw?.toDate()}, lastAction=${data['lastAction']}, sessionMasihAktif=$sessionMasihAktif');

      // Double-check: re-fetch document to avoid races (logout might have just updated it)
      if (sessionMasihAktif) {
        try {
          final fresh = await adminRef.get();
          final freshData = (fresh.data() ?? {}) as Map<String, dynamic>;
          final Timestamp? freshLastSeen = (freshData['lastSeen'] is Timestamp)
              ? freshData['lastSeen'] as Timestamp
              : (freshData['lastOnline'] is Timestamp ? freshData['lastOnline'] as Timestamp : null);
          bool freshActive = false;
          if (freshLastSeen != null) {
            final now = DateTime.now();
            final diffMinutes = now.difference(freshLastSeen.toDate()).inMinutes;
            if (diffMinutes < 5) freshActive = true;
          }
          final freshLastAction = freshData['lastAction']?.toString();
          final Timestamp? freshLastActionAtTs = freshData['lastActionAt'] is Timestamp ? freshData['lastActionAt'] as Timestamp : null;
          if (freshLastAction != null && freshLastAction == 'logout' && freshLastActionAtTs != null) {
            final diffSeconds = DateTime.now().difference(freshLastActionAtTs.toDate()).inSeconds;
            if (diffSeconds < 120) {
              freshActive = false;
            }
          }

          print('AdminLogin(fresh): isOnline=${freshData['isOnline']}, isonline=${freshData['isonline']}, lastSeen=${freshLastSeen?.toDate()}, lastAction=${freshData['lastAction']}, freshActive=$freshActive');

          if (!freshActive) {
            // Another process updated the doc (likely logout). Skip the popup.
            sessionMasihAktif = false;
          }
        } catch (e) {
          print('Failed to refresh admin doc: $e');
        }
      }

      if (sessionMasihAktif) {
        // Instead of blocking immediately, allow user to force login.
        // This helps when previous session didn't clear isOnline on logout.
        final force = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Sesi Aktif Ditemukan'),
            content: const Text(
              'Akun ini tampak sedang digunakan pada perangkat lain. Anda dapat memaksa login untuk mengakhiri sesi lain. Lanjutkan?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Paksa Login'),
              ),
            ],
          ),
        );

        if (force != true) {
          // User chose not to force login — sign out and show message
          await FirebaseAuth.instance.signOut();
          setState(() => _error = 'Akun sedang digunakan di perangkat lain');
          return;
        }

        // User chose to force login — update admin doc to claim session
        try {
          // Update both key variants and timestamps for compatibility.
          await adminRef.update({
            'isOnline': true,
            'isonline': true,
            'lastOnline': FieldValue.serverTimestamp(),
            'lastSeen': FieldValue.serverTimestamp(),
            'forcedLoginAt': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          // If update failed, be defensive: sign out and show error
          await FirebaseAuth.instance.signOut();
          setState(() => _error = 'Gagal memaksa login: ${e.toString()}');
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
        'isonline': true,
        'lastOnline': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
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
