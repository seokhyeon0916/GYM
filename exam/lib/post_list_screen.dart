import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'create_event_screen.dart';
import 'login.dart';
import 'post_detail_screen.dart';
import 'event_list_screen.dart'; // 모임 목록 페이지 import

class PostListScreen extends StatefulWidget {
  @override
  _PostListScreenState createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  List _posts = [];
  bool _isLoading = true;
  String _selectedCategory = '전체'; // 기본 카테고리 설정
  String _currentUserNickname = ''; // 현재 사용자 닉네임 추가

  @override
  void initState() {
    super.initState();
    _fetchPosts();
    _getCurrentUserNickname(); // 현재 사용자 닉네임 초기화
  }

  Future<void> _fetchPosts() async {
    String url = _selectedCategory == '전체'
        ? 'http://10.0.2.2:3000/posts'
        : 'http://10.0.2.2:3000/posts?category=$_selectedCategory';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      setState(() {
        _posts = jsonDecode(response.body);
        _isLoading = false;
      });
    } else {
      print('Failed to load posts');
    }
  }

  Future<void> _getCurrentUserNickname() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? nickname = prefs.getString('nickname');
    setState(() {
      _currentUserNickname = nickname ?? ''; // 현재 사용자 닉네임 설정
    });
  }

  Future<void> _navigateToCreateEvent() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? author = prefs.getString('nickname');

    if (author != null) {
      bool? eventCreated = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CreateEventScreen()),
      );

      if (eventCreated == true) {
        // 모임이 성공적으로 개설되면 목록을 다시 불러옴
        _fetchPosts();
      }
    } else {
      _logout();
    }
  }

  void _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('nickname');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  void _navigateToEventList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EventListScreen()),
    );
  }

  void _navigateToPostDetail(Map post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(post: post, currentUserNickname: _currentUserNickname),
      ),
    ).then((result) {
      if (result == true) {
        _refreshPosts(); // 수정 후에 목록을 갱신
      }
    });
  }

  void _refreshPosts() {
    setState(() {
      _isLoading = true;
    });
    _fetchPosts();
  }

  Widget _buildPostItem(Map post, int index) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
      padding: EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ListTile(
        title: Text('${index + 1}. ${post['title']}'),
        onTap: () => _navigateToPostDetail(post),
      ),
    );
  }

  void _changeCategory(String? newCategory) {
    setState(() {
      _selectedCategory = newCategory ?? '전체';
      _isLoading = true; // 카테고리 변경 시 로딩 상태로 설정
      _fetchPosts(); // Fetch posts for the selected category
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('게시판'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48.0), // 드롭다운의 높이 설정
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              items: ['전체', '헬스', '조깅', '필라테스', '크로스핏', '자전거', '기타']
                  .map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(
                    category,
                    style: TextStyle(fontSize: 12), // 작은 폰트 크기 설정
                  ),
                );
              }).toList(),
              onChanged: _changeCategory,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshPosts,
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
          IconButton(
            icon: Icon(Icons.person_add),
            onPressed: _navigateToEventList, // 모임 목록 페이지로 이동
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : _posts.isEmpty
              ? Center(
                  child: Text('게시글이 없습니다.'),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: _posts.length,
                        itemBuilder: (context, index) {
                          return _buildPostItem(_posts[index], index);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: PostListScreen(),
  ));
}
