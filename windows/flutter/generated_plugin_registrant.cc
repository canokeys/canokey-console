//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <audioplayers_windows/audioplayers_windows_plugin.h>
#include <ccid/ccid_plugin_c_api.h>
#include <file_saver/file_saver_plugin.h>
#include <flutter_webrtc/flutter_web_r_t_c_plugin.h>
#include <sentry_flutter/sentry_flutter_plugin.h>
#include <url_launcher_windows/url_launcher_windows.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  AudioplayersWindowsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("AudioplayersWindowsPlugin"));
  CcidPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("CcidPluginCApi"));
  FileSaverPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FileSaverPlugin"));
  FlutterWebRTCPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FlutterWebRTCPlugin"));
  SentryFlutterPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("SentryFlutterPlugin"));
  UrlLauncherWindowsRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("UrlLauncherWindows"));
}
