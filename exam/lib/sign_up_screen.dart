import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  String _message = '';

  void _submit() async {
    String username = _usernameController.text;
    String password = _passwordController.text;
    String nickname = _nicknameController.text;

    try {
      var response = await http.post(
        Uri.parse('http://10.0.2.2:3000/register'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'username': username,
          'password': password,
          'nickname': nickname,
        }),
      );

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        if (responseData['success']) {
          setState(() {
            _message = 'User registered successfully.';
          });
        } else {
          setState(() {
            _message = 'Failed to register user.';
          });
        }
      } else {
        setState(() {
          _message = 'Server error occurred.';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Failed to connect to the server.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('회원가입'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: '아이디'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: '비밀번호'),
              obscureText: true,
            ),
            TextField(
              controller: _nicknameController,
              decoration: InputDecoration(labelText: '닉네임'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              child: Text('회원가입'),
            ),
            SizedBox(height: 20),
            _message.isNotEmpty
                ? Text(
                    _message,
                    style: TextStyle(color: Colors.red),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }
}
