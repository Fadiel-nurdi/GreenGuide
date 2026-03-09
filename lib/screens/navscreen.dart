import 'package:flutter/material.dart';

class NavScreen extends StatelessWidget {
  final String currentPage; // 'home', 'panduan', 'data', 'form'

  const NavScreen({
    super.key,
    required this.currentPage,
  });

  void _go(BuildContext context, String page, String route) {
    Navigator.pop(context); // tutup drawer saja

    if (currentPage == page) return;

    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ================= HEADER =================
          DrawerHeader(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/Images/kocak.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Text(
                    'Green Guide',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),


          // ================= MENU =================
          _DrawerItem(
            title: 'Beranda',
            selected: currentPage == 'home',
            onTap: () => _go(context, 'home', '/home'),
          ),
          _DrawerItem(
            title: 'Panduan',
            selected: currentPage == 'panduan',
            onTap: () => _go(context, 'panduan', '/explore'),
          ),
          _DrawerItem(
            title: 'Data ekosistem',
            selected: currentPage == 'data',
            onTap: () => _go(context, 'data', '/dataekosistem'),
          ),
          _DrawerItem(
            title: 'Form Rekomendasi Tanaman',
            selected: currentPage == 'form',
            onTap: () => _go(context, 'form', '/formrekapps'),
          ),

          // TAMBAHAN INI
          _DrawerItem(
            title: 'Testimoni',
            selected: currentPage == 'testimoni',
            onTap: () => _go(context, 'testimoni', '/testimoni'),
          ),
          _DrawerItem(
            title: 'Saran & Masukan',
            selected: currentPage == 'suggestions',
            onTap: () => _go(context, 'suggestions', '/suggestions'),
          ),

          const Divider(),

          // ================= LOGOUT =================
          ListTile(
            title: const Text(
              'Keluar',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/onboarding',
                (_) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
          color: selected ? primary : null,
        ),
      ),
      selected: selected,
      onTap: onTap,
    );
  }
}
