import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../shared/circle_crop_screen.dart';
import 'admin_nav.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});
  static const routeName = '/admin/profile';

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameC = TextEditingController();
  final _emailC = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  String? _photoUrl;
  File? _pickedImage;
  bool _docExists = false; // track if admins/{uid} exists

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameC.dispose();
    _emailC.dispose();
    super.dispose();
  }

  // ================= LOAD PROFILE =================
  Future<void> _loadProfile() async {
    final user = _user;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('admins')
        .doc(user.uid);

    final doc = await docRef.get();

    final data = doc.data() ?? {};

    if (!mounted) return;
    setState(() {
      _nameC.text = data['name'] ?? '';
      _emailC.text = user.email ?? '';
      _photoUrl = (data['photoUrl'] as String?)?.trim();
      _docExists = doc.exists;
      _loading = false;
    });
  }

  // ================= IMAGE =================
  ImageProvider? _profileImage() {
    if (_pickedImage != null) return FileImage(_pickedImage!);
    if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      return NetworkImage(_photoUrl!);
    }
    return null;
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );
    if (picked == null || !mounted) return;

    final cropped = await Navigator.push<File?>(
      context,
      MaterialPageRoute(
        builder: (_) => CircleCropScreen(imageFile: File(picked.path)),
      ),
    );

    if (cropped != null && mounted) {
      // Evict previous image caches to ensure UI shows new image immediately
      try {
        if (_pickedImage != null) {
          await FileImage(_pickedImage!).evict();
        }
        if (_photoUrl != null && _photoUrl!.isNotEmpty) {
          await NetworkImage(_photoUrl!).evict();
        }
      } catch (e) {
        debugPrint('Evict cache error: $e');
      }

      setState(() {
        _pickedImage = cropped;
        debugPrint('Picked cropped file path: ${cropped.path}');
      });
    }
  }

  Future<String?> _uploadPhoto() async {
    if (_pickedImage == null || _user == null) return null;

    try {
      final ref = FirebaseStorage.instance.ref('admin_profiles/${_user!.uid}.png');
      final metadata = SettableMetadata(contentType: 'image/png');
      final uploadTask = ref.putFile(_pickedImage!, metadata);
      final snapshot = await uploadTask;
      if (snapshot.state != TaskState.success) {
        throw Exception('Upload gagal: ${snapshot.state}');
      }
      final url = await ref.getDownloadURL();
      try {
        await NetworkImage(url).evict();
      } catch (e) {
        debugPrint('Evict new network image failed: $e');
      }
      return url;
    } catch (e) {
      debugPrint('Upload photo error: $e');
      rethrow;
    }
  }

  // ================= SAVE PROFILE =================
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final user = _user;
    if (user == null) return;

    if (!_docExists) {
      // Security rules may disallow create by admin; better to inform user to contact super admin.
      _showSnack('Akun admin belum terdaftar di server. Minta super admin menambahkan akun Anda agar perubahan bisa disimpan.');
      return;
    }

    setState(() => _saving = true);
    try {
      String? newPhoto = _photoUrl;
      if (_pickedImage != null) {
        newPhoto = await _uploadPhoto();
      }

      await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .update({
        'name': _nameC.text.trim(),
        'photoUrl': newPhoto,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // update local state
      setState(() {
        _photoUrl = newPhoto;
        _pickedImage = null;
      });

      _showSnack('Profil berhasil diperbarui');
    } catch (e) {
      debugPrint('Save profile error: $e');
      _showSnack('Gagal menyimpan perubahan: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ================= REAUTH =================
  Future<void> _reauth(String password) async {
    final user = _user;
    if (user == null || user.email == null) return;

    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      ),
    );
  }

  // ================= CHANGE EMAIL =================
  void _showChangeEmailDialog() {
    final emailC = TextEditingController(text: _emailC.text);
    final passC = TextEditingController();
    bool submitting = false;

    final key = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setD) => Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: key,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Ubah Email Admin',
                    style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: emailC,
                    decoration: const InputDecoration(
                      labelText: 'Email Baru',
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Email wajib diisi';
                      if (!v.contains('@')) return 'Email tidak valid';
                      if (v == _emailC.text) return 'Email harus berbeda';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: passC,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password Saat Ini',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    validator: (v) =>
                    v == null || v.isEmpty ? 'Password wajib diisi' : null,
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: submitting
                              ? null
                              : () => Navigator.pop(context),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: submitting
                              ? null
                              : () async {
                            if (!key.currentState!.validate()) return;

                            setD(() => submitting = true);
                            try {
                              final newEmail = emailC.text.trim();

                              // 1️⃣ Re-auth
                              await _reauth(passC.text.trim());

                              // 2️⃣ Update email di Firebase Auth
                              await _user!.verifyBeforeUpdateEmail(newEmail);

                              // 🔥 3️⃣ UPDATE EMAIL DI FIRESTORE (INI YANG WAJIB)
                              await FirebaseFirestore.instance
                                  .collection('admins')
                                  .doc(_user!.uid)
                                  .update({
                                'email': newEmail,
                                'updatedAt': FieldValue.serverTimestamp(),
                              });

                              // 4️⃣ Update UI lokal
                              setState(() {
                                _emailC.text = newEmail;
                              });

                              if (mounted) Navigator.pop(context);
                              _showSnack('Email berhasil diperbarui & verifikasi dikirim');
                            } catch (e) {
                              _showSnack('Gagal mengubah email');
                            } finally {
                              if (mounted) setD(() => submitting = false);
                            }
                          },

                          child: submitting
                              ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2),
                          )
                              : const Text('Simpan'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= CHANGE PASSWORD =================
  void _showChangePasswordDialog() {
    final oldC = TextEditingController();
    final newC = TextEditingController();
    final confirmC = TextEditingController();

    bool showOld = false;
    bool showNew = false;
    bool showConfirm = false;
    bool submitting = false;

    final key = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setD) => Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: key,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Ubah Password',
                    style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 20),

                  _passwordField(
                    controller: oldC,
                    label: 'Password Lama',
                    show: showOld,
                    toggle: () => setD(() => showOld = !showOld),
                  ),
                  const SizedBox(height: 12),

                  _passwordField(
                    controller: newC,
                    label: 'Password Baru',
                    show: showNew,
                    toggle: () => setD(() => showNew = !showNew),
                    validator: (v) {
                      if (v == null || v.length < 6) {
                        return 'Minimal 6 karakter';
                      }
                      if (v == oldC.text) {
                        return 'Password baru harus berbeda';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  _passwordField(
                    controller: confirmC,
                    label: 'Konfirmasi Password',
                    show: showConfirm,
                    toggle: () => setD(() => showConfirm = !showConfirm),
                    validator: (v) =>
                    v != newC.text ? 'Password tidak sama' : null,
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: submitting
                        ? null
                        : () async {
                      if (!key.currentState!.validate()) return;

                      setD(() => submitting = true);
                      try {
                        await _reauth(oldC.text.trim());
                        await _user!.updatePassword(newC.text.trim());
                        if (mounted) Navigator.pop(context);
                        _showSnack('Password berhasil diubah');
                      } finally {
                        if (mounted) {
                          setD(() => submitting = false);
                        }
                      }
                    },
                    child: submitting
                        ? const CircularProgressIndicator(strokeWidth: 2)
                        : const Text('Simpan'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool show,
    required VoidCallback toggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !show,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(show ? Icons.visibility : Icons.visibility_off),
          onPressed: toggle,
        ),
      ),
      validator:
      validator ?? (v) => v == null || v.isEmpty ? '$label wajib diisi' : null,
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminNav(),
      appBar: AppBar(title: const Text('Profil Admin')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 46,
                      backgroundImage: _profileImage(),
                      child: _profileImage() == null
                          ? const Icon(Icons.person, size: 46)
                          : null,
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              _input(_nameC, 'Nama', Icons.person),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.email),
                  title: Text(_emailC.text),
                  trailing: TextButton(
                    onPressed: _showChangeEmailDialog,
                    child: const Text('Ubah'),
                  ),
                ),
              ),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.lock),
                  title: const Text('Keamanan Akun'),
                  subtitle: const Text('Ubah password akun'),
                  trailing: TextButton(
                    onPressed: _showChangePasswordDialog,
                    child: const Text('Ubah'),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _saveProfile,
                child: _saving
                    ? const CircularProgressIndicator()
                    : const Text('Simpan Perubahan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(TextEditingController c, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
        validator:
            (v) => v == null || v.isEmpty ? '$label wajib diisi' : null,
      ),
    );
  }
}
