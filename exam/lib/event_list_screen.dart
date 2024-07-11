import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'create_event_screen.dart';

class EventListScreen extends StatefulWidget {
  @override
  _EventListScreenState createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  List _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    final url = 'http://10.0.2.2:3000/events';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      setState(() {
        _events = jsonDecode(response.body);
        _isLoading = false;
      });
    } else {
      print('Failed to load events');
    }
  }

  void _navigateToCreateEvent() async {
    bool? eventCreated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateEventScreen()),
    );

    if (eventCreated == true) {
      // 모임이 성공적으로 개설되면 목록을 다시 불러옴
      _fetchEvents();
    }
  }

  Widget _buildEventItem(Map event) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
      padding: EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ListTile(
        title: Text(event['title']),
        subtitle: Text(
          event['description'],
          style: TextStyle(color: Colors.grey),
        ),
        trailing: Text('${event['participants'].length}/${event['maxParticipants']}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('모임 목록'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _navigateToCreateEvent,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : _events.isEmpty
              ? Center(
                  child: Text('모임이 없습니다.'),
                )
              : ListView.builder(
                  itemCount: _events.length,
                  itemBuilder: (context, index) {
                    return _buildEventItem(_events[index]);
                  },
                ),
    );
  }
}
