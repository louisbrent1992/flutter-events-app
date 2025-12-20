import 'package:flutter/material.dart';
import 'banner_ad.dart';
import 'offline_banner.dart';

class PersistentBannerLayout extends StatelessWidget {
  final Widget child;

  const PersistentBannerLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final routeName = ModalRoute.of(context)?.settings.name ?? '';
    return Stack(
      children: [
        // Main content
        child,
        // Offline banner at the top
        const Positioned(top: 0, left: 0, right: 0, child: OfflineBanner()),
        // Banner ad at the bottom (hide on screens that use inline ads / dense layouts)
        if (routeName != '/eventDetail' &&
            routeName != '/myEvents' &&
            routeName != '/createEvent' &&
            routeName != '/importEvent' &&
            routeName != '/planner' &&
            routeName != '/home' &&
            routeName != '/settings' &&
            routeName != '/subscription')
          const BannerAdWidget(),
      ],
    );
  }
}
