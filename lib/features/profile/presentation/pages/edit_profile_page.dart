import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _firstnameCtrl = TextEditingController();
  final _lastnameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _batchCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  String? _photoUrl;
  File? _selectedImage;
  bool _loading = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _loadUserData();
      _initialized = true;
    }
  }

  void _loadUserData() {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    _firstnameCtrl.text = user.firstname ?? '';
    _lastnameCtrl.text = user.lastname ?? '';
    _emailCtrl.text = user.email ?? '';
    _phoneCtrl.text = user.phone ?? '';
    _batchCtrl.text = user.batch ?? '';
    _addressCtrl.text = user.address ?? '';
    _cityCtrl.text = user.city ?? '';
    _countryCtrl.text = user.country ?? '';
    _photoUrl = user.photo;
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Camera'), onTap: () => Navigator.pop(ctx, ImageSource.camera)),
            ListTile(leading: const Icon(Icons.photo_library), title: const Text('Gallery'), onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
          ],
        ),
      ),
    );
    if (source == null) return;
    final file = await ref.read(fileUploadServiceProvider).pickImage(source: source);
    if (file != null) {
      setState(() { _selectedImage = file; });
    }
  }

  Future<String?> _uploadPhoto() async {
    if (_selectedImage == null) return _photoUrl;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading photo...'), backgroundColor: AppColors.info));
    final result = await ref.read(fileUploadServiceProvider).uploadToCloudinary(_selectedImage!, folder: 'profile_pics');
    if (result != null) return result.url;
    return _photoUrl;
  }

  Future<void> _saveProfile() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    setState(() { _loading = true; });
    try {
      final newPhotoUrl = await _uploadPhoto();

      final data = {
        'firstname': _firstnameCtrl.text.trim(),
        'lastname': _lastnameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'batch': _batchCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'country': _countryCtrl.text.trim(),
        if (newPhotoUrl != null && newPhotoUrl.isNotEmpty) 'img': newPhotoUrl,
      };

      await ref.read(dioClientProvider).patch('/api/user/updateUser/${user.id}', data: data);

      setState(() { _loading = false; });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!'), backgroundColor: AppColors.success));
        ref.invalidate(currentUserProvider);
        context.pop();
      }
    } catch (e) {
      setState(() { _loading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  void dispose() {
    _firstnameCtrl.dispose();
    _lastnameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _batchCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('Not logged in'));
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.primarySurface,
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!)
                            : (user.photo != null && user.photo!.isNotEmpty)
                                ? NetworkImage(user.photo!) as ImageProvider
                                : null,
                        child: (_selectedImage == null && (user.photo == null || user.photo!.isEmpty))
                            ? Text(
                                user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
                                style: const TextStyle(fontSize: 36, color: AppColors.primary, fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text('Tap to change photo', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                const SizedBox(height: 24),
                _field('First Name', _firstnameCtrl, Icons.person_outlined),
                const SizedBox(height: 14),
                _field('Last Name', _lastnameCtrl, Icons.person_outlined),
                const SizedBox(height: 14),
                _field('Email', _emailCtrl, Icons.email_outlined, readOnly: true),
                const SizedBox(height: 14),
                _field('Phone', _phoneCtrl, Icons.phone_outlined, keyboard: TextInputType.phone),
                const SizedBox(height: 14),
                _field('Batch', _batchCtrl, Icons.class_outlined, hint: 'e.g. 2025-A'),
                const SizedBox(height: 14),
                _field('Address', _addressCtrl, Icons.location_on_outlined),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: _field('City', _cityCtrl, Icons.location_city_outlined)),
                  const SizedBox(width: 12),
                  Expanded(child: _field('Country', _countryCtrl, Icons.public_outlined)),
                ]),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: _loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error')),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon, {String? hint, TextInputType? keyboard, bool readOnly = false}) {
    return TextField(
      controller: ctrl,
      readOnly: readOnly,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: readOnly ? AppColors.surfaceVariant.withOpacity(0.5) : AppColors.surfaceVariant,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      ),
    );
  }
}
