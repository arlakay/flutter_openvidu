// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';

// import 'package:eva_icons_flutter/eva_icons_flutter.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_background/flutter_background.dart';
// import 'package:openvidu_client/openvidu_client.dart';

// import '../utils/extensions.dart';

// class ControlsWidget extends StatefulWidget {
//   //
//   final OpenViduClient room;
//   final LocalParticipant participant;

//   const ControlsWidget(
//     this.room,
//     this.participant, {
//     Key? key,
//   }) : super(key: key);

//   @override
//   State<StatefulWidget> createState() => _ControlsWidgetState();
// }

// class _ControlsWidgetState extends State<ControlsWidget> {
//   //
//   StreamMode position = StreamMode.frontCamera;

//   List<MediaDeviceInfo>? _audioInputs;
//   List<MediaDeviceInfo>? _audioOutputs;
//   List<MediaDeviceInfo>? _videoInputs;
//   MediaDeviceInfo? _selectedVideoInput;

//   StreamSubscription? _subscription;

//   @override
//   void initState() {
//     super.initState();
//     participant.addListener(_onChange);

//     _loadDevices(widget.room.devices);
//   }

//   @override
//   void dispose() {
//     _subscription?.cancel();
//     participant.removeListener(_onChange);
//     super.dispose();
//   }

//   LocalParticipant get participant => widget.participant;

//   void _loadDevices(List<MediaDeviceInfo> devices) async {
//     _audioInputs = devices.where((d) => d.kind == 'audioinput').toList();
//     _audioOutputs = devices.where((d) => d.kind == 'audiooutput').toList();
//     _videoInputs = devices.where((d) => d.kind == 'videoinput').toList();
//     _selectedVideoInput = _videoInputs?.first;
//     setState(() {});
//   }

//   void _onChange() {
//     // trigger refresh
//     setState(() {});
//   }

//   void _unpublishAll() async {
//     final result = await context.showUnPublishDialog();
//     if (result == true) await participant.unpublishAllTracks();
//   }

//   bool get isMuted => participant.audioActive;

//   void _disableAudio() async {
//     participant.enableAudio(false);
//   }

//   Future<void> _enableAudio() async {
//     await participant.publishAudio(true);
//   }

//   void _disableVideo() async {
//     await participant.setCameraEnabled(false);
//   }

//   void _enableVideo() async {
//     await participant.setCameraEnabled(true);
//   }

//   void _selectAudioOutput(MediaDevice device) async {
//     await Hardware.instance.selectAudioOutput(device);
//     setState(() {});
//   }

//   void _selectAudioInput(MediaDevice device) async {
//     await Hardware.instance.selectAudioInput(device);
//     setState(() {});
//   }

//   void _selectVideoInput(MediaDevice device) async {
//     final track = participant.videoTracks.firstOrNull?.track;
//     if (track == null) return;
//     if (_selectedVideoInput?.deviceId != device.deviceId) {
//       await track.switchCamera(device.deviceId);
//       _selectedVideoInput = device;
//       setState(() {});
//     }
//   }

//   void _toggleCamera() async {
//     //
//     final track = participant.videoTracks.firstOrNull?.track;
//     if (track == null) return;

//     try {
//       final newPosition = position.switched();
//       await track.setCameraPosition(newPosition);
//       setState(() {
//         position = newPosition;
//       });
//     } catch (error) {
//       print('could not restart track: $error');
//       return;
//     }
//   }

//   void _enableScreenShare() async {
//     if (WebRTC.platformIsDesktop) {
//       try {
//         final source = await showDialog<DesktopCapturerSource>(
//           context: context,
//           builder: (context) => ScreenSelectDialog(),
//         );
//         if (source == null) {
//           print('cancelled screenshare');
//           return;
//         }
//         print('DesktopCapturerSource: ${source.id}');
//         var track = await LocalVideoTrack.createScreenShareTrack(
//           ScreenShareCaptureOptions(
//             sourceId: source.id,
//             maxFrameRate: 15.0,
//           ),
//         );
//         await participant.publishVideoTrack(track);
//       } catch (e) {
//         print('could not publish video: $e');
//       }
//       return;
//     }
//     if (WebRTC.platformIsAndroid) {
//       // Android specific
//       requestBackgroundPermission([bool isRetry = false]) async {
//         // Required for android screenshare.
//         try {
//           bool hasPermissions = await FlutterBackground.hasPermissions;
//           if (!isRetry) {
//             const androidConfig = FlutterBackgroundAndroidConfig(
//               notificationTitle: 'Screen Sharing',
//               notificationText: 'LiveKit Example is sharing the screen.',
//               notificationImportance: AndroidNotificationImportance.Default,
//               notificationIcon: AndroidResource(
//                   name: 'livekit_ic_launcher', defType: 'mipmap'),
//             );
//             hasPermissions = await FlutterBackground.initialize(
//                 androidConfig: androidConfig);
//           }
//           if (hasPermissions &&
//               !FlutterBackground.isBackgroundExecutionEnabled) {
//             await FlutterBackground.enableBackgroundExecution();
//           }
//         } catch (e) {
//           if (!isRetry) {
//             return await Future<void>.delayed(const Duration(seconds: 1),
//                 () => requestBackgroundPermission(true));
//           }
//           print('could not publish video: $e');
//         }
//       }

