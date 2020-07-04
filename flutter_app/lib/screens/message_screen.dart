import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pusher_websocket_flutter/pusher.dart';

class MessageScreen extends StatefulWidget {
  @override
  _MessageScreenState createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  StreamController<String> _eventData = StreamController<String>();
  Sink get _inEventData => _eventData.sink;
  Stream get eventStream => _eventData.stream;

  Channel channel;

  String channelName = 'flutter-laravel-app';
  String eventName = 'laravel.app';

  List<String> messages = new List<String>();

  @override
  void initState()
  {
    super.initState();

    initPusher();
  }

  @override
  void dispose()
  {
    Pusher.unsubscribe(channelName);
    channel.unbind(eventName);
    _eventData.close();

    super.dispose();
  }

  Future<void> initPusher() async {
    await Pusher.init(
        DotEnv().env['PUSHER_APP_KEY'],
        PusherOptions(cluster: DotEnv().env['PUSHER_APP_CLUSTER']),
        enableLogging: true
    );

    Pusher.connect();

    channel = await Pusher.subscribe(channelName);

    channel.bind(eventName, (last) {
      final String data = last.data;
      _inEventData.add(data);
    });

    eventStream.listen((data) async {
      Map<String, dynamic> message = jsonDecode(data);

      setState(() {
        messages.add(message['message']);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter + Laravel + Pusher',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Messages'),
        ),
        body: ListView.builder(
          itemCount: messages.length,
          itemBuilder: (BuildContext context, int index) {
            return Container(
              margin: EdgeInsets.all(15),
              child: Center(
                child: Text(
                  messages[index],
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }
        )
      ),
    );
  }
}
