import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final roomOptions = const RoomOptions(
    adaptiveStream: true,
    dynacast: true,
  );

  Participant<TrackPublication<Track>>? localParticipant; //自分側
  Participant<TrackPublication<Track>>? remoteParticipant; //相手側
  Room? roomstate;

  @override
  void initState() {
    super.initState();
    connectToLivekit();
  }

  Future<void> connectToLivekit() async {
    const url = 'wss://my-example-ljubn5ws.livekit.cloud'; //LivekitのKey
    const token =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3MDc1NzAxMzgsImlzcyI6IkFQSW1WaFJSamM0aE41aSIsIm5iZiI6MTcwNzU2OTIzOCwic3ViIjoic2ltIiwidmlkZW8iOnsiY2FuUHVibGlzaCI6dHJ1ZSwiY2FuUHVibGlzaERhdGEiOnRydWUsImNhblN1YnNjcmliZSI6dHJ1ZSwicm9vbSI6InRlc3QiLCJyb29tSm9pbiI6dHJ1ZX19.2eEQc1jCgfBkhVYiOsWqQj6qAzIatl2lKVuQ0QfoRUo'; //LivekitのKey
    final room = Room(roomOptions: roomOptions);
    roomstate = room;

    room.createListener().on<TrackSubscribedEvent>((event) {
      //他の参加者の接続
      print('-----track event : $event');
      setState(() {
        remoteParticipant = event.participant;
      });
    });

    try {
      await room.connect(url, token);
    } catch (_) {
      print('Failed : $_');
    }

    setState(() {
      localParticipant = room.localParticipant!;
    });

    await room.localParticipant!.setCameraEnabled(true); //カメラの接続
    await room.localParticipant!.setMicrophoneEnabled(true); //マイクの接続
  }

  // @override
  // Future<void> generateToken(uuid) async {
  //   HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
  //     'generateToken',
  //   );
  //   final randomname = const Uuid().v4();
  //   final Map<String, dynamic> requestBody = {
  //     'roomName': uuid,
  //     'randomname': randomname
  //   };
  //   final results = await callable(requestBody);
  //   Map<String, dynamic> data = results.data;

  //   String token = data['token'];
  //   state = state.copyWith(token: token);
  //   print("generateToken finished");
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('LiveKit.ex')),
      body: Center(
        child: Column(
          children: [
            // local video
            localParticipant != null
                ? Expanded(child: ParticipantWidget(localParticipant!))
                : const CircularProgressIndicator(),
            // remote video
            remoteParticipant != null
                ? Expanded(child: ParticipantWidget(remoteParticipant!))
                : const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class ParticipantWidget extends StatefulWidget {
  final Participant participant;
  const ParticipantWidget(this.participant, {super.key});

  @override
  State<StatefulWidget> createState() {
    return _ParticipantState();
  }
}

class _ParticipantState extends State<ParticipantWidget> {
  TrackPublication? videoPub;

  @override
  void initState() {
    super.initState();
    widget.participant.addListener(_onChange);
  }

  @override
  void dispose() {
    super.dispose();
    widget.participant.removeListener(_onChange);
  }

  void _onChange() {
    var visibleVideos = widget.participant.videoTrackPublications.where((pub) {
      return pub.kind == TrackType.VIDEO && pub.subscribed && !pub.muted;
    });

    if (visibleVideos.isNotEmpty) {
      setState(() {
        videoPub = visibleVideos.first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (videoPub != null) {
      return VideoTrackRenderer(videoPub?.track as VideoTrack);
    } else {
      return Container(
        color: Colors.grey,
      );
    }
  }
}
