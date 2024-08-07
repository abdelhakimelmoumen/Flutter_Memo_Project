// ignore_for_file: prefer_const_constructors, unnecessary_string_interpolations, sort_child_properties_last, unnecessary_import, prefer_final_fields

import 'dart:convert'; // تأكد من استيراد مكتبة dart:convert
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_memo/models/note.dart';
import 'package:smart_memo/constants/colors.dart';
import 'package:smart_memo/screens/edit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Note> filtredNotes = [];
  bool sorted = false;
  FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesString = prefs.getString('notes') ?? '[]';
    final List<dynamic> notesJson = json.decode(notesString);
    setState(() {
      filtredNotes = notesJson.map((json) => Note.fromJson(json)).toList();
    });
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = filtredNotes.map((note) => note.toJson()).toList();
    await prefs.setString('notes', json.encode(notesJson));
  }

  List<Note> sortNotesByModifiedTime(List<Note> notes) {
    if (sorted) {
      notes.sort((a, b) => a.modifiedTime.compareTo(b.modifiedTime));
    } else {
      notes.sort((b, a) => a.modifiedTime.compareTo(b.modifiedTime));
    }
    sorted = !sorted;
    return notes;
  }

  Color getRandomColor() {
    Random random = Random();
    return backgroundColors[random.nextInt(backgroundColors.length)];
  }

  void onSearchTextChanged(String searchText) {
    setState(() {
      filtredNotes = filtredNotes
          .where((note) =>
              note.content.toLowerCase().contains(searchText.toLowerCase()) ||
              note.title.toLowerCase().contains(searchText.toLowerCase()))
          .toList();
    });
  }

  void deleteNoteAt(int index) {
    setState(() {
      filtredNotes.removeAt(index);
      _saveNotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Smart Memo',
                  style: TextStyle(
                      fontSize: 30,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      filtredNotes = sortNotesByModifiedTime(filtredNotes);
                    });
                  },
                  icon: Container(
                    padding: EdgeInsets.all(0),
                    child: Icon(Icons.sort),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800.withOpacity(.8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  color: Colors.white,
                )
              ],
            ),
            SizedBox(
              height: 20,
            ),
            TextField(
              focusNode: _searchFocusNode,
              onChanged: onSearchTextChanged,
              style: TextStyle(fontSize: 16, color: Colors.white),
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(vertical: 12),
                hintText: "Search notes ...",
                hintStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.white,
                ),
                fillColor: Colors.grey.shade800,
                filled: true,
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Colors.transparent)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Colors.transparent)),
              ),
            ),
            Expanded(
                child: ListView.builder(
              padding: EdgeInsets.only(top: 16),
              itemCount: filtredNotes.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(top: 25),
                  color: getRandomColor(),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: ListTile(
                      onTap: () async {
                        final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (BuildContext context) => EditScreen(
                                note: filtredNotes[index],
                              ),
                            ));
                        if (result != null) {
                          setState(() {
                            int noteId = filtredNotes[index].id;
                            Note updatedNote = Note(
                                id: noteId,
                                title: result[0],
                                content: result[1],
                                modifiedTime: DateTime.now());

                            int originalIndex = filtredNotes
                                .indexWhere((note) => note.id == noteId);
                            filtredNotes[originalIndex] = updatedNote;
                            _saveNotes();

                            _searchFocusNode.unfocus();
                          });
                        }
                      },
                      title: RichText(
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                            text: '${filtredNotes[index].title}\n',
                            style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                height: 1.5),
                            children: [
                              TextSpan(
                                text: '${filtredNotes[index].content}',
                                style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.normal,
                                    fontSize: 14,
                                    height: 1.5),
                              ),
                            ]),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Edited : ${DateFormat('EEE MMM d, yyyy h:mm a').format(filtredNotes[index].modifiedTime)}', // تم تصحيح تنسيق التاريخ
                          style: TextStyle(
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800),
                        ),
                      ),
                      trailing: IconButton(
                          onPressed: () async {
                            final result = await confirmDialog(context);
                            if (result == true) {
                              deleteNoteAt(index);
                            }
                          },
                          icon: Icon(Icons.delete)),
                    ),
                  ),
                );
              },
            )),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.grey.shade800,
        elevation: 10,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => const EditScreen(),
            ),
          );
          if (result != null) {
            setState(() {
              Note newNote = Note(
                  id: filtredNotes.length,
                  title: result[0],
                  content: result[1],
                  modifiedTime: DateTime.now());
              filtredNotes.add(newNote);
              _saveNotes();

              _searchFocusNode.unfocus();
            });
          }
        },
        child: Icon(
          Icons.add,
          size: 38,
          color: Colors.white,
        ),
      ),
    );
  }

  Future<bool?> confirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          icon: const Icon(
            Icons.info,
            color: Colors.grey,
          ),
          title: const Text(
            'Are you sure you want to delete?',
            style: TextStyle(color: Colors.white),
          ),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {
                  Navigator.pop(context, true); 
                },
                child: SizedBox(
                  width: 30,
                  child: const Text(
                    'Yes',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  Navigator.pop(context, false); 
                },
                child: SizedBox(
                  width: 30,
                  child: const Text(
                    'No',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
