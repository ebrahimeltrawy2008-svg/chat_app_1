import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // تفعيل التخزين المحلي لفايربيس (يعمل تلقائياً ولكن نؤكده)
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  runApp(const MySecretChatApp());
}

class MySecretChatApp extends StatelessWidget {
  const MySecretChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'مساحتنا',
      // إجبار التطبيق على أن يكون من اليمين لليسار (عربي) دائماً
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B141A), // لون داكن عميق جداً
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF111B21), // لون شريط علوي أنيق
          elevation: 1,
          shadowColor: Colors.black54,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF00D09C), // أخضر زمردي عصري
          foregroundColor: Colors.white,
        ),
      ),
      home: const AuthCheck(),
    );
  }
}

// ---------------------------------------------------------
// 1. شاشة فحص الدخول (هل المستخدم مسجل من قبل؟)
// ---------------------------------------------------------
class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});
  @override
  _AuthCheckState createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  bool _isLoading = true;
  String? myId;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  void _checkLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedId = prefs.getString('my_id');
    setState(() {
      myId = savedId;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00D09C)),
        ),
      );
    }
    if (myId != null) return HomeScreen(myId: myId!);
    return const LoginScreen();
  }
}

// ---------------------------------------------------------
// 2. شاشة تسجيل الدخول العصرية
// ---------------------------------------------------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _idController = TextEditingController();

  void _login() async {
    String id = _idController.text.trim();
    if (id.length == 4) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('my_id', id);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(myId: id)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال 4 أرقام صحيحة'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00D09C).withOpacity(0.1),
                ),
                child: const Icon(
                  Icons.fingerprint,
                  size: 80,
                  color: Color(0xFF00D09C),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "المساحة الآمنة",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "أدخل معرفك السري للوصول",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _idController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  letterSpacing: 10,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  counterText: "",
                  hintText: "----",
                  filled: true,
                  fillColor: const Color(0xFF1F2C34),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D09C),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  "تسجيل الدخول",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 3. الشاشة الرئيسية (قائمة المحادثات)
// ---------------------------------------------------------
class HomeScreen extends StatefulWidget {
  final String myId;
  const HomeScreen({super.key, required this.myId});
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> friendsList = [];

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  // تحميل الأصدقاء المحفوظين في الهاتف
  void _loadFriends() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      friendsList = prefs.getStringList('friends_list') ?? [];
    });
  }

  // إضافة صديق جديد وحفظه
  void _addFriend(String friendId) async {
    if (friendId.length == 4 &&
        friendId != widget.myId &&
        !friendsList.contains(friendId)) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      friendsList.add(friendId);
      await prefs.setStringList('friends_list', friendsList);
      setState(() {});
    }
  }

  void _showAddDialog() {
    TextEditingController friendIdController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111B21),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("محادثة جديدة"),
        content: TextField(
          controller: friendIdController,
          keyboardType: TextInputType.number,
          maxLength: 4,
          style: const TextStyle(letterSpacing: 5),
          decoration: const InputDecoration(hintText: "رقم صديقك (4 أرقام)"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D09C),
            ),
            onPressed: () {
              _addFriend(friendIdController.text);
              Navigator.pop(context);
            },
            child: const Text("إضافة", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _openChat(String friendId) {
    int myNum = int.parse(widget.myId);
    int friendNum = int.parse(friendId);
    String chatId = myNum < friendNum
        ? '${widget.myId}_$friendId'
        : '${friendId}_${widget.myId}';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ChatScreen(chatId: chatId, myId: widget.myId, friendId: friendId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "الدردشات",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: friendsList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.speaker_notes_off,
                    size: 80,
                    color: Colors.grey[800],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "لا توجد محادثات بعد",
                    style: TextStyle(color: Colors.grey, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "اضغط على + بالأسفل لإضافة صديقك",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: friendsList.length,
              itemBuilder: (context, index) {
                String friend = friendsList[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: const Color(0xFF1F2C34),
                    child: const Icon(Icons.person, color: Color(0xFF00D09C)),
                  ),
                  title: Text(
                    "صديق ($friend)",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text(
                    "اضغط لفتح المحادثة...",
                    style: TextStyle(color: Colors.grey),
                  ),
                  onTap: () => _openChat(friend),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add_comment_rounded),
      ),
    );
  }
}

// ---------------------------------------------------------
// 4. شاشة المحادثة (الفقاعات العصرية)
// ---------------------------------------------------------
class ChatScreen extends StatefulWidget {
  final String chatId;
  final String myId;
  final String friendId;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.myId,
    required this.friendId,
  });
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();

  void _sendMessage() {
    if (_msgController.text.trim().isEmpty) return;
    FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
      'text': _msgController.text.trim(),
      'senderId': widget.myId,
      'timestamp': FieldValue.serverTimestamp(),
    });
    _msgController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[800],
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              widget.friendId,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      // خلفية داكنة مع لمسة عصرية
      body: Container(
        color: const Color(0xFF0B141A),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(widget.chatId)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF00D09C),
                      ),
                    );
                  }

                  var msgs = snapshot.data!.docs;
                  return ListView.builder(
                    reverse: true, // يبدأ من الأسفل للأعلى
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 20,
                    ),
                    itemCount: msgs.length,
                    itemBuilder: (context, index) {
                      var msg = msgs[index];
                      bool isMe = msg['senderId'] == widget.myId;

                      return Align(
                        // تحديد الاتجاه (يمين للمرسل، يسار للمستقبل)
                        alignment: isMe
                            ? AlignmentDirectional.centerEnd
                            : AlignmentDirectional.centerStart,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 15,
                          ),
                          // الفقاعة تتمدد حسب حجم النص، ولا تتجاوز 75% من الشاشة
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: isMe
                                ? const Color(0xFF005C4B)
                                : const Color(
                                    0xFF1F2C34,
                                  ), // ألوان واتساب العصرية
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(15),
                              topRight: const Radius.circular(15),
                              bottomRight: isMe
                                  ? const Radius.circular(0)
                                  : const Radius.circular(15),
                              bottomLeft: isMe
                                  ? const Radius.circular(15)
                                  : const Radius.circular(0),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            msg['text'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              height: 1.3,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(10),
      color: const Color(0xFF111B21),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2A3942),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _msgController,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                minLines: 1,
                maxLines: 5, // المربع يكبر تلقائياً إذا كتبت كلاماً طويلاً
                decoration: const InputDecoration(
                  hintText: "اكتب رسالتك...",
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              height: 48,
              width: 48,
              decoration: const BoxDecoration(
                color: Color(0xFF00D09C),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.black,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
