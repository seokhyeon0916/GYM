const express = require('express');
const bodyParser = require('body-parser');
const mongoose = require('mongoose');
const cors = require('cors');
const bcrypt = require('bcrypt');
const saltRounds = 10;

const app = express();
const port = 3000;

app.use(cors());
app.use(bodyParser.json());

mongoose.connect('mongodb://localhost:27017/gym', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => {
  console.log('Connected to MongoDB');
})
.catch((err) => {
  console.error('Error connecting to MongoDB', err);
});

// User 모델 정의
const userSchema = new mongoose.Schema({
  username: { type: String, unique: true },
  password: String,
  nickname: { type: String, unique: true },
  posts: [
    {
      title: String,
      content: String,
      author: String,
      category: String,
      date: { type: Date, default: Date.now },
      comments: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Comment' }],
      participants: [String], // 참가자 목록
      maxParticipants: Number // 댓글을 ObjectId로 참조
    }
  ]
});

const User = mongoose.model('User', userSchema);

// 댓글 모델 정의
const commentSchema = new mongoose.Schema({
  postId: { type: mongoose.Schema.Types.ObjectId, ref: 'Post' }, // 게시글 ObjectId로 참조
  author: String,
  content: String,
  date: { type: Date, default: Date.now }
});

const Comment = mongoose.model('Comment', commentSchema);

