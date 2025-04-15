import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Help extends StatelessWidget {
  const Help({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Help & Support',
          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Frequently Asked Questions',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            _buildFAQItem(
              'How do I create an ad?',
              'To create an ad, tap on the "Ads" tab in the bottom navigation bar and then tap the "Create Ad" button. Fill in the required information and submit.',
            ),
            _buildFAQItem(
              'How do I contact a seller?',
              'Tap on the "Chat" button in any ad to start a conversation with the seller. You can discuss the details of the exchange.',
            ),
            _buildFAQItem(
              'Is my payment information secure?',
              'Yes, we use industry-standard encryption to protect your payment information. We never store your full payment details on our servers.',
            ),
            const SizedBox(height: 24),
            Text(
              'Contact Support',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            _buildContactOption(
              context,
              'Email Support',
              'support@zhet.com',
              Icons.email_outlined,
              () {
                // TODO: Implement email support
              },
            ),
            _buildContactOption(
              context,
              'Call Support',
              '+263 77 123 4567',
              Icons.phone_outlined,
              () {
                // TODO: Implement call support
              },
            ),
            _buildContactOption(
              context,
              'Live Chat',
              'Available 24/7',
              Icons.chat_outlined,
              () {
                // TODO: Implement live chat
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          question,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              answer,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
