import 'package:canokey_console/helper/utils/logging.dart';
import 'package:flutter/widgets.dart';
import 'package:logger/logger.dart';

class LogNavigationObserver extends NavigatorObserver {
  LogNavigationObserver({Logger? logger})
      : _log = logger ?? Logging.logger('Navigation');

  final Logger _log;

  String _name(Route<dynamic>? route) => route == null
      ? '<none>'
      : route.settings.name ?? (route is PopupRoute ? '<dialog>' : '<unnamed>');

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log.t('Push: ${_name(previousRoute)} -> ${_name(route)}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log.t('Pop: ${_name(route)} -> ${_name(previousRoute)}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _log.t('Replace: ${_name(oldRoute)} -> ${_name(newRoute)}');
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log.t('Remove: ${_name(route)}; previous=${_name(previousRoute)}');
  }
}
