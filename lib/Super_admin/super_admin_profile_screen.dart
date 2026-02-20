import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../shared/circle_crop_screen.dart';
import 'super_admin_nav.dart';

class SuperAdminProfileScreen extends StatefulWidget {
  const SuperAdminProfileScreen({super.key});
  static const routeName = '/super-admin/profile';

  @override
  State<SuperAdminProfileScreen> createState() =>
      _SuperAdminProfileScreenState();
}

class _SuperAdminProfileScreenState extends State<SuperAdminProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameC = TextEditingController();
  final _emailC = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  String? _photoUrl;
  File? _pickedImage;

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

    final doc = await FirebaseFirestore.instance
        .collection('admins')
        .doc(user.uid)
        .get();

    final data = doc.data() ?? {};

    if (!mounted) return;
    setState(() {
      _nameC.text = data['name'] ?? '';
      _emailC.text = user.email ?? '';
      _photoUrl = (data['photoUrl'] as String?)?.trim();
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
      setState(() => _pickedImage = cropped);
    }
  }

  Future<String?> _uploadPhoto() async {
    if (_pickedImage == null || _user == null) return null;

    final ref =
    FirebaseStorage.instance.ref('admin_profiles/${_user!.uid}.png');
    await ref.putFile(_pickedImage!);
    return ref.getDownloadURL();
  }

  // ================= SAVE PROFILE =================
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final user = _user;
    if (user == null) return;

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

      _showSnack('Profil berhasil diperbarui');
    } catch (_) {
      _showSnack('Gagal menyimpan perubahan');
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

  // ================= PASSWORD FIELD (FIXED PLACE) =================
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: key,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Ubah Email Super Admin',
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
                      if (v == _emailC.text) {
                        return 'Email harus berbeda';
                      }
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
                          onPressed:
                          submitting ? null : () => Navigator.pop(context),
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
                              await _reauth(passC.text.trim());
                              await _user!.verifyBeforeUpdateEmail(
                                emailC.text.trim(),
                              );
                              await FirebaseFirestore.instance
                                  .collection('admins')
                                  .doc(_user!.uid)
                                  .update({
                                'email': emailC.text.trim(),
                                'updatedAt': FieldValue.serverTimestamp(),
                              });

                              setState(() {
                                _emailC.text = emailC.text.trim();
                              });
                              if (mounted) Navigator.pop(context);
                              _showSnack(
                                  'Email verifikasi telah dikirim');
                            } finally {
                              if (mounted) {
                                setD(() => submitting = false);
                              }
                            }
                          },
                          child: submitting
                              ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
                        await _user!
                            .updatePassword(newC.text.trim());
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

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const SuperAdminNav(),
      appBar: AppBar(title: const Text('Profil Super Admin')),
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
