import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_persistent_state/flutter_persistent_state.dart';

/// Complete example application demonstrating the persistent state package.
///
/// This app showcases all major features of the package including:
/// - Automatic field persistence with annotations
/// - Navigation state management
/// - Text field integration with auto-save
/// - Form handling with validation
/// - Settings management
/// - User onboarding flow
/// - Search functionality with history
///
/// The app demonstrates how to eliminate boilerplate while maintaining
/// clean, readable code and excellent user experience.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final navigationObserver = PersistentNavigationObserver(
    excludedRoutes: {'/', '/onboarding'},
  );

  runApp(ExampleApp(observer: navigationObserver));
}

class ExampleApp extends StatelessWidget {
  final PersistentNavigationObserver observer;

  const ExampleApp({super.key, required this.observer});

  @override
  Widget build(BuildContext context) {
    return PersistentNavigationWrapper(
      observer: observer,
      restoreOnStart: true,
      maxRouteAge: const Duration(days: 30),
      shouldRestore: (routeData) {
        final routeName = routeData['name'] as String?;
        return routeName != null && routeName != '/onboarding';
      },
      onRestorationComplete: (restored, routeName) {
        debugPrint('Navigation restored: $restored to $routeName');
      },
      child: MaterialApp(
        title: 'Persistent State Demo',
        navigatorObservers: [observer],
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/onboarding': (context) => const OnboardingScreen(),
          '/home': (context) => const HomeScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/search': (context) => const SearchScreen(),
        },
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
      ),
    );
  }
}

/// Splash screen that handles initial app setup and navigation.
///
/// This screen checks if the user has completed onboarding and
/// either navigates to the onboarding flow or the main app.
/// It demonstrates how to use persistent state for app-level decisions.
@PersistentState()
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with PersistentStateMixin<SplashScreen> {

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
    _initializeApp();
  }

  @override
  void dispose() {
    disposePersistence();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    await initializePersistence();

    await setPersistentValue('lastLaunchTime', DateTime.now().millisecondsSinceEpoch);

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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FlutterLogo(size: 100),
            const SizedBox(height: 24),
            Text(
              'Persistent State Demo',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

/// Onboarding screen with persistent progress tracking.
///
/// This screen demonstrates how to track user progress through
/// a multi-step onboarding flow with automatic state persistence.
@PersistentState()
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with PersistentStateMixin<OnboardingScreen> {

  final PageController _pageController = PageController();

  @override
  Map<String, PersistentFieldConfig> get persistentFields => {
    'currentPage': persistentField('onboarding_page', defaultValue: 0),
    'userName': persistentField('onboarding_name', defaultValue: ''),
    'userPreferences': persistentField('onboarding_prefs',
        defaultValue: <String, bool>{}),
  };

  @override
  void initState() {
    super.initState();
    _initializeOnboarding();
  }

  @override
  void dispose() {
    _pageController.dispose();
    disposePersistence();
    super.dispose();
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
  }

  void _nextPage() {
    final currentPage = getPersistentValue<int>('currentPage');
    if (currentPage < 2) {
      final nextPage = currentPage + 1;
      setPersistentValue('currentPage', nextPage);
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() async {
    final splashState = PersistentStateManager.instance;
    await splashState.setValue('has_completed_onboarding', true);

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isHydrated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildWelcomePage(),
          _buildNamePage(),
          _buildPreferencesPage(),
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
          const Icon(Icons.waving_hand, size: 100, color: Colors.orange),
          const SizedBox(height: 24),
          Text(
            'Welcome!',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 16),
          Text(
            'This app demonstrates persistent state management with zero boilerplate.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: _nextPage,
            child: const Text('Get Started'),
          ),
        ],
      ),
    );
  }

  Widget _buildNamePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person, size: 100, color: Colors.blue),
          const SizedBox(height: 24),
          Text(
            'What\'s your name?',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 32),
          PersistentTextField(
            storageKey: 'onboarding_name',
            decoration: const InputDecoration(
              labelText: 'Enter your name',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value.trim().isEmpty ? 'Name is required' : null,
            showSaveIndicator: false,
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () {
              if (getPersistentValue<String>('userName').trim().isNotEmpty) {
                _nextPage();
              }
            },
            child: const Text('Continue'),
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
          const Icon(Icons.settings, size: 100, color: Colors.green),
          const SizedBox(height: 24),
          Text(
            'Set your preferences',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 32),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Enable notifications'),
                  value: preferences['notifications'] ?? true,
                  onChanged: (value) {
                    final newPrefs = Map<String, bool>.from(preferences);
                    newPrefs['notifications'] = value;
                    setPersistentValue('userPreferences', newPrefs);
                  },
                ),
                SwitchListTile(
                  title: const Text('Dark mode'),
                  value: preferences['darkMode'] ?? false,
                  onChanged: (value) {
                    final newPrefs = Map<String, bool>.from(preferences);
                    newPrefs['darkMode'] = value;
                    setPersistentValue('userPreferences', newPrefs);
                  },
                ),
                SwitchListTile(
                  title: const Text('Analytics'),
                  value: preferences['analytics'] ?? false,
                  onChanged: (value) {
                    final newPrefs = Map<String, bool>.from(preferences);
                    newPrefs['analytics'] = value;
                    setPersistentValue('userPreferences', newPrefs);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: _completeOnboarding,
            child: const Text('Complete Setup'),
          ),
        ],
      ),
    );
  }
}

