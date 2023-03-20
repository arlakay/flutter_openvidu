import 'package:flutter/material.dart';

import 'ctrl/action_bar.dart';
import 'ctrl/float_btn.dart';

class CtrlPanel extends StatelessWidget {
  const CtrlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Stack(children: const [
        FloatBtn(),
        ActionBar(),
      ]),
    );
  }
}
