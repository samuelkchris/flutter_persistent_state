#ifndef FLUTTER_PLUGIN_FLUTTER_PERSISTENT_STATE_PLUGIN_H_
#define FLUTTER_PLUGIN_FLUTTER_PERSISTENT_STATE_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace flutter_persistent_state {

class FlutterPersistentStatePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FlutterPersistentStatePlugin();

  virtual ~FlutterPersistentStatePlugin();

  // Disallow copy and assign.
  FlutterPersistentStatePlugin(const FlutterPersistentStatePlugin&) = delete;
  FlutterPersistentStatePlugin& operator=(const FlutterPersistentStatePlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace flutter_persistent_state

#endif  // FLUTTER_PLUGIN_FLUTTER_PERSISTENT_STATE_PLUGIN_H_
