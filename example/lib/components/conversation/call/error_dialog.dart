import 'package:flutter/material.dart';
import 'package:openvidu_client/openvidu_client.dart';
import 'package:provider/provider.dart';

import '../../../models/call_model.dart';
import '../../../models/conversation_model.dart';

class ErrorDialog extends StatelessWidget {
  const ErrorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    var conversationModel = context.read<ConversationModel>();

    return Selector<CallModel, OpenViduError?>(
      builder: (context, error, child) {
        if (error == null) return const SizedBox.shrink();

        return Container(
          color: Colors.black45,
          child: AlertDialog(
            title: const Text('insinuación'),
            content: Text(error.message),
            actions: <Widget>[
              TextButton(
                child: const Text('devolver'),
                onPressed: () async {
                  conversationModel.stopCall();
                },
              ),
            ],
          ),
        );
      },
      selector: (ctx, s) => s.error,
    );
  }
}
