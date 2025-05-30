import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_persistent_state/src/core/persistent_state_manager.dart';


/// A TextEditingController that automatically persists its content.
///
/// This controller extends Flutter's TextEditingController to provide
/// automatic persistence of text content. It debounces changes, handles
/// validation, and provides reactive updates when the persisted value
/// changes from external sources.
///
/// The controller integrates seamlessly with existing TextField widgets
/// and provides additional features like auto-save indicators and
/// validation feedback.
class PersistentTextController extends TextEditingController {
  final PersistentStateManager _stateManager;
  final String _storageKey;
  final String _defaultValue;
  final Duration _debounce;
  final String? Function(String)? _validator;
  final void Function(String)? _onChanged;
  final void Function()? _onSaved;
  final void Function(String?)? _onError;

  Timer? _debounceTimer;
  StreamSubscription? _subscription;
  bool _isExternalUpdate = false;
  bool _hasUnsavedChanges = false;
  String? _lastError;

  /// Create a new persistent text controller.
  ///
  /// @param storageKey the key to use for persistence
  /// @param stateManager optional custom state manager instance
  /// @param defaultValue default text content
  /// @param debounce delay before persisting changes
  /// @param validator optional validation function
  /// @param onChanged callback when text changes
  /// @param onSaved callback when text is successfully persisted
  /// @param onError callback when persistence or validation fails
  PersistentTextController({
    required String storageKey,
    PersistentStateManager? stateManager,
    String defaultValue = '',
    Duration debounce = const Duration(milliseconds: 500),
    String? Function(String)? validator,
    void Function(String)? onChanged,
    void Function()? onSaved,
    void Function(String?)? onError,
  })  : _stateManager = stateManager ?? PersistentStateManager.instance,
        _storageKey = storageKey,
        _defaultValue = defaultValue,
        _debounce = debounce,
        _validator = validator,
        _onChanged = onChanged,
        _onSaved = onSaved,
        _onError = onError,
        super();

  /// Initialize the controller and load persisted content.
  ///
  /// This method must be called before using the controller.
  /// It loads any previously saved content and sets up reactive updates.
  Future<void> initialize() async {
    if (!_stateManager.isInitialized) {
      await _stateManager.initialize();
    }

    _stateManager.registerDefault(_storageKey, _defaultValue);

    final savedValue = await _stateManager.getValue<String>(_storageKey);
    if (savedValue != null && savedValue != text) {
      _isExternalUpdate = true;
      text = savedValue;
      _isExternalUpdate = false;
    }

    _subscription = _stateManager.getValueStream<String>(_storageKey).listen((value) {
      if (value != null && value != text) {
        _isExternalUpdate = true;
        text = value;
        _isExternalUpdate = false;
      }
    });

    addListener(_onTextChanged);
  }

  /// Clean up resources when the controller is no longer needed.
  @override
  void dispose() {
    _debounceTimer?.cancel();
    _subscription?.cancel();
    removeListener(_onTextChanged);
    super.dispose();
  }

  /// Whether there are unsaved changes pending persistence.
  bool get hasUnsavedChanges => _hasUnsavedChanges;

  /// The last validation or persistence error, if any.
  String? get lastError => _lastError;

  /// Force immediate persistence of the current content.
  ///
  /// This bypasses the debounce timer and immediately saves
  /// the current text content to persistent storage.
  Future<void> save() async {
    _debounceTimer?.cancel();
    await _persistText();
  }

  /// Reset the text to the last saved value.
  ///
  /// This discards any unsaved changes and restores the content
  /// to the most recently persisted value.
  Future<void> revert() async {
    final savedValue = await _stateManager.getValue<String>(_storageKey);
    if (savedValue != null) {
      _isExternalUpdate = true;
      text = savedValue;
      _isExternalUpdate = false;
      _hasUnsavedChanges = false;
      _lastError = null;
    }
  }

  /// Clear the persisted content and reset to default.
  ///
  /// This removes the saved content from storage and resets
  /// the text to the configured default value.
  Future<void> clear() async {
    await _stateManager.removeValue(_storageKey);
    _isExternalUpdate = true;
    text = _defaultValue;
    _isExternalUpdate = false;
    _hasUnsavedChanges = false;
    _lastError = null;
  }

