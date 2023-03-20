import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/token_model.dart';

class HomeForm extends StatelessWidget {
  const HomeForm({super.key});

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<TokenModel>(context, listen: false);

    return Form(
      child: Column(
        children: [
          TextFormField(
            decoration: const InputDecoration(labelText: "Server"),
            initialValue: model.server,
            onChanged: (val) => model.server = val,
          ),
          TextFormField(
            decoration: const InputDecoration(labelText: "Session"),
            initialValue: model.session,
            onChanged: (val) => model.session = val,
          ),
          TextFormField(
            decoration: const InputDecoration(labelText: "Usuario"),
            initialValue: model.userName,
            onChanged: (val) => model.userName = val,
          )
        ],
      ),
    );
  }
}
