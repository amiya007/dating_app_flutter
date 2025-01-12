import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late io.Socket socket;
  List<String> messages = [];
  TextEditingController messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  void connectToServer() {
    socket = io.io('http://192.168.1.3:3000/', <String, dynamic>{
      'transports': ['websocket'],
      // "connection": "upgrade",
      // "upgrade": "websocket",
      'autoConnect': true,
    });

    socket.connect();

    socket.onConnect((_) {
      log('Connected to server');
    });
    socket.onConnectError((data) {
      log('Connection error: $data');
    });

    socket.onError((data) {
      log('Error: $data');
    });
    socket.on('receive_message', (data) {
      setState(() {
        messages.add(data);
      });
      log(messages.toString());
    });
    log(socket.connected.toString());
    socket.onDisconnect((_) => log('Disconnected from server'));
  }

  void sendMessage(String message) {
    socket.emit('send_message', message);
    setState(() {
      messages.add("Me: $message");
    });
    messageController.clear();
  }

  @override
  void dispose() {
    socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat App'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.cast_connected),
            onPressed: () {
              connectToServer();
            },
          ),
          IconButton(
            onPressed: () async {
              socket.disconnect();
            },
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(messages[index]),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      hintText: 'Enter a message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    if (messageController.text.isNotEmpty) {
                      sendMessage(messageController.text);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      messages.clear();
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
