import 'package:flutter/material.dart';

class ArtStyle {
  final String name;
  final String promptSuffix;
  final IconData icon;
  final List<Color> gradientColors;

  const ArtStyle({
    required this.name,
    required this.promptSuffix,
    required this.icon,
    required this.gradientColors,
  });

  static const List<ArtStyle> styles = [
    ArtStyle(
      name: 'Realistic',
      promptSuffix: ', ultra realistic, photorealistic, 8k, high detail',
      icon: Icons.camera_alt_rounded,
      gradientColors: [Color(0xFF0D47A1), Color(0xFF42A5F5)],
    ),
    ArtStyle(
      name: 'Anime',
      promptSuffix: ', anime style, anime art, vibrant colors, manga',
      icon: Icons.auto_awesome,
      gradientColors: [Color(0xFFE91E63), Color(0xFFFF80AB)],
    ),
    ArtStyle(
      name: 'Digital Art',
      promptSuffix: ', digital art, concept art, detailed illustration',
      icon: Icons.brush_rounded,
      gradientColors: [Color(0xFF7C4DFF), Color(0xFFB388FF)],
    ),
    ArtStyle(
      name: '3D Render',
      promptSuffix: ', 3d render, octane render, cinema 4d, unreal engine',
      icon: Icons.view_in_ar_rounded,
      gradientColors: [Color(0xFF00BFA5), Color(0xFF64FFDA)],
    ),
    ArtStyle(
      name: 'Oil Painting',
      promptSuffix: ', oil painting, classical art, canvas texture, masterpiece',
      icon: Icons.palette_rounded,
      gradientColors: [Color(0xFFFF6F00), Color(0xFFFFAB40)],
    ),
    ArtStyle(
      name: 'Watercolor',
      promptSuffix: ', watercolor painting, soft colors, artistic, fluid',
      icon: Icons.water_drop_rounded,
      gradientColors: [Color(0xFF0097A7), Color(0xFF80DEEA)],
    ),
    ArtStyle(
      name: 'Pixel Art',
      promptSuffix: ', pixel art, retro, 16-bit, video game sprite',
      icon: Icons.grid_view_rounded,
      gradientColors: [Color(0xFF388E3C), Color(0xFF81C784)],
    ),
    ArtStyle(
      name: 'Fantasy',
      promptSuffix: ', fantasy art, magical, ethereal, mystical, epic',
      icon: Icons.castle_rounded,
      gradientColors: [Color(0xFF6A1B9A), Color(0xFFCE93D8)],
    ),
    ArtStyle(
      name: 'Cinematic',
      promptSuffix: ', cinematic lighting, dramatic, film still, moody',
      icon: Icons.movie_creation_rounded,
      gradientColors: [Color(0xFF37474F), Color(0xFF90A4AE)],
    ),
    ArtStyle(
      name: 'Sketch',
      promptSuffix: ', pencil sketch, hand drawn, detailed line art',
      icon: Icons.edit_rounded,
      gradientColors: [Color(0xFF455A64), Color(0xFFB0BEC5)],
    ),
  ];
}
