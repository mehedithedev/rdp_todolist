// Below we are importing all the packages and libraries that we need to use
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

  final List<String> tasks =
      <String>[]; // Stores the names of tasks entered by the user
  final List<bool> checkboxes = List.generate(
      8,
      (index) =>
          false); // Tracks the completion status of tasks: true if completed, false if not
  TextEditingController nameController =
      TextEditingController(); // Captures user input from a text field, storing the task name to be added

  bool isChecked = false;

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
    //Get the tasks to be removed
    String taskToBeRemoved = tasks[
        index]; // Identifyp the task name to remove based on its position in tasks list

    //Remove the task from Firestore
    QuerySnapshot querySnapshot =
        await db // Query Firestore to find the task by name
            .collection('tasks')
            .where('name', isEqualTo: taskToBeRemoved)
            .get();

    if (querySnapshot.size > 0) {
      DocumentSnapshot documentSnapshot = querySnapshot
          .docs[0]; // Getting the reference to the first matching document

      // Update the completed filed to the new completion status
      await documentSnapshot.reference
          .delete(); // Delete the task from Firestore
    }

    setState(() {
      // Update the UI with setState()
      tasks.removeAt(index); // Remove the task from the tasks list
      checkboxes.removeAt(
          index); // Remove the corresponding checkbox value from the checkboxes list
    });
  }

  Future<void> fetchTasksFromFirestore() async {
    // Get a reference to the 'tasks' collection from FireStore
    CollectionReference taskCollection =
        db.collection('tasks'); // Fetch all tasks from Firestore

    // fetch the documents (tasks) from the collection
    QuerySnapshot querySnapshot = await taskCollection.get();

    // Create an empty list to store the fetched task names
    List<String> fetchedTasks =
        []; // Initialize temporary lists to hold fetched tasks and their statuses

    // Loop through each do (task) in the querySnapshot object
    for (QueryDocumentSnapshot docSnapShot in querySnapshot.docs) {
      // Itereate through the Firestore documents, adding the name and completed status to the lists

      // Get the task name from the data
      String taskName = docSnapShot.get('new');

      // Get the completion statuus from the data
      String completed = docSnapShot.get('completed');

      // Add the task name to the fetched tasks
      fetchedTasks.add(taskName); // Add the task name to the fetchedTasks list
      setState(() {
        tasks.clear(); // Clear the app's tasks and checkboxes lists
        tasks.addAll(
            fetchedTasks); // Populate the app's tasks and checkboxes lists with the fetched data and update the UI
      });
    }
  }

  Future<void> updateTaskCompletionStatus(
      String taskName, bool completed) async {
    // Get a reference to the 'tasks' collection from Firestore
    CollectionReference tasksCollection = db.collection(
        'tasks'); // Update the completed status of the task in Firestore

    // Query firestore for documents (tasks) with the given task name
    QuerySnapshot querySnapshot = await tasksCollection
        .where('name', isEqualTo: taskName)
        .get(); // Query Firestore for the specific task by name

    // If matching task document is found
    if (querySnapshot.size > 0) {
      // Getting a reference to the first matching document
      DocumentSnapshot documentSnapshot = querySnapshot.docs[0];

      await documentSnapshot.reference.update({
        'completed': true,
      });
      setState(() {
        // find the index of the task in the task list

        int taskIndex = tasks.indexWhere((task) =>
            task == taskName); // Identify the task by its position in tasks

        // Update the corresponding checkbox value in the checkbox list

        checkboxes[taskIndex] =
            completed; // Reflect the change in the checkboxes list and update the UI with setState()
      });
    }
  }

  @override
  void initState() {
    // Called when the widget is first created
    super.initState(); // Call the parent class's initState
    fetchTasksFromFirestore(); // Automatically fetches tasks from Firestore to populate the app's task list as soon as the widget is loaded
  }

  // Below is the method to clear the text field
  void clearTextField() {
    // clear the text field after the user has added a task to the list
    nameController.clear();
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
          //
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
                  fontFamily: 'Caveat',
                  fontSize: 32,
                  color: Colors.white), // using the Caveat font for the title
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        // Allows the user to scroll through the body of the app
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
            SizedBox(
              // A box with a fixed height for the list of tasks
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
                          : Colors.blue.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(
                          12.0), // Adds padding around the entire ListView
                      child: Row(
                        // mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          const SizedBox(width: 18),
                          Expanded(
                            // Ensuers the Text widget takes up all available space in the row
                            child: Text(
                              // Displays the task from the tasks list at the current index
                              tasks[index],
                              style: checkboxes[
                                      index] // Shows whether the task is completed or not, based on checkboxes [index]. When checked or unchecked, it updates the state with the new value and cals updateTaskCopletionStatus to reflet this change in the app's logic
                                  ? TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      fontSize: 25,
                                      color: Colors.black.withOpacity(0.5),
                                    )
                                  : const TextStyle(fontSize: 25),
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
                                        checkboxes[index] = newValue!;
                                      });
                                      updateTaskCompletionStatus(
                                          tasks[index], newValue!);
                                    }),
                              ),
                              const IconButton(
                                // Displays a delete icon. When clicked, it triggers the removeItem(index) function, which removes the task from the list
                                color: Colors.black,
                                iconSize: 30,
                                icon: Icon(Icons.delete),
                                onPressed: null,
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
                    margin: const EdgeInsets.only(top: 20),
                    child: TextField(
                      // Captures user input, tied to nameController
                      controller: nameController,
                      maxLength: 20,
                      decoration: InputDecoration(
                        // It is for labels hints, and bordersl .The IconButton next to it cleaers the text when pressed.
                        contentPadding: const EdgeInsets.all(23),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        labelText: 'Add To-Do List Item',
                        labelStyle: const TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                        ),
                        hintText: 'Enter your task here',
                        hintStyle: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                const IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: null,
                  //To-Do clearTextField()
                ),
              ],
            ),

            // The second Padding widget adds uniform spacing around an ElvatedButton. The button is styled with default Flutter behavior and displays the text "add To-DO Item"
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: ElevatedButton(
                // When pressed, triggers addItemToList() to add the task to the list and Firestore
                onPressed: () {
                  // The onPressed callback is triggered when the button is pressed
                  addItemToList(); // is called to add the current input to the list
                  clearTextField(); // clears the input frmo the TextField.
                },
                style: const ButtonStyle(
                  // The button's style is set to the default Flutter style
                  backgroundColor: WidgetStatePropertyAll(Colors
                      .blue), // The button's background color is set to blue
                ),
                child: const Text(
                  'Add To-Do List Item', // The text displayed on the button
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
