import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  FirebaseFirestore db = FirebaseFirestore.instance;

  final List<String> tasks = <String>[];
  final List<bool> checkboxes = List.generate(8, (index) => false);
  TextEditingController nameController = TextEditingController();

  bool isChecked = false;

  void addItemToList() async {
    final String taskName = nameController.text;
    // Firestone funcitonalities
    await db.collection('tasks').add({
      'name': taskName,
      'completed': false,
      'timestamp': FieldValue.serverTimestamp(),
    });

    setState(() {
      tasks.insert(0, taskName);
      checkboxes.insert(0, false);
    });
  }

  void removeItems(int index) async {
    // Get the tasks to be removed
    String tasksToBeRemoved = tasks[index];

    // Remove the task from Firestone
    QuerySnapshot querySnapshot = await db
        .collection('tasks')
        .where('name', isEqualTo: tasksToBeRemoved)
        .get();

    if (querySnapshot.size > 0) {
      DocumentSnapshot documentSnapshot = querySnapshot.docs[0];

      await documentSnapshot.reference.delete();
    }

    setState(() {
      tasks.removeAt(index);
      checkboxes.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Below is the App Bar
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              height: 80,
              child: Image.asset(
                  'assets/rdplogo.png'), // setting source of asset for the app bar icon
            ),
            const // using const to impvove performance
            Text(
              'Daily Planner',
              style: TextStyle(
                  fontFamily:
                      'Caveat' // using the Caveat font that we already added in pubspec.yaml file
                  ,
                  fontSize: 32,
                  color: Colors.white),
            ),
          ],
        ),
      ),

      // Below is the body of my To-Do list app
      body: Container(
        // color: Colors.black,
        child: Column(
          children: [
            TableCalendar(
              calendarFormat: CalendarFormat
                  .month, // defining how the calender will format dates, in this case month
              headerVisible:
                  true, // seeting the boolean value for app title bar
              focusedDay: DateTime.now(), // setting today as the focused day
              firstDay: DateTime(2023),
              lastDay: DateTime(2025),
            ),
            Container(
              height: 300, // setting the height for input container
              child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: tasks.length,
                  itemBuilder: (BuildContext context, int index) {
                    return SingleChildScrollView(
                      child: Container(
                        child: Container(
                          margin: const EdgeInsets.only(top: 6),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: checkboxes[index]
                                  ? Colors.green.withOpacity(0.7)
                                  : Colors.blue.withOpacity(0.7)),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Container(
                              child: Row(
                                // mainAxisAlignment: MainAxisAlignment.spaceBetween,  // Commented out to allow checkboxes to align to the right side of the window
                                children: [
                                  Icon(
                                      size: 36,
                                      !checkboxes[index]
                                          ? Icons.manage_history
                                          : Icons.playlist_add_check_circle),
                                  SizedBox(width: 18),
                                  Expanded(
                                    child: Text(
                                      '${tasks[index]}',
                                      style: checkboxes[index]
                                          ? TextStyle(
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              fontSize: 25,
                                              color:
                                                  Colors.black.withOpacity(0.5))
                                          : TextStyle(fontSize: 25),
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Transform.scale(
                                        scale: 1.4,
                                        child: Checkbox(
                                            value: checkboxes[index],
                                            onChanged: (newValue) {
                                              setState(() {
                                                checkboxes[index] =
                                                    newValue!; // have to add ! as it can't be nullable
                                              });
                                              // To-Do: updateTaskComplettionStatus()
                                            }),
                                      ),
                                      const IconButton(
                                          color: Colors.black,
                                          iconSize: 30,
                                          onPressed: null,
                                          icon: Icon(Icons.delete))
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
            ),
            Row(
              children: [
                Expanded(
                  child: Container(
                    // height: 100,
                    padding: EdgeInsets.all(23),
                    child: TextField(
                      controller: nameController,
                      maxLength: 20,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        labelText: 'Add To-Do List Item',
                        labelStyle:
                            const TextStyle(color: Colors.blue, fontSize: 26),
                        // hintText: 'Enter your task here',
                        // hintStyle: TextStyle(color: Colors.grey.withOpacity(3)),
                      ),
                    ),
                  ),
                ),
                const IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: null,
                )
              ],
            ),
            Padding(
              padding: EdgeInsets.all(3.0),
              child: ElevatedButton(
                  style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(Colors.blue)),
                  onPressed: () {
                    addItemToList();
                  },
                  child: Text(
                    'Add To-Do List Item',
                    style: TextStyle(color: Colors.white),
                  )),
            )
          ],
        ),
      ),
    );
  }
}
