// Importing the required packages and files
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

//HomePage is a StatefulWidget, meaning it has a mutable state that can change over time
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

//_State class defines the mutable state for the HomePage widget
class _HomePageState extends State<HomePage> {
  FirebaseFirestore db =
      FirebaseFirestore.instance; // Create a Firestore instance.

  final List<String> tasks = <String>[]; // Stores the tasks entered by the user
  final List<bool> checkboxes = List.generate(
      8,
      (index) =>
          false); // Tracks the completion status of tasks: true if completed, false if not
  TextEditingController nameController =
      TextEditingController(); // Controller for task input.

  bool isChecked = false; // Tracks whether a task is checked.

  // Adds a new task to the Firestore database and updates the UI.
  void addItemToList() async {
    final String taskName = nameController.text;

    if (taskName != '') {
      // Add to the Firestore collection
      await db.collection('tasks').add({
        'name': taskName, // get the task name from nameController
        'completed': false,  // add the task to Firestore with completed wet to false
        'timestamp': FieldValue.serverTimestamp(), // add a timestamp to the task
      });

      setState(() {
        // clear the text input field and update the UI with setState()
        tasks.insert(0, taskName); // add the task to tasks list
        checkboxes.insert(0, false); // initializing checkboxes to false to maintain consitency
      });
    }
  }


  void removeItems(int index) async {
    // Get the task to be removed.
    String taskToBeRemoved = tasks[index]; // Identify the task name to remove based on its position in tasks list


    // Remove the task from Firestore.
    QuerySnapshot querySnapshot = await db
        .collection('tasks')
        .where('name', isEqualTo: taskToBeRemoved)
        .get();

    if (querySnapshot.size > 0) {
      DocumentSnapshot documentSnapshot = querySnapshot.docs[0];

      await documentSnapshot.reference.delete();
    }

    setState(() {
            // Update the UI with setState()
      tasks.removeAt(index); // Remove task from the local list.
      checkboxes.removeAt(index); // Remove the corresponding checkbox value from the checkboxes list
    });
  }

  // Fetches tasks from Firestore and updates the UI.
  Future<void> fetchTasksFromFirestore() async {
    // Get a reference to the 'tasks' collection from Firestore.
    CollectionReference tasksCollection = db.collection('tasks');

    // Fetch the documents (tasks) from the collection.
    QuerySnapshot querySnapshot = await tasksCollection.get();

    // Create an empty list to store the fetched task names.
    List<String> fetchedTasks = [];

    // Loop through each doc (task) in the querySnapshot object.
    for (QueryDocumentSnapshot docSnapshot in querySnapshot.docs) {  // Itereate through the Firestore documents, adding the name and completed status to the lists
      // Get the task name from the data.
      String taskName = docSnapshot.get('name');

      // Get the completion status from the data.
      bool completed = docSnapshot.get('completed');

      // Add the tasks to the fetched tasks.
      fetchedTasks.add(taskName);
      checkboxes.add(completed); // Add the corresponding checkbox state.
    }
    setState(() {
      tasks.clear(); // Clear the app's tasks and checkboxes lists
      tasks.addAll(fetchedTasks); // Populate the app's tasks and checkboxes lists with the fetched data and update the UI
    });
  }

  // Updates the completion status of a task in Firestore and updates the UI.
  Future<void> updateTaskCompletionStatus(
      String taskName, bool completed) async {
    // Get a reference to the 'tasks' collection from Firestore.
    CollectionReference tasksCollection = db.collection('tasks');

    // Query Firestore for tasks with the given task name.
    QuerySnapshot querySnapshot =
        await tasksCollection.where('name', isEqualTo: taskName).get(); // Query Firestore for the specific task by name

    // If a matching document is found.
    if (querySnapshot.size > 0) {
      // Get a reference to the first matching document.
      DocumentSnapshot documentSnapshot = querySnapshot.docs[0];

      await documentSnapshot.reference.update({'completed': completed});
    }

    setState(() {
      // Find the index of the task in the task list.
      int taskIndex = tasks.indexWhere((task) => task == taskName);

      // Update the corresponding checkbox value in the checkbox list.
      checkboxes[taskIndex] = completed;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchTasksFromFirestore(); // Fetch tasks from Firestore when the widget is initialized.
  }

  // Clears the input field for task entry.
  void clearInput() {
    setState(() {
      nameController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SizedBox(
              height: 80,
              child: Image.asset('assets/rdplogo.png'),
            ),
            const Text(
              'Daily Planner',
              style: TextStyle(
                  fontFamily: 'Caveat', fontSize: 32, color: Colors.white),
            ),
          ],
        ),
      ),
      body: Container(
        child: SingleChildScrollView(
          child: Column(
            children: [
              TableCalendar(
                calendarFormat: CalendarFormat.month,
                headerVisible: true,
                focusedDay: DateTime.now(),
                firstDay: DateTime(2023),
                lastDay: DateTime(2025),
              ),
              Container(
                height: 280,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: tasks.length, // Number of tasks to display.
                  itemBuilder: (BuildContext context, int index) {
                    return Container(
                      margin: const EdgeInsets.only(top: 3.0),
                      decoration: BoxDecoration(
                        color: checkboxes[index]
                            ? Colors.green.withOpacity(0.7)
                            : Colors.blue.withOpacity(
                                0.7), // Change color based on completion status.
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(
                              size: 44,
                              !checkboxes[index]
                                  ? Icons.manage_history
                                  : Icons
                                      .playlist_add_check_circle, // Change icon based on completion status.
                            ),
                            SizedBox(width: 18),
                            Expanded(
                              child: Text(
                                '${tasks[index]}',
                                style: checkboxes[index]
                                    ? TextStyle(
                                        decoration: TextDecoration.lineThrough,
                                        fontSize: 25,
                                        color: Colors.black.withOpacity(0.5),
                                      )
                                    : TextStyle(fontSize: 25),
                                textAlign: TextAlign.left,
                              ),
                            ),
                            Row(
                              children: [
                                Transform.scale(
                                  scale: 1.4,
                                  child: Checkbox(
                                      value: checkboxes[
                                          index], // Checkbox value linked to task completion status.
                                      onChanged: (newValue) {
                                        setState(() {
                                          checkboxes[index] = newValue!;
                                        });
                                        updateTaskCompletionStatus(tasks[index],
                                            newValue!); // Update the task's completion status in Firestore.
                                      }),
                                ),
                                IconButton(
                                  color: Colors.black,
                                  iconSize: 30,
                                  icon: Icon(Icons.delete), // Delete task icon.
                                  onPressed: () {
                                    removeItems(
                                        index); // Remove the task from Firestore.
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(top: 20),
                      child: TextField(
                        controller: nameController,
                        maxLength: 20,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.all(23),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          labelText: 'Add To-Do List Item',
                          labelStyle: TextStyle(
                            fontSize: 16,
                            color: Colors.blue,
                          ),
                          hintText: 'Enter your task here',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.clear), // Clear input field icon.
                    onPressed: clearInput, // Clears the input field.
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.all(4.0),
                child: ElevatedButton(
                  onPressed: () {
                    addItemToList(); // Adds the task to Firestore and updates the UI.
                    clearInput(); // Clears the input field.
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                        Colors.blue), // Button background color.
                  ),
                  child: Text(
                    'Add To-Do List Item',
                    style: TextStyle(color: Colors.white), // Button text color.
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