  void _onTextChanged() {
    if (_isExternalUpdate) {
      return;
    }

    _hasUnsavedChanges = true;
    _lastError = null;
    _onChanged?.call(text);

    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, _persistText);
  }

  Future<void> _persistText() async {
    final currentText = text;

    if (_validator != null) {
      final error = _validator!(currentText);
      if (error != null) {
        _lastError = error;
        _onError?.call(error);
        return;
      }
    }

    try {
      await _stateManager.setValue(_storageKey, currentText);
      _hasUnsavedChanges = false;
      _lastError = null;
      _onSaved?.call();
    } catch (e) {
      _lastError = e.toString();
      _onError?.call(_lastError);
    }
  }
}

/// A TextField widget that automatically persists its content.
///
/// This widget combines a TextField with a PersistentTextController
/// to provide automatic text persistence with additional UI features
/// like save indicators, error display, and validation feedback.
class PersistentTextField extends StatefulWidget {
  /// The storage key for persisting the text content.
  final String storageKey;

  /// Optional custom state manager instance.
  final PersistentStateManager? stateManager;

  /// Default text content when no saved value exists.
  final String defaultValue;

  /// Delay before automatically saving changes.
  final Duration debounce;

  /// Optional validation function for the text content.
  final String? Function(String)? validator;

  /// Callback when the text changes.
  final void Function(String)? onChanged;

  /// Callback when text is successfully saved.
  final void Function()? onSaved;

  /// Callback when an error occurs during validation or saving.
  final void Function(String?)? onError;

  /// Whether to show a save indicator when there are unsaved changes.
  final bool showSaveIndicator;

  /// Whether to show error messages below the field.
  final bool showErrors;

  /// Whether to enable auto-save functionality.
  final bool autoSave;

  /// All the standard TextField properties.
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final TextStyle? style;
  final TextAlign textAlign;
  final TextAlignVertical? textAlignVertical;
  final bool autofocus;
  final bool readOnly;
  final bool? showCursor;
  final String obscuringCharacter;
  final bool obscureText;
  final bool autocorrect;
  final SmartDashesType? smartDashesType;
  final SmartQuotesType? smartQuotesType;
  final bool enableSuggestions;
  final int? maxLines;
  final int? minLines;
  final bool expands;
  final int? maxLength;
  final MaxLengthEnforcement? maxLengthEnforcement;
  final void Function(String)? onSubmitted;
  final void Function(String, Map<String, dynamic>)? onAppPrivateCommand;
  final List<TextInputFormatter>? inputFormatters;
  final bool? enabled;
  final double cursorWidth;
  final double? cursorHeight;
  final Radius? cursorRadius;
  final Color? cursorColor;
  final Brightness? keyboardAppearance;
  final EdgeInsets scrollPadding;
  final DragStartBehavior dragStartBehavior;
  final bool? enableInteractiveSelection;
  final TextSelectionControls? selectionControls;
  final void Function()? onTap;
  final MouseCursor? mouseCursor;
  final EditableTextContextMenuBuilder? contextMenuBuilder;
  final ScrollPhysics? scrollPhysics;
  final ScrollController? scrollController;
  final Iterable<String>? autofillHints;
  final String? restorationId;
  final bool enableIMEPersonalizedLearning;

  const PersistentTextField({
    super.key,
    required this.storageKey,
    this.stateManager,
    this.defaultValue = '',
    this.debounce = const Duration(milliseconds: 500),
    this.validator,
    this.onChanged,
    this.onSaved,
    this.onError,
    this.showSaveIndicator = true,
    this.showErrors = true,
    this.autoSave = true,
    this.decoration,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.style,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.autofocus = false,
    this.readOnly = false,
    this.showCursor,
    this.obscuringCharacter = '•',
    this.obscureText = false,
    this.autocorrect = true,
    this.smartDashesType,
    this.smartQuotesType,
    this.enableSuggestions = true,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.maxLength,
    this.maxLengthEnforcement,
    this.onSubmitted,
    this.onAppPrivateCommand,
    this.inputFormatters,
    this.enabled,
    this.cursorWidth = 2.0,
    this.cursorHeight,
    this.cursorRadius,
    this.cursorColor,
    this.keyboardAppearance,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.dragStartBehavior = DragStartBehavior.start,
    this.enableInteractiveSelection,
    this.selectionControls,
    this.onTap,
    this.mouseCursor,
    this.contextMenuBuilder,
    this.scrollPhysics,
    this.scrollController,
    this.autofillHints,
    this.restorationId,
    this.enableIMEPersonalizedLearning = true,
  });

