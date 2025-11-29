import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kukuo/providers/auth_provider.dart';
import 'package:kukuo/providers/user_input_provider.dart';
import 'package:kukuo/providers/exchange_rate_provider.dart';
import 'package:kukuo/screens/currency_screen.dart';

enum SettingsView { main, account, appearance, deleteAccount }

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({super.key});

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  SettingsView _currentView = SettingsView.main;

  void _navigateTo(SettingsView view) {
    setState(() {
      _currentView = view;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 32),
      decoration: BoxDecoration(
        color: const Color(0xFF00312F),
        borderRadius: BorderRadius.circular(30),
      ),
      height: null, // Make height responsive
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Back button removed from header

                  Text(
                    _getTitle(),
                    style: const TextStyle(
                      fontFamily: 'Gazpacho',
                      fontSize: 24,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),

                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00514F).withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white.withValues(alpha: 0.2),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Content
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _buildCurrentView(context),
            ),
          ],
        ),
      ),
    );
  }

  String _getTitle() {
    switch (_currentView) {
      case SettingsView.main:
        return 'Settings';
      case SettingsView.account:
        return 'Account & Support';
      case SettingsView.appearance:
        return 'Appearance';
      case SettingsView.deleteAccount:
        return 'Delete Your Account';
    }
  }

  Widget _buildCurrentView(BuildContext context) {
    switch (_currentView) {
      case SettingsView.main:
        return _buildMainView(context);
      case SettingsView.account:
        return _buildAccountView(context);
      case SettingsView.appearance:
        return _buildAppearanceView(context);
      case SettingsView.deleteAccount:
        return _buildDeleteAccountView(context);
    }
  }

  Widget _buildMainView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildSettingsButton(
            context,
            icon: Iconsax.user,
            label: 'Account & Support',
            color: Colors.white,
            onTap: () => _navigateTo(SettingsView.account),
          ),
          // Reduced spacing
          _buildSettingsButton(
            context,
            icon: Iconsax.brush_2,
            label: 'Appearance',
            color: Colors.white,
            onTap: () => _navigateTo(SettingsView.appearance),
          ),
          const SizedBox(height: 32), // Added bottom padding
        ],
      ),
    );
  }

  Widget _buildAccountView(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // User Profile
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF003E3C), // Lighter background
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00514F),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Iconsax.user,
                    color: Color(0xFFD8FE00),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (user?.displayName ?? 'User')
                                .substring(0, 1)
                                .toUpperCase() +
                            (user?.displayName ?? 'User').substring(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8), // Reduced from 16

          _buildSettingsButton(
            context,
            icon: Iconsax.shield_tick,
            label: 'Privacy Policy',
            color: Colors.white,
            onTap: () =>
                _launchUrl('https://www.apple.com/legal/privacy/en-ww/'),
          ),
          const SizedBox(height: 0), // Reduced spacing

          _buildSettingsButton(
            context,
            icon: Iconsax.document_text,
            label: 'Terms of Service',
            color: Colors.white,
            onTap: () => _launchUrl(
                'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/'),
          ),
          const SizedBox(height: 0), // Reduced spacing

          _buildSettingsButton(
            context,
            icon: Iconsax.logout,
            label: 'Log Out',
            color: Colors.white, // Changed to white
            onTap: () => authProvider.signOut(context),
          ),
          const SizedBox(height: 0), // Reduced spacing

          _buildSettingsButton(
            context,
            icon: Iconsax.trash,
            label: 'Delete Account',
            color: Colors.white, // Fixed color
            onTap: () => _navigateTo(SettingsView.deleteAccount),
          ),
          const SizedBox(height: 16), // Reduced from 32

          // Bottom Navigation
          Row(
            children: [
              GestureDetector(
                onTap: () => _navigateTo(SettingsView.main),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00514F),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8FE00),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Center(
                      child: Text(
                        'Done',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAppearanceView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return _buildSettingsButton(
                context,
                icon: Iconsax.money_change,
                label: 'Set Default Currency',
                color: Colors.white,
                onTap: () => _showCurrencyPicker(context),
              );
            },
          ),
          // Reduced spacing
          Consumer<UserInputProvider>(
            builder: (context, provider, _) {
              return Container(
                decoration: BoxDecoration(
                  // border removed
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Show Chart Above Assets',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  value: provider.showChartAboveAssets,
                  onChanged: (value) {
                    provider.toggleChartPosition(value);
                  },
                  activeTrackColor: const Color(0xFFD8FE00),
                  contentPadding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32), // Added bottom padding

          // Bottom Navigation
          Row(
            children: [
              GestureDetector(
                onTap: () => _navigateTo(SettingsView.main),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00514F).withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8FE00),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Center(
                      child: Text(
                        'Done',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSettingsButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
          decoration: BoxDecoration(
            // border removed
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20), // Reduced icon size
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(Iconsax.arrow_right_3, color: color, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.inAppWebView)) {
      throw Exception('Could not launch $url');
    }
  }

  Widget _buildDeleteAccountView(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const Text(
            "This action will permanently delete all your to-do's and data from this device and our database. This action cannot be undone.",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // Bottom Navigation
          Row(
            children: [
              GestureDetector(
                onTap: () => _navigateTo(SettingsView.account),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00514F).withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final error = await authProvider.deleteAccount(context);
                    if (error != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(error),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } else if (context.mounted) {
                      Navigator.pop(context); // Close sheet on success
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Iconsax.trash,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Delete Account',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _showCurrencyPicker(BuildContext context) async {
    final userInputProvider =
        Provider.of<UserInputProvider>(context, listen: false);
    final exchangeRateProvider =
        Provider.of<ExchangeRateProvider>(context, listen: false);

    final selectedCurrency = await showCurrencyBottomSheet(context);

    if (selectedCurrency != null && context.mounted) {
      await userInputProvider.setSelectedCurrency(
        selectedCurrency,
        exchangeRateProvider.exchangeRates,
      );
    }
  }
}
