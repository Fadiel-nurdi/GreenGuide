import 'package:flutter/material.dart';

// ================= USER SCREENS =================
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/plant_detail_screen.dart';
import 'screens/dataekosistem.dart';
import 'screens/formrekapps.dart';
import 'screens/suggestions_screen.dart';

// ================= ADMIN SCREENS =================
import 'admin/AdminLoginScreen.dart'; // ⬅️ pastikan class: AdminLoginScreen
import 'admin/admin_home_screen.dart';
import 'admin/admin_profile_screen.dart';
import 'admin/admin_ecosystem_list_screen.dart';
import 'admin/admin_ecosystem_form_screen.dart';
import 'admin/admin_activity_screen.dart';
import 'admin/admin_reference_form_screen.dart';
import 'admin/admin_suggestions_screen.dart';

// ================= SUPER ADMIN SCREENS =================
import 'super_admin/super_admin_home_screen.dart';
import 'super_admin/super_admin_profile_screen.dart';
import 'super_admin/super_admin_activity_screen.dart';
import 'super_admin/super_admin_admin_manage.dart';
import 'super_admin/super_admin_ecosystem.dart';
import 'super_admin/super_admin_reference_list_screen.dart';
import 'super_admin/super_admin_suggestions_screen.dart';
// ================= TESTIMONI SCREENS =================
import 'screens/testimonial_screen.dart';
import 'admin/admin_testimonial_screen.dart' as admin;
import 'super_admin/super_admin_testimonial_screen.dart' as superadmin;

Route<dynamic> onGenerateRoute(RouteSettings settings) {
  late final Widget page;

  switch (settings.name) {
  // ================= ROOT =================
    case '/welcome':
      page = const SplashScreen();
      break;

  // ================= USER =================
    case '/onboarding':
      page = const OnboardingScreen();
      break;

    case '/home':
      page = const HomeScreen();
      break;

    case '/explore':
      page = const ExploreScreen();
      break;

    case '/dataekosistem':
      page = const EcosystemScreen();
      break;

    case '/formrekapps':
      page = const FormRekAppsScreen();
      break;

    case '/favorites':
      page = const FavoritesScreen();
      break;

    case '/profile':
      page = const ProfileScreen();
      break;

    case '/detail':
      final args = settings.arguments;
      page = args is String && args.isNotEmpty
          ? PlantDetailScreen(id: args)
          : const Scaffold(
        body: Center(child: Text('ID tanaman tidak valid')),
      );
      break;

    case '/suggestions':
      page = const SuggestionsScreen();
      break;
  // ================= TESTIMONI =================
    case '/testimoni':
      page = const TestimonialScreen();
      break;

    case '/admin/testimoni':
      page = admin.AdminTestimonialScreen();
      break;

    case '/super/testimoni':
      page = superadmin.SuperAdminTestimonialScreen();
      break;


  // ================= ADMIN =================
    case '/admin-login':
      page = const AdminLoginScreen();
      break;

    case AdminHomeScreen.routeName:
      page = const AdminHomeScreen();
      break;

    case AdminProfileScreen.routeName:
      page = const AdminProfileScreen();
      break;

    case AdminEcosystemListScreen.routeName:
      page = const AdminEcosystemListScreen();
      break;

    case AdminEcosystemFormScreen.routeName:
      page = const AdminEcosystemFormScreen();
      break;

    case AdminReferenceFormScreen.routeName:
      page = const AdminReferenceFormScreen();
      break;

    case AdminActivityScreen.routeName:
      page = const AdminActivityScreen();
      break;

    case '/admin/suggestions':
      page = const AdminSuggestionsScreen();
      break;

  // ================= SUPER ADMIN =================
    case SuperAdminHomeScreen.routeName:
      page = const SuperAdminHomeScreen();
      break;

    case SuperAdminProfileScreen.routeName:
      page = const SuperAdminProfileScreen();
      break;

    case SuperAdminActivityScreen.routeName:
      page = const SuperAdminActivityScreen();
      break;

    case SuperAdminAdminManage.routeName:
      page = const SuperAdminAdminManage();
      break;

    case SuperAdminEcosystemScreen.routeName:
      page = const SuperAdminEcosystemScreen();
      break;

    case SuperAdminReferenceListScreen.routeName:
      page = const SuperAdminReferenceListScreen();
      break;

    case superadmin.SuperAdminTestimonialScreen.routeName:
      page = superadmin.SuperAdminTestimonialScreen();
      break;

    case '/super/suggestions':
      page = const SuperAdminSuggestionsScreen();
      break;


  // ================= FALLBACK =================
    default:
      page = Scaffold(
        appBar: AppBar(title: const Text('404')),
        body: Center(
          child: Text(
            '404 - Route "${settings.name}" tidak ditemukan',
            textAlign: TextAlign.center,
          ),
        ),
      );
  }

  return MaterialPageRoute(
    builder: (_) => page,
    settings: settings,
  );
}
