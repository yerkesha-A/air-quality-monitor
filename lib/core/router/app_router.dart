import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/providers/auth_controller.dart';
import '../../presentation/providers/settings_controller.dart';
import '../../presentation/screens/account_screen.dart';
import '../../presentation/screens/alerts_screen.dart';
import '../../presentation/screens/auth_screen.dart';
import '../../presentation/screens/cities_screen.dart';
import '../../presentation/screens/city_link_screen.dart';
import '../../presentation/screens/compare_screen.dart';
import '../../presentation/screens/health_screen.dart';
import '../../presentation/screens/history_screen.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/insights_screen.dart';
import '../../presentation/screens/map_screen.dart';
import '../../presentation/screens/notes_screen.dart';
import '../../presentation/screens/onboarding_screen.dart';
import '../../presentation/screens/privacy_screen.dart';
import '../../presentation/screens/profile_screen.dart';

GoRouter createRouter(SettingsController settings, AuthController auth) =>
    GoRouter(
      initialLocation: '/',
      refreshListenable: Listenable.merge([settings, auth]),
      redirect: (context, state) {
        if (!settings.onboarded) {
          return state.matchedLocation == '/welcome' ? null : '/welcome';
        }
        if (state.matchedLocation == '/welcome') return '/';
        if (state.matchedLocation.startsWith('/account') &&
            auth.account == null) {
          return '/login';
        }
        if (state.matchedLocation == '/login' && auth.account != null) {
          return '/account';
        }
        return null;
      },
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Страница не найдена')),
        body: Center(
          child: FilledButton(
            onPressed: () => context.go('/'),
            child: const Text('На главную'),
          ),
        ),
      ),
      routes: [
        GoRoute(
          path: '/welcome',
          name: 'welcome',
          builder: (_, _) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (_, _) => const AuthScreen(),
        ),
        GoRoute(
          path: '/account',
          name: 'account',
          builder: (_, _) => const AccountScreen(),
        ),
        GoRoute(
          path: '/alerts',
          name: 'alerts',
          builder: (_, _) => const AlertsScreen(),
        ),
        GoRoute(
          path: '/health',
          name: 'health',
          builder: (_, _) => const HealthScreen(),
        ),
        GoRoute(
          path: '/insights',
          name: 'insights',
          builder: (_, _) => const InsightsScreen(),
        ),
        GoRoute(
          path: '/compare',
          name: 'compare',
          builder: (_, _) => const CompareScreen(),
        ),
        GoRoute(
          path: '/notes',
          name: 'notes',
          builder: (_, _) => const NotesScreen(),
        ),
        GoRoute(
          path: '/privacy',
          name: 'privacy',
          builder: (_, _) => const PrivacyScreen(),
        ),
        GoRoute(
          path: '/city/:id',
          name: 'city',
          builder: (_, state) =>
              CityLinkScreen(id: state.pathParameters['id']!),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => Scaffold(
            body: shell,
            bottomNavigationBar: NavigationBar(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: (index) => shell.goBranch(
                index,
                initialLocation: index == shell.currentIndex,
              ),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.air_rounded),
                  label: 'Сегодня',
                ),
                NavigationDestination(
                  icon: Icon(Icons.location_city_outlined),
                  label: 'Города',
                ),
                NavigationDestination(
                  icon: Icon(Icons.map_outlined),
                  label: 'Карта',
                ),
                NavigationDestination(
                  icon: Icon(Icons.timeline_rounded),
                  label: 'История',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  label: 'Профиль',
                ),
              ],
            ),
          ),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/',
                  name: 'home',
                  builder: (_, _) => const HomeScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/cities',
                  name: 'cities',
                  builder: (_, _) => const CitiesScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/map',
                  name: 'map',
                  builder: (_, _) => const MapScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/history',
                  name: 'history',
                  builder: (_, _) => const HistoryScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  name: 'profile',
                  builder: (_, _) => const ProfileScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
