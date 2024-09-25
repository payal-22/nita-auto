import 'package:flutter/material.dart';
import 'package:nita_auto/addyour.dart';
// import 'package:nita_auto/graph.dart';
import 'package:nita_auto/screens/bar_graph_screen.dart';
import 'firebase_functions.dart';
import 'comment.dart'; // Import the Comments section

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFunctions _firebaseFunctions = FirebaseFunctions();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 93, 94, 146),
        title: Text(
          'Auto-Mate',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await _firebaseFunctions.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Container(
        color: const Color.fromARGB(255, 250, 230, 170),
        child: SingleChildScrollView(
          // Wrap with SingleChildScrollView to prevent overflow

          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Number of People vs Time (Today)',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                // Placeholder for the graph
                SizedBox(
                  height: 250,
                  child: BarGraphScreen(),
                ),

                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => Addyour(),
                    );
                  },
                  child: Text('Add Your Trip Details'),
                ),
                SizedBox(height: 20),
                // Add the Comments Section below the button
                CommentsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Dialog to add trip details
class AddTripDialog extends StatefulWidget {
  @override
  _AddTripDialogState createState() => _AddTripDialogState();
}

class _AddTripDialogState extends State<AddTripDialog> {
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _numPeopleController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // Form key for validation

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Trip Details'),
      content: SingleChildScrollView(
        // Ensure content is scrollable if needed
        child: Form(
          key: _formKey, // Form for validation
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _timeController,
                decoration: InputDecoration(labelText: 'Time (HH:MM)'),
                keyboardType: TextInputType.datetime,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a valid time';
                  }
                  // Add more validation for correct time format if needed
                  return null;
                },
              ),
              TextFormField(
                controller: _numPeopleController,
                decoration: InputDecoration(labelText: 'Number of People'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter number of people';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Enter a valid number of people';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // Process the input (for now just print the values)
              print(
                  "Time: ${_timeController.text}, People: ${_numPeopleController.text}");

              // Clear text fields after submission
              _timeController.clear();
              _numPeopleController.clear();

              // Close the dialog
              Navigator.pop(context);
            }
          },
          child: Text('Add'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // Dispose controllers to free up resources
    _timeController.dispose();
    _numPeopleController.dispose();
    super.dispose();
  }
}
