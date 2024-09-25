import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Addyour extends StatefulWidget {
  const Addyour({super.key});

  @override
  State<Addyour> createState() => _AddyourState();
}

class _AddyourState extends State<Addyour> {
  TextEditingController timePicker = TextEditingController();
  TextEditingController datePicker = TextEditingController();
  TextEditingController peopleCountController = TextEditingController();

  // Firebase Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 252, 229, 176),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: timePicker,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                labelText: 'Travel Time',
                labelStyle: const TextStyle(
                  fontSize: 16,
                  color: Colors.purple,
                ),
              ),
              onTap: () async {
                var time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );

                if (time != null) {
                  setState(() {
                    timePicker.text = time.format(context);
                  });
                }
              },
            ),
            const SizedBox(
              height: 20,
            ),
            TextField(
              controller: datePicker,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                labelText: 'Travel Date',
                labelStyle: const TextStyle(
                  fontSize: 16,
                  color: Colors.purple,
                ),
              ),
              onTap: () async {
                DateTime? datetime = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1950),
                  lastDate: DateTime(2100),
                );
                if (datetime != null) {
                  String formattedDate =
                      DateFormat('yyyy-MM-dd').format(datetime);

                  setState(() {
                    datePicker.text = formattedDate;
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: peopleCountController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                labelText: 'Number of People Traveling',
                labelStyle: const TextStyle(
                  fontSize: 16,
                  color: Colors.purple,
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (timePicker.text.isNotEmpty &&
                    datePicker.text.isNotEmpty &&
                    peopleCountController.text.isNotEmpty) {
                  try {
                    // Store data in Firestore
                    await _firestore.collection('travel_details').add({
                      'travel_time': timePicker.text,
                      'travel_date': datePicker.text,
                      'people_count': int.parse(peopleCountController.text),
                    });

                    // Provide success feedback (Snackbar or other)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Data added successfully!')),
                    );

                    // Navigate back to the homepage after storing
                    Navigator.pop(context);
                  } catch (error) {
                    // Handle any Firestore error
                    print("Failed to add data: $error");
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error adding data')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
