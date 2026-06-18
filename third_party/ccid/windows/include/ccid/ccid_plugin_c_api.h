#ifndef FLUTTER_PLUGIN_CCID_PLUGIN_C_API_H_
#define FLUTTER_PLUGIN_CCID_PLUGIN_C_API_H_

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FLUTTER_PLUGIN_EXPORT __declspec(dllimport)
#endif

#if defined(__cplusplus)
extern "C" {
#endif

FLUTTER_PLUGIN_EXPORT void CcidPluginCApiRegisterWithRegistrar(
    void *registrar);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // FLUTTER_PLUGIN_CCID_PLUGIN_C_API_H_
