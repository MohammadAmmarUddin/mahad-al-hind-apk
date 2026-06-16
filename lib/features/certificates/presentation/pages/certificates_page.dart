import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import 'certificate_verify_page.dart';

class CertificatesPage extends StatelessWidget {
  const CertificatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Certificates'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => _showVerifyDialog(context),
          ),
        ],
      ),
      body: _buildCertificatesList(),
    );
  }

  Widget _buildCertificatesList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _CertificateCard(
          title: 'Quran Recitation - Level 1',
          studentName: 'Mohammad Ahmed',
          issueDate: 'March 15, 2024',
          certificateId: 'CERT-QR-2024-001',
          course: 'Quran Recitation Fundamentals',
        ),
        const SizedBox(height: 12),
        _CertificateCard(
          title: 'Islamic Studies - Intermediate',
          studentName: 'Mohammad Ahmed',
          issueDate: 'June 20, 2024',
          certificateId: 'CERT-IS-2024-042',
          course: 'Islamic Studies Intermediate',
        ),
      ],
    );
  }

  void _showVerifyDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verify Certificate'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter Certificate ID',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CertificateVerifyPage(certificateId: controller.text),
                ),
              );
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  final String title;
  final String studentName;
  final String issueDate;
  final String certificateId;
  final String course;

  const _CertificateCard({
    required this.title,
    required this.studentName,
    required this.issueDate,
    required this.certificateId,
    required this.course,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.workspace_premium, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(studentName, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('Issued: $issueDate', style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
          Text('ID: $certificateId', style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
          const SizedBox(height: 12),
          QrImageView(
            data: 'https://mahad-al-hind.vercel.app/api/certificate/check/$certificateId',
            version: QrVersions.auto,
            size: 100,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CertificateVerifyPage(certificateId: certificateId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.qr_code, size: 16),
                  label: const Text('View'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Share.share(
                      'Certificate: $title\nStudent: $studentName\nVerify at: https://mahad-al-hind.vercel.app/api/certificate/check/$certificateId',
                    );
                  },
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('Share'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
