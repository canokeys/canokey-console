#ifndef FLUTTER_PLUGIN_CCID_PLUGIN_H_
#define FLUTTER_PLUGIN_CCID_PLUGIN_H_

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __attribute__((visibility("default")))
#else
#define FLUTTER_PLUGIN_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

FLUTTER_PLUGIN_EXPORT void ccid_plugin_register_with_registrar(
    void* registrar);

#ifdef __cplusplus
}
#endif

#endif  // FLUTTER_PLUGIN_CCID_PLUGIN_H_
