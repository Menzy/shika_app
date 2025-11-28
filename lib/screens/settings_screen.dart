import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kukuo/common/top_section_container.dart';
import 'package:kukuo/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kukuo/screens/currency_screen.dart';
import 'package:kukuo/providers/user_input_provider.dart';
import 'package:kukuo/providers/exchange_rate_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: const Color(0xFF000D0C),
      body: TTopSectionContainer(
        isHeaderOnTop: true, // Fix back button clickability
        customHeader: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00312F),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00514F),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              'Settings',
              style: TextStyle(
                fontFamily: 'Gazpacho',
                fontSize: 24,
                color: Colors.white,
              ),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF00312F),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Profile Section
              Row(
                children: [
                  // Avatar Placeholder
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00514F),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Iconsax.user,
                      color: Color(0xFFD8FE00),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // User Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Set Default Currency Button
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  // We need UserInputProvider to set the currency
                  // But we can access it via Provider.of in the onTap
                  return _buildSettingsButton(
                    context,
                    icon: Iconsax.money_change,
                    label: 'Set Default Currency',
                    color: Colors.white,
                    onTap: () => _showCurrencyPicker(context),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Layout Preference Toggle
              Consumer<UserInputProvider>(
                builder: (context, provider, _) {
                  return SwitchListTile(
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
                    activeColor: const Color(0xFFD8FE00),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFF00514F)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Privacy Policy Button
              _buildSettingsButton(
                context,
                icon: Iconsax.shield_tick,
                label: 'Privacy Policy',
                color: Colors.white,
                onTap: () =>
                    _launchUrl('https://www.apple.com/legal/privacy/en-ww/'),
              ),
              const SizedBox(height: 16),

              // Terms of Service Button
              _buildSettingsButton(
                context,
                icon: Iconsax.document_text,
                label: 'Terms of Service',
                color: Colors.white,
                onTap: () => _launchUrl(
                    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/'),
              ),
              const SizedBox(height: 16),

              // Logout Button
              _buildSettingsButton(
                context,
                icon: Iconsax.logout,
                label: 'Log Out',
                color: const Color(0xFFD8FE00),
                onTap: () {
                  authProvider.signOut(context);
                },
              ),
              const SizedBox(height: 16),

              // Delete Account Button
              _buildSettingsButton(
                context,
                icon: Iconsax.trash,
                label: 'Delete Account',
                color: Colors.redAccent,
                onTap: () => _showDeleteConfirmation(context, authProvider),
              ),
            ],
          ),
        ),
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
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF00514F)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
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

  void _showDeleteConfirmation(
      BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF00312F),
        title: const Text(
          'Delete Account',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog
              final error = await authProvider.deleteAccount(context);
              if (error != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.inAppWebView)) {
      throw Exception('Could not launch $url');
    }
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
