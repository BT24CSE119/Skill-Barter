import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class CallingScreen extends StatelessWidget {
  final String callId;
  final String sessionId;
  final bool isCaller;

  const CallingScreen({
    super.key,
    required this.callId,
    required this.sessionId,
    required this.isCaller,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    /// 🔥 Safety check
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text("User not logged in"),
        ),
      );
    }

    final String userID = user.uid;
    final String userName = user.email?.split('@')[0] ?? "User";

    /// 🔥 FIX: Remove minimize button (prevents PiP crash)
    final config = ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
      ..turnOnCameraWhenJoining = true
      ..turnOnMicrophoneWhenJoining = true
      ..useSpeakerWhenJoining = true
      ..bottomMenuBarConfig = ZegoBottomMenuBarConfig(
        buttons: [
          ZegoCallMenuBarButtonName.toggleCameraButton,
          ZegoCallMenuBarButtonName.toggleMicrophoneButton,
          ZegoCallMenuBarButtonName.switchCameraButton,
          ZegoCallMenuBarButtonName.hangUpButton,
        ],
      );

    return Scaffold(
      body: ZegoUIKitPrebuiltCall(
        appID: 268784912,
        appSign:
            '0e8487543305bc88f9b8dfd1eda310c5b601fe3f0270423035f71f194d094208',
        userID: userID,
        userName: userName,
        callID: callId,
        config: config,

        /// 🔥 FINAL FIX (VERY IMPORTANT)
        events: ZegoUIKitPrebuiltCallEvents(
          onCallEnd: (event, defaultAction) async {
            /// 1️⃣ Let SDK handle cleanup
            defaultAction.call();

            try {
              /// 2️⃣ Update session safely
              await FirebaseFirestore.instance
                  .collection("sessions")
                  .doc(sessionId)
                  .update({
                "status": "completed",
                "completedAt": FieldValue.serverTimestamp(),
              });
            } catch (e) {
              debugPrint("Session update error: $e");
            }

            /// 3️⃣ Close screen safely
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
    );
  }
}