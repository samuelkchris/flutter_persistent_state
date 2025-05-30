import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:flutter_persistent_state/src/annotations/persistent_annotations.dart';
import 'package:source_gen/source_gen.dart';


/// Code generator for persistent state annotations.
///
/// This generator analyzes StatefulWidget classes marked with @PersistentState
/// and generates the necessary boilerplate code for automatic state persistence
/// and hydration. It creates extension methods and helper classes that integrate
/// seamlessly with the PersistentStateMixin.
///
/// The generator handles type-safe serialization, validation, debouncing,
/// and reactive updates while maintaining clean, readable generated code.
class PersistentStateGenerator extends GeneratorForAnnotation<PersistentState> {

  @override
  FutureOr<String> generateForAnnotatedElement(
      Element element,
      ConstantReader annotation,
      BuildStep buildStep,
      ) {
    if (element is! ClassElement || !element.name.endsWith('Widget')) {
      throw InvalidGenerationSourceError(
        'PersistentState can only be applied to StatefulWidget classes',
        element: element,
      );
    }

    final widgetClass = element;
    final persistentFields = _extractPersistentFields(widgetClass);

    if (persistentFields.isEmpty) {
      log.warning(
        'No @PersistentField annotations found in ${widgetClass.name}. '
            'Consider removing @PersistentState if no fields need persistence.',
      );
      return '';
    }

    final namespace = annotation.peek('namespace')?.stringValue;
    final backend = annotation.peek('backend')?.typeValue;
    final autoInitialize = annotation.peek('autoInitialize')?.boolValue ?? true;

    return _generatePersistentStateExtension(
      widgetClass,
      persistentFields,
      namespace: namespace,
      backend: backend,
      autoInitialize: autoInitialize,
    );
  }

  /// Extract persistent field information from the widget class.
  ///
  /// Analyzes all fields in the widget class and its state class to find
  /// those marked with @PersistentField annotations. Returns a list of
  /// field metadata that will be used for code generation.
  List<PersistentFieldInfo> _extractPersistentFields(ClassElement widgetClass) {
    final fields = <PersistentFieldInfo>[];
    final stateClass = _findStateClass(widgetClass);

    if (stateClass == null) {
      throw InvalidGenerationSourceError(
        'Could not find State class for ${widgetClass.name}',
        element: widgetClass,
      );
    }

    for (final field in stateClass.fields) {
      final annotation = _getPersistentFieldAnnotation(field);
      if (annotation != null) {
        fields.add(_createFieldInfo(field, annotation));
      }
    }

    for (final field in widgetClass.fields) {
      final annotation = _getPersistentFieldAnnotation(field);
      if (annotation != null) {
        fields.add(_createFieldInfo(field, annotation));
      }
    }

    return fields;
  }

  /// Find the corresponding State class for a StatefulWidget.
  ///
  /// Searches for a class that follows the pattern [WidgetName]State
  /// or _[WidgetName]State in the same library.
  ClassElement? _findStateClass(ClassElement widgetClass) {
    final library = widgetClass.library;
    final widgetName = widgetClass.name;

    final possibleNames = [
      '${widgetName}State',
      '_${widgetName}State',
    ];

    for (final name in possibleNames) {
      final stateClass = library.getClass(name);
      if (stateClass != null) {
        return stateClass;
      }
    }

    return null;
  }

  /// Extract PersistentField annotation from a field element.
  ConstantReader? _getPersistentFieldAnnotation(FieldElement field) {
    for (final metadata in field.metadata) {
      final annotation = metadata.computeConstantValue();
      if (annotation?.type?.element?.name == 'PersistentField') {
        return ConstantReader(annotation);
      }
    }
    return null;
  }

  /// Create field information from a field element and its annotation.
  PersistentFieldInfo _createFieldInfo(
      FieldElement field,
      ConstantReader annotation,
      ) {
    final key = annotation.peek('key')?.stringValue ?? field.name;
    final defaultValue = annotation.peek('defaultValue');
    final serializer = annotation.peek('serializer')?.stringValue;
    final deserializer = annotation.peek('deserializer')?.stringValue;
    final encrypted = annotation.peek('encrypted')?.boolValue ?? false;
    final validator = annotation.peek('validator')?.stringValue;

    Duration? debounce;
    final debounceValue = annotation.peek('debounce');
    if (debounceValue != null) {
      final microseconds = debounceValue.objectValue.getField('_duration')?.toIntValue();
      if (microseconds != null) {
        debounce = Duration(microseconds: microseconds);
      }
    }

    return PersistentFieldInfo(
      name: field.name,
      type: field.type,
      storageKey: key,
      defaultValue: defaultValue?.literalValue,
      serializer: serializer,
      deserializer: deserializer,
      encrypted: encrypted,
      debounce: debounce,
      validator: validator,
    );
  }

