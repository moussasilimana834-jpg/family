import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

const String appId = '997fdd9f062a4e13a0defdbb299f799d';

class LiveStreamPage extends StatefulWidget {
  final String liveId;
  final bool isBroadcaster;

  const LiveStreamPage({
    super.key,
    required this.liveId,
    required this.isBroadcaster,
  });

  @override
  State<LiveStreamPage> createState() => _LiveStreamPageState();
}

class _LiveStreamPageState extends State<LiveStreamPage> {
  late final RtcEngine _engine;
  int? _remoteUid;
  bool _isjoined = false;
  bool _isMuted = false;
  bool _isVideoDisabled = false;
  bool _isEngineDisposed = false;

  @override
  void initState() {
    super.initState();
    _initEngine();
  }

  @override
  void dispose() {
    _disposeEngine();
    super.dispose();
  }

  Future<void> _disposeEngine() async {
    if (_isEngineDisposed) return;
    _isEngineDisposed = true;
    await _engine.leaveChannel();
    await _engine.release();
  }

  Future<void> _initEngine() async {
    await [Permission.microphone, Permission.camera].request();
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(appId: appId));
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("onjoinChannelSuccess: channel = ${connection.channelId} uid= ${connection.localUid}");
          setState(() {
            _isjoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("onUserJoined: uid =$remoteUid");
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          debugPrint("onUserOffline: uid =$remoteUid");
          setState(() {
            _remoteUid = null;
          });
        },
        onError: (err, msg) {
          debugPrint("onError: $err, $msg");
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          debugPrint("onLeaveChannel");
          setState(() {
            _isjoined = false;
          });
        },
      ),
    );
    // active le module video
    await _engine.enableVideo();
    //definir le role (Broadcaster ou Listener)
    ClientRoleType role = widget.isBroadcaster
        ? ClientRoleType.clientRoleBroadcaster
        : ClientRoleType.clientRoleAudience;
    await _engine.setClientRole(role: role);
    // sin on diffuseur on demarre l'apercu local
    if (widget.isBroadcaster) {
      await _engine.startPreview();
    }
    // Rejoindre le canal
    await _engine.joinChannel(
      token: '',
      channelId: widget.liveId,
      uid: 0,
      options: ChannelMediaOptions(
        clientRoleType: role,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        // Logique pour quitter proprement
        await _disposeEngine();
        if (context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        body: SafeArea(
          child: _isjoined // on affiche le contenu seulement si on a rejoint le canal
              ? Stack(
                  children: [
                    // widget qui affiche les videos
                    _buildVideoViews(),
                    // widget qui affiche les boutons
                    _buildControls(),
                  ],
                )
              : const Center(
                  child: CircularProgressIndicator(),
                ),
        ),
      ),
    );
  }

// widget pour construire le vue video
  Widget _buildVideoViews() {
    //si on est le diffuseur , on affiche notre propre video
    if (widget.isBroadcaster) {
      return AgoraVideoView(
          controller: VideoViewController(
        rtcEngine: _engine,
        canvas: const VideoCanvas(uid: 0), // uid = 0 pour la vue locale
      ));
    } else {
      // si on est spectacteur , on affiche la video du diffuseur distant
      if (_remoteUid != null) {
        return AgoraVideoView(
            controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid!),
          connection: RtcConnection(channelId: widget.liveId),
        ));
      } else {
        // message en attendant que le diffuseur arrive
        return const Center(
          child: Text(
            "En attente du diffuseur...",
            style: TextStyle(color: Colors.white),
          ),
        );
      }
    }
  }

// widget pour les boutons de controle
  Widget _buildControls() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // boutoon pour couper/activer le micro
            if (widget.isBroadcaster) ...[
              IconButton(
                onPressed: () {
                  setState(() {
                    _isMuted = !_isMuted;
                  });
                  _engine.muteLocalAudioStream(_isMuted);
                },
                icon: Icon(_isMuted ? Icons.mic_off : Icons.mic),
                color: Colors.white,
                iconSize: 32,
              ),
              const SizedBox(width: 16),
              // bouton pour couper/activer la camera
              IconButton(
                onPressed: () {
                  setState(() {
                    _isVideoDisabled = !_isVideoDisabled;
                  });
                  _engine.enableLocalVideo(!_isVideoDisabled);
                },
                icon: Icon(_isVideoDisabled ? Icons.videocam_off : Icons.videocam),
                color: Colors.white,
                iconSize: 32,
              ),
              const SizedBox(width: 16),
            ],
            // bouton pour raccrocher
            IconButton(
              onPressed: () {
                // declenche le onpopInvoked du Popscope
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.call_end),
              color: Colors.redAccent,
              iconSize: 40,
            )
          ],
        ),
      ),
    );
  }
}
