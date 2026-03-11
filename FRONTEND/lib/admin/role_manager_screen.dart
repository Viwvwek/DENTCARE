import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';
import '../utils/theme.dart';

/// A developer tool screen to set the current user's role.
/// Accessible from the Profile screen during development.
class RoleManagerScreen extends StatefulWidget {
  const RoleManagerScreen({super.key});

  @override
  State<RoleManagerScreen> createState() => _RoleManagerScreenState();
}

class _RoleManagerScreenState extends State<RoleManagerScreen> {
  UserProfile? _profile;
  bool _isLoading = true;
  bool _isSaving = false;
  AppRole _selectedRole = AppRole.doctor;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await UserService.getCurrentProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
        _selectedRole = profile?.role ?? AppRole.doctor;
        _isLoading = false;
      });
    }
  }

  Future<void> _applyRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      await UserService.setRole(user.uid, _selectedRole);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Role updated to ${_selectedRole.label}!'),
            backgroundColor: AppTheme.accent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _loadProfile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _makeAdmin() async {
    setState(() => _isSaving = true);
    try {
      await UserService.makeCurrentUserAdmin();
      if (mounted) {
        setState(() => _selectedRole = AppRole.admin);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ You are now Admin! Restart the app to see all changes.'),
            backgroundColor: AppTheme.accent,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
        await _loadProfile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'ROLE MANAGER',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: AppTheme.primary,
            fontSize: 15,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current status card
                  _buildCurrentStatusCard(),
                  const SizedBox(height: 28),

                  // Quick admin button
                  _buildMakeAdminCard(),
                  const SizedBox(height: 28),

                  // Role picker
                  const Text(
                    'ASSIGN ROLE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 14),

                  ...AppRole.values
                      .where((r) => r != AppRole.unknown)
                      .map((role) => _buildRoleTile(role)),

                  const SizedBox(height: 28),

                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppTheme.premiumGradient,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: TextButton(
                        onPressed: _isSaving ? null : _applyRole,
                        child: Text(
                          _isSaving ? 'APPLYING...' : 'APPLY ROLE: ${_selectedRole.label.toUpperCase()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: Colors.amber.shade700, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'In production, roles are managed by the clinic admin only. This screen is for development setup.',
                            style: TextStyle(color: Colors.amber.shade900, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCurrentStatusCard() {
    final role = _profile?.role ?? AppRole.unknown;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.premiumGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.accent, width: 2),
            ),
            child: Center(
              child: Text(
                (_profile?.displayName.isNotEmpty == true)
                    ? _profile!.displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _profile?.displayName ?? 'Unknown',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17),
                ),
                Text(
                  _profile?.email ?? '',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 12),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _roleColor(role).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _roleColor(role).withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    role.label.toUpperCase(),
                    style: TextStyle(
                      color: _roleColor(role),
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMakeAdminCard() {
    return GestureDetector(
      onTap: _isSaving ? null : _makeAdmin,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppTheme.softShadow,
          border: Border.all(color: AppTheme.accent.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Make Me Admin', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.primary)),
                  Text(
                    'One tap — grants full admin access to your account instantly',
                    style: AppTheme.subHeading.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            if (_isSaving)
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent))
            else
              const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.accent, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleTile(AppRole role) {
    final selected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? _roleColor(role).withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? _roleColor(role) : Colors.transparent,
            width: selected ? 1.5 : 0,
          ),
          boxShadow: selected ? [] : AppTheme.softShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _roleColor(role).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_roleIcon(role), color: _roleColor(role), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(role.label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.primary)),
                  Text(_roleDesc(role), style: AppTheme.subHeading.copyWith(fontSize: 12)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selected ? _roleColor(role) : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: selected ? _roleColor(role) : AppTheme.secondaryText, width: 2),
              ),
              child: selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : null,
            ),
          ],
        ),
      ),
    );
  }

  Color _roleColor(AppRole role) {
    switch (role) {
      case AppRole.admin:   return AppTheme.accent;
      case AppRole.doctor:  return AppTheme.primary;
      case AppRole.staff:   return const Color(0xFF6366F1);
      case AppRole.patient: return const Color(0xFFF59E0B);
      default:              return AppTheme.secondaryText;
    }
  }

  IconData _roleIcon(AppRole role) {
    switch (role) {
      case AppRole.admin:   return Icons.admin_panel_settings_rounded;
      case AppRole.doctor:  return Icons.medical_services_rounded;
      case AppRole.staff:   return Icons.badge_rounded;
      case AppRole.patient: return Icons.person_rounded;
      default:              return Icons.help_outline_rounded;
    }
  }

  String _roleDesc(AppRole role) {
    switch (role) {
      case AppRole.admin:   return 'Full access: dashboard, staff management, analytics';
      case AppRole.doctor:  return 'Scan, patients, appointments, reports';
      case AppRole.staff:   return 'Scan only, view appointments';
      case AppRole.patient: return 'View own reports and appointments';
      default:              return 'No access';
    }
  }
}