/// Main home screen demonstrating reactive persistent state.
///
/// This screen shows how persistent state automatically updates
/// the UI when values change, creating a reactive experience
/// without manual state management.
@PersistentState()
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with PersistentStateMixin<HomeScreen> {

  @override
  Map<String, PersistentFieldConfig> get persistentFields => {
    'userName': persistentField('onboarding_name', defaultValue: 'User'),
    'counter': persistentField('home_counter', defaultValue: 0),
    'favoriteItems': persistentField('favorite_items', defaultValue: <String>[]),
    'lastVisit': persistentField('last_home_visit',
        defaultValue: DateTime.now().millisecondsSinceEpoch),
  };

  @override
  void initState() {
    super.initState();
    _initializeHome();
  }

  @override
  void dispose() {
    disposePersistence();
    super.dispose();
  }

  Future<void> _initializeHome() async {
    await initializePersistence();
    await setPersistentValue('lastVisit', DateTime.now().millisecondsSinceEpoch);
  }

  void _incrementCounter() {
    final current = getPersistentValue<int>('counter');
    setPersistentValue('counter', current + 1);
    HapticFeedback.lightImpact();
  }

  void _addFavorite(String item) {
    final favorites = List<String>.from(getPersistentValue<List<String>>('favoriteItems'));
    if (!favorites.contains(item)) {
      favorites.add(item);
      setPersistentValue('favoriteItems', favorites);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isHydrated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final userName = getPersistentValue<String>('userName');
    final counter = getPersistentValue<int>('counter');
    final favorites = getPersistentValue<List<String>>('favoriteItems');

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome back, $userName!'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, '/search'),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Counter: $counter',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _incrementCounter,
                      child: const Text('Increment'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Favorites',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            if (favorites.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No favorites yet. Tap the + button to add some!'),
                ),
              )
            else
              Card(
                child: Column(
                  children: favorites.map((item) => ListTile(
                    leading: const Icon(Icons.favorite),
                    title: Text(item),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        final newFavorites = List<String>.from(favorites);
                        newFavorites.remove(item);
                        setPersistentValue('favoriteItems', newFavorites);
                      },
                    ),
                  )).toList(),
                ),
              ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      children: [
                        ActionChip(
                          label: const Text('Add Favorite'),
                          avatar: const Icon(Icons.add),
                          onPressed: () => _showAddFavoriteDialog(),
                        ),
                        ActionChip(
                          label: const Text('Reset Counter'),
                          avatar: const Icon(Icons.refresh),
                          onPressed: () => setPersistentValue('counter', 0),
                        ),
                        ActionChip(
                          label: const Text('Clear Favorites'),
                          avatar: const Icon(Icons.clear),
                          onPressed: () => setPersistentValue('favoriteItems', <String>[]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFavoriteDialog,
        child: const Icon(Icons.add),
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
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _addFavorite(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

/// Profile screen with form handling and persistent text fields.
///
/// This screen demonstrates how to use persistent text fields
/// in forms with validation, auto-save, and reactive updates.
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
    'profileData': persistentField('profile_data', defaultValue: <String, dynamic>{}),
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
            icon: const Icon(Icons.save),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 50,
                child: Icon(Icons.person, size: 50),
              ),
              const SizedBox(height: 24),
              PersistentTextFormField(
                storageKey: 'onboarding_name',
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              PersistentTextFormField(
                storageKey: 'user_email',
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || !value.contains('@')) {
                    return 'Valid email is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              PersistentTextFormField(
                storageKey: 'user_phone',
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              PersistentTextFormField(
                storageKey: 'user_bio',
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  child: const Text('Save Profile'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _resetProfile,
                child: const Text('Reset to Defaults'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveProfile() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _resetProfile() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Profile'),
        content: const Text('Are you sure you want to reset all profile data?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await resetAllPersistentFields();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile reset to defaults')),
        );
      }
    }
  }
}

/// Settings screen demonstrating various persistent controls.
///
/// This screen shows how to use persistent state with different
/// types of form controls and complex data structures.
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
        defaultValue: <String, bool>{}),
    'themeMode': persistentField('theme_mode', defaultValue: 'system'),
    'language': persistentField('app_language', defaultValue: 'en'),
    'fontSize': persistentField('font_size', defaultValue: 14.0),
    'autoSave': persistentField('auto_save_enabled', defaultValue: true),
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

    final preferences = getPersistentValue<Map<String, bool>>('preferences');
    final themeMode = getPersistentValue<String>('themeMode');
    final language = getPersistentValue<String>('language');
    final fontSize = getPersistentValue<double>('fontSize');
    final autoSave = getPersistentValue<bool>('autoSave');

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme'),
            subtitle: Text(themeMode),
            trailing: DropdownButton<String>(
              value: themeMode,
              items: const [
                DropdownMenuItem(value: 'light', child: Text('Light')),
                DropdownMenuItem(value: 'dark', child: Text('Dark')),
                DropdownMenuItem(value: 'system', child: Text('System')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setPersistentValue('themeMode', value);
                }
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            subtitle: Text(language),
            trailing: DropdownButton<String>(
              value: language,
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'es', child: Text('Spanish')),
                DropdownMenuItem(value: 'fr', child: Text('French')),
                DropdownMenuItem(value: 'de', child: Text('German')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setPersistentValue('language', value);
                }
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('Font Size'),
            subtitle: Slider(
              value: fontSize,
              min: 10.0,
              max: 24.0,
              divisions: 14,
              label: fontSize.toStringAsFixed(0),
              onChanged: (value) => setPersistentValue('fontSize', value),
            ),
          ),
          SwitchListTile(
            leading: const Icon(Icons.save),
            title: const Text('Auto Save'),
            subtitle: const Text('Automatically save changes'),
            value: autoSave,
            onChanged: (value) => setPersistentValue('autoSave', value),
          ),
          const Divider(),
          SwitchListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            value: preferences['notifications'] ?? true,
            onChanged: (value) {
              final newPrefs = Map<String, bool>.from(preferences);
              newPrefs['notifications'] = value;
              setPersistentValue('preferences', newPrefs);
            },
          ),
          SwitchListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Analytics'),
            subtitle: const Text('Help improve the app'),
            value: preferences['analytics'] ?? false,
            onChanged: (value) {
              final newPrefs = Map<String, bool>.from(preferences);
              newPrefs['analytics'] = value;
              setPersistentValue('preferences', newPrefs);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            onTap: () => _showAboutDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Reset All Data'),
            textColor: Colors.red,
            iconColor: Colors.red,
            onTap: () => _resetAllData(),
          ),
        ],
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
        const Text('This app demonstrates the flutter_persistent_state package.'),
      ],
    );
  }

  void _resetAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Data'),
        content: const Text(
          'This will delete all your data and reset the app to its initial state. '
              'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset Everything'),
          ),
        ],
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

