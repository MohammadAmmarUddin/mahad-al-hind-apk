import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/network/dio_client.dart';

class CertificateVerifyPage extends StatefulWidget {
  final String certificateId;
  const CertificateVerifyPage({super.key, required this.certificateId});

  @override
  State<CertificateVerifyPage> createState() => _CertificateVerifyPageState();
}

class _CertificateVerifyPageState extends State<CertificateVerifyPage>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  bool _verified = false;
  String? _error;
  Map<String, dynamic>? _certData;

  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
    _verifyCertificate();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _verifyCertificate() async {
    if (widget.certificateId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'No certificate ID provided';
      });
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final dio = sl<DioClient>();
      final response = await dio.get('/api/certificate/check/${widget.certificateId}');
      final data = response.data;

      Map<String, dynamic>? certInfo;
      if (data is Map) {
        if (data['data'] is Map) {
          certInfo = Map<String, dynamic>.from(data['data']);
        } else if (data['certificate'] is Map) {
          certInfo = Map<String, dynamic>.from(data['certificate']);
        } else if (data['valid'] == true || data['verified'] == true || data['success'] == true) {
          certInfo = Map<String, dynamic>.from(data);
        }
      }

      if (mounted) {
        setState(() {
          _verified = true;
          _certData = certInfo;
          _loading = false;
        });
        _animController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _verified = false;
          _error = 'Certificate not found or invalid';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Certificate')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('Verifying certificate...', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cancel_outlined, size: 60, color: AppColors.error),
              ),
              const SizedBox(height: 24),
              const Text(
                'Certificate Not Found',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.error),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'ID: ${widget.certificateId}',
                style: const TextStyle(color: AppColors.textHint, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() { _loading = true; _error = null; });
                  _verifyCertificate();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Verified state
    final courseTitle = _certData?['courseTitle'] ?? _certData?['course'] ?? _certData?['courseName'] ?? '';
    final studentName = _certData?['studentName'] ?? _certData?['student'] ?? _certData?['userName'] ?? '';
    final issueDate = _certData?['issuedDate'] ?? _certData?['issueDate'] ?? _certData?['createdAt'] ?? '';

    String formattedDate = issueDate.toString();
    if (issueDate.toString().isNotEmpty) {
      try {
        final dt = DateTime.parse(issueDate.toString());
        formattedDate = '${dt.day}/${dt.month}/${dt.year}';
      } catch (_) {}
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.verified, size: 60, color: AppColors.success),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Certificate Verified',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.success),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '✓ Authentic Certificate',
                style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.success.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  if (courseTitle.toString().isEmpty && studentName.toString().isEmpty) ...[
                    Text(
                      'ID: ${widget.certificateId}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                  ],
                  if (courseTitle.toString().isNotEmpty) ...[
                    _infoRow('Course', courseTitle.toString()),
                  ],
                  if (studentName.toString().isNotEmpty) ...[
                    _infoRow('Student', studentName.toString()),
                  ],
                  if (formattedDate.isNotEmpty) ...[
                    _infoRow('Issued', formattedDate),
                  ],
                  _infoRow('Certificate ID', widget.certificateId),
                ],
              ),
            ),
            const SizedBox(height: 20),
            QrImageView(
              data: 'https://mahad-al-hind.vercel.app/more/certificates/verify?id=${widget.certificateId}',
              version: QrVersions.auto,
              size: 140,
            ),
            const SizedBox(height: 16),
            Text(
              'Scan QR to verify',
              style: TextStyle(color: AppColors.textHint, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}