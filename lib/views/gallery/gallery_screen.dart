import 'dart:io';
import 'package:ai_image_generator/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<File> _savedImages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedImages();
  }

  Future<void> _loadSavedImages() async {
    setState(() => _isLoading = true);
    try {
      final tempDir = await getApplicationDocumentsDirectory();
      final dir = Directory(tempDir.path);
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('ai_') && f.path.endsWith('.png'))
          .toList();
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      setState(() {
        _savedImages = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteImage(File file, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Image',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: const Text('Are you sure you want to delete this image?',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await file.delete();
        setState(() => _savedImages.removeAt(index));
      } catch (_) {}
    }
  }

  void _viewImage(File file) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _FullImageView(file: file)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.accentCyan, strokeWidth: 3))
                  : _savedImages.isEmpty
                      ? _buildEmptyState()
                      : _buildGalleryGrid(),
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
            child: Text('My Gallery',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface)),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Text(
              '${_savedImages.length} saved',
              style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor),
              boxShadow: AppTheme.premiumShadow,
            ),
            child: IconButton(
              onPressed: _loadSavedImages,
              icon: const Icon(Icons.refresh_rounded,
                  color: AppTheme.accentCyan, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Icon(Icons.photo_library_outlined,
                color: Theme.of(context).hintColor, size: 36),
          ),
          const SizedBox(height: 20),
          Text('No saved images yet',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            'Your generated artworks will appear here\nonce you save them',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryGrid() {
    return RefreshIndicator(
      onRefresh: _loadSavedImages,
      color: AppTheme.accentCyan,
      backgroundColor: AppTheme.bgCard,
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85),
        itemCount: _savedImages.length,
        itemBuilder: (context, index) {
          final file = _savedImages[index];
          final mod = file.lastModifiedSync();
          final diff = DateTime.now().difference(mod);
          String timeAgo;
          if (diff.inMinutes < 1) {
            timeAgo = 'Just now';
          } else if (diff.inMinutes < 60) {
            timeAgo = '${diff.inMinutes}m ago';
          } else if (diff.inHours < 24) {
            timeAgo = '${diff.inHours}h ago';
          } else {
            timeAgo = '${diff.inDays}d ago';
          }

          return GestureDetector(
            onTap: () => _viewImage(file),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Theme.of(context).dividerColor),
                boxShadow: AppTheme.premiumShadow,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16)),
                      child: Image.file(file,
                          fit: BoxFit.cover, width: double.infinity),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            color: Theme.of(context).hintColor, size: 12),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(timeAgo,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  fontSize: 11)),
                        ),
                        GestureDetector(
                          onTap: () => _deleteImage(file, index),
                          child: Icon(Icons.delete_outline_rounded,
                              color: Theme.of(context).hintColor, size: 18),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FullImageView extends StatelessWidget {
  final File file;
  const _FullImageView({required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              try {
                await Gal.putImage(file.path);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Saved to device gallery!'),
                      backgroundColor: Theme.of(context).cardColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              } catch (_) {}
            },
            icon: const Icon(Icons.save_alt_rounded,
                color: AppTheme.accentCyan),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.file(file, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
