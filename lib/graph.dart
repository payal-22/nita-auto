import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'chart.dart'; // Your Graph class file

class TravelGraph extends StatefulWidget {
  const TravelGraph({super.key});

  @override
  State<TravelGraph> createState() => _TravelGraphState();
}

class _TravelGraphState extends State<TravelGraph> {
  List<BarChartGroupData> barChartData = [];
  String _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Details Graph'),
        backgroundColor: const Color.fromARGB(255, 93, 94, 146),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
          ),
        ],
      ),
      body: Container(
        color: const Color.fromARGB(255, 250, 230, 170),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Travel Data for $_selectedDate',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ),
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_selectedDate),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Widget _buildBody(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('travel_details')
          .where('travel_date', isEqualTo: _selectedDate)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No travel data available for this date',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        List<Graph> myData = snapshot.data!.docs
            .map((documentSnapshot) =>
                Graph.fromMap(documentSnapshot.data() as Map<String, dynamic>))
            .toList();

        // Filter and group data by hour
        List<Graph> groupedData = _filterAndGroupDataByHour(myData);
        return _buildChart(context, groupedData);
      },
    );
  }

  Widget _buildChart(BuildContext context, List<Graph> myData) {
    if (myData.isEmpty) {
      return const Center(
        child: Text(
          'No data to display for the selected date',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    _generateData(myData);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'People Count vs Time',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _calculateMaxY(myData),
                barGroups: barChartData,
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        if (value >= 0 && value < myData.length) {
                          String travelTime = myData[value.toInt()].travel_time;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              travelTime,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 35,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        );
                      },
                      reservedSize: 40,
                      interval: 1,
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade300,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.purple.withOpacity(0.8),
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      if (groupIndex < myData.length) {
                        String timeSlot = myData[groupIndex].travel_time;
                        int peopleCount = myData[groupIndex].people_count;
                        return BarTooltipItem(
                          '$timeSlot\n$peopleCount people',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(Colors.red, 'High (8+ people)'),
        const SizedBox(width: 16),
        _buildLegendItem(Colors.orange, 'Medium (4-7 people)'),
        const SizedBox(width: 16),
        _buildLegendItem(Colors.blue, 'Low (1-3 people)'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  double _calculateMaxY(List<Graph> data) {
    if (data.isEmpty) return 10;
    int maxValue =
        data.map((e) => e.people_count).reduce((a, b) => a > b ? a : b);
    return (maxValue + 2).toDouble(); // Add some padding
  }

  void _generateData(List<Graph> myData) {
    barChartData = myData.asMap().entries.map((entry) {
      int index = entry.key;
      Graph graph = entry.value;

      // Color coding based on people count
      Color barColor;
      if (graph.people_count >= 8) {
        barColor = Colors.red; // High traffic
      } else if (graph.people_count >= 4) {
        barColor = Colors.orange; // Medium traffic
      } else {
        barColor = Colors.blue; // Low traffic
      }

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: graph.people_count.toDouble(),
            color: barColor,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();
  }

  List<Graph> _filterAndGroupDataByHour(List<Graph> data) {
    Map<int, int> peoplePerHour = {};

    for (var record in data) {
      if (record.travel_date == _selectedDate) {
        DateTime travelTime;
        try {
          String cleanTravelTime = record.travel_time.trim();

          // Handle both 12-hour and 24-hour formats
          if (cleanTravelTime.contains('AM') ||
              cleanTravelTime.contains('PM')) {
            travelTime = DateFormat.jm().parse(cleanTravelTime);
          } else if (cleanTravelTime.contains(':')) {
            travelTime = DateFormat('HH:mm').parse(cleanTravelTime);
          } else {
            continue; // Skip invalid time formats
          }
        } catch (e) {
          print("Error parsing time: $e for time: ${record.travel_time}");
          continue;
        }

        int hour = travelTime.hour;

        // Group people count by hour
        peoplePerHour[hour] = (peoplePerHour[hour] ?? 0) + record.people_count;
      }
    }

    // Convert to Graph objects and sort by hour
    List<Graph> groupedData = peoplePerHour.entries.map((entry) {
      String formattedHour = "${entry.key.toString().padLeft(2, '0')}:00";
      return Graph(entry.value, _selectedDate, formattedHour);
    }).toList();

    // Sort by hour
    groupedData.sort((a, b) {
      int hourA = int.parse(a.travel_time.split(':')[0]);
      int hourB = int.parse(b.travel_time.split(':')[0]);
      return hourA.compareTo(hourB);
    });

    return groupedData;
  }
}
