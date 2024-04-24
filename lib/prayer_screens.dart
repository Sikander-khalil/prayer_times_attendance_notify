import 'dart:async';
import 'dart:convert';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:marquee/marquee.dart';
import 'package:prayer_times/snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'attendance_list_screen.dart';
import 'package:timezone/timezone.dart' as tz;

import 'notify.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({Key? key}) : super(key: key);

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();

  Future<void> initNotification() async {
    AndroidInitializationSettings initializationSettingsAndroid =
        const AndroidInitializationSettings('@mipmap/ic_launcher');

    var initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        onDidReceiveLocalNotification:
            (int id, String? title, String? body, String? payload) async {});

    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse:
            (NotificationResponse notificationResponse) async {});
  }
}

class _PrayerScreenState extends State<PrayerScreen>
    with WidgetsBindingObserver {
  Map<String, String>? prayerTimings;
  String? currentCity;
  String? currentCountry;
  static DateTime currentDateTime = DateTime.now();
  final formattedDateTime =
      DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(currentDateTime);
  late Timer _timer;
  DateTime? parsedFormattedDateTime;
  String _currentTime = '';
  int currentIndex = 0; // Declare currentIndex variable
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  List<Map<String, bool>> prayerAttendance = [];
  bool isNotificationShown = false;
  DateTime? fajarTime;
  DateTime? duhrTime;

  //   AppLifecycleState? appLifecycleState;

  DateTime? asrTime;
  DateTime? magribTime;
  DateTime? ishaTime;

  @override
  void initState() {
    super.initState();
    getLocation();
    fetchPrayerTimes();

    _loadPrayerAttendance();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      if (mounted)
        setState(() {
          _currentTime = _getCurrentTime();
        });
    });
  }

  Future<void> _loadPrayerAttendance() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? prayerAttendanceJson = prefs.getString('prayerAttendance');
    if (prayerAttendanceJson != null) {
      List<dynamic> decodedList = jsonDecode(prayerAttendanceJson);
      List<Map<String, bool>> loadedPrayerAttendance =
          List<Map<String, bool>>.from(
              decodedList.map((e) => Map<String, bool>.from(e)));
      setState(() {
        prayerAttendance = loadedPrayerAttendance;
      });
    }
  }

  String _getCurrentTime() {
    var now = DateTime.now();
    return '${_formatTimeUnit(now.hour)}:${_formatTimeUnit(now.minute)}:${_formatTimeUnit(now.second)}';
  }

  String _formatTimeUnit(int unit) {
    return unit < 10 ? '0$unit' : '$unit';
  }

  getLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      if (mounted) {
        // Check if widget is mounted
        setState(() {
          currentCity = 'Karachi';
          currentCountry = 'Pakistan';
        });
      }
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          currentCity = 'Karachi';
          currentCountry = 'Pakistan';
        });
      }
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark place = placemarks[0];
    if (mounted) {
      setState(() {
        currentCity = place.locality ?? 'Unknown';
        currentCountry = place.country ?? 'Unknown';
      });
    }
  }

  Future<void> fetchPrayerTimes() async {
    var url =
        "http://api.aladhan.com/v1/timingsByCity?city=${currentCity}&country=${currentCountry}&method=16";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data =
          json.decode(response.body)['data']['timings'];

      if (mounted)
        setState(() {
          prayerTimings = {
            'Fajr': data['Fajr'],
            'Dhuhr': data['Dhuhr'],
            'Asr': data['Asr'],
            'Maghrib': data['Maghrib'],
            'Isha': data['Isha'],
          };
          // Initialize prayerAttendance only if it's empty
          if (prayerAttendance.isEmpty) {
            prayerAttendance = List.generate(prayerTimings!.length, (index) {
              final prayerName = prayerTimings!.keys.toList()[index];
              final prayerTime = prayerTimings![prayerName];
              return {prayerTime!: false};
            });
          }
        });
    }
  }

  String _calculateRemainingTime() {
    if (prayerTimings == null) return '';

    final currentPrayer = _getCurrentPrayer();
    if (currentPrayer == 'Completed') {
      return 'No Prayer Time';
    }

    final timings = prayerTimings![currentPrayer];
    if (timings == null)
      return 'No prayer timings available for $currentPrayer';

    final remainingTime = _getRemainingTime(timings);
    return 'Remaining Time for $currentPrayer: $remainingTime';
  }

  String _getCurrentPrayer() {
    if (prayerTimings == null || _currentTime.isEmpty) return '';
    for (final prayer in prayerTimings!.keys) {
      final prayerTime = prayerTimings![prayer];
      if (prayerTime != null && _currentTime.compareTo(prayerTime) < 0) {
        return prayer;
      }
    }
    return 'Completed';
  }

  String _getRemainingTime(String prayerTime) {
    final now = DateTime.now();
    final DateTime nextPrayerTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(prayerTime.split(':')[0]),
      int.parse(prayerTime.split(':')[1]),
    );
    final remaining = nextPrayerTime.difference(now);
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);
    return '$hours:$minutes:$seconds';
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    parsedFormattedDateTime = DateTime.parse(formattedDateTime);
    // Ensure the app is paused or inactive and that prayer times are not null
    if ((state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.detached) &&
        parsedFormattedDateTime != null && fajarTime != null && duhrTime != null && asrTime != null && magribTime != null && ishaTime != null) {

      // Calculate the time differences
      Duration fajarDiff = parsedFormattedDateTime!.difference(fajarTime!);
      print("This is duration FajarDiff: ${fajarDiff}");
      Duration duhrDiff = parsedFormattedDateTime!.difference(duhrTime!);
      print("This is duration duhrDiff: ${duhrDiff}");
      Duration asrDiff = parsedFormattedDateTime!.difference(asrTime!);
      print("This is duration asrDiff: ${asrDiff}");
      Duration magribDiff = parsedFormattedDateTime!.difference(magribTime!);
      print("This is duration magribDiff: ${magribDiff}");

      Duration ishaDiff = parsedFormattedDateTime!.difference(ishaTime!);
      print("This is duration ishaDiff: ${ishaDiff}");

      // Convert differences to absolute values
      fajarDiff = fajarDiff.abs();
      print("THis is Fajar Diff: ${fajarDiff}");
      duhrDiff = duhrDiff.abs();
      print("THis is Duhr Diff: ${duhrDiff}");
      asrDiff = asrDiff.abs();
      print("THis is Asr Diff: ${asrDiff}");
      magribDiff = magribDiff.abs();
      print("THis is magrib Diff: ${magribDiff}");
      ishaDiff = ishaDiff.abs();
      print("THis is isha Diff: ${ishaDiff}");

      // Determine the closest prayer time
      if (fajarDiff <= duhrDiff) {
        print("If Condition FajarDiff: ${fajarDiff}");
        print("If Condition DuhrDiff: ${duhrDiff}");
        // Fajr time is closest
        NotificationService().scheduleNotification(
            scheduledNotificationDateTime: fajarTime!
        );
        print("Notification Scheduled: Fajr Time - ${fajarTime}");
      } else if (duhrDiff <= asrDiff) {
        print("If Condition DuhrDiff: ${duhrDiff}");
        print("If Condition asrDiff: ${asrDiff}");

        // Duhr time is closest
        NotificationService().scheduleNotification(
            scheduledNotificationDateTime: duhrTime!
        );
        print("Notification Scheduled: Duhr Time - ${duhrTime}");
      } else if (asrDiff <= magribDiff) {
        print("If Condition asrDiff: ${asrDiff}");
        print("If Condition magribDiff: ${magribDiff}");
        // Duhr time is closest
        NotificationService().scheduleNotification(
            scheduledNotificationDateTime: asrTime!
        );
        print("Notification Scheduled: Asr Time - ${asrTime}");
      }else if (magribDiff <= ishaDiff) {
        print("If Condition magribDiff: ${magribDiff}");
        print("If Condition ishaDiff: ${ishaDiff}");
        // Duhr time is closest
        NotificationService().scheduleNotification(
            scheduledNotificationDateTime: magribTime!
        );
        print("Notification Scheduled: Magrib Time - ${magribTime}");
      }
      setState(() {

      });
    }

  }



  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/PrayerBackground.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: prayerTimings == null
              ? Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Current Time: ${_currentTime}',
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          InkWell(
                            onTap: () {
                              dialogue();
                            },
                            child: Icon(
                              Icons.info,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 30,
                    ),
                    Text(
                      _calculateRemainingTime(),
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    SizedBox(
                      height: 30,
                    ),
                    Container(
                      height: 450,
                      child: ListView.builder(
                        itemCount: prayerTimings!.length,
                        itemBuilder: (context, index) {
                          final prayerTime =
                              prayerTimings!.keys.toList()[index];
                          final prayerName = prayerTimings![prayerTime];

                          return Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              children: [
                                buildRow(prayerName!, prayerTime, index),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => AttendanceListScreen()));
                      },
                      child: Container(
                        width: MediaQuery.sizeOf(context).width * .6,
                        height: MediaQuery.sizeOf(context).height * .07,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "View Prayer Attendance",
                              style: TextStyle(color: Colors.black),
                            ),
                            SizedBox(
                              width: 5,
                            ),
                            Icon(
                              Icons.check_circle_outline,
                              color: Colors.amber,
                              size: 30,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Container(
                      height: 20,
                      child: Marquee(
                        text:
                            'If the remaining time for Dhuhr is left, then the checkbox will be visible at Fajr and you can mark attendance at Fajr. If the remaining time for Asr is left, then the checkbox will be visible at Dhuhr and you can mark attendance at Dhuhr. If the remaining time for Maghrib is left, then the checkbox will be visible at Asr and you can mark attendance at Asr. If the remaining time for Isha is left, then the checkbox will be visible at Maghrib and you can mark attendance at Maghrib. If there is no remaining time, then the checkbox will be visible at Isha and you can mark attendance at Isha.If you mark attendance, it will show true, if not marked, it will show false. You can record this by clicking the button below, and you will be able to view the attendance record for your prayers.',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  ],
                ),
        ),
      ),
    );
  }

  Widget buildRow(String prayerTime, String prayerName, int index) {
    bool isChecked = prayerAttendance[index][prayerTime] ?? false;
    DateTime prayerDateTime = DateFormat('HH:mm').parse(prayerTime);
    // Format the parsed DateTime object to your desired format
    String finalTime = DateFormat('hh:mm a').format(prayerDateTime);

    bool showIcons = false;
    final now = DateTime.now();
    if (prayerTimings != null) {
      fajarTime = DateFormat('yyyy-MM-dd HH:mm').parse(
          '${DateFormat('yyyy-MM-dd').format(DateTime.now())} ${prayerTimings!['Fajr']}');

      duhrTime = DateFormat('yyyy-MM-dd HH:mm').parse(
          '${DateFormat('yyyy-MM-dd').format(DateTime.now())} ${prayerTimings!['Dhuhr']}');
      asrTime = DateFormat('yyyy-MM-dd HH:mm').parse(
          '${DateFormat('yyyy-MM-dd').format(DateTime.now())} ${prayerTimings!['Asr']}');
      magribTime = DateFormat('yyyy-MM-dd HH:mm').parse(
          '${DateFormat('yyyy-MM-dd').format(DateTime.now())} ${prayerTimings!['Maghrib']}');
      ishaTime = DateFormat('yyyy-MM-dd HH:mm').parse(
          '${DateFormat('yyyy-MM-dd').format(DateTime.now())} ${prayerTimings!['Isha']}');

      final timeThreshold = Duration(seconds: 1);

      // if (now.isAfter(fajarTime!.subtract(timeThreshold)) &&
      //     now.isBefore(fajarTime!.add(timeThreshold))  && appLifecycleState == AppLifecycleState.paused || appLifecycleState == AppLifecycleState.inactive && fajarTime != null && parsedFormattedDateTime == fajarTime || duhrTime != null && parsedFormattedDateTime == duhrTime) {
      //   print("Notification Fajar Schedular: ${fajarTime}");
      //   NotificationService()
      //       .scheduleNotification(scheduledNotificationDateTime: fajarTime!);
      //   print("Notification Duhr Schedular: ${duhrTime}");
      //   NotificationService()
      //       .scheduleNotification(scheduledNotificationDateTime: duhrTime!);
      //
      // } else if (now.isAfter(duhrTime!.subtract(timeThreshold)) &&
      //     now.isBefore(duhrTime!.add(timeThreshold))  && duhrTime != null && parsedFormattedDateTime == duhrTime && appLifecycleState == AppLifecycleState.paused || appLifecycleState == AppLifecycleState.inactive ) {
      //
      //   NotificationService()
      //       .scheduleNotification(scheduledNotificationDateTime: duhrTime!);
      // } else if (now.isAfter(asrTime!.subtract(timeThreshold)) &&
      //     now.isBefore(asrTime!.add(timeThreshold))  && asrTime != null && parsedFormattedDateTime == asrTime && appLifecycleState == AppLifecycleState.paused || appLifecycleState == AppLifecycleState.inactive) {
      //   NotificationService()
      //       .scheduleNotification(scheduledNotificationDateTime: asrTime!);
      // } else if (now.isAfter(magribTime!.subtract(timeThreshold)) &&
      //     now.isBefore(magribTime!.add(timeThreshold))  && magribTime != null && parsedFormattedDateTime == magribTime && appLifecycleState == AppLifecycleState.paused || appLifecycleState == AppLifecycleState.inactive) {
      //   NotificationService()
      //       .scheduleNotification(scheduledNotificationDateTime: magribTime!);
      // } else if (now.isAfter(ishaTime!.subtract(timeThreshold)) &&
      //     now.isBefore(ishaTime!.add(timeThreshold)) && ishaTime != null && parsedFormattedDateTime == ishaTime && appLifecycleState == AppLifecycleState.paused || appLifecycleState == AppLifecycleState.inactive) {
      //   NotificationService()
      //       .scheduleNotification(scheduledNotificationDateTime: ishaTime!);
      // }

      if (now.isAfter(fajarTime!) && now.isBefore(duhrTime!) && index == 0) {
        showIcons = true;

        _savePrayerAttendance(); // Save the updated prayer attendance
      } else if (now.isAfter(duhrTime!) &&
          now.isBefore(asrTime!) &&
          index == 1) {
        showIcons = true;

        _savePrayerAttendance(); // Save the updated prayer attendance
      } else if (now.isAfter(asrTime!) &&
          now.isBefore(magribTime!) &&
          index == 2) {
        showIcons = true;
        _savePrayerAttendance(); // Save the updated prayer attendance
      } else if (now.isAfter(magribTime!) &&
          now.isBefore(ishaTime!) &&
          index == 3) {
        showIcons = true;
        _savePrayerAttendance(); // Save the updated prayer attendance
      } else if (now == ishaTime && index == 4) {
        showIcons = true;

        _savePrayerAttendance(); // Save the updated prayer attendance
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(prayerName, style: TextStyle(color: Colors.white, fontSize: 20)),
          Row(
            children: [
              Text('$finalTime',
                  style: TextStyle(color: Colors.white, fontSize: 20)),
              SizedBox(width: 10),
              // Conditionally render GestureDetector and icons based on showIcons
              if (showIcons) ...[
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isChecked = !isChecked;
                      prayerAttendance[index][prayerTime] = isChecked;
                    });

                    attendanceMark(isChecked, prayerName, showIcons, index);
                  },
                  child: Icon(
                    isChecked && showIcons
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    color: Colors.white,
                  ),
                )
              ]
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _savePrayerAttendance() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String prayerAttendanceJson = jsonEncode(prayerAttendance);
    prefs.setString('prayerAttendance', prayerAttendanceJson);
  }

  void attendanceMark(
      bool isChecked, String prayerName, bool showIcons, int index) {
    // Get current date
    DateTime now = DateTime.now();
    String currentDate = DateFormat('yyyy-MM-dd').format(now);

    Map<String, bool> attendanceData = {prayerName: isChecked};

    setState(() {
      prayerAttendance[index][prayerName] = isChecked;
    });

    // Check if the prayer is marked as attended or not
    if (isChecked == true && showIcons == true) {
      CustomSnackbar.successful(
        message: "Your Attendance is Marked for $prayerName",
        context: context,
      );
      // Save attendance data to the database
      saveAttendanceToDatabase(currentDate, attendanceData, index);
    } else if (isChecked == false && showIcons == true) {
      CustomSnackbar.error(
        message: "Your Attendance is Not Marked for $prayerName",
        context: context,
      );
      // Save attendance data to the database with isChecked as false
      saveAttendanceToDatabase(currentDate, attendanceData, index);
    }
  }

  void saveAttendanceToDatabase(
      String currentDate, Map<String, bool> attendanceData, int index) {
    // Get the current user's UID
    final String? userUid = firebaseAuth.currentUser!.uid;
    // Get the current user's email
    String? userEmail = firebaseAuth.currentUser!.email;

    if (userUid != null && userEmail != null) {
      // Get a reference to the Firebase database with the user's email
      DatabaseReference userRef = FirebaseDatabase.instance
          .reference()
          .child('Users')
          .child(userEmail.replaceAll('.', ','));

      String prayerKey;
      switch (index) {
        case 0:
          prayerKey = 'Fajr';
          break;
        case 1:
          prayerKey = 'Dhuhr';
          break;
        case 2:
          prayerKey = 'Asr';
          break;
        case 3:
          prayerKey = 'Maghrib';
          break;
        case 4:
          prayerKey = 'Isha';
          break;
        default:
          prayerKey = '';
      }

      if (prayerKey.isNotEmpty) {
        // Push attendance data to Firebase database under the user's email node
        DatabaseReference userAttendanceRef =
            userRef.child("Attendance").child(currentDate).child(prayerKey);
        userAttendanceRef.set(attendanceData).then((value) {
          // Data saved successfully
        }).catchError((error) {
          // Handle error
          print(
              'Failed to save attendance data for $prayerKey on $currentDate: $error');
        });
      }
    } else {
      print('User UID or email is null');
    }
  }

  void dialogue() {
    showDialog(
        barrierColor: Colors.black,
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Container(
              height: MediaQuery.sizeOf(context).height * .70,
              child: Column(
                children: [
                  Icon(
                    Icons.info,
                    color: Colors.green,
                    size: 30,
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Text(
                    "If the remaining time for Dhuhr is left, then the checkbox will be visible at Fajr and you can mark attendance at Fajr. If the remaining time for Asr is left, then the checkbox will be visible at Dhuhr and you can mark attendance at Dhuhr. If the remaining time for Maghrib is left, then the checkbox will be visible at Asr and you can mark attendance at Asr. If the remaining time for Isha is left, then the checkbox will be visible at Maghrib and you can mark attendance at Maghrib. If there is no remaining time, then the checkbox will be visible at Isha and you can mark attendance at Isha.If you mark attendance, it will show true, if not marked, it will show false. You can record this by clicking the button below, and you will be able to view the attendance record for your prayers.",
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        });
  }
}