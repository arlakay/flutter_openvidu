import 'dart:io';

import 'package:flutter/material.dart';

import 'pages/conversation.dart';
import 'pages/home.dart';
import 'utils/global_http_overrides.dart';

void main() {
  HttpOverrides.global = GlobalHttpOverrides();

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: Home.routeName,
      routes: {
        Home.routeName: (ctx) => const Home(),
        Conversation.routeName: (ctx) => const Conversation(),
      },
    );
  }
}
