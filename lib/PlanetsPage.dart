import 'dart:async';
import 'package:flutter/material.dart';
import 'utils/loadData.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'utils/loadData.dart';
import 'package:humanize_duration/humanize_duration.dart';


class PlanetsPage extends StatefulWidget {
  const PlanetsPage({Key? key}) : super(key: key);

  @override
  _PlanetsPageState createState() => _PlanetsPageState();
}

class _PlanetsPageState extends State<PlanetsPage> {
  List<dynamic> data = [];
  Map<String, dynamic> planetData = {};

  @override
  @override
  void initState() {
    super.initState();
    
    fetchData('https://helldiverstrainingmanual.com/api/v1/war/campaign').then((value) {
      setState(() {
        data = value;
      });
    });

    loadJson('static/planets.json').then((value) {
      setState(() {
        planetData = value;
      });
    });
    /*
    rough format:
    {"0":{"name":"Super Earth","sector":"Sol","biome":null,"environmentals":[]},"1":{"name":"Klen Dahth II","sector":"Altus","biome":{"slug":"mesa","description":"A blazing-hot desert planet, it's rocky mesas are the sole interruptions to the endless sea of dunes."},"environmentals":[{"name":"Intense Heat","description":"High temperatures increase stamina drain and speed up heat buildup in weapons"}]}}
    */

    Timer.periodic(Duration(seconds: 30), (Timer t) async {
      if (this.mounted) {
        var value = await fetchData('https://helldiverstrainingmanual.com/api/v1/war/campaign');
        
        setState(() {
          data = value;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Active Fronts'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.15),
      body: ListView.builder(
        padding: EdgeInsets.all(8.0),
        itemCount: data.length,
        itemBuilder: (context, index) {
          final campaignFront = data[index];

          String faction = campaignFront['faction'].toString().substring(0, campaignFront['faction'].toString().length - 1) + ' Control';

          return FutureBuilder<dynamic>(
            future: fetchData('https://helldiverstrainingmanual.com/api/v1/war/history/${campaignFront['planetIndex']}?timeframe=short'),
            builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
              if (snapshot.hasData) {
                // You can access the data from snapshot.data
                // TODO: Use the data to build your widget
                /* returned data format:
                [
                  {
                    "created_at": "2024-04-07T12:15:08.361967+00:00",
                    "planet_index": 152,
                    "current_health": 341941,
                    "max_health": 1000000,
                    "player_count": 137013
                  },
                  {
                    "created_at": "2024-04-07T12:10:09.456448+00:00",
                    "planet_index": 152,
                    "current_health": 346239,
                    "max_health": 1000000,
                    "player_count": 135057
                  }
                ] */
                // calculate the rate per hour at which the planet is being captured or lost

                // equiv code in js
                // function calculateTimeTo100(history) {
                //   average = history.map(i => 100 - (100 / i.max_health * i.current_health)).reduce((a, b) => a + b, 0) / history.length || 0

                //   const now = Date.now()
                //   const firstEntryTime = history.length > 0 ? new Date(history[history.length - 1].created_at).getTime() : 0
                //   const interval = Math.max(1, (now - firstEntryTime) / 1000)

                //   const rateOfChange = interval > 0 ? (percentage - average) / interval : 0

                //   const remainingPercentage = rateOfChange > 0 ? 100 - percentage : 0 + percentage
                //   const timeToFilledInSeconds = remainingPercentage / rateOfChange

                //   const unixTimeToFilled = now + timeToFilledInSeconds * 1000

                //   estimatedEnd = Math.floor(unixTimeToFilled / 1000)
                //   stalemate = Math.abs(unixTimeToFilled - now) > (1000 * 60 * 60 * 24 * 30) // 30 days
                //   ratePerHour = stalemate ? 0 : rateOfChange * 60 * 60
                // }

                double average = snapshot.data.map((i) => 100 - (100 / i['max_health'] * i['current_health'])).reduce((a, b) => a + b) / snapshot.data.length;


                final now = DateTime.now().millisecondsSinceEpoch;

                final firstEntryTime = snapshot.data.length > 0 ? DateTime.parse(snapshot.data[snapshot.data.length - 1]['created_at']).millisecondsSinceEpoch : 0;

                final interval = (now - firstEntryTime) / 1000;

                final rateOfChange = interval > 0 ? (campaignFront['percentage'] - average) / interval : 0;


                final remainingPercentage = rateOfChange > 0 ? 100 - campaignFront['percentage'] : 0 + campaignFront['percentage'];

                var timeToFilledInSeconds = remainingPercentage / rateOfChange;

                if (timeToFilledInSeconds.isNaN) {
                  timeToFilledInSeconds = 31 * 24 * 60 * 60;
                }

                final unixTimeToFilled = now + timeToFilledInSeconds * 1000;


                // take the greatest of days, hours, minutes
                String estimatedEndFormatted = humanizeDuration(Duration(seconds: timeToFilledInSeconds.toInt()), options: const HumanizeOptions(
                  units: [Units.day, Units.hour, Units.minute],
                ));

                // add 'Liberty in' or 'Defeat in' to the beginning of the string
                estimatedEndFormatted = rateOfChange > 0 ? 'Liberty in $estimatedEndFormatted' : 'Defeat in $estimatedEndFormatted';


                final stalemate = (unixTimeToFilled - now).abs() > (1000 * 60 * 60 * 24 * 30); // 30 days

                final ratePerHour = double.parse(stalemate ? '0' : (rateOfChange * 60 * 60).toStringAsFixed(2));

                if (stalemate) estimatedEndFormatted = 'Stalemate';

                String rateOfChangeFormatted = '';


                if (rateOfChange > 0) {
                  print(rateOfChange);
                  rateOfChangeFormatted = 'Gaining ground at $ratePerHour% per hour';
                }
                else if (rateOfChange < 0) {
                  rateOfChangeFormatted = 'Losing ground at $ratePerHour% per hour';
                }
                else {
                  rateOfChangeFormatted = 'No change in progress';
                }

                return Card(
                  margin: EdgeInsets.all(10.0), // Increase the margin between cards
                  child: Column(
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12.0),
                          topRight: Radius.circular(12.0),
                        ),
                        child: Image.asset('static/biomes/${campaignFront['biome']['slug']}.jpg'),
                      ),
                      ListTile(
                        title: Text(campaignFront['name']),
                        subtitle: Text(faction),
                        trailing: Text('${campaignFront['players']} players'),
                      ),
                      // show rate of change
                      Padding(
                        padding: const EdgeInsets.fromLTRB(15, 7, 15, 5),
                        child: Text(rateOfChangeFormatted),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(15, 7, 15, 15),
                        child: Text('$estimatedEndFormatted'),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(15, 7, 15, 15),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                            child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: campaignFront['percentage'] / 100),
                            duration: const Duration(seconds: 2),
                            builder: (BuildContext context, double value, Widget? child) {
                              return LinearProgressIndicator(
                                minHeight: 10,
                                value: value,
                                // dark yellow if belongs to Terminids, red if belongs to automatons
                                backgroundColor: campaignFront['faction'] == 'Automatons' ? Colors.red : const Color.fromARGB(255, 255, 173, 32),
                                valueColor: AlwaysStoppedAnimation<Color>(const Color.fromARGB(255, 0, 141, 217)),
                              );
                            },
                          ),
                        )
                      ),
                    ],
                  ),
                );
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
            },
          );
        },
      ),
    );
  }
}