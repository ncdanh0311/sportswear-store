import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  final String src;
  final BoxFit fit;
  final double? width;
  final double? height;

  const ProductImage({
    super.key,
    required this.src,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
  });

  bool get _isNetwork => src.startsWith('http://') || src.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    final image = _isNetwork
        ? Image.network(
            src,
            fit: fit,
            width: width,
            height: height,
            errorBuilder: (context, error, stackTrace) {
              return _fallback();
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _fallback(isLoading: true);
            },
          )
        : Image.asset(
            src,
            fit: fit,
            width: width,
            height: height,
            errorBuilder: (context, error, stackTrace) => _fallback(),
          );

    return image;
  }

  Widget _fallback({bool isLoading = false}) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }
}
