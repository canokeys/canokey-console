import 'package:canokey_console/helper/widgets/my_route.dart';

class MyRoutes {
  static List<MyRoute> _routes = [];

  static List<MyRoute> get routes => _routes;

  static registerRoute(MyRoute route) {
    for (int i = 0; i < _routes.length; i++) {
      if (routes[i].name == route.name) {
        routes[i] = route;
        return;
      }
    }
    _routes.add(route);
  }

  static registerRoutes(List<MyRoute> routes) {
    for (var r in routes) {
      registerRoute(r);
    }
  }

  static void create([List<MyRoute>? routes]) {
    _routes = [];
    if (routes != null) _routes.addAll(routes);
  }

  @Deprecated('Use registerRoute method instead of this')
  static void add(MyRoute route) {
    _routes.add(route);
  }

  @Deprecated('Use registerRoutes method instead of this')
  static void addAll(List<MyRoute> routes) {
    _routes.addAll(routes);
  }
}
