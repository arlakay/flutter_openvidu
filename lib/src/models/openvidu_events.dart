typedef EventDispatcher = Function(
    OpenViduEvent event, Map<String, dynamic> params);
typedef EventHandler
    = Map<OpenViduEvent, Function(Map<String, dynamic> params)>;

enum OpenViduEvent {
  joinRoom,
  userJoined,
  userPublished,
  error,
  addStream,
  removeStream,
  publishVideo,
  publishAudio,
  audioActive,
  videoActive,
  audioTrack,
  videoTrack,
  videoDimensions,
  sendMessage,
}
