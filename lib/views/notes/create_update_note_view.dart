import 'package:flutter/material.dart';
import 'package:notes/services/auth/auth_service.dart';
import 'package:notes/utilities/generics/get_arguments.dart';

import '../../services/crud/notes_service.dart';

class CreateUpdateNoteView extends StatefulWidget {
  const CreateUpdateNoteView({super.key});

  @override
  State<CreateUpdateNoteView> createState() => _CreateUpdateNoteViewState();
}

class _CreateUpdateNoteViewState extends State<CreateUpdateNoteView> {
  DatabaseNote? _note;
  late final NotesService _notesService;
  late final TextEditingController _textEditingController;

  @override
  void initState() {
    _notesService = NotesService();
    _textEditingController = TextEditingController();
    super.initState();
  }

  void _textControllerListener() async {
    final note = _note;
    if (note == null) {
      return;
    }
    final text = _textEditingController.text;
    await _notesService.updateNote(
      note: note,
      text: text,
    );
  }

  void _setupTextControllerListener() {
    _textEditingController.removeListener(_textControllerListener);
    _textEditingController.addListener(_textControllerListener);
  }

  Future<DatabaseNote> createOrGetExistingNote(BuildContext context) async {

    final widgetNote = context.getArgument<DatabaseNote>();

    if (widgetNote != null) {
      _note = widgetNote;
      _textEditingController.text = widgetNote.text;
      return widgetNote;      
    }

    final existingNote = _note;
    if (existingNote != null) {
      return existingNote;
    }
    final currentUser = AuthService.firebase().currentUser!;
    final email = currentUser.email;
    final owner = await _notesService.getUser(email: email);
    final newNote = await _notesService.createNote(owner: owner);
    _note = newNote;
    return newNote;
  }

  void _deleteNoteIfTextIsEmpty() {
    final note = _note;
    if (_textEditingController.text.isEmpty && note != null) {
      _notesService.deleteNote(
        id: note.id,
      );
    }
  }

  void _saveNoteIfTextNotEmpty() async {
    final note = _note;
    if (note != null && _textEditingController.text.isNotEmpty) {
      await _notesService.updateNote(
        note: note,
        text: _textEditingController.text,
      );
    }
  }

  @override
  void dispose() {
    _deleteNoteIfTextIsEmpty();
    _saveNoteIfTextNotEmpty();
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Note'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: FutureBuilder(
        future: createOrGetExistingNote(context),
        builder: (context, snapshot) {
          switch (snapshot.connectionState){
            case ConnectionState.done:
              _note = snapshot.data as DatabaseNote;
              _setupTextControllerListener();
              return Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  color: const Color.fromARGB(108, 0, 0, 0),
                  child: TextField(
                    controller: _textEditingController,
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    expands: true,
                    autofocus: true,
                    cursorColor: Colors.red,
                    cursorHeight: 25,
                    decoration: const InputDecoration(
                      hintText: 'Start typing your note...',
                    ),
                  ),
                ),
              );
            default:
              return const Center(
                child: CircularProgressIndicator(),
              );
          }
        },
      )
      );
  }
}