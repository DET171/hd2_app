import 'dart:async';
import 'package:flutter/material.dart';
import 'utils/loadData.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
    
    fetchData().then((value) {
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
        var value = await fetchData();
        
        setState(() {
          data = value;
        });
      }
    });
  }

  Future<List<dynamic>> fetchData() async {
    final response = await http.get(Uri.parse('https://helldiverstrainingmanual.com/api/v1/war/campaign'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
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
        itemCount: data.length,
        itemBuilder: (context, index) {
          final campaignFront = data[index];
          /* rough format:
          {
            "planetIndex": 152,
            "name": "Durgen",
            "faction": "Automatons",
            "players": 131470,
            "health": 355556,
            "maxHealth": 1000000,
            "percentage": 64.4444,
            "defense": false,
            "majorOrder": false,
            "biome": {
              "slug": "mesa",
              "description": "A blazing-hot desert planet, it's rocky mesas are the sole interruptions to the endless sea of dunes."
            },
            "expireDateTime": null
          } */

          return Text('WIP');
        },
      ),
    );
  }
}