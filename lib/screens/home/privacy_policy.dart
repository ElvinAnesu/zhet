import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicy extends StatelessWidget {
  const PrivacyPolicy({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last Updated: March 2024',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. Information We Collect',
              'We collect the following information:\n\n'
                  '• Personal Information: Name, email address, phone number\n'
                  '• Transaction Information: Exchange rates, amounts, locations\n'
                  '• Device Information: IP address, device type, operating system\n'
                  '• Usage Data: How you interact with our app and services',
            ),
            _buildSection(
              '2. How We Use Your Information',
              'We use your information to:\n\n'
                  '• Provide and improve our services\n'
                  '• Facilitate currency exchanges\n'
                  '• Ensure platform security and prevent fraud\n'
                  '• Communicate with you about our services\n'
                  '• Comply with legal obligations',
            ),
            _buildSection(
              '3. Information Sharing',
              'We may share your information with:\n\n'
                  '• Other users (only necessary information for transactions)\n'
                  '• Service providers who assist in our operations\n'
                  '• Law enforcement when required by law\n'
                  '• Third parties with your consent',
            ),
            _buildSection(
              '4. Data Security',
              'We implement appropriate security measures to protect your information, including:\n\n'
                  '• Encryption of sensitive data\n'
                  '• Secure servers and networks\n'
                  '• Regular security assessments\n'
                  '• Access controls and authentication',
            ),
            _buildSection(
              '5. Your Rights',
              'You have the right to:\n\n'
                  '• Access your personal information\n'
                  '• Correct inaccurate information\n'
                  '• Request deletion of your data\n'
                  '• Opt-out of marketing communications\n'
                  '• Withdraw consent for data processing',
            ),
            _buildSection(
              '6. Cookies and Tracking',
              'We use cookies and similar technologies to:\n\n'
                  '• Remember your preferences\n'
                  '• Analyze app usage\n'
                  '• Improve our services\n'
                  '• Prevent fraud',
            ),
            _buildSection(
              '7. Children\'s Privacy',
              'Our services are not intended for users under 18 years of age. We do not knowingly collect personal information from children.',
            ),
            const SizedBox(height: 24),
            Text(
              'Contact Us',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'If you have any questions about our Privacy Policy, please contact us at:\n\n'
              'Email: privacy@zhet.com\n'
              'Phone: +263 77 123 4567',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Text(content, style: GoogleFonts.poppins(fontSize: 14)),
        const SizedBox(height: 24),
      ],
    );
  }
}
