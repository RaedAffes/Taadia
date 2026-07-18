import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:ta3dia/l10n/app_localizations.dart';
import 'package:ta3dia/providers/app_state.dart';
import 'package:ta3dia/screens/admin_manage_taadia_screen.dart';
import 'package:ta3dia/screens/home_screen.dart';
import 'package:ta3dia/screens/login_screen.dart';

import 'package:ta3dia/services/auth_services.dart';
import 'package:ta3dia/services/background_download_service.dart';
import 'package:ta3dia/services/code_lookup_service.dart';
import 'package:ta3dia/services/taadia_service.dart';
import 'package:ta3dia/services/evaluation_service.dart';
import 'package:ta3dia/services/feedback_service.dart';
import 'package:ta3dia/services/group_service.dart';
import 'package:ta3dia/services/connectivity_service.dart';
import 'package:ta3dia/services/offline_queue_service.dart';
import 'package:ta3dia/services/pexels_background_service.dart';
import 'package:ta3dia/services/quran_download_service.dart';
import 'package:ta3dia/services/quran_workmanager.dart';
import 'package:ta3dia/widgets/offline_observer.dart';

import 'firebase_options.dart';

class NoOverscrollBehavior extends ScrollBehavior {
  const NoOverscrollBehavior();
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
  FirebaseFirestore.instance.settings = Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  final quranService = QuranDownloadService.instance;
  await quranService.init();
  quranService.startBackgroundDownload();
  if (!kIsWeb) {
    BackgroundDownloadService.instance.init();
    initQuranWorkManager();
  }
  PexelsBackgroundService.instance.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _AppBody();
  }
}

class _AppBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthService()),
        ChangeNotifierProvider(create: (context) => ConnectivityService()),
        ChangeNotifierProvider(
          create: (context) => CodeLookupService(
            Provider.of<ConnectivityService>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) {
            final service = OfflineQueueService(
              Provider.of<ConnectivityService>(context, listen: false),
              Provider.of<CodeLookupService>(context, listen: false),
            );
            Provider.of<CodeLookupService>(context, listen: false).onCodeResolved =
                () => service.processQueue();
            return service;
          },
        ),
        ChangeNotifierProvider(
          create: (context) => TaadiaService(
            Provider.of<ConnectivityService>(context, listen: false),
            Provider.of<OfflineQueueService>(context, listen: false),
            Provider.of<CodeLookupService>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => EvaluationService(
            Provider.of<ConnectivityService>(context, listen: false),
            Provider.of<OfflineQueueService>(context, listen: false),
            Provider.of<CodeLookupService>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => FeedbackService(
            Provider.of<ConnectivityService>(context, listen: false),
            Provider.of<OfflineQueueService>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => GroupService(
            Provider.of<ConnectivityService>(context, listen: false),
            Provider.of<OfflineQueueService>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider(create: (context) => AppState()),
      ],
      child: Consumer<AppState>(
        builder: (context, state, _) => MaterialApp(
            title: 'Taadia',
            scrollBehavior: const NoOverscrollBehavior(),
            debugShowCheckedModeBanner: false,
            themeMode: state.themeMode,
            themeAnimationDuration: Duration(milliseconds: 200),
            themeAnimationCurve: Curves.easeOut,
            locale: state.locale,
            builder: (context, child) =>
                OfflineObserver(child: Directionality(
                  textDirection: state.locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
                  child: child!
                )),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.light(
              primary: Color(0xFF8B7D6B),
              secondary: Color(0xFFA0937D),
              surface: Color(0xFFF5F0EB),
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              onSurface: Color(0xFF3E3A36),
            ),
            scaffoldBackgroundColor: Color(0xFFF5F0EB),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF3E3A36),
              elevation: 0.5,
              centerTitle: true,
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF8B7D6B),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Color(0xFFFAFAF7),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: Color(0xFF8B7D6B),
              foregroundColor: Colors.white,
            ),
            dividerTheme: DividerThemeData(color: Color(0xFFE8E3DD)),
            snackBarTheme: SnackBarThemeData(
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 4,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.dark(
              primary: Color(0xFFA0937D),
              secondary: Color(0xFF8B7D6B),
              surface: Color(0xFF4A443E),
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              onSurface: Color(0xFFF0EBE6),
            ),
            scaffoldBackgroundColor: Color(0xFF3E3A36),
            appBarTheme: AppBarTheme(
              backgroundColor: Color(0xFF4A443E),
              foregroundColor: Color(0xFFF0EBE6),
              elevation: 0.5,
              centerTitle: true,
            ),
            cardTheme: CardThemeData(
              color: Color(0xFF4A443E),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFA0937D),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
              labelStyle: TextStyle(color: Color(0xFF6B5D4F)),
              hintStyle: TextStyle(color: Color(0xFFA0937D)),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            textSelectionTheme: TextSelectionThemeData(
              cursorColor: Color(0xFF8B7D6B),
            ),
            textTheme: TextTheme(
              bodyLarge: TextStyle(color: Color(0xFF3E3A36)),
              bodyMedium: TextStyle(color: Color(0xFF3E3A36)),
              labelLarge: TextStyle(color: Color(0xFF6B5D4F)),
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: Color(0xFFA0937D),
              foregroundColor: Colors.white,
            ),
            dividerTheme: DividerThemeData(color: Color(0xFF5A544E)),
            drawerTheme: DrawerThemeData(backgroundColor: Color(0xFF4A443E)),
            snackBarTheme: SnackBarThemeData(
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 4,
            ),
          ),
          home: AuthWrapper(),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;


  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }

        final user = snapshot.data;
        if (user == null) {
          analytics.logLogin();
          return LoginScreen();
        }

        if (authService.appUser == null) {
          return _buildLoading();
        }

        final isAdmin = authService.isAdmin;

        if (isAdmin) {
          analytics.setUserId(id: user.uid);
          analytics.logEvent(name: 'admin_access', parameters: {
            'user_id': user.uid,
          });
          return AdminManageTaadiaScreen();
        }

        analytics.setUserId(id: user.uid);
        analytics.logEvent(name: 'user_access', parameters: {
          'user_id': user.uid,
        });
        return HomeScreen();
      },
    );
  }

  Widget _buildLoading() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      body: ValueListenableBuilder<String?>(
        valueListenable: PexelsBackgroundService.instance.imageUrlNotifier,
        builder: (context, pexelsUrl, _) {
          return Stack(
            children: [
              if (pexelsUrl != null)
                Positioned.fill(
                  child: Image.network(pexelsUrl, fit: BoxFit.cover),
                ),
              if (pexelsUrl != null)
                Positioned.fill(
                  child: Container(color: const Color(0xFFF5F0EB).withValues(alpha: 0.75)),
                ),
              const Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B7D6B)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
