import 'package:flutter/material.dart';
import 'package:openvidu_client/openvidu_client.dart';
import 'package:provider/provider.dart';

import '../../models/call_model.dart';
import '../../models/conversation_model.dart';
import '../../models/token_model.dart';
import '../common/future_wrapper.dart';
import 'call/call_panel.dart';
import 'call/error_dialog.dart';
import 'call/timer.dart';

class Call extends StatelessWidget {
  const Call({super.key});

  @override
  Widget build(BuildContext context) {
    final tokenModel = ModalRoute.of(context)?.settings.arguments as TokenModel;
    final conversationModel = context.read<ConversationModel>();

    return ChangeNotifierProvider<CallModel>(
      create: (ctx) => CallModel(),
      builder: (context, child) {
        final callModel = context.read<CallModel>();

        final future = Future(() async {
          final token = await tokenModel.getToken();

          final mode = _isAudio(conversationModel)
              ? StreamMode.audio
              : StreamMode.frontCamera;

          // ignore: use_build_context_synchronously
          await callModel.start(context, tokenModel.userName, token, mode);
        });

        return FutureWrapper(
          future: future,
          builder: (context) {
            return Selector<CallModel, bool>(
              builder: (context, value, child) {
                //如果发现对方已经在房间内推流,而自己还没有推,则立即推流
                if (!callModel.enterd && value) callModel.enter();

                return child ?? Container();
              },
              selector: (ctx, s) => s.floatSelf,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CallPanel(isAudio: _isAudio(conversationModel)),
                  const Timer(),
                  const ErrorDialog()
                ],
              ),
            );
          },
        );
      },
    );
  }

  bool _isAudio(ConversationModel conversationModel) {
    return conversationModel.callMode == CallMode.Audio;
  }
}