/// Search screen with persistent search history.
///
/// This screen demonstrates how to use persistent text fields
/// with search functionality and automatic history management.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<String> _searchHistory = [];
  List<String> _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    final history = await PersistentTextUtils.getSearchHistory();
    setState(() {
      _searchHistory = history;
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await PersistentTextUtils.addToSearchHistory(query);
    await _loadSearchHistory();

    await Future.delayed(const Duration(milliseconds: 800));

    final results = _mockSearch(query);

    setState(() {
      _searchResults = results;
      _isLoading = false;
    });
  }

  List<String> _mockSearch(String query) {
    final allItems = [
      'Flutter Development',
      'Dart Programming',
      'State Management',
      'Persistent Storage',
      'Mobile Development',
      'Cross-platform Apps',
      'UI Design',
      'User Experience',
      'Performance Optimization',
      'Testing Strategies',
      'Code Architecture',
      'Material Design',
      'Cupertino Design',
      'Animation Techniques',
      'Navigation Patterns',
    ];

    return allItems
        .where((item) => item.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: 'Search...',
            border: InputBorder.none,
          ),
          autofocus: true,
          onSubmitted: _performSearch,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _performSearch(_controller.text),
          ),
          if (_searchHistory.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () => _showSearchHistory(),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoading)
            const LinearProgressIndicator(),
          Expanded(
            child: _buildSearchContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchContent() {
    if (_searchResults.isNotEmpty) {
      return ListView.builder(
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final result = _searchResults[index];
          return ListTile(
            leading: const Icon(Icons.search),
            title: Text(result),
            onTap: () {
              _controller.text = result;
              _performSearch(result);
            },
          );
        },
      );
    }

    if (_searchHistory.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Searches',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: () async {
                    await PersistentTextUtils.clearSearchHistory();
                    await _loadSearchHistory();
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _searchHistory.length,
              itemBuilder: (context, index) {
                final query = _searchHistory[index];
                return ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(query),
                  trailing: IconButton(
                    icon: const Icon(Icons.north_west),
                    onPressed: () {
                      _controller.text = query;
                    },
                  ),
                  onTap: () {
                    _controller.text = query;
                    _performSearch(query);
                  },
                );
              },
            ),
          ),
        ],
      );
    }

    return const Center(
      child: Text('Start typing to search...'),
    );
  }

  void _showSearchHistory() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Search History'),
            trailing: TextButton(
              onPressed: () async {
                await PersistentTextUtils.clearSearchHistory();
                await _loadSearchHistory();
                Navigator.pop(context);
              },
              child: const Text('Clear All'),
            ),
          ),
          const Divider(),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _searchHistory.length,
              itemBuilder: (context, index) {
                final query = _searchHistory[index];
                return ListTile(
                  title: Text(query),
                  onTap: () {
                    _controller.text = query;
                    Navigator.pop(context);
                    _performSearch(query);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}