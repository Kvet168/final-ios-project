import 'package:flutter/services.dart';

/// Photos are bundled with the app (assets/img for full size, assets/img/t for thumbnails).
/// The API still returns web URLs for every photo; this maps a URL to its bundled file so images
/// appear instantly and work offline. URLs we do not have locally fall back to the network.
class ImageCatalog {
  static final Set<String> _full = {};
  static final Set<String> _thumb = {};

  static Future<void> load() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      for (final a in manifest.listAssets()) {
        if (a.startsWith('assets/img/t/')) {
          _thumb.add(a.substring('assets/img/t/'.length));
        } else if (a.startsWith('assets/img/')) {
          _full.add(a.substring('assets/img/'.length));
        }
      }
    } catch (_) {
      // Without the manifest every image simply loads from the network.
    }
  }

  static String? _name(String? url) {
    if (url == null || !url.contains('/img/')) return null;
    final n = url.split('?').first.split('/').last;
    return n.endsWith('.jpg') ? n : null;
  }

  /// Bundled asset path for [url], or null when the photo is not bundled.
  static String? assetFor(String? url, {bool full = false}) {
    final n = _name(url);
    if (n == null) return null;
    if (!full && _thumb.contains(n)) return 'assets/img/t/$n';
    if (_full.contains(n)) return 'assets/img/$n';
    if (_thumb.contains(n)) return 'assets/img/t/$n';
    return null;
  }

  static int get count => _full.length;
}
