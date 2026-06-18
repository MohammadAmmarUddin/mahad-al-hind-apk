import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/providers/core_providers.dart';
import 'certificate_verify_page.dart';

class CertificatesPage extends ConsumerStatefulWidget {
  const CertificatesPage({super.key});

  @override
  ConsumerState<CertificatesPage> createState() => _CertificatesPageState();
}

class _CertificatesPageState extends ConsumerState<CertificatesPage> {
  List<dynamic> _certificates = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCertificates();
  }

  Future<void> _fetchCertificates() async {
    setState(() { _loading = true; _error = null; });
    try {
      final dio = ref.read(dioClientProvider);
      final response = await dio.get('/api/certificate');
      final data = response.data;

      List<dynamic> certs = [];
      if (data is List) {
        certs = data;
      } else if (data is Map && data['data'] is List) {
        certs = data['data'];
      } else if (data is Map && data['certificates'] is List) {
        certs = data['certificates'];
      }

      if (mounted) {
        setState(() {
          _certificates = certs;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load certificates';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Certificates'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Verify Certificate',
            onPressed: () => _showVerifyDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchCertificates,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchCertificates,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_certificates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.workspace_premium_outlined, size: 56, color: AppColors.primary.withOpacity(0.4)),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Certificates Yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Complete a course to earn your certificate. Your achievements will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchCertificates,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _certificates.length,
        itemBuilder: (ctx, i) {
          final cert = _certificates[i];
          return _CertificateCard(
            cert: cert,
            onVerify: () {
              final certId = cert['certificateId'] ?? cert['_id'] ?? cert['id'] ?? '';
              if (certId.toString().isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CertificateVerifyPage(certificateId: certId.toString()),
                  ),
                );
              }
            },
          );
        },
      ),
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
              if (controller.text.trim().isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CertificateVerifyPage(certificateId: controller.text.trim()),
                  ),
                );
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  final dynamic cert;
  final VoidCallback onVerify;

  const _CertificateCard({required this.cert, required this.onVerify});

  @override
  Widget build(BuildContext context) {
    final courseTitle = cert['courseTitle'] ?? cert['course'] ?? cert['courseName'] ?? 'Course';
    final studentName = cert['studentName'] ?? cert['student'] ?? cert['userName'] ?? '';
    final issueDate = cert['issuedDate'] ?? cert['issueDate'] ?? cert['createdAt'] ?? '';
    final certificateId = cert['certificateId'] ?? cert['_id'] ?? cert['id'] ?? '';
    final courseId = cert['courseId'] ?? '';

    String formattedDate = issueDate.toString();
    if (issueDate.toString().isNotEmpty) {
      try {
        final dt = DateTime.parse(issueDate.toString());
        formattedDate = '${dt.day}/${dt.month}/${dt.year}';
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          Text(
            courseTitle.toString(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          if (studentName.toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(studentName.toString(), style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 8),
          if (formattedDate.isNotEmpty)
            Text('Issued: $formattedDate', style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
          if (certificateId.toString().isNotEmpty)
            Text('ID: $certificateId', style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
          const SizedBox(height: 12),
          QrImageView(
            data: 'https://mahad-al-hind.vercel.app/more/certificates/verify?id=$certificateId',
            version: QrVersions.auto,
            size: 100,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onVerify,
                  icon: const Icon(Icons.qr_code, size: 16),
                  label: const Text('View'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Share.share(
                      'Certificate: $courseTitle\n'
                      '${studentName.toString().isNotEmpty ? 'Student: $studentName\n' : ''}'
                      'Verify at: https://mahad-al-hind.vercel.app/more/certificates/verify?id=$certificateId',
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