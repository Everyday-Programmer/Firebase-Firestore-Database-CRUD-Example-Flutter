import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final CollectionReference notes = FirebaseFirestore.instance.collection("notes");

  void _showBottomSheet({String? id, String? title, String? content}) {
    _titleController.text = title ?? "";
    _contentController.text = content ?? "";

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(labelText: "Title"),
              ),
              TextField(
                controller: _contentController,
                decoration: InputDecoration(labelText: "Content"),
              ),
              SizedBox(height: 20,),
              ElevatedButton(
                  onPressed: () async {
                    if (id == null) {
                      await notes.add({
                        "title": _titleController.text,
                        "content": _contentController.text,
                        "timestamp": FieldValue.serverTimestamp()
                      });
                    } else {
                      await notes.doc(id).update({
                        "title": _titleController.text,
                        "content": _contentController.text,
                        "timestamp": FieldValue.serverTimestamp()
                      });
                    }
                    Navigator.pop(context);
                  },
                  child: Text(id == null ? 'Add Note' : 'Update Note'),
              ),
            ],
          ),
        ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure to delete this note ?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel')
            ),
            TextButton(
                onPressed: () async {
                  await notes.doc(id).delete();
                  Navigator.pop(context);
                },
                child: Text('Delete', style: TextStyle(color: Colors.red),)
            ),
          ],
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Firestore CRUD Example'),),
      body: StreamBuilder(
          stream: notes.orderBy('timestamp', descending: true).snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
             if (!snapshot.hasData) {
               return Center(child: CircularProgressIndicator());
             }

             return ListView(
               children: snapshot.data!.docs.map((note) {
                 return ListTile(
                   title: Text(note['title']),
                   subtitle: Text(note['content']),
                   trailing: Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       IconButton(
                           onPressed: () => _showBottomSheet(id: note.id, title: note['title'], content: note['content']),
                           icon: Icon(Icons.edit),
                       ),
                       IconButton(
                           onPressed: () => _confirmDelete(note.id),
                           icon: Icon(Icons.delete)
                       )
                     ],
                   ),
                 );
               }).toList(),
             );
          }
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showBottomSheet,
        child: Icon(Icons.add),
      ),
    );
  }
}
