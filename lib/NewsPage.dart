import 'dart:async';
import 'package:flutter/material.dart';
import 'utils/loadData.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NewsPage extends StatefulWidget {
  const NewsPage({Key? key}) : super(key: key);

  @override
  _NewsPageState createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  int serverTimestamp = 0;
  int days = 5;
  List<dynamic> newsData = [];

  @override
  void initState() {
    super.initState();

    fetchData('https://helldiverstrainingmanual.com/api/v1/war/status').then((value) {
      var daysInSeconds = days * 24 * 60 * 60;
      var from = value['time'] - daysInSeconds;

      fetchData('https://helldiverstrainingmanual.com/api/v1/war/news?from=$from').then((value) {
        // sort by published date

        setState(() {
          newsData = value;
        });
      });

      setState(() {
        serverTimestamp = value['time'];
      });
    });

    Timer.periodic(Duration(seconds: 5 * 60), (timer) {
      if (this.mounted) {
        fetchData('https://helldiverstrainingmanual.com/api/v1/war/status').then((value) {
          setState(() {
            serverTimestamp = value['time'];
          });
        });

        if (serverTimestamp != 0) {
          var daysInSeconds = days * 24 * 60 * 60;
          var from = serverTimestamp - daysInSeconds;

          fetchData('https://helldiverstrainingmanual.com/api/v1/war/news?from=$from').then((value) {
 
            setState(() {
              newsData = value;
            });
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    newsData.sort((a, b) {
      return b['published'].compareTo(a['published']);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('News and Updates'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.15),
      body: ListView.builder(
        padding: EdgeInsets.all(12.0),
        itemCount: newsData.length,
        itemBuilder: (context, index) {
          final newsItem = newsData[index];
          /* {id: 2832, published: 4588675, type: 0, tagIds: [], message: <i=3>PRESIDENTIAL DECREE</i>\n\nThe President of Super Earth has officially recognized this day as Malevelon Creek Memorial Day. Every year on this day, Super Earth citizens will unite for a full 3 minutes of their lunch break in solemn remembrance of those who gave their lives to free Malevelon Creek.\n\nIn addition, all Helldivers have been issued a special commemorative cape, so they may carry the memory of their fallen companions into battle.} */

          // remove html tags from message
          String message = newsItem['message'].replaceAll(RegExp(r'<[^>]*>'), '');

          // from js Date.now() - serverTimestamp * 1000 + item.published * 1000
          var unixTimeStamp = DateTime.now().millisecondsSinceEpoch - serverTimestamp * 1000 + newsItem['published'] * 1000;
          
          // convert to DateTime
          var date = DateTime.fromMillisecondsSinceEpoch(unixTimeStamp.toInt());

          // format date
          var formattedDate = '${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute}';

          // replace unknown characters with spaces
          message = message.replaceAll(RegExp(r'[^\x00-\x7F]+'), ' ');
          
          // split message into title and body
          var msgChunks = message.split('\n').where((element) => element.isNotEmpty && !element.toLowerCase().contains('order')).toList();
          var title = msgChunks[0];
          var body = msgChunks.sublist(1).join('\n\n');

          return Card(
            child: Container(
              padding: EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6.0),
                  Text(
                    'Published $formattedDate',
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    body.length > 0 ? body : 'o7 Helldiver',
                    style: TextStyle(
                      fontSize: 14.0,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}