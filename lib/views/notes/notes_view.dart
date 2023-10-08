import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes/services/auth/auth_service.dart';
import 'package:notes/services/crud/notes_service.dart';
import '../../constants/routes.dart';
import '../../enum/menu_action.dart';

class NotesView extends StatefulWidget {
  const NotesView({super.key});

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {

  late final NotesService _notesService;
  String get userEmail => AuthService.firebase().currentUser!.email!;

  @override
  void initState() {
    _notesService = NotesService();
    _notesService.open();
    super.initState();    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Notes'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, newNoteRoute),
            icon: const Icon(Icons.add)
            ),
          PopupMenuButton<MenuAction>(
            onSelected: (value) async {
              switch (value) {
                case MenuAction.logout:
                  final shouldLogout = await showLogOutDialog(context);
                  if (shouldLogout) {
                    await AuthService.firebase().logOut();
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      loginRoute,
                      (route) => false);
                  }
                  break;
                default:
              }
            },
            itemBuilder: (context) {
              return const [ 
                PopupMenuItem(
                  value: MenuAction.logout,
                  child: Text('Log out')
                ),

              ];
            },
          )
        ],
      ),
      body: FutureBuilder(
        future: _notesService.getOrCreateUser(email: userEmail), 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return StreamBuilder(
              stream: _notesService.allNotes, 
              builder: (context, snapshot) {
               switch (snapshot.connectionState) {
                 case ConnectionState.waiting:
                 case ConnectionState.active:
                  if (snapshot.hasData) {
                    final allNotes = snapshot.data as List<DatabaseNote>;
                    return ListView.builder(
                      itemCount: allNotes.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.all(7),
                          child: ListTile(
                              title: Text(
                                allNotes[index].text,
                                style: GoogleFonts.roboto(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                allNotes[index].text,
                                style: GoogleFonts.roboto(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 4,
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: IconButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                     builder: ((context) {
                                       return AlertDialog(
                                        title: const Text('Delete Note?'),
                                        content: const Text('Are you sure you want to delete this note?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text('No'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              _notesService.deleteNote(
                                                id: allNotes[index].id,
                                              );
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text('Yes'),
                                          ),
                                        ],
                                       );
                                     }
                                     )
                                    );
                                },
                                 icon: const Icon(Icons.delete)),
                            ),
                        );
                      },
                    );
                  } else {
                    return const Center(
                      child: Text('No notes yet'),
                    );
                  }
                 default:
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
               }
              });
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        }),
    );
  }
}

Future<bool> showLogOutDialog (BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title:  const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('Cancel'),
          ),
            TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Text('Log Out'),
          )
        ],
      );
    },
  ).then((value) => value ?? false);
}
