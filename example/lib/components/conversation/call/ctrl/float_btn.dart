import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/call_model.dart';

class FloatBtn extends StatelessWidget {
  const FloatBtn({super.key});

  @override
  Widget build(BuildContext context) {
    final callModel = context.read<CallModel>();

    return Selector<CallModel, bool>(
        builder: (context, float, child) {
          return AnimatedPositioned(
            top: float ? -100 : 0,
            left: 0,
            right: 0,
            duration: const Duration(milliseconds: 500),
            child: IconButton(
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white,
                size: 30,
              ),
              onPressed: () {
                callModel.float = true;
              },
            ),
          );
        },
        selector: (ctx, s) => s.float);
  }
}
