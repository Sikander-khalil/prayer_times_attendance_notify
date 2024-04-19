import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:prayer_times/login_screen.dart';

class AttendanceListScreen extends StatefulWidget {
  @override
  _AttendanceListScreenState createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends State<AttendanceListScreen> {
  final DatabaseReference _databaseReference =
      FirebaseDatabase.instance.reference();

  List<Map<String, dynamic>> attendanceList = [];

  @override
  void initState() {
    super.initState();
    fetchAttendanceData();
  }

  Future<void> fetchAttendanceData() async {
    String? userEmail = FirebaseAuth.instance.currentUser?.email;

    if (userEmail != null) {
      DatabaseReference userRef = _databaseReference
          .child('Users')
          .child(userEmail.replaceAll('.', ','));

      userRef.child('Attendance').once().then((DatabaseEvent snapshot) {
        List<Map<String, dynamic>> fetchedData = [];

        if (snapshot.snapshot.value != null) {
          Map<dynamic, dynamic> values =
          snapshot.snapshot.value as Map<dynamic, dynamic>;

          values.forEach((dateKey, prayers) {
            Map<String, dynamic> dateEntry = {
              'date': dateKey,
              'prayers': <Map<String, dynamic>>[]
            };

            prayers.forEach((prayerName, prayerData) {
              if (prayerData is Map) {
                prayerData.forEach((_, attendance) {
                  bool parsedAttendance =
                      attendance == true || attendance == "true";
                  dateEntry['prayers'].add({
                    'prayerName': prayerName,
                    'attendance': parsedAttendance,
                  });
                });
              }
            });

            fetchedData.add(dateEntry);
          });
        }

        setState(() {
          attendanceList = fetchedData;
        });
      }).catchError((error) {
        print('Failed to fetch attendance data: $error');
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Attendance List', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
          actions: [
            InkWell(
                onTap: () {
                  _signOut();
                },
                child: Icon(
                  Icons.logout,
                  color: Colors.white,
                ))
          ],
        ),
        body: attendanceList.isEmpty
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: CircularProgressIndicator(),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Text(
                    "Attendance Records is Empty",
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  )
                ],
              )
            : ListView.builder(
                itemCount: attendanceList.length,
                itemBuilder: (context, index) {
                  String date = attendanceList[index]['date'];
                  List<Map<String, dynamic>> prayers =
                      attendanceList[index]['prayers'];

                  print('This is Prayers:${prayers}');

                  return Card(
                    color: index % 2 == 0 ? Colors.green : Colors.amber,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            date,
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: prayers.length,
                          itemBuilder: (context, prayerIndex) {
                            String prayerName =
                                prayers[prayerIndex]['prayerName'];
                            bool attendance =
                                prayers[prayerIndex]['attendance'];


                            return ListTile(
                                title: Text(
                                  prayerName,
                                  style: TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(
                                  'Attendance: $attendance',
                                  style: TextStyle(color: Colors.white),
                                ),
                                leading: attendance
                                    ? Icon(Icons.check_circle_outline, color: Colors.white)
                                    : Icon(Icons.cancel,
                                        color: Colors.red));
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();

    Navigator.push(
        context, MaterialPageRoute(builder: (context) => LoginScreen()));
  }
}