// 로그인 엔드포인트
app.post('/login', async (req, res) => {
  const { username, password } = req.body;

  try {
    const user = await User.findOne({ username });
    if (!user) {
      return res.status(400).json({ success: false, message: 'Invalid username or password' });
    }

    const match = await bcrypt.compare(password, user.password);
    if (!match) {
      return res.status(400).json({ success: false, message: 'Invalid username or password' });
    }

    res.status(200).json({ success: true, message: 'Login successful', nickname: user.nickname });
  } catch (error) {
    console.error('Error occurred during login:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// 회원가입 엔드포인트
app.post('/register', async (req, res) => {
  const { username, password, nickname } = req.body;

  try {
    const existingUser = await User.findOne({ username });
    if (existingUser) {
      return res.status(400).json({ success: false, message: 'Username already exists' });
    }

    const hashedPassword = await bcrypt.hash(password, saltRounds);
    const user = new User({ username, password: hashedPassword, nickname });
    await user.save();

    res.status(200).json({ success: true, message: 'User registered successfully' });
  } catch (error) {
    console.error('Error occurred during registration:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// 게시글 작성 엔드포인트
app.post('/create', async (req, res) => {
  const { title, content, author, category } = req.body;

  try {
    const user = await User.findOne({ nickname: author });

    if (!user) {
      return res.status(404).send({ success: false, message: 'User not found' });
    }

    user.posts.push({ title, content, author, category });
    await user.save();

    res.status(200).json({ success: true, message: 'Post created successfully' });
  } catch (error) {
    console.error('Error occurred while creating post:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// 카테고리별 게시글 조회 엔드포인트
app.get('/posts', async (req, res) => {
  const { category } = req.query;

  try {
    let users;
    if (category && category !== '전체') {
      users = await User.aggregate([
        { $unwind: '$posts' },
        { $match: { 'posts.category': category } },
        { $group: { _id: '$_id', posts: { $push: '$posts' } } }
      ]);
    } else {
      users = await User.find();
    }

    let posts = [];
    users.forEach(user => {
      posts = [...posts, ...user.posts];
    });

    res.status(200).json(posts);
  } catch (error) {
    console.error('Error occurred while fetching posts:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// 게시글 수정 엔드포인트
app.put('/posts/:id', async (req, res) => {
  const postId = req.params.id;
  const { title, content } = req.body;

  try {
    const user = await User.findOne({ 'posts._id': postId });
    if (!user) {
      return res.status(404).send({ success: false, message: 'Post not found' });
    }

    const post = user.posts.id(postId);
    if (!post) {
      return res.status(404).send({ success: false, message: 'Post not found' });
    }

    post.title = title;
    post.content = content;
    await user.save();

    res.status(200).json({ success: true, message: 'Post updated successfully' });
  } catch (error) {
    console.error('Error occurred while updating post:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// 게시글 삭제 엔드포인트
app.delete('/posts/:id', async (req, res) => {
  const postId = req.params.id;

  try {
    const user = await User.findOne({ 'posts._id': postId });
    if (!user) {
      return res.status(404).send({ success: false, message: 'Post not found' });
    }

    user.posts.id(postId).remove();
    await user.save();

    res.status(200).json({ success: true, message: 'Post deleted successfully' });
  } catch (error) {
    console.error('Error occurred while deleting post:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// 댓글 가져오기 엔드포인트
app.get('/comments', async (req, res) => {
  const { postId } = req.query;

  try {
    const comments = await Comment.find({ postId }).sort({ date: 'desc' }); // 최신 댓글이 먼저 오도록 정렬
    res.status(200).json(comments);
  } catch (error) {
    console.error('Error occurred while fetching comments:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// 댓글 작성 엔드포인트
app.post('/posts/:id/comments', async (req, res) => {
  const postId = req.params.id;
  const { author, content } = req.body;

  try {
    const comment = new Comment({ postId, author, content });
    await comment.save();

    // 해당 게시글의 User를 찾아서 댓글 추가
    const user = await User.findOne({ 'posts._id': postId });
    if (!user) {
      return res.status(404).send({ success: false, message: 'Post not found' });
    }

    const post = user.posts.id(postId);
    post.comments.push(comment._id);
    await user.save();

    res.status(200).json({ success: true, message: 'Comment added successfully', comment });
  } catch (error) {
    console.error('Error occurred while adding comment:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// 댓글 삭제 엔드포인트
app.delete('/comments/:commentId', async (req, res) => {
  const commentId = req.params.commentId;

  try {
    const comment = await Comment.findById(commentId);
    if (!comment) {
      return res.status(404).send({ success: false, message: 'Comment not found' });
    }

    // 댓글 삭제
    await Comment.findByIdAndDelete(commentId);

    // 해당 댓글이 속한 게시글의 User를 찾아서 댓글 제거
    const user = await User.findOne({ 'posts.comments': commentId });
    if (user) {
      user.posts.forEach(post => {
        const commentIndex = post.comments.indexOf(commentId);
        if (commentIndex > -1) {
          post.comments.splice(commentIndex, 1);
        }
      });
      await user.save();
    }

    res.status(200).json({ success: true, message: 'Comment deleted successfully' });
  } catch (error) {
    console.error('Error occurred while deleting comment:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// 모임 목록 조회 엔드포인트
app.get('/events', async (req, res) => {
  try {
    const users = await User.find({ 'posts.category': '모임' }, 'posts.$');
    let events = [];
    users.forEach(user => {
      events = [...events, ...user.posts];
    });
    res.status(200).json(events);
  } catch (error) {
    console.error('Error occurred while fetching events:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// 모임 생성 엔드포인트
app.post('/create_event', async (req, res) => {
  const { title, description, author, maxParticipants } = req.body;

  try {
    const user = await User.findOne({ nickname: author });

    if (!user) {
      return res.status(404).send({ success: false, message: 'User not found' });
    }

    // 모임 데이터를 생성하고 저장
    user.posts.push({ title, content: description, author, category: '모임', maxParticipants, participants: [] });
    await user.save();

    res.status(200).json({ success: true, message: 'Event created successfully' });
  } catch (error) {
    console.error('Error occurred while creating event:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// 모임 참여 엔드포인트
app.post('/join_event/:postId', async (req, res) => {
  const postId = req.params.postId;
  const { participant } = req.body;

  try {
    const user = await User.findOne({ 'posts._id': postId });

    if (!user) {
      return res.status(404).send({ success: false, message: 'Event not found' });
    }

    const post = user.posts.id(postId);
    if (!post) {
      return res.status(404).send({ success: false, message: 'Event not found' });
    }

    if (post.participants.length >= post.maxParticipants) {
      return res.status(400).send({ success: false, message: 'Event is full' });
    }

    if (post.participants.includes(participant)) {
      return res.status(400).send({ success: false, message: 'Already joined the event' });
    }

    post.participants.push(participant);
    await user.save();

    res.status(200).json({ success: true, message: 'Joined event successfully' });
  } catch (error) {
    console.error('Error occurred while joining event:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});
