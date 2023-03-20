import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:openvidu_client/openvidu_client.dart';

import 'drop_down.dart';
import 'media_stream_view.dart';
import 'text_field.dart';

class ConfigView extends StatefulWidget {
  final LocalParticipant participant;
  final String userName;
  final VoidCallback onConnect;
  const ConfigView({
    super.key,
    required this.onConnect,
    required this.participant,
    this.userName = '',
  });

  @override
  State<ConfigView> createState() => _ConfigViewState();
}

class _ConfigViewState extends State<ConfigView> {
  final TextEditingController _textUserNameController = TextEditingController();

  List<MediaDevice>? _audioInputs;
  List<MediaDevice>? _audioOutputs;
  List<MediaDevice>? _videoInputs;
  MediaDevice? selectedAudioInput;
  MediaDevice? selectedVideoInput;

  StreamSubscription? _subscription;

  @override
  void initState() {
    _textUserNameController.text = widget.userName;
    super.initState();
    _subscription = Hardware.instance.onDeviceChange.stream
        .listen((List<MediaDevice> devices) {
      _loadDevices(devices);
    });
    Hardware.instance.enumerateDevices().then(_loadDevices);
  }

  void _loadDevices(List<MediaDevice> devices) async {
    _audioInputs = devices.where((d) => d.kind == 'audioinput').toList();
    _audioOutputs = devices.where((d) => d.kind == 'audiooutput').toList();
    _videoInputs = devices.where((d) => d.kind == 'videoinput').toList();
    selectedAudioInput = _audioInputs?.first;
    selectedVideoInput = _videoInputs?.first;
    setState(() {});
  }

  void _selectAudioInput(MediaDevice? device) async {
    if (device == null) return;
    if (kIsWeb) {
      widget.participant.setAudioInput(device.deviceId);
    } else {
      await Hardware.instance.selectAudioInput(device);
    }
    selectedAudioInput = device;
    setState(() {});
  }

  void _selectVideoInput(MediaDevice? device) async {
    if (device == null) return;
    if (selectedVideoInput?.deviceId != device.deviceId) {
      widget.participant.selectVideoInput(device.deviceId);
      selectedVideoInput = device;
      setState(() {});
    }
  }

  void _connect(BuildContext context) {}

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
                stream: widget.participant.stream,
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
                      enabled: false,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 25),
                    child: OVDropDown(
                      label: 'Input',
                      devices: _audioInputs ?? [],
                      selectDevice: selectedAudioInput,
                      onChanged: _selectAudioInput,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 25),
                    child: OVDropDown(
                      label: 'Video',
                      devices: _videoInputs ?? [],
                      selectDevice: selectedVideoInput,
                      onChanged: _selectVideoInput,
                    ),
                  ),
                  // Padding(
                  //   padding: const EdgeInsets.only(bottom: 25),
                  //   child: OVTextField(
                  //     label: 'Secret',
                  //     ctrl: _textSecretController,
                  //   ),
                  // ),
                  ElevatedButton(
                    onPressed: widget.onConnect,
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