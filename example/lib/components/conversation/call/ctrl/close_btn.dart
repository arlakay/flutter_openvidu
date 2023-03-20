import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/call_model.dart';
import '../../../../models/conversation_model.dart';

class CloseBtn extends StatelessWidget {
  const CloseBtn({super.key});

  @override
  Widget build(BuildContext context) {
    final float = context.select<CallModel, bool>((value) => value.float);
    return FloatingActionButton(
      heroTag: "close",
      onPressed: context.read<ConversationModel>().stopCall,
      backgroundColor: Colors.red.shade300,
      mini: float,
      child: const Icon(Icons.close),
    );
  }
}
