import 'package:flutter/widgets.dart';
import 'package:mallory_launcher/configuration/configuration_screen.dart';

final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
  '/Config': (BuildContext context) => ConfigurationScreen(),
};
