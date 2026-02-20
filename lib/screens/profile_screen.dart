import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: const Text('Fadiel Nurdiansyah'),
            subtitle: const Text('Informatika - ITERA'),
            trailing: IconButton(onPressed: () {}, icon: const Icon(Icons.edit)),
          ),
          const Divider(height: 32),
          SwitchListTile(
            value: true,
            onChanged: (_) {},
            title: const Text('Tema hijau'),
            subtitle: const Text('Material You'),
          ),
          const ListTile(leading: Icon(Icons.info_outline), title: Text('Tentang Aplikasi'), subtitle: Text('Green Guide v1.0.0')),
          const ListTile(leading: Icon(Icons.privacy_tip_outlined), title: Text('Kebijakan Privasi')),
        ],
      ),
    );
  }
}
