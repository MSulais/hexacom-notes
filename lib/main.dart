import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  Brightness _brightness = Brightness.light;

  void _onChangedTheme(bool isDarkMode){
    setState((){
      _brightness = isDarkMode
        ? Brightness.dark 
        : Brightness.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notes',
      theme: ThemeData(
        useMaterial3: true,
        brightness: _brightness, // untuk darkmode/lightmode
        primarySwatch: Colors.blue,
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
        )
      ),
      debugShowCheckedModeBanner: false,
      home: HomePage(
        onChangedTheme: (value) => _onChangedTheme(value),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({
    Key? key, 
    required this.onChangedTheme
  }) : super(key: key);

  final void Function(bool) onChangedTheme;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  final List<Map<String, dynamic>> _notes = [];

  void _createNote() async {
    Map<String, dynamic> newNote = await Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => const NotePage()
      )
    );
    if (
        (newNote['title'] as String).trim().isEmpty 
        && (newNote['description'] as String).trim().isEmpty
      ) return;

    setState((){
      _notes.add(newNote);
    });
  }

  void _showAboutDialog(){
    Navigator.pop(context); // dismiss drawer
    showAboutDialog(
      context: context, 
      applicationIcon: Image.asset(
        'assets/image1.png', 
        width: 48, 
        height: 48, 
        filterQuality: FilterQuality.medium
      ),
      applicationName: 'Notes',
      applicationVersion: 'v1.0.0'
    );
  }

  void _onEditNote(int index) async {
    Map<String, dynamic> updateNote = await Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => NotePage(initData: _notes[index])
      )
    );
    if (
        (updateNote['title'] as String).trim().isEmpty 
        && (updateNote['description'] as String).trim().isEmpty
        && mounted
      ){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note is empty, removed'))
      );
      setState(() {
        _notes.removeAt(index);
      });
      return;
    }

    setState((){
      _notes[index] = updateNote;
    });
  }

  Future<bool?> _showAlertDialog() async {
    return await showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: const Text('Clear notes'),
        content: const Text('Are you sure want to clear all notes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('CANCEL')
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('CLEAR')
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {

    ThemeData theme = Theme.of(context);

    Widget drawerHeader = DrawerHeader(
      decoration: BoxDecoration(
        color: theme.primaryColor, 
        gradient: const LinearGradient(colors: [
          Colors.greenAccent,
          Colors.blue, 
        ]),
      ),
      child: Center(child: AnimatedTextKit(
        repeatForever: true,
        animatedTexts: [
          TypewriterAnimatedText(
            'Notes app', 
            textStyle: theme.textTheme.headline3, 
            speed: const Duration(milliseconds: 150)
          ),
        ],
      ))
    );

    Widget drawer = Drawer(
      child: ListView(children: [
        drawerHeader, 
        ListTile(
          leading: const Icon(Icons.dark_mode_outlined),
          title: const Text('Dark mode'),
          trailing: Switch(
            value: theme.brightness == Brightness.dark, 
            onChanged: (isDarkMode) => widget.onChangedTheme(isDarkMode)
          ),
        ),
        ListTile(
          leading: const Icon(Icons.info_outline_rounded),
          title: const Text('About app'),
          onTap: () => _showAboutDialog(),
        )
      ]),
    );

    Widget floatingActionButton = FloatingActionButton.extended(
      icon: const Icon(Icons.add),
      label: const Text('New note'),
      onPressed: () => _createNote()
    );

    Widget emptyWidget = SizedBox.expand(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.note_alt_outlined, size: 70), 
        const SizedBox(height: 8),
        Text('Empty', style: Theme.of(context).textTheme.headline5)
      ]
    ));

    Widget body = _notes.isEmpty? emptyWidget : Scrollbar(
      child: ListView.builder(
        itemCount: _notes.length,
        itemBuilder: (context, index){
    
          String title = _notes[index]['title'].trim();
          String description = _notes[index]['description'].trim();
          Color? color = _notes[index]['color'];
    
          return Dismissible(
            onDismissed: (DismissDirection direction) => _notes.removeAt(index),
            background: Row(children: const [
              SizedBox(width: 32),
              Icon(Icons.delete_outline),
              Spacer(),
            ]),
            secondaryBackground: Row(children: const [
              Spacer(),
              Icon(Icons.delete_outline),
              SizedBox(width: 32),
            ]),
            key: Key(index.toString()),
            child: Container(
              margin: EdgeInsets.fromLTRB(8, index == 0? 4 : 0, 8, 4),
              decoration: BoxDecoration(
                color: color?.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16)
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: title.isEmpty? null : Text(title),
                subtitle: description.isEmpty
                  ? null 
                  : Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
                onTap: () => _onEditNote(index)
              ),
            ),
          );
        }
      ),
    );

    PreferredSizeWidget appBar = AppBar(
      title: const Text('Notes'),
      actions: [
        if (_notes.isNotEmpty) PopupMenuButton(
          elevation: 4.0,
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'Clear all', child: Text('Clear all'))
          ], 
          onSelected: (value) async {
            switch (value){
              case 'Clear all': 
                bool isClear = await _showAlertDialog() ?? false;
                if (isClear != true) return;
                setState(() => _notes.clear());
            }
          },
        )
      ],
    );

    return Scaffold(
      floatingActionButton: floatingActionButton,
      appBar: appBar,
      body: body,
      drawer: drawer,
    );
  }
}

