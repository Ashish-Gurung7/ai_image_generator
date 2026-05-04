import 'dart:io';
import 'dart:typed_data';
import 'package:ai_image_generator/core/ai_services.dart';
import 'package:ai_image_generator/core/app_theme.dart';
import 'package:ai_image_generator/data/models/art_style.dart';
import 'package:ai_image_generator/data/models/promt_model.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final TextEditingController _promptController = TextEditingController();
  final AIService _aiService = AIService();
  final List<Prompt> _prompts = [];
  final ScrollController _scrollController = ScrollController();

  int _selectedStyleIndex = 0;
  int _selectedAspectIndex = 0;
  Uint8List? _imageToEdit;

  // Aspect ratio options
  final List<Map<String, dynamic>> _aspectRatios = [
    {'label': '1:1', 'icon': Icons.crop_square_rounded},
    {'label': '2:3', 'icon': Icons.crop_portrait_rounded},
    {'label': '3:2', 'icon': Icons.crop_landscape_rounded},
  ];

  void _handleGenerate() async {
    final text = _promptController.text.trim();
    if (text.isEmpty) return;

    // Append the art style suffix to the prompt
    final style = ArtStyle.styles[_selectedStyleIndex];
    final enhancedPrompt = text + style.promptSuffix;

    final newPrompt = Prompt(text: text, isLoading: true);
    setState(() {
      _prompts.insert(0, newPrompt);
      _promptController.clear();
    });

    Uint8List? bytes;
    if (_imageToEdit != null) {
      bytes = await _aiService.editImage(_imageToEdit!, enhancedPrompt);
      _imageToEdit = null;
    } else {
      bytes = await _aiService.generateImage(enhancedPrompt);
    }

    setState(() {
      final index = _prompts.indexOf(newPrompt);
      if (index != -1) {
        _prompts[index] = Prompt(
          text: text,
          imageBytes: bytes,
          isLoading: false,
        );
      }
    });
  }

  Future<void> _saveImage(Prompt prompt) async {
    if (prompt.imageBytes == null) return;
    try {
      final tempDir = await getTemporaryDirectory();
      final path =
          '${tempDir.path}/ai_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(path).writeAsBytes(prompt.imageBytes!);
      await Gal.putImage(path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.accentMint, size: 20),
                SizedBox(width: 10),
                Text('Image saved to gallery!'),
              ],
            ),
            backgroundColor: AppTheme.bgCardLight,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: _prompts.isEmpty ? _buildCreateView() : _buildResultsView(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── APP BAR ──────────────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (bounds) =>
                AppTheme.primaryGradient.createShader(bounds),
            child: const Text(
              'Create Art',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Spacer(),
          if (_imageToEdit != null)
            GestureDetector(
              onTap: () => setState(() => _imageToEdit = null),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accentPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.accentPurple.withOpacity(0.5),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_fix_high,
                        size: 16, color: AppTheme.accentPurple),
                    SizedBox(width: 6),
                    Text(
                      'Editing',
                      style: TextStyle(
                        color: AppTheme.accentPurple,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.close, size: 14, color: AppTheme.accentPurple),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── CREATE VIEW (shown when no results) ─────────────────
  Widget _buildCreateView() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          _buildPromptSection(),
          const SizedBox(height: 24),
          _buildAspectRatioSection(),
          const SizedBox(height: 28),
          _buildArtStyleSection(),
          const SizedBox(height: 28),
          _buildGenerateButton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── RESULTS VIEW (shown when images exist) ──────────────
  Widget _buildResultsView() {
    return Column(
      children: [
        // Compact input row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildCompactInput(),
        ),
        const SizedBox(height: 8),
        // Style chip row
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: ArtStyle.styles.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final style = ArtStyle.styles[index];
              final selected = index == _selectedStyleIndex;
              return GestureDetector(
                onTap: () => setState(() => _selectedStyleIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? LinearGradient(colors: style.gradientColors)
                        : null,
                    color: selected ? null : AppTheme.bgCardLight,
                    borderRadius: BorderRadius.circular(20),
                    border: selected
                        ? null
                        : Border.all(color: AppTheme.borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        style.icon,
                        size: 14,
                        color: selected
                            ? Colors.white
                            : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        style.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _prompts.length,
            itemBuilder: (context, index) =>
                _buildPromptCard(_prompts[index]),
          ),
        ),
      ],
    );
  }

  // ─── PROMPT INPUT SECTION ─────────────────────────────────
  Widget _buildPromptSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Enter prompt:',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            GestureDetector(
              onTap: () => _promptController.clear(),
              child: ShaderMask(
                shaderCallback: (bounds) =>
                    AppTheme.primaryGradient.createShader(bounds),
                child: const Text(
                  'Clear',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.bgCardLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: TextFormField(
            controller: _promptController,
            maxLines: 4,
            minLines: 3,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: _imageToEdit == null
                  ? 'Describe your art in as much detail as you like...'
                  : 'Describe changes to the image...',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  // ─── ASPECT RATIO SECTION ────────────────────────────────
  Widget _buildAspectRatioSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_aspectRatios.length, (index) {
        final isSelected = index == _selectedAspectIndex;
        return GestureDetector(
          onTap: () => setState(() => _selectedAspectIndex = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.accentCyan.withOpacity(0.12)
                  : AppTheme.bgCardLight,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isSelected ? AppTheme.accentCyan : AppTheme.borderColor,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _aspectRatios[index]['icon'],
                  size: 18,
                  color: isSelected
                      ? AppTheme.accentCyan
                      : AppTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  _aspectRatios[index]['label'],
                  style: TextStyle(
                    color: isSelected
                        ? AppTheme.accentCyan
                        : AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ─── ART STYLE SECTION ──────────────────────────────────
  Widget _buildArtStyleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose art style:',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: ArtStyle.styles.length,
          itemBuilder: (context, index) {
            final style = ArtStyle.styles[index];
            final isSelected = index == _selectedStyleIndex;

            return GestureDetector(
              onTap: () => setState(() => _selectedStyleIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: style.gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : AppTheme.bgCardLight,
                  borderRadius: BorderRadius.circular(14),
                  border: isSelected
                      ? null
                      : Border.all(color: AppTheme.borderColor),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: style.gradientColors.first.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      style.icon,
                      size: 20,
                      color: isSelected
                          ? Colors.white
                          : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        style.name,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ─── GENERATE BUTTON ────────────────────────────────────
  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentCyan.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _handleGenerate,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _imageToEdit != null
                    ? Icons.auto_fix_high
                    : Icons.auto_awesome,
                color: AppTheme.bgDark,
              ),
              const SizedBox(width: 10),
              Text(
                _imageToEdit != null ? 'Apply Changes' : 'Generate',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.bgDark,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── COMPACT INPUT (for results view) ───────────────────
  Widget _buildCompactInput() {
    return Row(
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
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: _imageToEdit == null
                    ? 'Describe your art...'
                    : 'Describe changes...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentCyan.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            onPressed: _handleGenerate,
            icon: Icon(
              _imageToEdit == null ? Icons.send_rounded : Icons.auto_fix_high,
              color: AppTheme.bgDark,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  // ─── PROMPT / IMAGE CARD ────────────────────────────────
  Widget _buildPromptCard(Prompt prompt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Prompt text header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.format_quote_rounded,
                    color: AppTheme.accentCyan, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    prompt.text,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Image area
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(18),
                ),
              ),
              child: prompt.isLoading
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppTheme.accentCyan,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Creating your art...',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : prompt.imageBytes != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(18),
                              ),
                              child: Image.memory(
                                prompt.imageBytes!,
                                fit: BoxFit.cover,
                              ),
                            ),
                            // Action buttons overlay
                            Positioned(
                              bottom: 12,
                              right: 12,
                              child: Row(
                                children: [
                                  _buildActionButton(
                                    icon: Icons.auto_fix_high,
                                    tooltip: 'Edit this image',
                                    onTap: () {
                                      setState(() =>
                                          _imageToEdit = prompt.imageBytes);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: const Row(
                                            children: [
                                              Icon(Icons.auto_fix_high,
                                                  color: AppTheme.accentPurple,
                                                  size: 18),
                                              SizedBox(width: 8),
                                              Text(
                                                  'Image ready for editing!'),
                                            ],
                                          ),
                                          backgroundColor:
                                              AppTheme.bgCardLight,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 10),
                                  _buildActionButton(
                                    icon: Icons.download_rounded,
                                    tooltip: 'Save to gallery',
                                    onTap: () => _saveImage(prompt),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline_rounded,
                                  color: AppTheme.error.withOpacity(0.7),
                                  size: 36),
                              const SizedBox(height: 10),
                              const Text(
                                'Failed to generate',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppTheme.bgDark.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
