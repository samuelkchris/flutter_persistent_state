#!/usr/bin/env dart

/// Script to generate the complete file and folder structure for the flutter_persistent_state package.
///
/// This script creates all necessary directories and empty files for the persistent state package.
/// Run this script to set up the initial project structure, then copy the code from the artifacts
/// into the appropriate files.

import 'dart:io';

Future<void> main() async {
  print('🚀 Generating Flutter Persistent State Package Structure...\n');
  
  final generator = PackageGenerator();
  await generator.generatePackage();
  
  print('\n✅ Package structure generated successfully!');
  print('\n📋 Next steps:');
  print('1. Copy the code from each artifact into the corresponding file');
  print('2. Run: flutter pub get');
  print('3. Run: dart run build_runner build');
  print('4. Run tests: flutter test');
}

class PackageGenerator {
  Future<void> generatePackage() async {
    await _createDirectoryStructure();
    await _createSourceFiles();
    await _createTestFiles();
    await _createExampleApp();
    await _createConfigurationFiles();
    await _createDocumentationFiles();
    await _createToolFiles();
  }
  
  Future<void> _createDirectoryStructure() async {
    print('📁 Creating directory structure...');
    
    final directories = [
      'lib', 'lib/src', 'lib/src/annotations', 'lib/src/backends',
      'lib/src/core', 'lib/src/generators', 'lib/src/navigation',
      'lib/src/widgets', 'lib/src/utils', 'test', 'test/unit',
      'test/widget', 'test/integration', 'test/mocks', 'example',
      'example/lib', 'example/lib/screens', 'example/lib/widgets',
      'example/test', 'doc', 'doc/api', 'doc/guides', 'doc/examples',
      'tool', 'tool/scripts', '.github', '.github/workflows',
    ];
    
    for (final dir in directories) {
      await Directory(dir).create(recursive: true);
      print('  ✓ Created: $dir/');
    }
  }
  
  Future<void> _createSourceFiles() async {
    print('\n📄 Creating source files...');
    
    final sourceFiles = {
      'lib/flutter_persistent_state.dart': 'Main library export file',
      'lib/src/annotations/persistent_annotations.dart': 'Core annotations for persistence',
      'lib/src/backends/persistence_backend.dart': 'Abstract backend interface',
      'lib/src/backends/shared_preferences_backend.dart': 'SharedPreferences implementation',
      'lib/src/core/persistent_state_manager.dart': 'Main state management class',
      'lib/src/core/persistent_state_mixin.dart': 'Widget mixin for persistence',
      'lib/src/generators/code_generator.dart': 'Build-time code generator',
      'lib/src/navigation/navigation_integration.dart': 'Navigation state persistence',
      'lib/src/widgets/text_field_integration.dart': 'Persistent text field widgets',
      'lib/src/utils/persistent_text_utils.dart': 'Text field utility functions',
    };
    
    for (final entry in sourceFiles.entries) {
      await _createFile(entry.key, entry.value);
    }
  }
  
  Future<void> _createTestFiles() async {
    print('\n🧪 Creating test files...');
    
    final testFiles = {
      'test/unit/backend_test.dart': 'Backend implementation tests',
      'test/unit/manager_test.dart': 'State manager tests',
      'test/unit/mixin_test.dart': 'Widget mixin tests',
      'test/widget/text_field_test.dart': 'Text field widget tests',
      'test/integration/full_app_test.dart': 'Full application tests',
      'test/mocks/memory_backend.dart': 'In-memory backend for testing',
    };
    
    for (final entry in testFiles.entries) {
      await _createFile(entry.key, entry.value);
    }
  }
  
  Future<void> _createExampleApp() async {
    print('\n🎯 Creating example application...');
    
    final exampleFiles = {
      'example/lib/main.dart': 'Example app main entry point',
      'example/lib/screens/home_screen.dart': 'Main home screen',
      'example/pubspec.yaml': 'Example app dependencies',
    };
    
    for (final entry in exampleFiles.entries) {
      await _createFile(entry.key, entry.value);
    }
  }
  
  Future<void> _createConfigurationFiles() async {
    print('\n⚙️  Creating configuration files...');
    
    final configFiles = {
      'pubspec.yaml': 'Package dependencies and metadata',
      'build.yaml': 'Build runner configuration',
      'analysis_options.yaml': 'Dart analyzer configuration',
      'README.md': 'Package documentation and usage guide',
      'CHANGELOG.md': 'Version history and changes',
      'LICENSE': 'Package license (MIT)',
      '.gitignore': 'Git ignore rules',
    };
    
    for (final entry in configFiles.entries) {
      await _createFile(entry.key, entry.value);
    }
  }
  
  Future<void> _createDocumentationFiles() async {
    print('\n📚 Creating documentation files...');
    
    final docFiles = {
      'doc/api/index.md': 'API documentation index',
      'doc/guides/getting_started.md': 'Getting started guide',
      'doc/examples/basic_usage.md': 'Basic usage examples',
    };
    
    for (final entry in docFiles.entries) {
      await _createFile(entry.key, entry.value);
    }
  }
  
  Future<void> _createToolFiles() async {
    print('\n🔧 Creating additional tool files...');
    
    final toolFiles = {
      'tool/scripts/format.dart': 'Code formatting script',
      'tool/scripts/analyze.dart': 'Code analysis script',
      'tool/scripts/test.dart': 'Test runner script',
    };
    
    for (final entry in toolFiles.entries) {
      await _createFile(entry.key, entry.value);
    }
  }
  
  Future<void> _createFile(String filePath, String description) async {
    final file = File(filePath);
    await file.parent.create(recursive: true);
    
    String header;
    if (filePath.endsWith('.dart')) {
      header = '/// $description\n///\n/// File: $filePath\n\n// TODO: Copy code from artifacts\n';
    } else if (filePath.endsWith('.yaml')) {
      header = '# $description\n# File: $filePath\n\n# TODO: Add configuration\n';
    } else if (filePath.endsWith('.md')) {
      final title = filePath.split('/').last.replaceAll('.md', '').replaceAll('_', ' ');
      header = '# ${title[0].toUpperCase()}${title.substring(1)}\n\n$description\n\nTODO: Add content\n';
    } else {
      header = '// $description\n// File: $filePath\n';
    }
    
    await file.writeAsString(header);
    print('  ✓ Created: $filePath');
  }
}