  /// Generate the complete persistent state extension code.
  ///
  /// Creates an extension on the widget's State class that provides
  /// automatic persistence capabilities, including field accessors,
  /// initialization methods, and lifecycle management.
  String _generatePersistentStateExtension(
      ClassElement widgetClass,
      List<PersistentFieldInfo> fields, {
        String? namespace,
        DartType? backend,
        bool autoInitialize = true,
      }) {
    final library = Library((b) => b
      ..body.addAll([
        _generateFieldsClass(widgetClass, fields, namespace),
        _generateStateExtension(widgetClass, fields, autoInitialize),
        ..._generateHelperMethods(widgetClass, fields),
      ]));

    final emitter = DartEmitter(
      allocator: Allocator.simplePrefixing(),
      orderDirectives: true,
      useNullSafetySyntax: true,
    );

    final source = library.accept(emitter).toString();
    return DartFormatter().format(source);
  }

  /// Generate a class that holds field configurations.
  Class _generateFieldsClass(
      ClassElement widgetClass,
      List<PersistentFieldInfo> fields,
      String? namespace,
      ) {
    final className = '_${widgetClass.name}PersistentFields';

    return Class((b) => b
      ..name = className
      ..docs.addAll([
        '/// Generated persistent field configurations for ${widgetClass.name}.',
        '///',
        '/// This class contains the field definitions and configurations',
        '/// needed for automatic state persistence and hydration.',
      ])
      ..fields.addAll(fields.map(_generateFieldDefinition))
      ..constructors.add(Constructor((b) => b
        ..constant = true
        ..name = '_'
      ))
      ..methods.add(_generateGetFieldsMethod(fields, namespace))
    );
  }

  /// Generate a field definition for a persistent field.
  Field _generateFieldDefinition(PersistentFieldInfo field) {
    return Field((b) => b
      ..name = field.name
      ..type = refer('PersistentFieldConfig<${field.type.getDisplayString()}>')
      ..static = true
      ..modifier = FieldModifier.final$
      ..assignment = _generateFieldConfiguration(field).code
    );
  }

  /// Generate the field configuration expression.
  Expression _generateFieldConfiguration(PersistentFieldInfo field) {
    var config = refer('PersistentFieldConfig').newInstance([
      literal(field.storageKey),
      _generateDefaultValueExpression(field),
    ]);

    if (field.validator != null) {
      config = config.property('withValidation').call([refer(field.validator!)]);
    }

    if (field.debounce != null) {
      config = config.property('withDebounce').call([
        refer('Duration').newInstance([], {
          'milliseconds': literal(field.debounce!.inMilliseconds),
        }),
      ]);
    }

    return config;
  }

  /// Generate the default value expression for a field.
  Expression _generateDefaultValueExpression(PersistentFieldInfo field) {
    if (field.defaultValue == null) {
      return literalNull;
    }

    final value = field.defaultValue!;

    if (value is String) {
      return literal(value);
    } else if (value is num) {
      return literal(value);
    } else if (value is bool) {
      return literal(value);
    } else if (value is List) {
      return literalList(value.map((item) => literal(item)));
    } else if (value is Map) {
      return literalMap(value.map((k, v) => MapEntry(literal(k), literal(v))));
    }

    return literal(value.toString());
  }

  /// Generate the getFields method that returns all field configurations.
  Method _generateGetFieldsMethod(
      List<PersistentFieldInfo> fields,
      String? namespace,
      ) {
    final entries = fields.map((field) =>
        literalString(field.name)
    );

    return Method((b) => b
      ..name = 'getFields'
      ..returns = refer('Map<String, PersistentFieldConfig>')
      ..static = true
      ..docs.addAll([
        '/// Get all persistent field configurations.',
        '///',
        '/// @returns map of field name to configuration',
      ])
      ..body = literalMap(Map.fromIterables(
        fields.map((f) => literal(f.name)),
        entries,
      )).returned.statement
    );
  }

