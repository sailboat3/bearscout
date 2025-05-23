import 'package:appwrite/appwrite.dart';
import 'package:beariscope/pages/auth/register_team_page.dart';
import 'package:beariscope/pages/auth/sign_in_page.dart';
import 'package:beariscope/pages/auth/signup_page.dart';
import 'package:beariscope/pages/auth/team_selection_page.dart';
import 'package:beariscope/pages/auth/welcome_page.dart';
import 'package:beariscope/pages/main_view.dart';
import 'package:beariscope/providers/auth_provider.dart';
import 'package:beariscope/services/auth_service.dart';
import 'package:beariscope/utils/platform_utils.dart';
import 'package:beariscope/utils/window_size_stub.dart'
    if (dart.library.io) 'package:window_size/window_size.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Start Appwrite
  Client client = Client();
  client
      .setEndpoint('https://nyc.cloud.appwrite.io/v1')
      .setProject('bear-scout')
      .setSelfSigned(status: true); // only use for development

  final authService = AuthService(client: client);

  SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

  if (PlatformUtils.isDesktop()) {
    setWindowMinSize(const Size(450, 640));
    setWindowMaxSize(Size.infinite);
    setWindowTitle('Beariscope');
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<SharedPreferences>.value(value: sharedPreferences),
        Provider<Client>.value(value: client),
        Provider<AuthService>(create: (_) => authService),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(authService: authService),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createRouter(context);
  }

  GoRouter createRouter(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return GoRouter(
      refreshListenable: authProvider,
      initialLocation: '/',
      routes: <RouteBase>[
        GoRoute(
          path: '/welcome',
          builder: (BuildContext context, GoRouterState state) {
            return const WelcomePage();
          },
          routes: [
            GoRoute(
              path: 'signin',
              builder: (BuildContext context, GoRouterState state) {
                return const SignInPage();
              },
            ),
            GoRoute(
              path: 'signup',
              builder: (BuildContext context, GoRouterState state) {
                return SignupPage();
              },
              routes: [
                GoRoute(
                  path: 'register_team',
                  builder: (BuildContext context, GoRouterState state) {
                    return const RegisterTeamPage();
                  },
                ),
                GoRoute(
                  path: 'select_team',
                  builder: (BuildContext context, GoRouterState state) {
                    return const TeamSelectionPage();
                  },
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/home',
          builder: (BuildContext context, GoRouterState state) {
            return const MainView();
          },
        ),
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) {
            // Load while auth state is determined
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
        ),
      ],
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isLoading = authProvider.isLoading;

        // Don't redirect while loading
        if (isLoading) return null;

        // If at root path, redirect based on if authed
        if (state.matchedLocation == '/') {
          return isAuthenticated ? '/home' : '/welcome';
        }

        // If authed but on welcome pages, go to home screen
        if (isAuthenticated && state.matchedLocation.startsWith('/welcome')) {
          return '/home';
        }

        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.lightBlue,
          brightness: Brightness.light,
        ),
        iconTheme: const IconThemeData(fill: 0.0, weight: 600),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.lightBlue,
          brightness: Brightness.dark,
        ),
        iconTheme: const IconThemeData(fill: 0.0, weight: 600),
      ),
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}
