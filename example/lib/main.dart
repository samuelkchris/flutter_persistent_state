import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_persistent_state/flutter_persistent_state.dart';

/// Modern beautiful example application showcasing persistent state.
///
/// This app demonstrates all features of the persistent state package
/// with a beautiful, modern Material 3 design that feels premium
/// and intuitive to use.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final navigationObserver = PersistentNavigationObserver(
    excludedRoutes: {'/', '/onboarding'},
  );

  runApp(ModernPersistentStateApp(observer: navigationObserver));
}

class ModernPersistentStateApp extends StatelessWidget {
  final PersistentNavigationObserver observer;

  const ModernPersistentStateApp({super.key, required this.observer});

  @override
  Widget build(BuildContext context) {
    return PersistentNavigationWrapper(
      observer: observer,
      restoreOnStart: true,
      maxRouteAge: const Duration(days: 30),
      child: MaterialApp(
        title: 'Persistent State Demo',
        navigatorObservers: [observer],
        initialRoute: '/',
        theme: _buildLightTheme(),
        darkTheme: _buildDarkTheme(),
        routes: {
          '/': (context) => const SplashScreen(),
          '/onboarding': (context) => const OnboardingFlow(),
          '/home': (context) => const HomeScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/preferences': (context) => const PreferencesScreen(),
        },
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6750A4),
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6750A4),
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade800),
        ),
      ),
    );
  }
}

