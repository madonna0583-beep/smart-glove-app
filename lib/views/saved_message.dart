import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SavedMessages extends StatefulWidget {
  const SavedMessages({super.key});

  @override
  State<SavedMessages> createState() => _SavedMessagesState();
}

class _SavedMessagesState extends State<SavedMessages> {

  final user = FirebaseAuth.instance.currentUser;

  Future<void> deleteMessage(String docId) async {
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .collection("messages")
        .doc(docId)
        .delete();



    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Message deleted"),
          backgroundColor: Color(0xFF660643),
        ),
      );
    
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in to see saved messages")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF660643),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Saved Messages',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(user!.uid)
            .collection("messages")
            .orderBy("time", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No saved messages"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final message = docs[index];

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(message["text"] ?? ""),
                  subtitle: Text(message["translation"] ?? ""),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => deleteMessage(message.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}