  /// Generate the state extension that provides persistence functionality.
  Extension _generateStateExtension(
      ClassElement widgetClass,
      List<PersistentFieldInfo> fields,
      bool autoInitialize,
      ) {
    final stateClassName = '${widgetClass.name}State';

    return Extension((b) => b
      ..name = '${widgetClass.name}PersistentStateExtension'
      ..on = refer(stateClassName)
      ..docs.addAll([
        '/// Extension that adds persistent state capabilities to ${stateClassName}.',
        '///',
        '/// This extension automatically generates getters, setters, and',
        '/// lifecycle methods for managing persistent state.',
      ])
      ..methods.addAll([
        _generatePersistentFieldsGetter(widgetClass),
        ...fields.map(_generateFieldGetter),
        ...fields.map(_generateFieldSetter),
        if (autoInitialize) _generateAutoInitMethod(),
        _generateInitializePersistenceMethod(),
        _generateDisposePersistenceMethod(),
      ])
    );
  }

  /// Generate the persistentFields getter.
  Method _generatePersistentFieldsGetter(ClassElement widgetClass) {
    return Method((b) => b
      ..name = 'persistentFields'
      ..type = MethodType.getter
      ..returns = refer('Map<String, PersistentFieldConfig>')
      ..docs.addAll([
        '/// Get the persistent field configurations for this widget.',
        '///',
        '/// @returns map of field name to persistence configuration',
      ])
      ..body = refer('_${widgetClass.name}PersistentFields')
          .property('getFields')
          .call([])
          .returned
          .statement
    );
  }

  /// Generate a getter for a persistent field.
  Method _generateFieldGetter(PersistentFieldInfo field) {
    return Method((b) => b
      ..name = field.name
      ..type = MethodType.getter
      ..returns = refer(field.type.getDisplayString())
      ..docs.addAll([
        '/// Get the current value of ${field.name}.',
        '///',
        '/// @returns the current persisted value or default value',
      ])
      ..body = refer('getPersistentValue')
          .call([literal(field.name)])
          .returned
          .statement
    );
  }

  /// Generate a setter for a persistent field.
  Method _generateFieldSetter(PersistentFieldInfo field) {
    return Method((b) => b
      ..name = 'set${_capitalize(field.name)}'
      ..returns = refer('Future<void>')
      ..requiredParameters.add(Parameter((b) => b
        ..name = 'value'
        ..type = refer(field.type.getDisplayString())
      ))
      ..docs.addAll([
        '/// Set the value of ${field.name}.',
        '///',
        '/// @param value the new value to persist',
      ])
      ..body = refer('setPersistentValue')
          .call([literal(field.name), refer('value')])
          .statement
    );
  }

  /// Generate the auto-initialization method for StatefulWidget.initState.
  Method _generateAutoInitMethod() {
    return Method((b) => b
      ..name = 'initializePersistentState'
      ..returns = refer('Future<void>')
      ..docs.addAll([
        '/// Initialize persistent state automatically.',
        '///',
        '/// Call this method from your initState() override to enable',
        '/// automatic persistence for all annotated fields.',
      ])
      ..body = refer('initializePersistence').call([]).statement
    );
  }

  /// Generate the manual initialization method.
  Method _generateInitializePersistenceMethod() {
    return Method((b) => b
      ..name = 'initializePersistence'
      ..returns = refer('Future<void>')
      ..docs.addAll([
        '/// Initialize the persistence system for this widget.',
        '///',
        '/// This method sets up the persistence backend, loads saved values,',
        '/// and configures reactive updates for all persistent fields.',
      ])
      ..body = Block.of([
        refer('super').property('initializePersistence').call([]).statement,
      ])
    );
  }

  /// Generate the disposal method.
  Method _generateDisposePersistenceMethod() {
    return Method((b) => b
      ..name = 'disposePersistence'
      ..returns = refer('void')
      ..docs.addAll([
        '/// Dispose of persistence resources.',
        '///',
        '/// Call this method from your dispose() override to properly',
        '/// clean up persistence subscriptions and resources.',
      ])
      ..body = refer('super').property('disposePersistence').call([]).statement
    );
  }

