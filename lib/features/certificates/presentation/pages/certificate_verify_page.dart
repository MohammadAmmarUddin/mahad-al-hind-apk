import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';

class CertificateVerifyPage extends StatelessWidget {
  final String certificateId;
  const CertificateVerifyPage({super.key, required this.certificateId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Certificate')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified, size: 60, color: AppColors.success),
              ),
              const SizedBox(height: 24),
              const Text('Certificate Verified', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('ID: $certificateId', style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              QrImageView(
                data: 'https://mahad-al-hind.vercel.app/api/certificate/check/$certificateId',
                version: QrVersions.auto,
                size: 150,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
