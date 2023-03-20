import 'dart:io';

import 'package:flutter/material.dart';

import 'app/pages/connect_page.dart';
import 'theme/theme.dart';
import 'utils/global_http_overrides.dart';

void main() {
  HttpOverrides.global = GlobalHttpOverrides();

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'OpenViduClient Flutter Example',
        theme: OpenViduTheme().buildThemeData(context),
        home: const ConnectPage(),
      );
}

// void main() {
//   /////关闭https证书验证/////
//   HttpOverrides.global = GlobalHttpOverrides();
//   /////关闭https证书验证/////

//   runApp(App());
// }

// class App extends StatelessWidget {
//   const App({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       initialRoute: Home.routeName,
//       routes: {
//         Home.routeName: (ctx) => const Home(),
//         Conversation.routeName: (ctx) => const Conversation(),
//       },
//     );
//   }
// }