  /// Generate helper methods for the widget.
  List<Method> _generateHelperMethods(
      ClassElement widgetClass,
      List<PersistentFieldInfo> fields,
      ) {
    return [
      _generateResetAllMethod(fields),
      _generateExportDataMethod(fields),
      _generateImportDataMethod(fields),
    ];
  }

  /// Generate a method to reset all persistent fields.
  Method _generateResetAllMethod(List<PersistentFieldInfo> fields) {
    return Method((b) => b
      ..name = 'resetAllPersistentFields'
      ..returns = refer('Future<void>')
      ..docs.addAll([
        '/// Reset all persistent fields to their default values.',
        '///',
        '/// This method removes all persisted data and restores',
        '/// all fields to their configured default values.',
      ])
      ..body = Block.of([
        ...fields.map((field) =>
        refer('resetPersistentField').call([literal(field.name)]).statement
        ),
      ])
    );
  }

  /// Generate a method to export all persistent data.
  Method _generateExportDataMethod(List<PersistentFieldInfo> fields) {
    final exportMap = Map.fromIterables(
      fields.map((f) => literal(f.name)),
      fields.map((f) => refer('getPersistentValue').call([literal(f.name)])),
    );

    return Method((b) => b
      ..name = 'exportPersistentData'
      ..returns = refer('Map<String, dynamic>')
      ..docs.addAll([
        '/// Export all persistent field values.',
        '///',
        '/// @returns a map of field names to their current values',
      ])
      ..body = literalMap(exportMap).returned.statement
    );
  }

  /// Generate a method to import persistent data.
  Method _generateImportDataMethod(List<PersistentFieldInfo> fields) {
    final statements = fields.map((field) =>
        Block.of([
          refer('data').property('containsKey').call([literal(field.name)])
              .conditional(
            refer('setPersistentValue').call([
              literal(field.name),
              refer('data').index(literal(field.name)),
            ]),
            refer('null'),
          )
              .statement,
        ])
    );

    return Method((b) => b
      ..name = 'importPersistentData'
      ..returns = refer('Future<void>')
      ..requiredParameters.add(Parameter((b) => b
        ..name = 'data'
        ..type = refer('Map<String, dynamic>')
      ))
      ..docs.addAll([
        '/// Import persistent field values from a data map.',
        '///',
        '/// @param data map of field names to values to import',
      ])
      ..body = Block.of(statements.expand((s) => s.statements))
    );
  }

  /// Capitalize the first letter of a string.
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

/// Information about a persistent field extracted from annotations.
///
/// This class holds all the metadata needed to generate appropriate
/// persistence code for a field, including type information, storage
/// configuration, and behavioral options.
class PersistentFieldInfo {
  /// The name of the field in the Dart class.
  final String name;

  /// The Dart type of the field.
  final DartType type;

  /// The storage key to use for persistence.
  final String storageKey;

  /// The default value for the field.
  final Object? defaultValue;

  /// Optional custom serializer function name.
  final String? serializer;

  /// Optional custom deserializer function name.
  final String? deserializer;

  /// Whether the field should be encrypted.
  final bool encrypted;

  /// Optional debounce duration.
  final Duration? debounce;

  /// Optional validation function name.
  final String? validator;

  const PersistentFieldInfo({
    required this.name,
    required this.type,
    required this.storageKey,
    this.defaultValue,
    this.serializer,
    this.deserializer,
    this.encrypted = false,
    this.debounce,
    this.validator,
  });

  /// Get the Dart type name as a string.
  String get typeName => type.getDisplayString();

  /// Check if this field needs custom serialization.
  bool get needsCustomSerialization => serializer != null || deserializer != null;

  /// Check if this field is a primitive type that can be stored directly.
  bool get isPrimitive {
    final element = type.element;
    if (element == null) return false;

    final primitiveTypes = {
      'String', 'int', 'double', 'bool',
      'List<String>', 'Map<String, dynamic>'
    };

    return primitiveTypes.contains(typeName);
  }
}

/// Builder for the persistent state code generator.
///
/// This builder configures the source_gen package to run the
/// PersistentStateGenerator on files containing the appropriate annotations.
Builder persistentStateBuilder(BuilderOptions options) {
  return SharedPartBuilder(
    [PersistentStateGenerator()],
    'persistent_state',
    allowSyntaxErrors: false,
  );
}