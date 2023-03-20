import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/call_model.dart';

class Timer extends StatelessWidget {
  const Timer({super.key});

  @override
  Widget build(BuildContext context) {
    final srceen = MediaQuery.of(context);
    return Selector<CallModel, bool>(
      builder: (context, float, child) {
        return AnimatedPositioned(
          curve: Curves.easeInOut,
          duration: const Duration(milliseconds: 500),
          right: float ? 20 + srceen.padding.right : 0,
          top: (float ? 180 : 40) + srceen.padding.top,
          width: float ? 100 : srceen.size.width,
          child: child ?? Container(),
        );
      },
      selector: (ctx, s) => s.float,
      child: const Center(
        child: Text(
          "29:30:00",
          style: TextStyle(color: Colors.redAccent),
        ),
      ),
    );
  }
}
