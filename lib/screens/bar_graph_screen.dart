import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BarGraphScreen extends StatefulWidget {
  const BarGraphScreen({Key? key}) : super(key: key);

  @override
  State<BarGraphScreen> createState() => _BarGraphScreenState();
}

class _BarGraphScreenState extends State<BarGraphScreen> {
  String _currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('travel_details')
          .where('travel_date', isEqualTo: _currentDate)
          .snapshots(), // Using snapshots() for real-time updates
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text('No travel data available for today'));
        }

        // Process the data and build the chart
        final Map<String, int> timeSlotData =
            _processTimeSlotData(snapshot.data!.docs);
        return _buildBarChart(timeSlotData);
      },
    );
  }

  Map<String, int> _processTimeSlotData(List<QueryDocumentSnapshot> docs) {
    Map<String, int> timeSlotData = {};

    // Only show time slots from 5:00 to 22:00 - focus on likely travel times
    for (int hour = 5; hour <= 22; hour++) {
      String timeSlot = '${hour.toString().padLeft(2, '0')}:00';
      timeSlotData[timeSlot] = 0;
    }

    for (var doc in docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      if (data.containsKey('travel_time') && data.containsKey('people_count')) {
        String travelTime = data['travel_time'];
        int peopleCount = data['people_count'] ?? 0;

        try {
          DateTime parsedTime;
          if (travelTime.contains('AM') || travelTime.contains('PM')) {
            parsedTime = DateFormat('h:mm a').parse(travelTime);
          } else {
            parsedTime = DateFormat('HH:mm').parse(travelTime);
          }

          String hourSlot = '${parsedTime.hour.toString().padLeft(2, '0')}:00';

          if (timeSlotData.containsKey(hourSlot)) {
            timeSlotData[hourSlot] =
                (timeSlotData[hourSlot] ?? 0) + peopleCount;
          } else if (parsedTime.hour >= 5 && parsedTime.hour <= 22) {
            // Only add the slot if it's within our display range
            timeSlotData[hourSlot] = peopleCount;
          }
        } catch (e) {
          print('Error parsing time: $e for time: $travelTime');
        }
      }
    }

    return timeSlotData;
  }

  Widget _buildBarChart(Map<String, int> timeSlotData) {
    // Show only 6 time slots at a time to prevent overcrowding
    final List<String> timeSlots = _getVisibleTimeSlots(timeSlotData);
    final Map<String, int> visibleData = Map.fromEntries(
        timeSlots.map((slot) => MapEntry(slot, timeSlotData[slot] ?? 0)));

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _calculateMaxY(timeSlotData),
                barGroups: _createBarGroups(visibleData),
                titlesData: _createTitlesData(visibleData),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[300],
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (BarChartGroupData touchedGroup) =>
                        const Color.fromRGBO(100, 58, 140, 0.8),
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      String timeSlot = visibleData.keys.toList()[groupIndex];
                      int peopleCount = visibleData[timeSlot] ?? 0;
                      return BarTooltipItem(
                        '$timeSlot\n$peopleCount people',
                        const TextStyle(color: Colors.white),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<String> _getVisibleTimeSlots(Map<String, int> timeSlotData) {
    // Return a subset of time slots that are most relevant
    // Focus on time slots with data or current time range
    final now = DateTime.now();
    final currentHour = now.hour;

    // First look for slots with actual data
    final slotsWithData = timeSlotData.entries
        .where((entry) => entry.value > 0)
        .map((entry) => entry.key)
        .toList();

    if (slotsWithData.isNotEmpty) {
      // Show slots with data + a few more around them
      slotsWithData.sort();
      return slotsWithData.take(6).toList();
    }

    // If no data, show time slots around current hour
    int startHour = (currentHour - 2).clamp(5, 22);
    List<String> visibleSlots = [];
    for (int i = 0; i < 6; i++) {
      int hour = (startHour + i).clamp(5, 22);
      visibleSlots.add('${hour.toString().padLeft(2, '0')}:00');
    }

    return visibleSlots;
  }

  double _calculateMaxY(Map<String, int> timeSlotData) {
    int maxValue =
        timeSlotData.values.fold(0, (max, count) => count > max ? count : max);
    return maxValue > 0 ? (maxValue + 1).toDouble() : 5.0; // Minimum scale to 5
  }

  List<BarChartGroupData> _createBarGroups(Map<String, int> visibleData) {
    List<BarChartGroupData> barGroups = [];
    List<String> timeSlots = visibleData.keys.toList()..sort();

    for (int i = 0; i < timeSlots.length; i++) {
      String timeSlot = timeSlots[i];
      int peopleCount = visibleData[timeSlot] ?? 0;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: peopleCount.toDouble(),
              color: peopleCount >= 5
                  ? Colors.green // Good for sharing auto (5 or more people)
                  : peopleCount >= 3
                      ? Colors.orange // Possible to share (3-4 people)
                      : Colors.blue, // Few people (1-2)
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return barGroups;
  }

  FlTitlesData _createTitlesData(Map<String, int> visibleData) {
    List<String> timeSlots = visibleData.keys.toList()..sort();

    return FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          getTitlesWidget: (double value, TitleMeta meta) {
            if (value >= 0 && value < timeSlots.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  timeSlots[value.toInt()],
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          getTitlesWidget: (double value, TitleMeta meta) {
            if (value == value.roundToDouble()) {
              return Text(
                value.toInt().toString(),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.black,
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }
}
