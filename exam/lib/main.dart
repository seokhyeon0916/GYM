import 'package:flutter/material.dart';
import 'login.dart';  // 로그인 화면을 포함한 파일
import 'post_list_screen.dart';  // 게시판 목록 화면을 포함한 파일
import 'create_post_screen.dart';  // 게시글 작성 화면을 포함한 파일
import 'sign_up_screen.dart';  // 회원가입 화면을 포함한 파일
import 'post_detail_screen.dart';
import 'create_event_screen.dart';
import 'event_list_screen.dart';



void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  String loggedInUser = 'example_user'; // 로그인된 사용자의 닉네임을 여기에 설정

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/login', // 초기 라우트 설정
      routes: {
        '/login': (context) => LoginScreen(),
        '/postList': (context) => PostListScreen(),
      },
      onGenerateRoute: (settings) { // 라우트를 동적으로 생성할 때 사용
        if (settings.name == '/createPost') {
          return MaterialPageRoute(
            builder: (context) => CreatePostScreen(author: loggedInUser),
          );
        }
        return null;
      },
    );
  }
}
