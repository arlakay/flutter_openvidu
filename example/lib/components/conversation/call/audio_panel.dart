import 'package:flutter/material.dart';

class AudioPanel extends StatelessWidget {
  const AudioPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //语音通话不需要进行stream渲染动作,只需要添加一张背景
    return Stack(
      children: [
        Container(
          color: Colors.black45,
          child: const Center(
            child: Text(
              "Llamada de voz, reemplazada por la imagen de fondo del proyecto",
              style: TextStyle(color: Colors.white),
            ),
          ),
        )
      ],
    );
  }
}