class NotePage extends StatefulWidget {
  const NotePage({
    Key? key, 
    this.initData
  }) : super(key: key);

  final Map<String, dynamic>? initData;

  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {

  final TextEditingController _title = TextEditingController();
  final TextEditingController _description = TextEditingController();
  Color? _noteColor;

  void _selectNoteColor() async {
    List<List> colors = [
      ['Red'   , Colors.red   ], 
      ['Orange', Colors.orange], 
      ['Yellow', Colors.yellow], 
      ['Green' , Colors.green ], 
      ['Cyan'  , Colors.cyan  ], 
      ['Blue'  , Colors.blue  ], 
      ['Purple', Colors.purple], 
      ['Pink'  , Colors.pink  ], 
      ['None'  , null]
    ];
    Widget colorWidget(int index) => Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors[index][1],
        border: Border.all(
          color: colors[index][1] ?? Theme.of(context).iconTheme.color!, 
          width: 2.5
        ),
      ),
    );
    showDialog(
      context: context, 
      builder: (context) => SimpleDialog(
        clipBehavior: Clip.hardEdge,
        title: const Text('Select note color'),
        children: List.generate(colors.length, (index) => ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24.0),
          leading: Stack(
            alignment: AlignmentDirectional.center,
            children: [
              colorWidget(index), 
              if (_noteColor == colors[index][1]) 
                  const Icon(Icons.check_circle_outline, color: Colors.white)
            ]
          ),
          title: Text(colors[index][0]),
          onTap: (){
            Navigator.pop(context); // dismiss dialog
            setState(() => _noteColor = colors[index][1]);
          }
        )),
      ) 
    );
  }

  @override
  void initState(){
    super.initState();
    if (widget.initData != null){
      _title.text = widget.initData!['title'];
      _description.text = widget.initData!['description'];
      _noteColor = widget.initData!['color'];
    }
  }

  @override
  void dispose(){
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    bool darkMode = Theme.of(context).brightness == Brightness.dark;

    PreferredSizeWidget appBar = AppBar(
      backgroundColor: _noteColor == null? null : (_noteColor! as MaterialColor)[darkMode? 800 : 200],
      leading: IconButton(
        icon: const Icon(Icons.arrow_back), 
        onPressed: () => Navigator.pop(
          context, {
            'title': _title.text, 
            'description': _description.text,
            'color': _noteColor
          }
        ),
      ),
      title: Text(widget.initData != null? 'Edit note' : 'New note'),
      actions: [
        GestureDetector(
          onTap: () => _selectNoteColor(),
          child: Container(
            margin: const EdgeInsets.only(right: 8.0),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(
                color: _noteColor ?? Theme.of(context).iconTheme.color!, 
                width: 2.5
              ),
              shape: BoxShape.circle,
              color: _noteColor ?? Theme.of(context).appBarTheme.backgroundColor,
            ),
          )
        ),
      ],
    );

    Widget body = ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      children: [
        TextField(
          controller: _title,
          textCapitalization: TextCapitalization.sentences,
          maxLines: null, // tidak terhingga
          style: const TextStyle(
            fontSize: 22, 
            fontWeight: FontWeight.normal, 
            height: 1
          ),
          decoration: const InputDecoration(
            border: InputBorder.none, 
            hintText: 'Title ...'
          ),
        ), 
        TextField(
          textCapitalization: TextCapitalization.sentences,
          controller: _description,
          style: const TextStyle(fontWeight: FontWeight.normal, height: 1),
          decoration: const InputDecoration(
            isDense: true,
            border: InputBorder.none, 
            hintText: 'Description ...'
          ),
          maxLines: null
        )
      ],
    );

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, {
          'title': _title.text, 
          'description': _description.text, 
          'color': _noteColor
        });
        return false;
      },
      child: Scaffold(
        backgroundColor: _noteColor == null
          ? null 
          : (_noteColor! as MaterialColor)[darkMode? 900 : 100],
        appBar: appBar,
        body: body,
      ),
    );
  }
}