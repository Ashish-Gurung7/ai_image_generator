import 'dart:io';
import 'dart:typed_data';
import 'package:ai_image_generator/core/ai_services.dart';
import 'package:ai_image_generator/core/app_theme.dart';
import 'package:ai_image_generator/data/models/art_style.dart';
import 'package:ai_image_generator/data/models/promt_model.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_image_generator/services/theme_service.dart';
import 'package:khalti_flutter/khalti_flutter.dart';
import 'package:ai_image_generator/services/payment_service.dart';
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
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isPremium = prefs.getBool('isPremium') ?? false;
    });
  }
  void _handleGenerate() async {
    final text = _promptController.text.trim();
    if (text.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    int generateCount = prefs.getInt('generateCount') ?? 0;
    int resetTime = prefs.getInt('generateCountResetTime') ?? 0;
    bool isPremium = prefs.getBool('isPremium') ?? false;

    // Reset count if 24 hours have passed
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - resetTime >= 24 * 60 * 60 * 1000) {
      generateCount = 0;
      await prefs.setInt('generateCount', 0);
      await prefs.setInt('generateCountResetTime', now);
    }

    if (!isPremium && generateCount >= 3) {
      _showPremiumDialog(resetTime);
      return;
    }

    if (!isPremium) {
      if (generateCount == 0) {
        await prefs.setInt('generateCountResetTime', now);
      }
      await prefs.setInt('generateCount', generateCount + 1);
    }

    // Append the art style suffix to the prompt
    final style = ArtStyle.styles[_selectedStyleIndex];
    final enhancedPrompt = text + style.promptSuffix;

    final newPrompt = Prompt(text: text, isLoading: true);
    setState(() {
      _prompts.insert(0, newPrompt);
      _promptController.clear();
    });

    Uint8List? bytes = await _aiService.generateImage(enhancedPrompt);

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

  void _showPremiumDialog(int resetTime) {
    final resetAt = DateTime.fromMillisecondsSinceEpoch(resetTime + 24 * 60 * 60 * 1000);
    final remaining = resetAt.difference(DateTime.now());
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    final timeLeft = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Daily Limit Reached', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          content: Text(
            'You have used all 3 free generations for today. Your limit resets in $timeLeft.\n\nPurchase premium for unlimited generations!',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textHint)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentCyan,
                foregroundColor: AppTheme.bgDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(context);
                _initiateKhaltiPayment();
              },
              child: const Text('Go Premium (Rs. 10)'),
            ),
          ],
        );
      },
    );
  }

  void _initiateKhaltiPayment() {
    PaymentService.initiatePremiumPayment(
      context: context,
      onPaymentSuccess: () {
        setState(() {
          _isPremium = true;
        });
      },
    );
  }

  Future<void> _saveImage(Prompt prompt) async {
    if (prompt.imageBytes == null) return;
    try {
      final tempDir = await getApplicationDocumentsDirectory();
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: AppTheme.error),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: _prompts.isEmpty
                  ? _buildCreateView()
                  : _buildResultsView(),
            ),
          ],
        ),
      ),
    );
  }

  //APP BAR
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (bounds) =>
                AppTheme.primaryGradient.createShader(bounds),
            child: GestureDetector(
              onLongPress: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isPremium', false);
                await prefs.setInt('generateCount', 0);
                setState(() => _isPremium = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dev: Premium reset!')),
                );
              },
              child: Center(
                child: Text(
                  'Create Art',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => ThemeService.toggleTheme(),
            icon: Icon(
              ThemeService.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (!_isPremium)
            GestureDetector(
              onTap: _initiateKhaltiPayment,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.star_rounded, color: AppTheme.bgDark, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Go Premium',
                      style: TextStyle(
                        color: AppTheme.bgDark,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
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
                        color: selected ? Colors.white : AppTheme.textSecondary,
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
            itemBuilder: (context, index) => _buildPromptCard(_prompts[index]),
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
            Text(
              'Enter prompt:',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
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
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: TextFormField(
            controller: _promptController,
            maxLines: 4,
            minLines: 3,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: 'Describe your art in as much detail as you like...',
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              filled: false,
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



  // ─── ART STYLE SECTION ──────────────────────────────────
  Widget _buildArtStyleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose art style:',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
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
                  color: isSelected ? null : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: isSelected
                      ? null
                      : Border.all(color: Theme.of(context).dividerColor),
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
                      color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        style.name,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
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
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.glowShadow,
      ),
      child: ElevatedButton(
        onPressed: _handleGenerate,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, color: Colors.white, size: 22),
            SizedBox(width: 12),
            Text(
              'Generate Masterpiece',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
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
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: TextFormField(
              controller: _promptController,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Describe your art...',
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppTheme.glowShadow,
          ),
          child: IconButton(
            onPressed: _handleGenerate,
            icon: const Icon(
              Icons.send_rounded,
              color: Colors.white,
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
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: AppTheme.premiumShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Prompt text header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Icon(
                  Icons.format_quote_rounded,
                  color: AppTheme.accentCyan,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    prompt.text,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
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
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
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
                          Icon(
                            Icons.error_outline_rounded,
                            color: AppTheme.error.withOpacity(0.7),
                            size: 36,
                          ),
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
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
