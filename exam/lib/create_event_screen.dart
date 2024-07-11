import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CreateEventScreen extends StatefulWidget {
  @override
  _CreateEventScreenState createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _titleController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _maxParticipantsController = TextEditingController();

  void _submitEvent() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? author = prefs.getString('nickname');

    if (author != null) {
      String title = _titleController.text;
      String description = _descriptionController.text;
      int maxParticipants = int.parse(_maxParticipantsController.text);

      // 서버로 데이터를 전송하는 예시 코드
      String url = 'http://10.0.2.2:3000/create_event'; // 실제 API 엔드포인트에 맞게 수정 필요

      try {
        final response = await http.post(
          Uri.parse(url),
          body: jsonEncode({
            'title': title,
            'description': description,
            'author': author,
            'maxParticipants': maxParticipants
          }),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          // 성공적으로 모임을 개설한 경우
          Navigator.pop(context, true); // 이전 화면으로 돌아가기
        } else {
          // 실패 시 처리
          print('Failed to create event');
        }
      } catch (e) {
        print('Error creating event: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('모임 개설'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: '모임 제목'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '모임 제목을 입력하세요';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: '모임 설명'),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '모임 설명을 입력하세요';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _maxParticipantsController,
                decoration: InputDecoration(labelText: '모임 제한 인원'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '모임 제한 인원을 입력하세요';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return '유효한 숫자를 입력하세요';
                  }
                  return null;
                },
              ),
              SizedBox(height: 32.0),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _submitEvent();
                  }
                },
                child: Text('모임 개설하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
