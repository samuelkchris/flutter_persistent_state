#include "include/flutter_persistent_state/flutter_persistent_state_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "flutter_persistent_state_plugin.h"

void FlutterPersistentStatePluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flutter_persistent_state::FlutterPersistentStatePlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
