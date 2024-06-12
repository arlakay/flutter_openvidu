import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:openvidu_client/openvidu_client.dart';

import '../utils/extensions.dart';

class ControlsWidget extends StatefulWidget {
  //
  final OpenViduClient room;
  final LocalParticipant participant;

  const ControlsWidget(
    this.room,
    this.participant, {
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ControlsWidgetState();
}

class _ControlsWidgetState extends State<ControlsWidget> {
  //
  StreamMode position = StreamMode.frontCamera;

  List<MediaDevice>? _audioInputs;
  List<MediaDevice>? _audioOutputs;
  List<MediaDevice>? _videoInputs;
  MediaDevice? selectedAudioInput;
  MediaDevice? selectedVideoInput;

  StreamSubscription? _subscription;

  bool isFrontCam = false;

  @override
  void initState() {
    Hardware.instance.enumerateDevices().then(
      (value) {
        print('ersa cek = ${value.toString()}');
        return _loadDevices(value);
      },
    );
    final audioId = participant.stream?.getVideoTracks().firstOrNull?.id;
    final videoId = participant.stream?.getVideoTracks().firstOrNull?.id;
    selectedAudioInput = _audioInputs?.firstWhereOrNull((el) => el.deviceId == audioId);
    selectedVideoInput = _videoInputs?.firstWhereOrNull((el) => el.deviceId == videoId);
    Hardware.instance.selectedAudioInput = selectedAudioInput;
    Hardware.instance.selectedVideoInput = selectedVideoInput;
    super.initState();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  LocalParticipant get participant => widget.participant;

  void _loadDevices(List<MediaDevice> devices) async {
    _audioInputs = devices.where((d) => d.kind == 'audioinput').toList();
    _audioOutputs = devices.where((d) => d.kind == 'audiooutput').toList();
    _videoInputs = devices.where((d) => d.kind == 'videoinput').toList();
    selectedAudioInput = _audioInputs?.first;
    selectedVideoInput = _videoInputs?.last;
    setState(() {});
  }

  void _onChange() {
    // trigger refresh
    setState(() {});
  }

  void _unpublishAll() async {
    final result = await context.showUnPublishDialog();
    if (result == true) await participant.unpublishAllTracks();
  }

  bool get isMuted => !participant.audioActive;

  bool get isVideoMuted => !participant.videoActive;

  void _disableAudio() async {
    await participant.publishAudio(false);
    setState(() {});
  }

  Future<void> _enableAudio() async {
    await participant.publishAudio(true);
    setState(() {});
  }

  void _disableVideo() async {
    await participant.publishVideo(false);
    setState(() {});
  }

  void _enableVideo() async {
    await participant.publishVideo(true);
    setState(() {});
  }

  void _selectAudioInput(MediaDevice device) async {
    await Hardware.instance.selectAudioInput(device);
    setState(() {});
  }

  void _selectVideoInput(MediaDevice? device) async {
    if (device == null) return;
    if (selectedVideoInput?.deviceId != device.deviceId) {
      widget.participant.setVideoInput(device.deviceId);
      selectedVideoInput = device;
      setState(() {});
    }
  }

  int indexCam = 0;

  void _selectVideoInputV2() async {
    print('cek cam index = ${_videoInputs![indexCam]}');

    // continuous switch between 0 and 1 camera index
    indexCam = 1 - indexCam; 

    widget.participant.setVideoInput(_videoInputs![indexCam].deviceId);
    selectedVideoInput = _videoInputs![indexCam];

    setState(() {});
  }

  void _toggleCamera() async {
    try {
      participant.switchCamera();
      final videoId = participant.stream?.getVideoTracks().firstOrNull?.id;
      selectedVideoInput = _videoInputs?.firstWhereOrNull((el) => el.deviceId == videoId);
    } catch (error) {
      print('could not restart track: $error');
      return;
    }
  }

  void _enableScreenShare() async {
    await widget.participant.shareScreen(context);
    setState(() {});
  }

  void _onTapDisconnect() async {
    final nav = Navigator.of(context);
    final result = await context.showDisconnectDialog();
    if (result == true) {
      await widget.room.disconnect();
      nav.pop();
    }
  }

  void _onTapSendData() async {
    final result = await context.showSendDataDialog();
    if (result == true) {
      await widget.room.sendMessage(
        OvMessage(data: 'This is a sample data message', to: [widget.participant.id]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 15,
        horizontal: 15,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // IconButton(
          //   onPressed: _unpublishAll,
          //   icon: const Icon(EvaIcons.closeCircleOutline),
          //   tooltip: 'Unpublish all',
          // ),
          const SizedBox(
            height: 40,
            width: 40,
          ),
          GestureDetector(
            onTap: isMuted ? _enableAudio : _disableAudio,
            child: Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isMuted ? Colors.red : Colors.white,
              ),
              child: IconButton(
                onPressed: isMuted ? _enableAudio : _disableAudio,
                icon: isMuted ? const Icon(Icons.mic_off) : const Icon(Icons.mic),
                color: isMuted ? Colors.white : Colors.black,
                tooltip: 'un-mute audio',
              ),
            ),
          ),
          // if (participant.videoActive)
          //   PopupMenuButton<MediaDevice>(
          //     icon: const Icon(EvaIcons.video),
          //     itemBuilder: (BuildContext context) {
          //       return [
          //         PopupMenuItem<MediaDevice>(
          //           value: null,
          //           onTap: _disableVideo,
          //           child: const ListTile(
          //             leading: Icon(
          //               EvaIcons.videoOff,
          //               color: Colors.white,
          //             ),
          //             title: Text('Disable Camera'),
          //           ),
          //         ),
          //         if (_videoInputs != null)
          //           ..._videoInputs!.map((device) {
          //             return PopupMenuItem<MediaDevice>(
          //               value: device,
          //               child: ListTile(
          //                 leading: (device.deviceId == selectedVideoInput?.deviceId)
          //                     ? const Icon(
          //                         EvaIcons.checkmarkSquare,
          //                         color: Colors.white,
          //                       )
          //                     : const Icon(
          //                         EvaIcons.square,
          //                         color: Colors.white,
          //                       ),
          //                 title: Text(device.label),
          //               ),
          //               onTap: () => _selectVideoInput(device),
          //             );
          //           }).toList()
          //       ];
          //     },
          //   )
          // else
          GestureDetector(
            onTap: () => _selectVideoInputV2(),
            child: Container(
              height: 40,
              width: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Center(
                child: IconButton(
                  onPressed: () => _selectVideoInputV2(),
                  icon: const Icon(Icons.flip_camera_android_rounded),
                  color: Colors.grey,
                  tooltip: 'un-mute video',
                ),
              ),
            ),
          ),
          // IconButton(
          //   onPressed: _onTapDisconnect,
          //   icon: const Icon(EvaIcons.closeCircle),
          //   tooltip: 'disconnect',
          // ),
        ],
      ),
    );
  }
}