/// Beautiful animated splash screen with persistent state initialization.
@PersistentState()
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with PersistentStateMixin<SplashScreen>, TickerProviderStateMixin {

  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  Map<String, PersistentFieldConfig> get persistentFields => {
    'hasCompletedOnboarding': persistentField('has_completed_onboarding',
        defaultValue: false),
    'appVersion': persistentField('app_version', defaultValue: '1.0.0'),
    'lastLaunchTime': persistentField('last_launch_time',
        defaultValue: DateTime.now().millisecondsSinceEpoch),
  };

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _scaleController.forward();
    });
  }

  Future<void> _initializeApp() async {
    await initializePersistence();

    await setPersistentValue('lastLaunchTime', DateTime.now().millisecondsSinceEpoch);

    // Beautiful loading delay for animation
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      final hasOnboarded = getPersistentValue<bool>('hasCompletedOnboarding');

      if (hasOnboarded) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    disposePersistence();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.storage_rounded,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  Text(
                    'Persistent State',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Beautiful state persistence for Flutter',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modern onboarding flow with beautiful animations and persistent progress.
@PersistentState()
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow>
    with PersistentStateMixin<OnboardingFlow>, TickerProviderStateMixin {

  final PageController _pageController = PageController();
  late AnimationController _progressController;

  @override
  Map<String, PersistentFieldConfig> get persistentFields => {
    'currentPage': persistentField('onboarding_page', defaultValue: 0),
    'userName': persistentField('onboarding_name', defaultValue: ''),
    'userPreferences': persistentField('onboarding_prefs',
        defaultValue: <String, bool>{
          'notifications': true,
          'darkMode': false,
          'analytics': false,
        }),
  };

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _initializeOnboarding();
  }

  Future<void> _initializeOnboarding() async {
    await initializePersistence();

    final currentPage = getPersistentValue<int>('currentPage');
    if (currentPage > 0) {
      _pageController.animateToPage(
        currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
    _updateProgress();
  }

  void _updateProgress() {
    final currentPage = getPersistentValue<int>('currentPage');
    _progressController.animateTo((currentPage + 1) / 3);
  }

  void _nextPage() {
    final currentPage = getPersistentValue<int>('currentPage');
    if (currentPage < 2) {
      final nextPage = currentPage + 1;
      setPersistentValue('currentPage', nextPage);
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      _updateProgress();
      HapticFeedback.lightImpact();
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() async {
    await PersistentStateManager.instance.setValue('has_completed_onboarding', true);

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    disposePersistence();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isHydrated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressHeader(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildWelcomePage(),
                  _buildNamePage(),
                  _buildPreferencesPage(),
                ],
              ),
            ),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Setup',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${getPersistentValue<int>('currentPage') + 1}/3',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: _progressController.value,
                backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
                borderRadius: BorderRadius.circular(8),
                minHeight: 6,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.secondaryContainer,
                ],
              ),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(
              Icons.waving_hand_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            'Welcome!',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'This beautiful app demonstrates persistent state management with zero boilerplate. Your data stays perfectly synchronized across app sessions.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.5,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          _buildFeatureCards(),
        ],
      ),
    );
  }

  Widget _buildFeatureCards() {
    final features = [
      {'icon': Icons.flash_on_rounded, 'title': 'Instant Sync', 'desc': 'Real-time updates'},
      {'icon': Icons.security_rounded, 'title': 'Type Safe', 'desc': 'Compile-time safety'},
      {'icon': Icons.auto_awesome_rounded, 'title': 'Zero Config', 'desc': 'Works out of the box'},
    ];

    return Row(
      children: features.map((feature) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: [
              Icon(
                feature['icon'] as IconData,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                feature['title'] as String,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                feature['desc'] as String,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildNamePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.person_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'What should we call you?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Your name will be saved automatically and remembered across app sessions.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          PersistentTextField(
            storageKey: 'onboarding_name',
            decoration: InputDecoration(
              labelText: 'Your name',
              hintText: 'Enter your name',
              prefixIcon: const Icon(Icons.person_outline_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            ),
            validator: (value) => value.trim().isEmpty ? 'Name is required' : null,
            showSaveIndicator: false,
            textCapitalization: TextCapitalization.words,
            onChanged: (value) {
              if (value.trim().isNotEmpty) {
                HapticFeedback.selectionClick();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesPage() {
    final preferences = getPersistentValue<Map<String, bool>>('userPreferences');

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.tune_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Customize your experience',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'These preferences will be automatically saved and applied throughout the app.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Card(
            child: Column(
              children: [
                _buildPreferenceItem(
                  icon: Icons.notifications_rounded,
                  title: 'Push Notifications',
                  subtitle: 'Get notified about important updates',
                  value: preferences['notifications'] ?? true,
                  onChanged: (value) {
                    final newPrefs = Map<String, bool>.from(preferences);
                    newPrefs['notifications'] = value;
                    setPersistentValue('userPreferences', newPrefs);
                    HapticFeedback.lightImpact();
                  },
                ),
                const Divider(height: 1),
                _buildPreferenceItem(
                  icon: Icons.dark_mode_rounded,
                  title: 'Dark Mode',
                  subtitle: 'Use dark theme for better night viewing',
                  value: preferences['darkMode'] ?? false,
                  onChanged: (value) {
                    final newPrefs = Map<String, bool>.from(preferences);
                    newPrefs['darkMode'] = value;
                    setPersistentValue('userPreferences', newPrefs);
                    HapticFeedback.lightImpact();
                  },
                ),
                const Divider(height: 1),
                _buildPreferenceItem(
                  icon: Icons.analytics_rounded,
                  title: 'Analytics',
                  subtitle: 'Help us improve the app experience',
                  value: preferences['analytics'] ?? false,
                  onChanged: (value) {
                    final newPrefs = Map<String, bool>.from(preferences);
                    newPrefs['analytics'] = value;
                    setPersistentValue('userPreferences', newPrefs);
                    HapticFeedback.lightImpact();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }

  Widget _buildBottomNavigation() {
    final currentPage = getPersistentValue<int>('currentPage');
    final canContinue = currentPage == 0 ||
        (currentPage == 1 && getPersistentValue<String>('userName').trim().isNotEmpty);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (currentPage > 0)
            OutlinedButton(
              onPressed: () {
                final prevPage = currentPage - 1;
                setPersistentValue('currentPage', prevPage);
                _pageController.animateToPage(
                  prevPage,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
                _updateProgress();
                HapticFeedback.lightImpact();
              },
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Back'),
            ),
          const Spacer(),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: FilledButton(
              onPressed: canContinue ? _nextPage : null,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: Text(currentPage == 2 ? 'Get Started' : 'Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modern home screen with beautiful cards and persistent state.
@PersistentState()
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with PersistentStateMixin<HomeScreen>, TickerProviderStateMixin {

  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  @override
  Map<String, PersistentFieldConfig> get persistentFields => {
    'userName': persistentField('onboarding_name', defaultValue: 'User'),
    'counter': persistentField('home_counter', defaultValue: 0),
    'favoriteItems': persistentField('favorite_items', defaultValue: <String>[]),
    'lastVisit': persistentField('last_home_visit',
        defaultValue: DateTime.now().millisecondsSinceEpoch),
    'achievements': persistentField('user_achievements', defaultValue: <String>[]),
  };

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeOut),
    );
    _initializeHome();
  }

  Future<void> _initializeHome() async {
    await initializePersistence();
    await setPersistentValue('lastVisit', DateTime.now().millisecondsSinceEpoch);
    _fabController.forward();
    _checkAchievements();
  }

  void _checkAchievements() {
    final counter = getPersistentValue<int>('counter');
    final achievements = List<String>.from(getPersistentValue<List<String>>('achievements'));

    if (counter >= 10 && !achievements.contains('counter_10')) {
      achievements.add('counter_10');
      setPersistentValue('achievements', achievements);
      _showAchievement('First Milestone!', 'You reached 10 taps');
    }

    if (counter >= 50 && !achievements.contains('counter_50')) {
      achievements.add('counter_50');
      setPersistentValue('achievements', achievements);
      _showAchievement('Tap Master!', 'You reached 50 taps');
    }
  }

  void _showAchievement(String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.emoji_events_rounded, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(message),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _incrementCounter() {
    final current = getPersistentValue<int>('counter');
    setPersistentValue('counter', current + 1);
    HapticFeedback.lightImpact();
    _checkAchievements();
  }

  @override
  void dispose() {
    _fabController.dispose();
    disposePersistence();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isHydrated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final userName = getPersistentValue<String>('userName');
    final counter = getPersistentValue<int>('counter');
    final favorites = getPersistentValue<List<String>>('favoriteItems');
    final achievements = getPersistentValue<List<String>>('achievements');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text('Hello, $userName!'),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_rounded),
                onPressed: () => Navigator.pushNamed(context, '/profile'),
              ),
              IconButton(
                icon: const Icon(Icons.settings_rounded),
                onPressed: () => Navigator.pushNamed(context, '/settings'),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildStatsCard(counter, achievements.length),
                const SizedBox(height: 16),
                _buildFavoritesCard(favorites),
                const SizedBox(height: 16),
                _buildAchievementsCard(achievements),
                const SizedBox(height: 16),
                _buildQuickActionsCard(),
                const SizedBox(height: 100), // Space for FAB
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: _incrementCounter,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Tap me!'),
        ),
      ),
    );
  }

  Widget _buildStatsCard(int counter, int achievementCount) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.analytics_rounded,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Progress',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Stats update in real-time',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Taps',
                    counter.toString(),
                    Icons.touch_app_rounded,
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Achievements',
                    achievementCount.toString(),
                    Icons.emoji_events_rounded,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesCard(List<String> favorites) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.favorite_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Favorites',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _showAddFavoriteDialog,
                  icon: const Icon(Icons.add_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (favorites.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.favorite_border_rounded,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No favorites yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      'Tap the + button to add some!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: favorites.map((item) => _buildFavoriteChip(item)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteChip(String item) {
    return Chip(
      label: Text(item),
      avatar: const Icon(Icons.favorite, size: 16),
      deleteIcon: const Icon(Icons.close_rounded, size: 18),
      onDeleted: () {
        final newFavorites = List<String>.from(getPersistentValue<List<String>>('favoriteItems'));
        newFavorites.remove(item);
        setPersistentValue('favoriteItems', newFavorites);
        HapticFeedback.lightImpact();
      },
      backgroundColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
      deleteIconColor: Theme.of(context).colorScheme.onPrimaryContainer,
    );
  }

  Widget _buildAchievementsCard(List<String> achievements) {
    final allAchievements = [
      {'id': 'counter_10', 'title': 'First Milestone', 'desc': 'Reach 10 taps', 'icon': Icons.flag_rounded},
      {'id': 'counter_50', 'title': 'Tap Master', 'desc': 'Reach 50 taps', 'icon': Icons.emoji_events_rounded},
      {'id': 'counter_100', 'title': 'Century Club', 'desc': 'Reach 100 taps', 'icon': Icons.star_rounded},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Achievements',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...allAchievements.map((achievement) {
              final isUnlocked = achievements.contains(achievement['id']);
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                      : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isUnlocked
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                        : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isUnlocked
                            ? Colors.orange.withOpacity(0.2)
                            : Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        achievement['icon'] as IconData,
                        color: isUnlocked ? Colors.orange : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            achievement['title'] as String,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isUnlocked ? null : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          Text(
                            achievement['desc'] as String,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isUnlocked)
                      Icon(
                        Icons.check_circle_rounded,
                        color: Colors.orange,
                        size: 24,
                      ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    'Reset Counter',
                    Icons.refresh_rounded,
                        () {
                      setPersistentValue('counter', 0);
                      HapticFeedback.mediumImpact();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    'Clear Favorites',
                    Icons.clear_all_rounded,
                        () {
                      setPersistentValue('favoriteItems', <String>[]);
                      HapticFeedback.mediumImpact();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(String label, IconData icon, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAddFavoriteDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Favorite'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter item name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                final favorites = List<String>.from(getPersistentValue<List<String>>('favoriteItems'));
                favorites.add(controller.text.trim());
                setPersistentValue('favoriteItems', favorites);
                Navigator.pop(context);
                HapticFeedback.lightImpact();
              }
            },
            child: const Text('Add'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

/// Modern profile screen with beautiful form fields.
@PersistentState()
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with PersistentStateMixin<ProfileScreen> {

  final _formKey = GlobalKey<FormState>();

  @override
  Map<String, PersistentFieldConfig> get persistentFields => {
    'userName': persistentField('onboarding_name', defaultValue: ''),
    'email': persistentField('user_email', defaultValue: ''),
    'phone': persistentField('user_phone', defaultValue: ''),
    'bio': persistentField('user_bio', defaultValue: ''),
    'location': persistentField('user_location', defaultValue: ''),
  };

  @override
  void initState() {
    super.initState();
    initializePersistence();
  }

  @override
  void dispose() {
    disposePersistence();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isHydrated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 32),
              _buildFormFields(),
              const SizedBox(height: 32),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final userName = getPersistentValue<String>('userName');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Center(
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              userName.isNotEmpty ? userName : 'User',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Persistent State User',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        PersistentTextFormField(
          storageKey: 'onboarding_name',
          decoration: InputDecoration(
            labelText: 'Full Name',
            prefixIcon: const Icon(Icons.person_outline_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Name is required';
            }
            return null;
          },
          textCapitalization: TextCapitalization.words,
          showSaveIndicator: false,
        ),
        const SizedBox(height: 16),
        PersistentTextFormField(
          storageKey: 'user_email',
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value != null && value.isNotEmpty && !value.contains('@')) {
              return 'Please enter a valid email';
            }
            return null;
          },
          showSaveIndicator: false,
        ),
        const SizedBox(height: 16),
        PersistentTextFormField(
          storageKey: 'user_phone',
          decoration: InputDecoration(
            labelText: 'Phone Number',
            prefixIcon: const Icon(Icons.phone_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          ),
          keyboardType: TextInputType.phone,
          showSaveIndicator: false,
        ),
        const SizedBox(height: 16),
        PersistentTextFormField(
          storageKey: 'user_location',
          decoration: InputDecoration(
            labelText: 'Location',
            prefixIcon: const Icon(Icons.location_on_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          ),
          textCapitalization: TextCapitalization.words,
          showSaveIndicator: false,
        ),
        const SizedBox(height: 16),
        PersistentTextFormField(
          storageKey: 'user_bio',
          decoration: InputDecoration(
            labelText: 'Bio',
            prefixIcon: const Icon(Icons.edit_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            alignLabelWithHint: true,
          ),
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          showSaveIndicator: false,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _saveProfile,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Save Profile'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _resetProfile,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Reset to Defaults'),
          ),
        ),
      ],
    );
  }

  void _saveProfile() {
    if (_formKey.currentState?.validate() ?? false) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Profile saved successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _resetProfile() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Profile'),
        content: const Text('Are you sure you want to reset all profile data to defaults?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );

    if (confirmed == true) {
      await resetAllPersistentFields();
      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.refresh_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text('Profile reset to defaults'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }
}

/// Modern settings screen with beautiful switches and preferences.
@PersistentState()
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with PersistentStateMixin<SettingsScreen> {

  @override
  Map<String, PersistentFieldConfig> get persistentFields => {
    'preferences': persistentField('onboarding_prefs',
        defaultValue: <String, bool>{
          'notifications': true,
          'darkMode': false,
          'analytics': false,
        }),
    'appSettings': persistentField('app_settings',
        defaultValue: <String, dynamic>{
          'language': 'English',
          'fontSize': 16.0,
          'autoSave': true,
        }),
  };

  @override
  void initState() {
    super.initState();
    initializePersistence();
  }

  @override
  void dispose() {
    disposePersistence();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isHydrated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPreferencesCard(),
            const SizedBox(height: 16),
            _buildAppSettingsCard(),
            const SizedBox(height: 16),
            _buildAboutCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesCard() {
    final preferences = getPersistentValue<Map<String, bool>>('preferences');

    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Preferences',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _buildSettingItem(
            icon: Icons.notifications_rounded,
            title: 'Push Notifications',
            subtitle: 'Receive important updates and alerts',
            value: preferences['notifications'] ?? true,
            onChanged: (value) {
              final newPrefs = Map<String, bool>.from(preferences);
              newPrefs['notifications'] = value;
              setPersistentValue('preferences', newPrefs);
              HapticFeedback.lightImpact();
            },
          ),
          const Divider(height: 1),
          _buildSettingItem(
            icon: Icons.dark_mode_rounded,
            title: 'Dark Mode',
            subtitle: 'Use dark theme for better night viewing',
            value: preferences['darkMode'] ?? false,
            onChanged: (value) {
              final newPrefs = Map<String, bool>.from(preferences);
              newPrefs['darkMode'] = value;
              setPersistentValue('preferences', newPrefs);
              HapticFeedback.lightImpact();
            },
          ),
          const Divider(height: 1),
          _buildSettingItem(
            icon: Icons.analytics_rounded,
            title: 'Analytics',
            subtitle: 'Help us improve your experience',
            value: preferences['analytics'] ?? false,
            onChanged: (value) {
              final newPrefs = Map<String, bool>.from(preferences);
              newPrefs['analytics'] = value;
              setPersistentValue('preferences', newPrefs);
              HapticFeedback.lightImpact();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppSettingsCard() {
    final appSettings = getPersistentValue<Map<String, dynamic>>('appSettings');

    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.settings_rounded,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'App Settings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.language_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            title: const Text('Language'),
            subtitle: Text(appSettings['language'] ?? 'English'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showLanguageDialog(appSettings),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.text_fields_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            title: const Text('Font Size'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${(appSettings['fontSize'] ?? 16.0).toInt()}px'),
                const SizedBox(height: 8),
                Slider(
                  value: (appSettings['fontSize'] ?? 16.0).toDouble(),
                  min: 12.0,
                  max: 24.0,
                  divisions: 12,
                  onChanged: (value) {
                    final newSettings = Map<String, dynamic>.from(appSettings);
                    newSettings['fontSize'] = value;
                    setPersistentValue('appSettings', newSettings);
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildSettingItem(
            icon: Icons.save_rounded,
            title: 'Auto Save',
            subtitle: 'Automatically save changes',
            value: appSettings['autoSave'] ?? true,
            onChanged: (value) {
              final newSettings = Map<String, dynamic>.from(appSettings);
              newSettings['autoSave'] = value;
              setPersistentValue('appSettings', newSettings);
              HapticFeedback.lightImpact();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.info_outline_rounded,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            title: const Text('About'),
            subtitle: const Text('Learn more about this app'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _showAboutDialog,
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.red,
              ),
            ),
            title: const Text('Reset All Data'),
            subtitle: const Text('Clear all persistent data'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _resetAllData,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  void _showLanguageDialog(Map<String, dynamic> appSettings) {
    final languages = ['English', 'Spanish', 'French', 'German', 'Japanese'];
    final currentLanguage = appSettings['language'] ?? 'English';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((language) => RadioListTile<String>(
            value: language,
            groupValue: currentLanguage,
            onChanged: (value) {
              if (value != null) {
                final newSettings = Map<String, dynamic>.from(appSettings);
                newSettings['language'] = value;
                setPersistentValue('appSettings', newSettings);
                Navigator.pop(context);
                HapticFeedback.lightImpact();
              }
            },
            title: Text(language),
          )).toList(),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Persistent State Demo',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2024 Flutter Community',
      children: [
        const SizedBox(height: 16),
        const Text(
          'This beautiful app demonstrates the flutter_persistent_state package with modern Material 3 design.',
        ),
      ],
    );
  }

  void _resetAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Data'),
        content: const Text(
          'This will permanently delete all your data and reset the app to its initial state. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset Everything'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );

    if (confirmed == true) {
      await PersistentStateManager.instance.clearAll();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    }
  }
}

/// Additional preferences screen for more granular settings.
@PersistentState()
class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen>
    with PersistentStateMixin<PreferencesScreen> {

  @override
  Map<String, PersistentFieldConfig> get persistentFields => {
    'uiPreferences': persistentField('ui_preferences',
        defaultValue: <String, dynamic>{
          'showAnimations': true,
          'hapticFeedback': true,
          'soundEffects': false,
          'reducedMotion': false,
        }),
  };

  @override
  void initState() {
    super.initState();
    initializePersistence();
  }

  @override
  void dispose() {
    disposePersistence();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isHydrated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final preferences = getPersistentValue<Map<String, dynamic>>('uiPreferences');

    return Scaffold(
      appBar: AppBar(title: const Text('Preferences')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Column(
            children: [
              _buildPreferenceHeader(),
              _buildPreferenceItem(
                icon: Icons.animation_rounded,
                title: 'Show Animations',
                subtitle: 'Enable smooth transitions and effects',
                value: preferences['showAnimations'] ?? true,
                onChanged: (value) => _updatePreference('showAnimations', value),
              ),
              const Divider(height: 1),
              _buildPreferenceItem(
                icon: Icons.vibration_rounded,
                title: 'Haptic Feedback',
                subtitle: 'Feel vibrations for button taps',
                value: preferences['hapticFeedback'] ?? true,
                onChanged: (value) => _updatePreference('hapticFeedback', value),
              ),
              const Divider(height: 1),
              _buildPreferenceItem(
                icon: Icons.volume_up_rounded,
                title: 'Sound Effects',
                subtitle: 'Play sounds for interactions',
                value: preferences['soundEffects'] ?? false,
                onChanged: (value) => _updatePreference('soundEffects', value),
              ),
              const Divider(height: 1),
              _buildPreferenceItem(
                icon: Icons.accessibility_rounded,
                title: 'Reduced Motion',
                subtitle: 'Minimize motion for accessibility',
                value: preferences['reducedMotion'] ?? false,
                onChanged: (value) => _updatePreference('reducedMotion', value),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreferenceHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.palette_rounded,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'UI Preferences',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Customize your experience',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  void _updatePreference(String key, bool value) {
    final preferences = Map<String, dynamic>.from(
        getPersistentValue<Map<String, dynamic>>('uiPreferences')
    );
    preferences[key] = value;
    setPersistentValue('uiPreferences', preferences);
    HapticFeedback.lightImpact();
  }
}