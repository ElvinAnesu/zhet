import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsOfService extends StatelessWidget {
  const TermsOfService({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Terms of Service',
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
              '1. Acceptance of Terms',
              'By accessing and using Zhet, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our services.',
            ),
            _buildSection(
              '2. Service Description',
              'Zhet is a peer-to-peer currency exchange platform that connects users looking to exchange USD and ZWG. We provide a platform for users to create ads and communicate with each other, but we are not a party to any transactions.',
            ),
            _buildSection(
              '3. User Responsibilities',
              'Users are responsible for:\n\n'
                  '• Verifying the identity of their exchange partners\n'
                  '• Ensuring the accuracy of exchange rates and amounts\n'
                  '• Conducting transactions in a safe and legal manner\n'
                  '• Complying with all applicable laws and regulations',
            ),
            _buildSection(
              '4. Prohibited Activities',
              'Users may not:\n\n'
                  '• Engage in fraudulent or illegal activities\n'
                  '• Post false or misleading information\n'
                  '• Use the platform for money laundering\n'
                  '• Harass or threaten other users\n'
                  '• Violate any applicable laws or regulations',
            ),
            _buildSection(
              '5. Limitation of Liability',
              'Zhet is not responsible for:\n\n'
                  '• Any losses incurred during transactions\n'
                  '• Disputes between users\n'
                  '• The accuracy of user-provided information\n'
                  '• Technical issues beyond our control',
            ),
            _buildSection(
              '6. Account Termination',
              'We reserve the right to terminate or suspend accounts that violate these terms or engage in suspicious activities. Users may appeal such decisions by contacting our support team.',
            ),
            _buildSection(
              '7. Changes to Terms',
              'We may update these terms at any time. Users will be notified of significant changes, and continued use of the service constitutes acceptance of the updated terms.',
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
              'If you have any questions about these Terms of Service, please contact us at:\n\n'
              'Email: support@zhet.com\n'
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
