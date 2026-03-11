import 'package:flutter/material.dart';
import '../services/user_service.dart';

/// Inherited widget that propagates the current user's role down the tree.
/// Wrap the app (or navigator) with this to have role-aware widgets everywhere.
class RoleProvider extends InheritedWidget {
  final UserProfile? profile;
  final bool isLoading;

  const RoleProvider({
    super.key,
    required this.profile,
    required this.isLoading,
    required super.child,
  });

  static RoleProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<RoleProvider>();
  }

  AppRole get role => profile?.role ?? AppRole.unknown;
  bool get isAdmin  => role == AppRole.admin;

  @override
  bool updateShouldNotify(RoleProvider old) =>
      old.profile?.role != profile?.role || old.isLoading != isLoading;
}

/// Stateful wrapper that listens to Firestore and rebuilds when role changes.
class RoleProviderWrapper extends StatefulWidget {
  final Widget child;
  const RoleProviderWrapper({super.key, required this.child});

  @override
  State<RoleProviderWrapper> createState() => _RoleProviderWrapperState();
}

class _RoleProviderWrapperState extends State<RoleProviderWrapper> {
  UserProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    UserService.watchCurrentProfile().listen((profile) {
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return RoleProvider(
      profile: _profile,
      isLoading: _isLoading,
      child: widget.child,
    );
  }
}

// ─── Route Guard ──────────────────────────────────────────────────────────────
/// Wraps a screen with a role check. If the user doesn't have the required role,
/// show a "No Access" page instead.
class RoleGuard extends StatelessWidget {
  final Widget child;
  final List<AppRole> allowedRoles;
  final String? featureName;

  const RoleGuard({
    super.key,
    required this.child,
    required this.allowedRoles,
    this.featureName,
  });

  @override
  Widget build(BuildContext context) {
    final rp = RoleProvider.of(context);
    final role = rp?.role ?? AppRole.unknown;

    if (rp?.isLoading == true) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!allowedRoles.contains(role)) {
      return _NoAccessScreen(
        requiredRole: allowedRoles.first.label,
        currentRole: role.label,
        featureName: featureName,
      );
    }

    return child;
  }
}

// ─── No Access Screen ─────────────────────────────────────────────────────────
class _NoAccessScreen extends StatelessWidget {
  final String requiredRole;
  final String currentRole;
  final String? featureName;

  const _NoAccessScreen({
    required this.requiredRole,
    required this.currentRole,
    this.featureName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red.shade200, width: 2),
                ),
                child: Icon(Icons.lock_rounded, color: Colors.red.shade400, size: 48),
              ),
              const SizedBox(height: 28),
              const Text(
                'Access Restricted',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F2744),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                featureName != null
                    ? '$featureName requires $requiredRole access.'
                    : 'This area requires $requiredRole access.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Text(
                  'Your current role: $currentRole',
                  style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Contact your clinic administrator\nto request elevated access.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
              ),
              const SizedBox(height: 36),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Go Back'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F2744),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
