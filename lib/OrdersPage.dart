import 'package:flutter/material.dart';
import 'utils/loadData.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OrdersPage extends StatefulWidget {
  const OrdersPage({Key? key}) : super(key: key);

  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<dynamic> data = [];
  Map<String, dynamic> planetData = {};
  List<dynamic> planetStatus = [];
  List<dynamic> campaignStatus = [];

  @override
  void initState() {
    super.initState();

    loadJson('static/planets.json').then((value) {
      setState(() {
        planetData = value;
      });
    });

    fetchData('https://helldiverstrainingmanual.com/api/v1/war/major-orders').then((value) {
      setState(() {
        data = value;
      });
    });

    fetchData('https://helldiverstrainingmanual.com/api/v1/war/status').then((value) {
      setState(() {
        planetStatus = value['planetStatus'];
      });
    });

    fetchData('https://helldiverstrainingmanual.com/api/v1/war/campaign').then((value) {
      setState(() {
        campaignStatus = value;
      });
    });
  }

  Future<dynamic> fetchData(url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.15),
      appBar: AppBar(
        title: Text('Orders'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(8.0),
        itemCount: data.length,
        itemBuilder: (context, index) {
          final expiresInSeconds = data[index]['expiresIn'];
          // convert to days, hours, minutes
          final days = expiresInSeconds ~/ 86400;
          final hours = (expiresInSeconds % 86400) ~/ 3600;
          final minutes = ((expiresInSeconds % 86400) % 3600) ~/ 60;

          final String expires = '$days days, $hours hours, $minutes minutes';

          String rewards = data[index]['setting']['reward']['amount'].toString();

          if (data[index]['setting']['reward']['type'] == 1) rewards += ' Medals';


          return Card(
            child: Container(
              padding: EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(data[index]['setting']['overrideTitle'], style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10.0),
                  Text(data[index]['setting']['overrideBrief']),
                  SizedBox(height: 10.0),
                  Text(data[index]['setting']['taskDescription']),
                  SizedBox(height: 10.0),
                  Text('Objectives:'),
                  ListView.builder(
                    shrinkWrap: true,
                    scrollDirection: Axis.vertical,
                    itemCount: data[index]['setting']['tasks'].length,
                    padding: EdgeInsets.all(0.0),
                    /*
                    tasks
                    [
                      {
                        "type": 11,
                        "values": [1, 1, 238],
                        "valueTypes": [3, 11, 12]
                      },
                      {
                        "type": 11,
                        "values": [1, 1, 152],
                        "valueTypes": [3, 11, 12]
                      },
                      {
                        "type": 11,
                        "values": [1, 1, 195],
                        "valueTypes": [3, 11, 12]
                      }
                    ],
                    */
                    itemBuilder: (context, index1) {
                      final planetIndex = data[index]['setting']['tasks'][index1]['values'][2].toString();

                      final planet = planetData[planetIndex];

                      final completed = data[index]['progress'][index1];
                      // 1 = completed, 0 = not completed
                      final styles = completed == 1 ? TextStyle(color: Colors.green) : TextStyle(color: Colors.red);

                      // get object in campaignStatus with matching planetIndex
                      final planetStatusIndex = campaignStatus.indexWhere((element) => element['planetIndex'] == int.parse(planetIndex));
                      String percentageProgress = '';

                      if (planetStatusIndex == -1) {
                        if (completed == 1) {
                          percentageProgress = '100%';
                        } else {
                          percentageProgress = '0%';
                        }
                      }
                      else {
                        final planetStatusData = campaignStatus[planetStatusIndex];

                        percentageProgress = '${planetStatusData['percentage'].toStringAsFixed(2)}%';
                      }

                               
                      return ListTile(
                        title: Text('${planet['name']} (${percentageProgress})', style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold).merge(styles)),
                        subtitle: Text('${planet['sector']} sector'),
                      );
                    }
                  ),
                  SizedBox(height: 10.0),
                  Text('Expires in: $expires'),
                  Text('Reward: ${rewards}'),
                ],
              ),
            ),
          );
        },
      )
    );
  }
}
