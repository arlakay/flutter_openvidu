import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/call_model.dart';
import '../../../../models/conversation_model.dart';
import 'answer_btn.dart';
import 'close_btn.dart';

class ActionBar extends StatelessWidget {
  const ActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    final enterd = context.select<CallModel, bool>((value) => value.enterd);
    final isOffer = context.read<ConversationModel>().isCallOffer;
    final List<Widget> children = [const CloseBtn()];
    if (!enterd && !isOffer) children.add(const AnswerBtn());

    return Selector<CallModel, bool>(
      builder: (context, float, child) {
        return AnimatedPositioned(
          duration: const Duration(milliseconds: 500),
          bottom: float ? 10 : 50,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: children,
          ),
        );
      },
      selector: (ctx, s) => s.float,
    );
  }
}
