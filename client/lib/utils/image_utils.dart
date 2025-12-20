import 'package:flutter/material.dart';

class ImageUtils {
  /// Default profile icon - uses local asset for faster loading
  static const String defaultProfileIconUrl = 'assets/images/chefs_hat.png';

  /// Determines if the given path is a network URL
  static bool isNetworkUrl(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  /// Determines if the given path is an asset path
  static bool isAssetPath(String path) {
    return path.startsWith('assets/') || path.startsWith('images/');
  }

  /// Determines if the given path is a local file
  static bool isLocalFile(String path) {
    return path.startsWith('file://') ||
        (!path.startsWith('http') &&
            !path.startsWith('assets/') &&
            !path.startsWith('images/'));
  }

  /// Get a fallback image URL when the original image fails to load
  static String? getFallbackImageUrl(String? originalUrl) {
    // Return null instead of placeholder - let the UI handle empty images
    return null;
  }

  /// Check if an image URL is valid
  static bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;

    // Check if it's a valid URL
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Builds a profile image widget that handles both network URLs and local assets
  static Widget buildProfileImage({
    required String? imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? errorWidget,
  }) {
    final url = imageUrl ?? defaultProfileIconUrl;
    
    if (isAssetPath(url)) {
      return Image.asset(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => errorWidget ?? 
          Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: const Icon(Icons.person, color: Colors.grey),
          ),
      );
    } else {
      return Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => errorWidget ??
          Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: const Icon(Icons.person, color: Colors.grey),
          ),
      );
    }
  }
}
