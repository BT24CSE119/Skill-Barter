import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../dashboard/dashboard_screen.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class CallingScreen extends StatefulWidget {
  final String callId;
  final String sessionId;
  final bool isCaller;

  const CallingScreen({
    super.key,
    required this.callId,
    required this.sessionId,
    this.isCaller = true,
  });

  @override
  State<CallingScreen> createState() => _CallingScreenState();
}

class _CallingScreenState extends State<CallingScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _animation;

  bool _isCallAccepted = false;

  StreamSubscription? _callSub;

  Future<bool> _ensureCallPermissions() async {
    final cam = await Permission.camera.request();
    final mic = await Permission.microphone.request();
    final ok = cam.isGranted && mic.isGranted;
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Camera access required to start video.")),
      );
    }
    return ok;
  }

  @override
  void initState() {
    super.initState();

    /// 🔵 Animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(_controller);

    /// 🔥 LISTEN CALL STATUS
    _callSub = FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.callId)
        .snapshots()
        .listen((doc) {

      if (!doc.exists || !mounted) return;

      final status = doc.data()?['status'];

      print("CALL SCREEN STATUS: $status");

      /// ✅ ACCEPTED → OPEN VIDEO CALL
      if (status == "accepted" && !_isCallAccepted) {
        // Ensure permissions before entering call UI.
        _ensureCallPermissions().then((ok) {
          if (!ok || !mounted) return;
          setState(() {
            _isCallAccepted = true;
          });
        });
      }

      /// ❌ END / REJECT / MISSED
      if (status == "ended" || status == "rejected" || status == "missed") {
        _callSub?.cancel();

        if (!mounted) return;

        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
            (route) => false,
          );
        }
      }
    });
  }

  /// ❌ Caller cancels call
  void _cancelCall() async {
    await FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.callId)
        .update({'status': 'ended'});
  }

  /// ✅ Receiver accepts call
  Future<void> _acceptCall() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.callId)
        .update({'status': 'accepted'});

    if (widget.sessionId.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection("sessions")
          .doc(widget.sessionId)
          .set({
        "participants": FieldValue.arrayUnion([uid]),
        "status": "ongoing",
        "startTime": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  /// ❌ Receiver rejects call
  void _rejectCall() async {
    await FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.callId)
        .update({'status': 'rejected'});
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _controller.dispose();
    _callSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final user = FirebaseAuth.instance.currentUser;

    final String userID =
        user?.uid ?? "user_${DateTime.now().millisecondsSinceEpoch}";
    final String userName =
        user?.email?.split('@')[0] ?? "User";

    /// 🔥 VIDEO CALL UI (ZEGO)
    if (_isCallAccepted) {
      WakelockPlus.enable();
      return Scaffold(
        body: ZegoUIKitPrebuiltCall(
          appID: 268784912,
          appSign:
              '0e8487543305bc88f9b8dfd1eda310c5b601fe3f0270423035f71f194d094208',
          userID: userID,
          userName: userName,
          callID: widget.callId,

          config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
            ..turnOnCameraWhenJoining = true
            ..turnOnMicrophoneWhenJoining = true
            ..useSpeakerWhenJoining = true,

          events: ZegoUIKitPrebuiltCallEvents(
            onCallEnd: (event, defaultAction) async {

              defaultAction.call();

              try {
                /// ✅ SESSION COMPLETE
                if (widget.sessionId.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection("sessions")
                      .doc(widget.sessionId)
                      .update({
                    "status": "completed",
                    "completedAt": FieldValue.serverTimestamp(),
                    "endTime": FieldValue.serverTimestamp(),
                  });
                }

                /// ✅ CALL END
                await FirebaseFirestore.instance
                    .collection("calls")
                    .doc(widget.callId)
                    .update({
                  "status": "ended",
                });

              } catch (e) {
                debugPrint("Call end error: $e");
              }

              if (context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
        ),
      );
    }

    /// 🔥 CALLING UI (WAIT SCREEN)
    final text = widget.isCaller ? "Calling..." : "Incoming Call...";

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            ScaleTransition(
              scale: _animation,
              child: Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withOpacity(0.2),
                ),
                child: const Icon(
                  Icons.phone,
                  color: Colors.white,
                  size: 60,
                ),
              ),
            ),

            const SizedBox(height: 30),

            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 40),

            /// 👇 ONLY CANCEL / REJECT (NO ACCEPT HERE)
            if (widget.isCaller) ...[
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(20),
                ),
                onPressed: _cancelCall,
                child: const Icon(Icons.call_end, color: Colors.white),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(20),
                    ),
                    onPressed: _acceptCall,
                    child: const Icon(Icons.call, color: Colors.white),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(20),
                    ),
                    onPressed: _rejectCall,
                    child: const Icon(Icons.call_end, color: Colors.white),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}