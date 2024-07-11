import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PostDetailScreen extends StatefulWidget {
  final Map post;
  final String currentUserNickname;

  PostDetailScreen({required this.post, required this.currentUserNickname});

  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _commentController;
  bool _isEditing = false;
  List _comments = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.post['title']);
    _contentController = TextEditingController(text: widget.post['content']);
    _commentController = TextEditingController();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    final response = await http.get(Uri.parse(
        'http://10.0.2.2:3000/comments?postId=${widget.post['_id']}'));

    if (response.statusCode == 200) {
      setState(() {
        _comments = jsonDecode(response.body);
      });
    } else {
      print('Failed to load comments');
    }
  }

  void _addComment() async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/posts/${widget.post['_id']}/comments'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'postId': widget.post['_id'],
        'author': widget.currentUserNickname,
        'content': _commentController.text,
        'date': DateTime.now().toIso8601String(),
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        _comments.add(jsonDecode(response.body));
        _commentController.clear();
      });
    } else {
      print('Failed to add comment');
    }
  }

  void _deleteComment(String commentId) async {
    final response = await http.delete(
      Uri.parse('http://10.0.2.2:3000/comments/$commentId'),
    );

    if (response.statusCode == 200) {
      setState(() {
        _comments.removeWhere((comment) => comment['_id'] == commentId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('댓글이 삭제되었습니다.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('댓글 삭제에 실패했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool canModify = widget.post['author'] == widget.currentUserNickname;

    return Scaffold(
      appBar: AppBar(
        title: Text('게시글 내용'),
        actions: canModify
            ? [
                IconButton(
                  icon: Icon(_isEditing ? Icons.save : Icons.edit),
                  onPressed: _isEditing ? _savePost : _startEditing,
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    _showDeleteConfirmationDialog(context);
                  },
                ),
              ]
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _isEditing
                ? TextField(
                    controller: _titleController,
                    decoration: InputDecoration(labelText: '제목'),
                  )
                : Text(
                    widget.post['title'],
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
            SizedBox(height: 10),
            Text(
              '작성자: ${widget.post['author']}',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 5),
            Text(
              '작성일: ${DateTime.parse(widget.post['date']).toLocal().toString().split(' ')[0]}',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 5),
            Text(
              '카테고리: ${widget.post['category']}',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 70),
            _isEditing
                ? TextField(
                    controller: _contentController,
                    decoration: InputDecoration(labelText: '게시글 내용'),
                    maxLines: null,
                  )
                : Text(
                    widget.post['content'],
                    style: TextStyle(fontSize: 20),
                  ),
            SizedBox(height: 120),
            Text(
              '댓글 (${_comments.length})',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _comments.length,
                itemBuilder: (context, index) {
                  final comment = _comments[index];
                  final isAuthor = comment['author'] == widget.post['author'];
                  final authorText = isAuthor
                      ? '${comment['author']}(작성자)'
                      : (comment['author'] ?? 'Unknown Author');
                  final isCurrentUser = comment['author'] == widget.currentUserNickname;

                  return ListTile(
                    title: Text(authorText, style: TextStyle(color: Colors.black)),
                    subtitle: Text(comment['content'] ?? 'No content'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          comment['date'] != null
                              ? DateTime.parse(comment['date'])
                                  .toLocal()
                                  .toString()
                                  .split(' ')[0]
                              : 'Unknown Date',
                          style: TextStyle(color: Colors.grey),
                        ),
                        if (isCurrentUser)
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.grey),
                            onPressed: () {
                              _showCommentDeleteConfirmationDialog(
                                  context, comment['_id']);
                            },
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                labelText: '댓글 작성',
                suffixIcon: IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _addComment,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  void _savePost() async {
    String updatedTitle = _titleController.text;
    String updatedContent = _contentController.text;

    final response = await http.put(
      Uri.parse('http://10.0.2.2:3000/posts/${widget.post['_id']}'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'title': updatedTitle,
        'content': updatedContent,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        _isEditing = false;
        widget.post['title'] = updatedTitle;
        widget.post['content'] = updatedContent;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('게시글이 수정되었습니다.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('게시글 수정에 실패했습니다.')),
      );
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('게시글 삭제'),
          content: Text('정말로 삭제하시겠습니까?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () {
                _deletePost(context);
                Navigator.of(context).pop();
              },
              child: Text('삭제'),
            ),
          ],
        );
      },
    );
  }

  void _deletePost(BuildContext context) async {
    final response = await http.delete(
      Uri.parse('http://10.0.2.2:3000/posts/${widget.post['_id']}'),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('게시글이 삭제되었습니다.')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('게시글 삭제에 실패했습니다.')),
      );
    }
  }

  void _showCommentDeleteConfirmationDialog(
      BuildContext context, String commentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('댓글 삭제'),
          content: Text('정말로 삭제하시겠습니까?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () {
                _deleteComment(commentId);
                Navigator.of(context).pop();
              },
              child: Text('삭제'),
            ),
          ],
        );
      },
    );
  }
}
