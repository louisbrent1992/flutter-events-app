import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import 'package:eventease/components/persistent_banner_layout.dart';
import 'package:eventease/firebase_options.dart';
import 'package:eventease/screens/home_screen.dart';
import 'package:eventease/screens/settings_screen.dart';
import 'package:eventease/screens/auth/login_screen.dart';
import 'package:eventease/screens/auth/register_screen.dart';
import 'package:eventease/screens/auth/auth_required_screen.dart';
import 'package:eventease/screens/subscription_screen.dart';
import 'package:eventease/screens/splash_screen.dart';
import 'package:eventease/theme/theme.dart';
import 'package:eventease/providers/auth_provider.dart';
import 'package:eventease/providers/user_profile_provider.dart';
import 'package:eventease/providers/theme_provider.dart';
import 'package:eventease/providers/event_provider.dart';
import 'package:eventease/providers/subscription_provider.dart';
import 'package:eventease/providers/dynamic_ui_provider.dart';
import 'package:eventease/components/dynamic_background.dart';
import 'package:eventease/services/event_service.dart';
import 'package:eventease/models/event.dart';
import 'package:eventease/screens/my_events_screen.dart';
import 'package:eventease/providers/discover_provider.dart';
import 'package:eventease/providers/collection_provider.dart';
import 'package:eventease/screens/create_event_screen.dart';
import 'package:eventease/screens/event_detail_screen.dart';
import 'package:eventease/screens/import_event_screen.dart';
import 'package:eventease/screens/ai_planner_screen.dart';
import 'package:eventease/screens/discover_events_screen.dart';
import 'package:eventease/screens/event_collections_screen.dart';
import 'package:eventease/screens/collection_detail_screen.dart';
import 'package:eventease/screens/add_events_to_collection_screen.dart';
import 'package:eventease/providers/generated_plan_provider.dart';
import 'package:eventease/screens/generated_plans_screen.dart';
import 'package:eventease/screens/generated_plan_detail_screen.dart';
import 'package:eventease/screens/random_event_screen.dart';
import 'package:eventease/screens/map_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:share_handler/share_handler.dart';
import 'package:eventease/services/permission_service.dart';
import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'dart:convert';
import 'package:eventease/services/notification_scheduler.dart';
import 'package:eventease/providers/connectivity_provider.dart';
import 'package:flutter/services.dart';
import 'package:eventease/utils/snackbar_helper.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Route<dynamic> _blockedAuthRoute(RouteSettings settings) {
  // Push a zero-size, transparent route and immediately pop it so the user
  // remains on the current screen, while still showing feedback.
  return PageRouteBuilder(
    settings: settings,
    opaque: false,
    barrierColor: Colors.transparent,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    pageBuilder: (context, animation, secondaryAnimation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = navigatorKey.currentContext;
        if (ctx == null) return;
        SnackBarHelper.showInfo(
          ctx,
          'Sign in to use this feature.',
          action: SnackBarAction(
            label: 'Sign in',
            onPressed: () {
              navigatorKey.currentState?.pushNamed(
                '/login',
                arguments: {'redirectRoute': settings.name},
              );
            },
          ),
        );

        // Cancel the navigation (keep the user where they are)
        navigatorKey.currentState?.pop();
      });
      return const SizedBox.shrink();
    },
  );
}

final kWebRecaptchaSiteKey = '6Lemcn0dAAAAABLkf6aiiHvpGD6x-zF3nOSDU2M8';

// Debug flag to disable ads for screenshots - set to false to show ads in testing
const bool hideAds = false;

// Push notifications: background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

/// Initializes the app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable edge-to-edge mode for Android 15+ compliance
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Initialize MobileAds with test device configuration
  await MobileAds.instance.initialize();

  // Configure test devices
  MobileAds.instance.updateRequestConfiguration(
    RequestConfiguration(
      testDeviceIds: ['02A173696D1667C3CA2143D2D279EE38'],
      tagForChildDirectedTreatment: TagForChildDirectedTreatment.unspecified,
      tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
    ),
  );

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize timezone database
  tz.initializeTimeZones();
  try {
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    final String timezoneName = tzInfo.identifier;
    tz.setLocalLocation(tz.getLocation(timezoneName));
  } catch (_) {}

  // Set background handler early
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize Firebase App Check
  if (kDebugMode) {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );
  } else {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.deviceCheck,
    );
  }

  await Hive.initFlutter();
  await Hive.openBox('preferences');

  // EventEase: legacy app-era caching/tutorial/gamification services removed.

  runApp(MyApp(Key('key')));
}

