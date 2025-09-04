import 'package:flutter/material.dart';

/// A reusable heart (favorite) icon that can be toggled.
/// - [isFavorite] controls the filled/outlined state.
/// - [onPressed] is called when the icon is tapped.
class FavoriteIcon extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onPressed;
  final Key? testKey;

  const FavoriteIcon({
    super.key,
    required this.isFavorite,
    required this.onPressed,
    this.testKey,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        key: testKey,
        isFavorite ? Icons.favorite : Icons.favorite_border,
        color: isFavorite ? Colors.red : Colors.grey,
      ),
      onPressed: onPressed,
    );
  }
}
