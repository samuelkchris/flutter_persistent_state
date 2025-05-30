#!/bin/bash

# Setup script for the Flutter Persistent State Package
# This script creates the complete project structure and provides guidance

set -e

echo "🚀 Flutter Persistent State Package Setup"
echo "=========================================="
echo ""

# Check if Dart is installed
if ! command -v dart &> /dev/null; then
    echo "❌ Error: Dart is not installed or not in PATH"
    echo "Please install Flutter/Dart SDK first: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "✅ Dart SDK found: $(dart --version 2>&1)"
echo ""

# Create the main project directory
PROJECT_NAME="flutter_persistent_state"
if [ -d "$PROJECT_NAME" ]; then
    echo "📁 Directory '$PROJECT_NAME' already exists."
    read -p "Do you want to continue and potentially overwrite files? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Setup cancelled."
        exit 1
    fi
fi

echo "📁 Creating project directory: $PROJECT_NAME"
cd "$PROJECT_NAME"

# Create the file generator script first
echo "📄 Creating file generator script..."
mkdir -p tool

cat > tool/generate_files.dart << 'EOF'
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
      'example/test', 'docs', 'docs/api', 'docs/guides', 'docs/examples',
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
      'docs/api/index.md': 'API documentation index',
      'docs/guides/getting_started.md': 'Getting started guide',
      'docs/examples/basic_usage.md': 'Basic usage examples',
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
EOF

# Make the generator script executable
chmod +x tool/generate_files.dart

# Run the file generator
echo "🏗️  Generating package structure..."
dart run tool/generate_files.dart

echo ""
echo "✅ Setup complete!"
echo ""
echo "📋 Next Steps:"
echo "1. Copy the code from the provided artifacts into the corresponding files:"
echo "   • Copy 'persistent_annotations.dart' code into lib/src/annotations/persistent_annotations.dart"
echo "   • Copy 'persistence_backend.dart' code into lib/src/backends/persistence_backend.dart"
echo "   • Copy 'shared_preferences_backend.dart' code into lib/src/backends/shared_preferences_backend.dart"
echo "   • Copy 'persistent_state_manager.dart' code into lib/src/core/persistent_state_manager.dart"
echo "   • Copy 'persistent_state_mixin.dart' code into lib/src/core/persistent_state_mixin.dart"
echo "   • Copy 'code_generator.dart' code into lib/src/generators/code_generator.dart"
echo "   • Copy 'navigation_integration.dart' code into lib/src/navigation/navigation_integration.dart"
echo "   • Copy 'text_field_integration.dart' code into lib/src/widgets/text_field_integration.dart"
echo "   • Copy 'main_export_file.dart' code into lib/flutter_persistent_state.dart"
echo "   • Copy configuration YAML code into pubspec.yaml, build.yaml, analysis_options.yaml"
echo "   • Copy README.md content"
echo "   • Copy test code into the test files"
echo "   • Copy example app code into example/lib/main.dart"
echo ""
echo "2. Install dependencies:"
echo "   cd $PROJECT_NAME"
echo "   flutter pub get"
echo ""
echo "3. Generate code:"
echo "   dart run build_runner build"
echo ""
echo "4. Run tests:"
echo "   flutter test"
echo ""
echo "5. Run the example app:"
echo "   cd example"
echo "   flutter run"
echo ""
echo "📁 Project structure created in: $(pwd)"
echo ""
echo "Happy coding! 🎉"
