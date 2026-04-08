import 'dart:typed_data';

class Prompt {
  final String text;
  final Uint8List? imageBytes;
  final DateTime timestamp;
  final bool isLoading;

  Prompt({required this.text, this.imageBytes, this.isLoading = false})
    : timestamp = DateTime.now();
}