//       await requestBackgroundPermission();
//     }
//     if (WebRTC.platformIsIOS) {
//       var track = await LocalVideoTrack.createScreenShareTrack(
//         const ScreenShareCaptureOptions(
//           useiOSBroadcastExtension: true,
//           maxFrameRate: 15.0,
//         ),
//       );
//       await participant.publishVideoTrack(track);
//       return;
//     }
//     await participant.setScreenShareEnabled(true, captureScreenAudio: true);
//   }

//   void _disableScreenShare() async {
//     await participant.setScreenShareEnabled(false);
//     if (Platform.isAndroid) {
//       // Android specific
//       try {
//         //   await FlutterBackground.disableBackgroundExecution();
//       } catch (error) {
//         print('error disabling screen share: $error');
//       }
//     }
//   }

//   void _onTapDisconnect() async {
//     final result = await context.showDisconnectDialog();
//     if (result == true) await widget.room.disconnect();
//   }

//   void _onTapUpdateSubscribePermission() async {
//     final result = await context.showSubscribePermissionDialog();
//     if (result != null) {
//       try {
//         widget.room.localParticipant?.setTrackSubscriptionPermissions(
//           allParticipantsAllowed: result,
//         );
//       } catch (error) {
//         await context.showErrorDialog(error);
//       }
//     }
//   }

//   void _onTapSimulateScenario() async {
//     final result = await context.showSimulateScenarioDialog();
//     if (result != null) {
//       print('$result');
//       await widget.room.sendSimulateScenario(
//         signalReconnect:
//             result == SimulateScenarioResult.signalReconnect ? true : null,
//         nodeFailure: result == SimulateScenarioResult.nodeFailure ? true : null,
//         migration: result == SimulateScenarioResult.migration ? true : null,
//         serverLeave: result == SimulateScenarioResult.serverLeave ? true : null,
//         switchCandidate:
//             result == SimulateScenarioResult.switchCandidate ? true : null,
//       );
//     }
//   }

