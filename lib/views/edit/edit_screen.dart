import 'dart:io';
import 'dart:typed_data';
import 'package:ai_image_generator/core/ai_services.dart';
import 'package:ai_image_generator/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';

class EditScreen extends StatefulWidget {
  const EditScreen({super.key});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  final TextEditingController _promptController = TextEditingController();
  final AIService _aiService = AIService();
  final ImagePicker _picker = ImagePicker();

  Uint8List? _sourceImage;
  Uint8List? _resultImage;
  bool _isProcessing = false;
  String? _sourceLabel;



  // Editing presets
  final List<Map<String, dynamic>> _presets = [
    {'label': 'Enhance', 'prompt': 'enhance quality, sharpen, improve details', 'icon': Icons.auto_fix_high},
    {'label': 'Ghibli', 'prompt': 'studio ghibli anime style, soft colors', 'icon': Icons.animation},
    {'label': 'Cyberpunk', 'prompt': 'cyberpunk style, neon lights, futuristic', 'icon': Icons.electric_bolt},
    {'label': 'Vintage', 'prompt': 'vintage retro style, film grain, faded colors', 'icon': Icons.filter_vintage},
    {'label': 'Watercolor', 'prompt': 'watercolor painting style, soft artistic', 'icon': Icons.water_drop},
    {'label': 'Pop Art', 'prompt': 'pop art style, bold colors, comic', 'icon': Icons.color_lens},
  ];



  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        final bytes = await File(picked.path).readAsBytes();
        setState(() {
          _sourceImage = bytes;
          _resultImage = null;
          _sourceLabel = picked.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _applyEdit(String prompt) async {
    if (_sourceImage == null) return;
    setState(() => _isProcessing = true);
    final result = await _aiService.editImage(_sourceImage!, prompt);
    setState(() {
      _resultImage = result;
      _isProcessing = false;
    });
  }

  Future<void> _handleCustomEdit() async {
    final text = _promptController.text.trim();
    if (text.isEmpty || _sourceImage == null) return;
    _promptController.clear();
    await _applyEdit(text);
  }

  Future<void> _saveResult() async {
    if (_resultImage == null) return;
    try {
      final tempDir = await getTemporaryDirectory();
      final path =
          '${tempDir.path}/ai_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(path).writeAsBytes(_resultImage!);
      await Gal.putImage(path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.accentMint, size: 18),
                SizedBox(width: 8),
                Text('Image saved!'),
              ],
            ),
            backgroundColor: AppTheme.bgCardLight,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    if (_sourceImage == null) _buildImagePicker(),
                    if (_sourceImage != null) ...[
                      _buildSelectedImage(),
                      const SizedBox(height: 20),
                      _buildPresetsSection(),
                      const SizedBox(height: 20),
                      _buildCustomPromptSection(),
                      const SizedBox(height: 20),
                    ],
                    if (_resultImage != null || _isProcessing)
                      _buildResultSection(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
            child: const Text('Edit Image',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ),
          const Spacer(),
          if (_sourceImage != null)
            GestureDetector(
              onTap: () => setState(() {
                _sourceImage = null;
                _resultImage = null;
                _sourceLabel = null;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppTheme.error.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close, size: 14, color: AppTheme.error),
                    SizedBox(width: 4),
                    Text('Clear',
                        style: TextStyle(
                            color: AppTheme.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: AppTheme.bgCardLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_photo_alternate_outlined,
              color: AppTheme.textHint, size: 48),
          const SizedBox(height: 16),
          const Text('Select an image to edit',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Choose a picture from your device',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: _buildGalleryUploadButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryUploadButton() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentCyan.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, color: AppTheme.bgDark),
            SizedBox(width: 10),
            Text('Upload from Device Gallery',
                style: TextStyle(
                    color: AppTheme.bgDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(_sourceImage!, fit: BoxFit.cover),
            if (_sourceLabel != null)
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.bgDark.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_sourceLabel!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Styles:',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _presets.map((p) {
            return GestureDetector(
              onTap: _isProcessing
                  ? null
                  : () => _applyEdit(p['prompt']),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.bgCardLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(p['icon'] as IconData,
                        size: 16, color: AppTheme.accentCyan),
                    const SizedBox(width: 8),
                    Text(p['label'],
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCustomPromptSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Custom Edit:',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.bgCardLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: TextFormField(
                  controller: _promptController,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Describe changes...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: IconButton(
                onPressed: _isProcessing ? null : _handleCustomEdit,
                icon: const Icon(Icons.auto_fix_high,
                    color: AppTheme.bgDark, size: 22),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Result:',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            if (_resultImage != null)
              GestureDetector(
                onTap: _saveResult,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.download_rounded,
                          color: AppTheme.bgDark, size: 16),
                      SizedBox(width: 6),
                      Text('Save',
                          style: TextStyle(
                              color: AppTheme.bgDark,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isProcessing)
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.bgCardLight,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                      color: AppTheme.accentCyan, strokeWidth: 3),
                  SizedBox(height: 16),
                  Text('Applying edits...',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
            ),
          )
        else if (_resultImage != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.memory(_resultImage!, fit: BoxFit.cover),
          ),
      ],
    );
  }
}
