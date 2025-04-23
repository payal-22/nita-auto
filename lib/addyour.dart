import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nita_auto/services/firestore_service.dart';

class Addyour extends StatefulWidget {
  const Addyour({super.key});

  @override
  State<Addyour> createState() => _AddyourState();
}

class _AddyourState extends State<Addyour> {
  final TextEditingController timePicker = TextEditingController();
  final TextEditingController datePicker = TextEditingController();
  final TextEditingController peopleCountController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    // Set default date to today
    datePicker.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 252, 229, 176),
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Your Trip Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: timePicker,
                decoration: InputDecoration(
                  prefixIcon:
                      const Icon(Icons.access_time, color: Colors.purple),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  labelText: 'Travel Time',
                  labelStyle: const TextStyle(
                    fontSize: 16,
                    color: Colors.purple,
                  ),
                ),
                readOnly: true,
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
              const SizedBox(height: 20),
              TextField(
                controller: datePicker,
                decoration: InputDecoration(
                  prefixIcon:
                      const Icon(Icons.calendar_today, color: Colors.purple),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  labelText: 'Travel Date',
                  labelStyle: const TextStyle(
                    fontSize: 16,
                    color: Colors.purple,
                  ),
                ),
                readOnly: true,
                onTap: () async {
                  DateTime? datetime = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
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
                  prefixIcon: const Icon(Icons.people, color: Colors.purple),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () async {
                      if (timePicker.text.isNotEmpty &&
                          datePicker.text.isNotEmpty &&
                          peopleCountController.text.isNotEmpty) {
                        try {
                          // Use FirestoreService to add travel details
                          await _firestoreService.addTravelDetails(
                            travelTime: timePicker.text,
                            travelDate: datePicker.text,
                            peopleCount: int.parse(peopleCountController.text),
                          );

                          // Provide success feedback
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Trip details added successfully!')),
                            );
                            Navigator.pop(context);
                          }
                        } catch (error) {
                          // Handle any Firestore error
                          print("Failed to add data: $error");
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Error adding trip details')),
                            );
                          }
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please fill all fields')),
                        );
                      }
                    },
                    child: const Text(
                      'Submit',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    timePicker.dispose();
    datePicker.dispose();
    peopleCountController.dispose();
    super.dispose();
  }
}
