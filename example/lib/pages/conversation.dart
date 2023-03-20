import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/conversation/call.dart';
import '../components/conversation/chat.dart';
import '../models/conversation_model.dart';

class Conversation extends StatelessWidget {
  static const routeName = "/conversation";

  const Conversation({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ChangeNotifierProvider<ConversationModel>(
        create: (context) => ConversationModel(),
        builder: (context, child) {
          return Stack(
            children: [
              const Chat(),
              Selector<ConversationModel, bool>(
                builder: (context, call, child) {
                  return call ? const Call() : const SizedBox.expand();
                },
                selector: (ctx, s) => s.callMode != CallMode.None,
              ),
            ],
          );
        },
      ),
    );
  }
}
