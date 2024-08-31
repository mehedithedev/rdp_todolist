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
        'completed':
            false, // add the task to Firestore with completed wet to false
        'timestamp':
            FieldValue.serverTimestamp(), // add a timestamp to the task
      });

      setState(() {
        // clear the text input field and update the UI with setState()
        tasks.insert(0, taskName); // add the task to tasks list
        checkboxes.insert(0,
            false); // initializing checkboxes to false to maintain consitency
      });
    }
  }

  void removeItems(int index) async {
    // Get the task to be removed.
    String taskToBeRemoved = tasks[
        index]; // Identify the task name to remove based on its position in tasks list

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
      checkboxes.removeAt(
          index); // Remove the corresponding checkbox value from the checkboxes list
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
    for (QueryDocumentSnapshot docSnapshot in querySnapshot.docs) {
      // Itereate through the Firestore documents, adding the name and completed status to the lists
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
      tasks.addAll(
          fetchedTasks); // Populate the app's tasks and checkboxes lists with the fetched data and update the UI
    });
  }

  // Updates the completion status of a task in Firestore and updates the UI.
  Future<void> updateTaskCompletionStatus(
      String taskName, bool completed) async {
    // Get a reference to the 'tasks' collection from Firestore.
    CollectionReference tasksCollection = db.collection('tasks');

    // Query Firestore for tasks with the given task name.
    QuerySnapshot querySnapshot = await tasksCollection
        .where('name', isEqualTo: taskName)
        .get(); // Query Firestore for the specific task by name

    // If a matching document is found.
    if (querySnapshot.size > 0) {
      // Get a reference to the first matching document.
      DocumentSnapshot documentSnapshot = querySnapshot.docs[0];

      await documentSnapshot.reference.update({'completed': completed});
    }

    setState(() {
      // Find the index of the task in the task list.
      int taskIndex = tasks.indexWhere((task) =>
          task == taskName); // Identify the task by its position in tasks

      // Update the corresponding checkbox value in the checkbox list.
      checkboxes[taskIndex] =
          completed; // Reflect the change in the checkboxes list and update the UI with setState()
    });
  }

  @override
  void initState() {
    // Called when the widget is first created
    super.initState(); // Call the parent class's initState
    fetchTasksFromFirestore(); // Automatically fetches tasks from Firestore to populate the app's task list as soon as the widget is loaded
  }

  // Below is the method to clear the text field
  void clearInput() {
    setState(() {
      nameController
          .clear(); // clear the text field after the user has added a task to the list
    });
  }

  // Building the UI Scaffold for the HomePage
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Provides the basic strcuture of the UI, including an AppBar, body and more
      appBar: AppBar(
        // Displays the title of the app
        backgroundColor: Colors.blue,
        title: Row(
          mainAxisAlignment: MainAxisAlignment
              .spaceEvenly, // aligns items in the row with equal space between them
          children: [
            SizedBox(
              // a box with a fixed height for the app logo
              height: 80, // Sets the height of the app logo
              child: Image.asset(
                  'assets/rdplogo.png'), //defining the source location for app logo
            ),
            const Text(
              'Daily Planner', // Title of the app
              style: TextStyle(
                  fontFamily: 'Caveat', fontSize: 32, color: Colors.white),
            ),
          ],
        ),
      ),
      body: Container(
        child: SingleChildScrollView(
          child: Column(
            // Arranges children widgets vertically
            children: [
              TableCalendar(
                // Shows a calender for the user to pick a date
                calendarFormat: CalendarFormat
                    .month, // Specifies how the calendar showld be displayed (monthly, weekly, etc.)
                headerVisible:
                    true, // Display calender header (month/year selector)
                focusedDay: DateTime.now(), // Set the currently focused  day
                firstDay: DateTime(
                    2023), // Define the earliest date that can be displayed on the calender
                lastDay: DateTime(
                    2025), // Define the latest date that can be displayed on the calender
              ),
              Container(
                height: 280,
                child: ListView.builder(
                  // Dynamically creates the task list
                  shrinkWrap:
                      true, // Makes the ListView wrap its height based on the content size rather than expandin gto fill the available space
                  itemCount: tasks
                      .length, // Specifies the number of items in the list, based on the length of the tasks list
                  itemBuilder: (BuildContext context, int index) {
                    // A function that builds each item in the list. It takes the context and the current item index as parameters
                    return Container(
                      // Creates a container for each task in the list
                      margin: const EdgeInsets.only(top: 3.0),
                      decoration: BoxDecoration(
                        color: checkboxes[
                                index] // Displays each task with a checkbox to mark it as complete
                            ? Colors.green.withOpacity(0.7)
                            : Colors.blue.withOpacity(
                                0.7), // Change color based on completion status.
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(
                            12.0), // Adds padding around the entire ListView
                        child: Row(
                          children: [
                            Icon(
                              // Displays and icon withing the row. The icon changes based on the checkboxes[index] value
                              size: 44,
                              !checkboxes[index] // is true or false
                                  ? Icons
                                      .manage_history // Shown when checkboxes[index] is false
                                  : Icons
                                      .playlist_add_check_circle, // Shown when checkboxes[index] is true
                            ),
                            SizedBox(width: 18),
                            Expanded(
                              // Ensuers the Text widget takes up all available space in the row
                              child: Text(
                                '${tasks[index]}',
                                style: checkboxes[
                                        index] // Shows whether the task is completed or not, based on checkboxes [index]. When checked or unchecked, it updates the state with the new value and cals updateTaskCopletionStatus to reflet this change in the app's logic
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
                                  // Displays a delete icon. When clicked, it triggers the removeItem(index) function, which removes the task from the list and Firestore
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
                // Aligns the input field and button horizontally, it ensure that its contents are not flush against the screen edges. The Row aligns its children(a TextField and an IconButton) horizontally.
                children: [
                  // The TextField is wrapped in an Expanded widget to take up the ramaining horizontal space in the Row. It includes a controller for text input, management.
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(top: 20),
                      child: TextField(
                        // Captures user input, tied to nameController
                        controller: nameController,
                        maxLength: 20,
                        decoration: InputDecoration(
                          // It is for labels hints, and bordersl .The IconButton next to it cleaers the text when pressed.
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
                    onPressed: clearInput, //To-Do clearInput()
                  ),
                ],
              ),
              Padding(
                // The second Padding widget adds uniform spacing around an ElvatedButton. The button is styled with default Flutter behavior and displays the text "add To-DO Item"
                padding: EdgeInsets.all(4.0),
                child: ElevatedButton( // When pressed, triggers addItemToList() to add the task to the list and Firestore
                  onPressed: () { // The onPressed callback is triggered when the button is pressed
                    addItemToList(); // is called to add the current input to the list
                    clearInput(); // clears the input frmo the TextField.
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
