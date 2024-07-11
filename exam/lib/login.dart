import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'post_list_screen.dart';
import 'sign_up_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _message = '';

  void _submit() async {
    String username = _usernameController.text;
    String password = _passwordController.text;

    try {
      var response = await http.post(
        Uri.parse('http://10.0.2.2:3000/login'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        if (responseData['success']) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('nickname', responseData['nickname']);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => PostListScreen()),
          );
        } else {
          setState(() {
            _message = responseData['message'];  // 오류 메시지를 서버에서 받아오기
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

  void _navigateToSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SignUpScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('로그인'),
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
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              child: Text('로그인'),
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: _navigateToSignUp,
              child: Text(
                '회원가입',
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
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