//   void _onTapSendData() async {
//     final result = await context.showSendDataDialog();
//     if (result == true) {
//       await widget.participant.publishData(
//         utf8.encode('This is a sample data message'),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(
//         vertical: 15,
//         horizontal: 15,
//       ),
//       child: Wrap(
//         alignment: WrapAlignment.center,
//         spacing: 5,
//         runSpacing: 5,
//         children: [
//           IconButton(
//             onPressed: _unpublishAll,
//             icon: const Icon(EvaIcons.closeCircleOutline),
//             tooltip: 'Unpublish all',
//           ),
//           if (participant.isMicrophoneEnabled())
//             PopupMenuButton<MediaDevice>(
//               icon: const Icon(Icons.settings_voice),
//               itemBuilder: (BuildContext context) {
//                 return [
//                   PopupMenuItem<MediaDevice>(
//                     value: null,
//                     onTap: isMuted ? _enableAudio : _disableAudio,
//                     child: const ListTile(
//                       leading: Icon(
//                         EvaIcons.micOff,
//                         color: Colors.white,
//                       ),
//                       title: Text('Mute Microphone'),
//                     ),
//                   ),
//                   if (_audioInputs != null)
//                     ..._audioInputs!.map((device) {
//                       return PopupMenuItem<MediaDevice>(
//                         value: device,
//                         child: ListTile(
//                           leading: (device.deviceId ==
//                                   Hardware
//                                       .instance.selectedAudioInput?.deviceId)
//                               ? const Icon(
//                                   EvaIcons.checkmarkSquare,
//                                   color: Colors.white,
//                                 )
//                               : const Icon(
//                                   EvaIcons.square,
//                                   color: Colors.white,
//                                 ),
//                           title: Text(device.label),
//                         ),
//                         onTap: () => _selectAudioInput(device),
//                       );
//                     }).toList()
//                 ];
//               },
//             )
//           else
//             IconButton(
//               onPressed: _enableAudio,
//               icon: const Icon(EvaIcons.micOff),
//               tooltip: 'un-mute audio',
//             ),
//           PopupMenuButton<MediaDevice>(
//             icon: const Icon(Icons.volume_up),
//             itemBuilder: (BuildContext context) {
//               return [
//                 const PopupMenuItem<MediaDevice>(
//                   value: null,
//                   child: ListTile(
//                     leading: Icon(
//                       EvaIcons.speaker,
//                       color: Colors.white,
//                     ),
//                     title: Text('Select Audio Output'),
//                   ),
//                 ),
//                 if (_audioOutputs != null)
//                   ..._audioOutputs!.map((device) {
//                     return PopupMenuItem<MediaDevice>(
//                       value: device,
//                       child: ListTile(
//                         leading: (device.deviceId ==
//                                 Hardware.instance.selectedAudioOutput?.deviceId)
//                             ? const Icon(
//                                 EvaIcons.checkmarkSquare,
//                                 color: Colors.white,
//                               )
//                             : const Icon(
//                                 EvaIcons.square,
//                                 color: Colors.white,
//                               ),
//                         title: Text(device.label),
//                       ),
//                       onTap: () => _selectAudioOutput(device),
//                     );
//                   }).toList()
//               ];
//             },
//           ),
//           if (participant.isCameraEnabled())
//             PopupMenuButton<MediaDevice>(
//               icon: const Icon(EvaIcons.video),
//               itemBuilder: (BuildContext context) {
//                 return [
//                   PopupMenuItem<MediaDevice>(
//                     value: null,
//                     onTap: _disableVideo,
//                     child: const ListTile(
//                       leading: Icon(
//                         EvaIcons.videoOff,
//                         color: Colors.white,
//                       ),
//                       title: Text('Disable Camera'),
//                     ),
//                   ),
//                   if (_videoInputs != null)
//                     ..._videoInputs!.map((device) {
//                       return PopupMenuItem<MediaDevice>(
//                         value: device,
//                         child: ListTile(
//                           leading:
//                               (device.deviceId == _selectedVideoInput?.deviceId)
//                                   ? const Icon(
//                                       EvaIcons.checkmarkSquare,
//                                       color: Colors.white,
//                                     )
//                                   : const Icon(
//                                       EvaIcons.square,
//                                       color: Colors.white,
//                                     ),
//                           title: Text(device.label),
//                         ),
//                         onTap: () => _selectVideoInput(device),
//                       );
//                     }).toList()
//                 ];
//               },
//             )
//           else
//             IconButton(
//               onPressed: _enableVideo,
//               icon: const Icon(EvaIcons.videoOff),
//               tooltip: 'un-mute video',
//             ),
//           IconButton(
//             icon: Icon(position == CameraPosition.back
//                 ? EvaIcons.camera
//                 : EvaIcons.person),
//             onPressed: () => _toggleCamera(),
//             tooltip: 'toggle camera',
//           ),
//           if (participant.isScreenShareEnabled())
//             IconButton(
//               icon: const Icon(EvaIcons.monitorOutline),
//               onPressed: () => _disableScreenShare(),
//               tooltip: 'unshare screen (experimental)',
//             )
//           else
//             IconButton(
//               icon: const Icon(EvaIcons.monitor),
//               onPressed: () => _enableScreenShare(),
//               tooltip: 'share screen (experimental)',
//             ),
//           IconButton(
//             onPressed: _onTapDisconnect,
//             icon: const Icon(EvaIcons.closeCircle),
//             tooltip: 'disconnect',
//           ),
//           IconButton(
//             onPressed: _onTapSendData,
//             icon: const Icon(EvaIcons.paperPlane),
//             tooltip: 'send demo data',
//           ),
//           IconButton(
//             onPressed: _onTapUpdateSubscribePermission,
//             icon: const Icon(EvaIcons.settings2),
//             tooltip: 'Subscribe permission',
//           ),
//           IconButton(
//             onPressed: _onTapSimulateScenario,
//             icon: const Icon(EvaIcons.alertTriangle),
//             tooltip: 'Simulate scenario',
//           ),
//         ],
//       ),
//     );
//   }
// }
