import 'package:flutter/material.dart';

import '../../../core/theme/wask_theme.dart';

class WaskProductImage extends StatelessWidget {
  const WaskProductImage({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.fit = BoxFit.contain,
    this.fallbackIconSize = 32,
  });

  final String? imageUrl;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;
  final BoxFit fit;
  final double fallbackIconSize;

  @override
  Widget build(BuildContext context) {
    final trimmed = imageUrl?.trim();
    final hasNetworkUrl = trimmed != null &&
        (trimmed.startsWith('http://') || trimmed.startsWith('https://'));

    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        width: width,
        height: height,
        color: WaskColors.surfaceElevated,
        child: hasNetworkUrl
            ? Image.network(
                trimmed,
                fit: fit,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }
                  return _fallbackWidget(showProgress: true);
                },
                errorBuilder: (_, __, ___) => _fallbackWidget(),
              )
            : _fallbackWidget(),
      ),
    );
  }

  Widget _fallbackWidget({bool showProgress = false}) {
    return Container(
      color: WaskColors.surfaceElevated,
      alignment: Alignment.center,
      child: showProgress
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: WaskColors.electricBlue.withOpacity(0.65),
              ),
            )
          : Icon(
              Icons.local_bar_rounded,
              size: fallbackIconSize,
              color: WaskColors.electricBlue,
            ),
    );
  }
}