  @override
  State<PersistentTextField> createState() => _PersistentTextFieldState();
}

class _PersistentTextFieldState extends State<PersistentTextField> {
  late PersistentTextController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeController() async {
    _controller = PersistentTextController(
      storageKey: widget.storageKey,
      stateManager: widget.stateManager,
      defaultValue: widget.defaultValue,
      debounce: widget.debounce,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onSaved: widget.onSaved,
      onError: widget.onError,
    );

    await _controller.initialize();

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return TextField(
        enabled: false,
        decoration: (widget.decoration ?? const InputDecoration()).copyWith(
          hintText: 'Loading...',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          decoration: _buildDecoration(),
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.textCapitalization,
          style: widget.style,
          textAlign: widget.textAlign,
          textAlignVertical: widget.textAlignVertical,
          autofocus: widget.autofocus,
          readOnly: widget.readOnly,
          showCursor: widget.showCursor,
          obscuringCharacter: widget.obscuringCharacter,
          obscureText: widget.obscureText,
          autocorrect: widget.autocorrect,
          smartDashesType: widget.smartDashesType,
          smartQuotesType: widget.smartQuotesType,
          enableSuggestions: widget.enableSuggestions,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          expands: widget.expands,
          maxLength: widget.maxLength,
          maxLengthEnforcement: widget.maxLengthEnforcement,
          onSubmitted: widget.onSubmitted,
          onAppPrivateCommand: widget.onAppPrivateCommand,
          inputFormatters: widget.inputFormatters,
          enabled: widget.enabled,
          cursorWidth: widget.cursorWidth,
          cursorHeight: widget.cursorHeight,
          cursorRadius: widget.cursorRadius,
          cursorColor: widget.cursorColor,
          keyboardAppearance: widget.keyboardAppearance,
          scrollPadding: widget.scrollPadding,
          dragStartBehavior: widget.dragStartBehavior,
          enableInteractiveSelection: widget.enableInteractiveSelection,
          selectionControls: widget.selectionControls,
          onTap: widget.onTap,
          mouseCursor: widget.mouseCursor,
          contextMenuBuilder: widget.contextMenuBuilder,
          scrollPhysics: widget.scrollPhysics,
          scrollController: widget.scrollController,
          autofillHints: widget.autofillHints,
          restorationId: widget.restorationId,
          enableIMEPersonalizedLearning: widget.enableIMEPersonalizedLearning,
        ),
        if (widget.showErrors && _controller.lastError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              _controller.lastError!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
        if (widget.showSaveIndicator && _controller.hasUnsavedChanges)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              children: [
                Icon(
                  Icons.edit,
                  size: 12,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Unsaved changes',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _controller.save,
                  child: Text(
                    'Save now',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  InputDecoration _buildDecoration() {
    var decoration = widget.decoration ?? const InputDecoration();

    if (widget.showSaveIndicator && _controller.hasUnsavedChanges) {
      decoration = decoration.copyWith(
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (decoration.suffixIcon != null) decoration.suffixIcon!,
            IconButton(
              icon: const Icon(Icons.save, size: 16),
              onPressed: _controller.save,
              tooltip: 'Save changes',
            ),
          ],
        ),
      );
    }

    return decoration;
  }
}

/// A form field wrapper for PersistentTextField.
///
/// This widget provides FormField integration for PersistentTextField,
/// enabling use within Form widgets with standard validation and
/// submission handling.
class PersistentTextFormField extends FormField<String> {
  /// Create a new persistent text form field.
  ///
  /// @param storageKey the key to use for persistence
  /// @param stateManager optional custom state manager instance
  /// @param defaultValue default text content
  /// @param debounce delay before automatically saving changes
  /// @param autovalidateMode validation mode for the form field
  /// @param showSaveIndicator whether to show save indicators
  /// @param showErrors whether to show error messages
  PersistentTextFormField({
    super.key,
    required String storageKey,
    PersistentStateManager? stateManager,
    String defaultValue = '',
    Duration debounce = const Duration(milliseconds: 500),
    String? Function(String)? persistentValidator,
    void Function(String)? onChanged,
    void Function()? onPersistentSaved,
    void Function(String?)? onError,
    bool showSaveIndicator = true,
    bool showErrors = true,
    super.validator,
    super.onSaved,
    super.autovalidateMode,
    super.enabled,
    super.restorationId,
    InputDecoration? decoration,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextStyle? style,
    TextAlign textAlign = TextAlign.start,
    TextAlignVertical? textAlignVertical,
    bool autofocus = false,
    bool readOnly = false,
    bool? showCursor,
    String obscuringCharacter = '•',
    bool obscureText = false,
    bool autocorrect = true,
    SmartDashesType? smartDashesType,
    SmartQuotesType? smartQuotesType,
    bool enableSuggestions = true,
    int? maxLines = 1,
    int? minLines,
    bool expands = false,
    int? maxLength,
    MaxLengthEnforcement? maxLengthEnforcement,
    void Function(String)? onFieldSubmitted,
    List<TextInputFormatter>? inputFormatters,
    double cursorWidth = 2.0,
    double? cursorHeight,
    Radius? cursorRadius,
    Color? cursorColor,
    Brightness? keyboardAppearance,
    EdgeInsets scrollPadding = const EdgeInsets.all(20.0),
    bool? enableInteractiveSelection,
    TextSelectionControls? selectionControls,
    void Function()? onTap,
    MouseCursor? mouseCursor,
    ScrollPhysics? scrollPhysics,
    ScrollController? scrollController,
    Iterable<String>? autofillHints,
    bool enableIMEPersonalizedLearning = true,
  }) : super(
    initialValue: defaultValue,
    builder: (FormFieldState<String> field) {
      return PersistentTextField(
        storageKey: storageKey,
        stateManager: stateManager,
        defaultValue: defaultValue,
        debounce: debounce,
        validator: persistentValidator,
        onChanged: (value) {
          field.didChange(value);
          onChanged?.call(value);
        },
        onSaved: onPersistentSaved,
        onError: onError,
        showSaveIndicator: showSaveIndicator,
        showErrors: showErrors,
        decoration: (decoration ?? const InputDecoration()).copyWith(
          errorText: field.errorText,
        ),
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        textCapitalization: textCapitalization,
        style: style,
        textAlign: textAlign,
        textAlignVertical: textAlignVertical,
        autofocus: autofocus,
        readOnly: readOnly,
        showCursor: showCursor,
        obscuringCharacter: obscuringCharacter,
        obscureText: obscureText,
        autocorrect: autocorrect,
        smartDashesType: smartDashesType,
        smartQuotesType: smartQuotesType,
        enableSuggestions: enableSuggestions,
        maxLines: maxLines,
        minLines: minLines,
        expands: expands,
        maxLength: maxLength,
        maxLengthEnforcement: maxLengthEnforcement,
        onSubmitted: onFieldSubmitted,
        inputFormatters: inputFormatters,
        enabled: enabled,
        cursorWidth: cursorWidth,
        cursorHeight: cursorHeight,
        cursorRadius: cursorRadius,
        cursorColor: cursorColor,
        keyboardAppearance: keyboardAppearance,
        scrollPadding: scrollPadding,
        enableInteractiveSelection: enableInteractiveSelection,
        selectionControls: selectionControls,
        onTap: onTap,
        mouseCursor: mouseCursor,
        scrollPhysics: scrollPhysics,
        scrollController: scrollController,
        autofillHints: autofillHints,
        enableIMEPersonalizedLearning: enableIMEPersonalizedLearning,
      );
    },
  );
}

