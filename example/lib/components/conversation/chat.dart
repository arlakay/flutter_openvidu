import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/conversation_model.dart';

class Chat extends StatelessWidget {
  const Chat({super.key});

  @override
  Widget build(BuildContext context) {
    var startCall = context.read<ConversationModel>().startCall;

    return Align(
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => startCall(CallMode.Video, true),
                child: const Text("Iniciar una videollamada"),
              ),
              TextButton(
                onPressed: () => startCall(CallMode.Audio, true),
                child: const Text("Iniciar una llamada de voz"),
              ),
              TextButton(
                onPressed: () => startCall(CallMode.Video, false),
                child: const Text("Ingrese el estado del timbre de video"),
              ),
              TextButton(
                onPressed: () => startCall(CallMode.Audio, false),
                child: const Text("Ingrese el estado de timbre de voz"),
              )
            ],
          ),
          const TextField()
        ],
      ),
    );
  }
}
