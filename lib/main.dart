import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:prayer_times/prayer_screens.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'login_screen.dart';
import 'notify.dart';

PrayerScreen prayerScreen = PrayerScreen();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel notificationChannel =
    AndroidNotificationChannel(
        "coding is life foreground", "coding is life foreground service",
        description: "This is channel des..", importance: Importance.high);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();


  NotificationService().initNotification();
  tz.initializeTimeZones();
  runApp(MyApp());
}

// Future<void> initService() async {
//   var service = FlutterBackgroundService();
//
//   if (Platform.isAndroid) {
//     await flutterLocalNotificationsPlugin.initialize(
//         const InitializationSettings(
//             android: AndroidInitializationSettings("@mipmap/ic_launcher")));
//   }
//
//   await flutterLocalNotificationsPlugin
//       .resolvePlatformSpecificImplementation<
//           AndroidFlutterLocalNotificationsPlugin>()
//       ?.createNotificationChannel(notificationChannel);
//
//   await service.configure(
//       iosConfiguration: IosConfiguration(),
//       androidConfiguration: AndroidConfiguration(
//           onStart: onStart,
//           isForegroundMode: true,
//           autoStart: true,
//           notificationChannelId: 'coding is life',
//           initialNotificationTitle: "Coding is Life",
//           initialNotificationContent: "Awesome Content",
//           foregroundServiceNotificationId: 90));
//
//   service.startService();
// }

// @pragma("vm:entry-point")
// void onStart(ServiceInstance serviceInstance) {
//   DartPluginRegistrant.ensureInitialized();
//   serviceInstance.on("setAsForeground").listen((event) {
//     print("foreground");
//   });
//
//   serviceInstance.on("setAsBackground").listen((event) {
//     print("Background");
//   });
//
//   serviceInstance.on("stopService").listen((event) {
//     serviceInstance.stopSelf();
//   });
//
//   Timer.periodic(Duration(seconds: 2), (timer) {
//     flutterLocalNotificationsPlugin.show(
//         90,
//         "Cool Service",
//         "Awesome ${DateTime.now()}",
//         NotificationDetails(
//             android: AndroidNotificationDetails(
//                 "codign is life", "coding is life service",
//                 ongoing: true,icon: "@mipmap/ic_launcher")
//         )
//     );
//   });
//   print("Background Service: ${DateTime.now()}");
// }

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  FirebaseAuth? firebaseAuth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Prayer Times',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Waiting for Firebase Authentication to initialize
            return CircularProgressIndicator();
          } else {
            if (snapshot.hasData) {
              // User is logged in, show PrayerScreen
              return PrayerScreen();
            } else {
              // User is not logged in, show LoginScreen
              return LoginScreen();
            }
          }
        },
      ),
     // home: PrayerScreen(),

    );
  }
}

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//
//   @override
//   State<HomePage> createState() => _HomePageState();
// }
//
// class _HomePageState extends State<HomePage> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//
//             ElevatedButton(onPressed: (){
//
//               FlutterBackgroundService().invoke("stopService");
//
//             }, child: Text("Stop Services")),
//
//             ElevatedButton(onPressed: (){
//
//               FlutterBackgroundService().invoke("startService");
//
//             }, child: Text("Start Services")),
//
//
//           ],
//         ),
//       ),
//     );
//   }
// }



