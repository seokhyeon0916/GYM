import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CreatePostScreen extends StatefulWidget {
  final String author;

  CreatePostScreen({required this.author});

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  String _selectedCategory = '헬스'; // 기본 카테고리 설정
  TextEditingController _titleController = TextEditingController();
  TextEditingController _contentController = TextEditingController();

  List<String> _categories = ['헬스', '조깅', '필라테스', '크로스핏', '자전거', '기타']; // 카테고리 목록

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('게시글 작성'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue!;
                });
              },
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: '제목',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: _contentController,
              maxLines: null,
              decoration: InputDecoration(
                labelText: '내용',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                _createPost();
              },
              child: Text('작성'),
            ),
          ],
        ),
      ),
    );
  }

  void _createPost() async {
    String title = _titleController.text.trim();
    String content = _contentController.text.trim();

    // HTTP POST 요청으로 게시글 작성
    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/create'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'author': widget.author,
        'title': title,
        'content': content,
        'category': _selectedCategory,
      }),
    );

    if (response.statusCode == 201) {
      Navigator.pop(context, true); // 작성 완료 후 이전 화면으로 돌아가기
    } else {
      print('Failed to create post');
    }
  }
}
