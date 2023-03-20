import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/home/home_form.dart';
import '../models/token_model.dart';
import 'conversation.dart';

class Home extends StatelessWidget {
  static const routeName = "/home";

  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // if (!kIsWeb) {
    //   print('EsWeb');
    //   PermissionChecker.check();
    // }

    void submit(TokenModel model) async {
      Navigator.pushNamed(context, Conversation.routeName, arguments: model);
    }

    return Scaffold(
        appBar: AppBar(
          title: const Text("Home"),
        ),
        body: ChangeNotifierProvider(
          create: (context) => TokenModel(),
          builder: (context, child) => Stack(
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: HomeForm(),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 50),
                  child: Consumer<TokenModel>(
                    builder: (context, value, child) => MaterialButton(
                      onPressed: () => submit(value),
                      color: theme.colorScheme.secondary,
                      textColor: Colors.white,
                      child: const Text("Entrar a la sala"),
                    ),
                  ),
                ),
              )
            ],
          ),
        ));
  }
}