/// Platform-aware scroll behavior
class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class MyApp extends StatefulWidget {
  const MyApp(Key? key) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();

  static RouteObserver<PageRoute> get routeObserver =>
      _MyAppState.routeObserver;
}

String? getPendingSharedUrl() => _MyAppState._getPendingSharedUrl();

String? getPendingNotificationPayload() =>
    _MyAppState._getPendingNotificationPayload();

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  StreamSubscription<SharedMedia>? _mediaStreamSub;
  StreamSubscription<Uri>? _linkStreamSub;
  final PermissionService _permissionService = PermissionService();
  String? _lastHandledShareUrl;
  DateTime? _lastHandledAt;
  static String? _pendingSharedUrl;
  static String? _processedInitialUrl;
  static String? _pendingNotificationPayload;
  NotificationResponse? _lastNotificationResponse;
  bool _isHandlingNotification = false;

  static final RouteObserver<PageRoute> routeObserver =
      RouteObserver<PageRoute>();
  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'eventease_general',
        'General',
        description: 'General notifications',
        importance: Importance.high,
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initReceiveSharing();
    _initDeepLinkHandling();
    _initPushNotifications();
    _requestInitialPermissions();
  }

  // Note: This method is kept for potential cold start handling.
  // With the AppDelegate fix, onDidReceiveNotificationResponse handles most cases.
  // getNotificationAppLaunchDetails() is only intended for Cold Starts (app terminated).
  // ignore: unused_element
  @pragma('vm:entry-point')
  Future<void> _checkForPendingNotificationResponse() async {
    try {
      final details =
          await _localNotifications.getNotificationAppLaunchDetails();

      if (details != null &&
          details.didNotificationLaunchApp &&
          details.notificationResponse != null) {
        final response = details.notificationResponse!;
        final payload = response.payload;

        if (_lastNotificationResponse?.payload != payload &&
            payload != null &&
            payload.isNotEmpty) {
          _handleNotificationNavigation(payload);
          _lastNotificationResponse = response;
        }
      }
    } catch (e) {
      debugPrint('Error checking for pending notification: $e');
    }
  }

  Future<void> _requestInitialPermissions() async {
    await _permissionService.requestNotificationPermission();
    // Note: Removed exact alarm permission request as we're using inexact alarms
  }

  void _initDeepLinkHandling() {
    try {
      _handleInitialUrlScheme();
    } catch (e) {
      debugPrint('Error initializing deep link handling: $e');
    }
  }

  Future<void> _initPushNotifications() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.setAutoInitEnabled(true);
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      final token = await messaging.getToken();
      if (kDebugMode) {
        debugPrint('FCM token: ${token ?? 'null'}');
      }

      const androidInit = AndroidInitializationSettings(
        '@drawable/ic_notification',
      );
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // --- FIX: Check if app was launched by Local Notification (Cold Start) ---
      // This must be checked BEFORE initializing the plugin
      final notificationAppLaunchDetails =
          await _localNotifications.getNotificationAppLaunchDetails();

      if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
        final payload =
            notificationAppLaunchDetails!.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) {
          // Unify with the existing FCM pending payload variable
          // SplashScreen will consume this and handle navigation
          _pendingNotificationPayload = payload;
        }
      }
      // --- FIX END ---

      await _localNotifications.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
        onDidReceiveNotificationResponse: (resp) {
          // Only handle navigation here if the app is ALREADY running (not cold start)
          // For cold starts, _pendingNotificationPayload is set above and SplashScreen handles it
          if (navigatorKey.currentState == null) {
            // App is still initializing, skip navigation (SplashScreen will handle it)
            return;
          }

          // Prevent duplicate handling if already processing
          if (_isHandlingNotification) {
            return;
          }

          _lastNotificationResponse = resp;
          final payload = resp.payload;
          if (payload != null && payload.isNotEmpty) {
            // Check if this is the same payload we're already handling from splash
            if (payload == _pendingNotificationPayload) {
              // Splash screen will handle this, skip duplicate navigation
              _pendingNotificationPayload = null;
              return;
            }

            _isHandlingNotification = true;
            _handleNotificationNavigation(payload);
            _isHandlingNotification = false;
          }
        },
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_androidChannel);

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      NotificationScheduler.init(_localNotifications);

      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen((message) {
        final notif = message.notification;
        if (notif != null) {
          final Map<String, dynamic> args = {};
          if (message.data['eventId'] != null) {
            args['eventId'] = message.data['eventId'];
          }
          if (message.data['query'] != null || message.data['tag'] != null) {
            args['query'] =
                (message.data['query'] as String?) ??
                (message.data['tag'] as String?) ??
                '';
          }

          final payload = jsonEncode({
            'route': (message.data['route'] as String?) ?? '/home',
            'args': args,
          });

          _localNotifications.show(
            notif.hashCode,
            notif.title,
            notif.body,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'eventease_general',
                'General',
                importance: Importance.high,
                priority: Priority.high,
              ),
              iOS: DarwinNotificationDetails(),
            ),
            payload: payload,
          );
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        final payload = jsonEncode({
          'route': message.data['route'] ?? '/home',
          'args': message.data['args'] ?? {},
        });
        _handleNotificationNavigation(payload);
      });

      final initialMsg = await messaging.getInitialMessage();
      if (initialMsg != null) {
        final payload = jsonEncode({
          'route': initialMsg.data['route'] ?? '/home',
          'args': initialMsg.data['args'] ?? {},
        });
        _pendingNotificationPayload = payload;
      }

      // EventEase: category-based legacy notification schedules removed.
    } catch (e) {
      debugPrint('Push notification init error: $e');
    }
  }

  void _handleNotificationNavigation(String payload) {
    try {
      final obj = jsonDecode(payload) as Map<String, dynamic>;
      final route = obj['route'] as String?;
      final args = obj['args'] as Map<String, dynamic>?;

      if (route == null || route.isEmpty) {
        return;
      }

      _waitForNavigatorAndNavigateToRoute(route, args);
    } catch (e) {
      _waitForNavigatorAndNavigateToRoute(payload, null);
    }
  }

  void _waitForNavigatorAndNavigateToRoute(
    String route,
    Map<String, dynamic>? args,
  ) {
    if (navigatorKey.currentState != null) {
      _performNavigation(route, args);
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigatorKey.currentState != null) {
        _performNavigation(route, args);
      } else {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (navigatorKey.currentState != null) {
            _performNavigation(route, args);
          }
        });
      }
    });
  }

  void _performNavigation(String route, Map<String, dynamic>? args) async {
    try {
      final navigatorState = navigatorKey.currentState;
      if (navigatorState == null) {
        return;
      }

      if (route == '/eventDetail' && args != null && args['eventId'] != null) {
        final eventId = args['eventId'] as String;
        try {
          final response = await EventService.getEventById(eventId);
          if (response.success && response.data != null) {
            navigatorState.pushNamed('/eventDetail', arguments: response.data);
          } else {
            debugPrint(
              'Failed to fetch event for notification: ${response.message}',
            );
            navigatorState.pushNamed('/home');
          }
        } catch (e) {
          debugPrint('Error fetching event for notification: $e');
          navigatorState.pushNamed('/home');
        }
        return;
      }

      Map<String, String>? stringArgs;
      if (args != null && args.isNotEmpty) {
        stringArgs = args.map(
          (key, value) => MapEntry(key, value?.toString() ?? ''),
        );
      }

      navigatorState.pushNamed(route, arguments: stringArgs ?? args);
    } catch (e) {
      debugPrint('Navigation error to $route: $e');
    }
  }

  void _handleInitialUrlScheme() {}

  Future<void> _initReceiveSharing() async {
    final handler = ShareHandlerPlatform.instance;
    final SharedMedia? initialMedia = await handler.getInitialSharedMedia();
    if (initialMedia != null) {
      final maybeUrl = _extractUrlFromSharedMedia(initialMedia);
      if (maybeUrl != null) {
        _pendingSharedUrl = maybeUrl;
        _processedInitialUrl = maybeUrl;
      }
    }

    _mediaStreamSub = handler.sharedMediaStream.listen((SharedMedia media) {
      final maybeUrl = _extractUrlFromSharedMedia(media);
      if (maybeUrl != null) {
        if (_processedInitialUrl == maybeUrl) {
          return;
        }
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _handleSharedUrl(maybeUrl),
        );
      }
    });
  }

  String? _extractUrlFromSharedMedia(SharedMedia media) {
    if (media.content != null && media.content!.isNotEmpty) {
      if (_looksLikeUrl(media.content!)) return media.content!;
    }
    if (media.attachments != null) {
      for (final attachment in media.attachments!) {
        if (attachment != null && _looksLikeUrl(attachment.path)) {
          return attachment.path;
        }
      }
    }
    return null;
  }

  bool _looksLikeUrl(String value) {
    final v = value.toLowerCase();
    return v.startsWith('http://') ||
        v.startsWith('https://') ||
        v.startsWith('www.');
  }

  void _importEventFromSharedMedia(String url) {
    _navigateToImportEventScreen(url);
  }

  void _handleSharedUrl(String url) {
    final now = DateTime.now();
    if (_lastHandledShareUrl == url && _lastHandledAt != null) {
      final diff = now.difference(_lastHandledAt!);
      if (diff.inSeconds < 30) {
        return;
      }
    }
    _lastHandledShareUrl = url;
    _lastHandledAt = now;
    _importEventFromSharedMedia(url);
  }

  void _navigateToImportEventScreen(String url) {
    _waitForNavigatorAndNavigate(url);
  }

  void _waitForNavigatorAndNavigate(String url) {
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushNamed('/importEvent', arguments: url);
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushNamed('/importEvent', arguments: url);
      } else {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (navigatorKey.currentState != null) {
            navigatorKey.currentState!.pushNamed(
              '/importEvent',
              arguments: url,
            );
          }
        });
      }
    });
  }

  static String? _getPendingSharedUrl() {
    final url = _pendingSharedUrl;
    _pendingSharedUrl = null;
    return url;
  }

  static String? _getPendingNotificationPayload() {
    final payload = _pendingNotificationPayload;
    _pendingNotificationPayload = null;
    return payload;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    try {
      _mediaStreamSub?.cancel();
      _linkStreamSub?.cancel();
    } catch (_) {}
    super.dispose();
  }

  static final Map<String, Widget Function(dynamic)> _routes = {
    '/discover':
        (args) => const PersistentBannerLayout(child: DiscoverEventsScreen()),
    '/map': (args) => const PersistentBannerLayout(child: MapScreen()),
    '/collections':
        (args) => const PersistentBannerLayout(child: EventCollectionsScreen()),
    '/collectionDetail': (args) {
      final collectionId =
          (args is Map && args['collectionId'] != null)
              ? args['collectionId'] as String
              : '';
      return PersistentBannerLayout(
        child: CollectionDetailScreen(collectionId: collectionId),
      );
    },
    '/addEventsToCollection': (args) {
      final collectionId =
          (args is Map && args['collectionId'] != null)
              ? args['collectionId'] as String
              : '';
      return PersistentBannerLayout(
        child: AddEventsToCollectionScreen(collectionId: collectionId),
      );
    },
    '/myEvents':
        (args) => const PersistentBannerLayout(child: MyEventsScreen()),
    '/createEvent':
        (args) => const PersistentBannerLayout(child: CreateEventScreen()),
    '/eventDetail':
        (args) => PersistentBannerLayout(
          child: EventDetailScreen(event: args as Event),
        ),
    '/importEvent':
        (args) => PersistentBannerLayout(
          child: ImportEventScreen(sharedUrl: args as String?),
        ),
    '/planner':
        (args) => const PersistentBannerLayout(child: AiPlannerScreen()),
    '/splash': (args) => const SplashScreen(),
    '/home': (args) => const PersistentBannerLayout(child: HomeScreen()),
    '/login': (args) => const LoginScreen(),
    '/register': (args) => const RegisterScreen(),
    '/authRequired':
        (args) =>
            PersistentBannerLayout(child: AuthRequiredScreen.fromArgs(args)),
    '/settings':
        (args) => const PersistentBannerLayout(child: SettingsScreen()),
    '/subscription':
        (args) => const PersistentBannerLayout(child: SubscriptionScreen()),
    '/generated':
        (args) => const PersistentBannerLayout(child: GeneratedPlansScreen()),
    '/generatedDetail': (args) {
      final planId =
          (args is Map && args['planId'] != null)
              ? args['planId'] as String
              : '';
      return PersistentBannerLayout(
        child: GeneratedPlanDetailScreen(planId: planId),
      );
    },
    '/random':
        (args) => const PersistentBannerLayout(child: RandomEventScreen()),
  };

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => DiscoverProvider()),
        ChangeNotifierProvider(create: (_) => CollectionProvider()),
        ChangeNotifierProvider(create: (_) => GeneratedPlanProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => DynamicUiProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
      ],
      child: Consumer2<AuthService, ThemeProvider>(
        builder: (context, authService, themeProvider, _) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            navigatorObservers: [MyApp.routeObserver],
            title: 'EventEase',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            debugShowCheckedModeBanner: false,
            showSemanticsDebugger: false,
            showPerformanceOverlay: false,
            checkerboardRasterCacheImages: false,
            checkerboardOffscreenLayers: false,
            supportedLocales: const [
              Locale('en', 'US'),
              Locale('en', 'GB'),
              Locale('es', 'ES'),
              Locale('fr', 'FR'),
            ],
            localizationsDelegates: const [],
            scrollBehavior: AppScrollBehavior(),
            onGenerateRoute: (settings) {
              // Route-level auth gate (lightweight):
              // If a guest tries to navigate to an account-only route, cancel the
              // navigation and show a SnackBar prompting sign-in.
              final protectedRoutes = <String>{
                '/myEvents',
                '/createEvent',
                '/importEvent',
                '/planner',
                '/collections',
                '/collectionDetail',
                '/addEventsToCollection',
                '/generated',
                '/generatedDetail',
                '/subscription',
              };

              final requestedName = settings.name ?? '';
              final isAuthed = authService.user != null;
              if (!isAuthed && protectedRoutes.contains(requestedName)) {
                return _blockedAuthRoute(settings);
              }

              final routeBuilder = _MyAppState._routes[settings.name];
              if (routeBuilder == null) return null;

              final widget = routeBuilder(settings.arguments);

              if (Platform.isIOS) {
                // Use the FastCupertinoPageRoute discovered by the user for optimal gesture/speed.
                return FastCupertinoPageRoute(
                  settings: settings,
                  // IMPORTANT: Keep the Stack wrapper to simulate visual transparency over global background
                  builder:
                      (context) => Stack(
                        children: [
                          const Positioned.fill(
                            child: RepaintBoundary(
                              child: DynamicGlobalBackground(),
                            ),
                          ),
                          widget,
                        ],
                      ),
                );
              } else {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => widget,
                );
              }
            },
            builder: (context, child) {
              ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.error,
                          size: 60,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Something went wrong!',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        if (kDebugMode)
                          Text(
                            errorDetails.exception.toString(),
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),
                );
              };

              return LayoutBuilder(
                builder: (context, constraints) {
                  return Consumer<DynamicUiProvider>(
                    builder: (context, dyn, _) {
                      final hasBg = dyn.config?.globalBackground != null;

                      return Stack(
                        children: [
                          // The Persistent Background
                          if (hasBg)
                            const Positioned.fill(
                              child: RepaintBoundary(
                                child: DynamicGlobalBackground(),
                              ),
                            ),
                          // The App Content
                          Positioned.fill(
                            child: Scaffold(
                              backgroundColor: Colors.transparent,
                              body: child ?? const SizedBox.shrink(),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
            home: const SplashScreen(),
            routes: const {},
          );
        },
      ),
    );
  }
}

/// A custom CupertinoPageRoute that provides fast transitions:
/// - Overrides transitionDuration to 100ms for a nearly instant push.
/// - Relies on the base CupertinoRouteTransitionMixin for native swipe-back.
class FastCupertinoPageRoute<T> extends CupertinoPageRoute<T> {
  FastCupertinoPageRoute({required super.builder, super.settings});

  // Sets the duration to a short value (100ms) to simulate an instant/pop-in transition
  // for pushes, while maintaining the native gesture functionality on pop.
  @override
  Duration get transitionDuration => const Duration(milliseconds: 0);

  // We deliberately do NOT override buildTransitions here, relying on the base
  // CupertinoRouteTransitionMixin to handle the slide animation and gesture integrity.
}
