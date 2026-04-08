import 'dart:io';
import 'dart:typed_data';
import 'package:ai_image_generator/core/ai_services.dart';
import 'package:ai_image_generator/data/models/promt_model.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _promptController = TextEditingController();
  final AIService _aiService = AIService();
  final List<Prompt> _prompts = [];

  // Track if we are editing an existing image
  Uint8List? _imageToEdit;

  void _handleGenerate() async {
    final text = _promptController.text.trim();
    if (text.isEmpty) return;

    final newPrompt = Prompt(text: text, isLoading: true);
    setState(() {
      _prompts.insert(0, newPrompt);
      _promptController.clear();
    });

    Uint8List? bytes;
    if (_imageToEdit != null) {
      // Logic for Editing
      bytes = await _aiService.editImage(_imageToEdit!, text);
      _imageToEdit = null; // Reset after editing
    } else {
      // Logic for New Generation
      bytes = await _aiService.generateImage(text);
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Saved! ✅")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Studio"),
        actions: [
          if (_imageToEdit != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: InputChip(
                label: const Text("Editing Mode"),
                onDeleted: () {
                  setState(() {
                    _imageToEdit = null;
                  });
                },
                deleteIconColor: Colors.red,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _prompts.length,
              itemBuilder: (context, index) {
                final item = _prompts[index];
                return _buildPromptCard(item);
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _promptController,
              decoration: InputDecoration(
                hintText: _imageToEdit == null
                    ? "Describe a new image..."
                    : "Describe changes to image...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filled(
            onPressed: _handleGenerate,
            icon: Icon(_imageToEdit == null ? Icons.send : Icons.auto_fix_high),
            style: IconButton.styleFrom(backgroundColor: Colors.deepPurple),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptCard(Prompt prompt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              prompt.text,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: prompt.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : prompt.imageBytes != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(16),
                          ),
                          child: Image.memory(
                            prompt.imageBytes!,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: Row(
                            children: [
                              // EDIT BUTTON (Magic Wand)
                              CircleAvatar(
                                backgroundColor: Colors.white,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.auto_fix_high,
                                    color: Colors.deepPurple,
                                  ),
                                  onPressed: () {
                                    setState(
                                      () => _imageToEdit = prompt.imageBytes,
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Image selected for editing! Type your changes.",
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              // DOWNLOAD BUTTON
                              CircleAvatar(
                                backgroundColor: Colors.white,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.download,
                                    color: Colors.black,
                                  ),
                                  onPressed: () => _saveImage(prompt),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : const Center(child: Text("Error")),
            ),
          ),
        ],
      ),
    );
  }
}
