import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/call_model.dart';

class AnswerBtn extends StatelessWidget {
  const AnswerBtn({super.key});

  @override
  Widget build(BuildContext context) {
    final float = context.select<CallModel, bool>((value) => value.float);

    return FloatingActionButton(
      heroTag: "answer",
      onPressed: context.read<CallModel>().enter,
      backgroundColor: Colors.green.shade300,
      mini: float,
      child: const Icon(Icons.call),
    );
  }
}
