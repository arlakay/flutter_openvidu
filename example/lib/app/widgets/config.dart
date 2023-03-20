import 'package:flutter/material.dart';
import 'package:openvidu_client/openvidu_client.dart';

import 'media_stream_view.dart';
import 'text_field.dart';

class ConfigView extends StatelessWidget {
  final MediaStream stream;
  final OpenViduClient openvidu;
  final MediaDeviceInfo? inputDevice;
  final void Function(MediaDeviceInfo?) onChangeInput;
  const ConfigView(
      {super.key,
      required this.stream,
      required this.openvidu,
      required this.onChangeInput,
      required this.inputDevice});

  static final TextEditingController _textUserNameController =
      TextEditingController();

  _connect(BuildContext context) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                  top: 80, left: 60, bottom: 30, right: 30),
              child: MediaStreamView(
                borderRadius: BorderRadius.circular(15),
                stream: stream,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 70),
                    child: Image.asset(
                      'assets/logo.png',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 25),
                    child: OVTextField(
                      label: 'Username',
                      ctrl: _textUserNameController,
                    ),
                  ),
                  // Padding(
                  //   padding: const EdgeInsets.only(bottom: 25),
                  //   child: OVDropDown(
                  //     label: 'Input Device',
                  //     devices: openvidu.audioInputs,
                  //     selectDevice: inputDevice,
                  //     onChanged: onChangeInput,
                  //   ),
                  // ),
                  // Padding(
                  //   padding: const EdgeInsets.only(bottom: 25),
                  //   child: OVTextField(
                  //     label: 'Secret',
                  //     ctrl: _textSecretController,
                  //   ),
                  // ),
                  ElevatedButton(
                    onPressed: () => _connect(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Padding(
                          padding: EdgeInsets.only(right: 10),
                          child: SizedBox(
                            height: 15,
                            width: 15,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        Text('CONNECT'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
