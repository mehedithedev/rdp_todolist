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

    if (taskName != '') {
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
  }

  void removeItems(int index) async {
    //Get the tasks to be removed
    String taskToBeRemoved = tasks[index];

    //Remove the task from Firestore
    QuerySnapshot querySnapshot = await db
        .collection('tasks')
        .where('name', isEqualTo: taskToBeRemoved)
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

  Future<void> fetchTasksFromFirestore() async {
    // Get a reference to the 'tasks' collection from FireStore
    CollectionReference taskCollection = db.collection('tasks');

    // fetch the documents (tasks) from the collection
    QuerySnapshot querySnapshot = await taskCollection.get();

    // Create an empty list to store the fetched task names
    List<String> fetchedTasks = [];

    // Loop through each do (task) in the querySnapshot object
    for (QueryDocumentSnapshot docSnapShot in querySnapshot.docs) {
      // Get the task name from the data
      String taskName = docSnapShot.get('new');

      // Get the completion statuus from the data
      String completed = docSnapShot.get('completed');

      // Add the task name to the fetched tasks
      fetchedTasks.add(taskName);
      setState(() {
        tasks.clear();
        tasks.addAll(fetchedTasks);
      });
    }
  }

  Future<void> updateTaskCompletionStatus(
      String taskName, bool completed) async {
    // Get a reference to the 'tasks' collection from Firestore
    CollectionReference tasksCollection = db.collection('tasks');

    // Query firestore for tasks with the task name
    QuerySnapshot querySnapshot =
        await tasksCollection.where('name', isEqualTo: taskName).get();

    // If matching document is found
    if (querySnapshot.size > 0) {
      // Getting a reference to the first matching document
      DocumentSnapshot documentSnapshot = querySnapshot.docs[0];

      await documentSnapshot.reference.update({
        'completed': true,
      });
      setState(() {
        // find the index of the task in the task list

        int taskIndex = tasks.indexWhere((task) => task == taskName);

        // Update the corresponding checkbox value in the checkbox list

        checkboxes[taskIndex] = completed;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchTasksFromFirestore();
  }

  // Belo is the method to clear the text field
  void clearTextField() {
    nameController.clear();
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            TableCalendar(
              calendarFormat: CalendarFormat.month,
              headerVisible: true,
              focusedDay: DateTime.now(),
              firstDay: DateTime(2023),
              lastDay: DateTime(2025),
            ),
            SizedBox(
              height: 280,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: tasks.length,
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    margin: const EdgeInsets.only(top: 3.0),
                    decoration: BoxDecoration(
                      color: checkboxes[index]
                          ? Colors.green.withOpacity(0.7)
                          : Colors.blue.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            size: 44,
                            !checkboxes[index]
                                ? Icons.manage_history
                                : Icons.playlist_add_check_circle,
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Text(
                              tasks[index],
                              style: checkboxes[index]
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
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 20),
                    child: TextField(
                      controller: nameController,
                      maxLength: 20,
                      decoration: InputDecoration(
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
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: ElevatedButton(
                onPressed: () {
                  addItemToList();
                },
                style: const ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(Colors.blue),
                ),
                child: const Text(
                  'Add To-Do List Item',
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
