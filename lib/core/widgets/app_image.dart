import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_colors.dart';

class AppImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Color? placeholderColor;
  final Widget? placeholder;
  final Widget? errorWidget;
  final String? assetPath;

  const AppImage({
    super.key,
    this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderColor,
    this.placeholder,
    this.errorWidget,
    this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    final placeholderWidget = placeholder ??
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: placeholderColor ?? AppColors.surfaceVariant,
              borderRadius: borderRadius,
            ),
          ),
        );

    final errorWidgetFinal = errorWidget ??
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: borderRadius,
          ),
          child: const Icon(
            Icons.image_not_supported_outlined,
            color: AppColors.textHint,
            size: 32,
          ),
        );

    Widget image;
    if (assetPath != null && assetPath!.isNotEmpty) {
      image = Image.asset(
        assetPath!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => errorWidgetFinal,
      );
    } else if (url != null && url!.isNotEmpty) {
      image = CachedNetworkImage(
        imageUrl: url!,
        width: width,
        height: height,
        fit: fit,
        placeholder: (_, __) => placeholderWidget,
        errorWidget: (_, __, ___) => errorWidgetFinal,
        memCacheWidth: width?.toInt(),
        memCacheHeight: height?.toInt(),
      );
    } else {
      return placeholderWidget;
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }
    return image;
  }
}
