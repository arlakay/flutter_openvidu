import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/call_model.dart';
import 'audio_panel.dart';
import 'ctrl_panel.dart';
import 'video_panel.dart';

class CallPanel extends StatelessWidget {
  final bool isAudio;
  const CallPanel({Key? key, this.isAudio = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final srceen = MediaQuery.of(context);

    return Selector<CallModel, bool>(
      builder: (context, float, child) {
        return AnimatedPositioned(
          curve: Curves.easeInOut,
          duration: const Duration(milliseconds: 500),
          right: float ? 20 + srceen.padding.right : 0,
          top: float ? 20 + srceen.padding.top : 0,
          width: float ? 100 : srceen.size.width,
          height: float ? 150 : srceen.size.height,
          child: InkWell(
            child: child,
            onTap: () {
              if (float) context.read<CallModel>().float = false;
            },
          ),
        );
      },
      selector: (ctx, s) => s.float,
      child: ClipRect(
        child: Align(
          alignment: Alignment.center,
          child: Stack(
            children: [
              isAudio ? const AudioPanel() : const VideoPanel(),
              const CtrlPanel(),
            ],
          ),
        ),
      ),
    );
  }
}
