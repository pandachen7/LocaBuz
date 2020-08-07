import 'package:flutter/material.dart';

///////////////////////////////////paint
class Paint {
  final int id;
  final String title;
  final Color colorpicture;
  bool selected = false;

  Paint(this.id, this.title, this.colorpicture);
}

void test(){
  // ListView
  // Colorful :)
  List<Paint> paints = <Paint>[
    Paint(1, 'Red', Colors.red),
    Paint(2, 'Blue', Colors.blue),
    Paint(3, 'Green', Colors.green),
    Paint(4, 'Lime', Colors.lime),
    Paint(5, 'Indigo', Colors.indigo),
    Paint(6, 'Yellow', Colors.yellow)
  ];
}

/////////////////////////////////////dialog
class DialogList extends StatefulWidget {
  final String name;
  DialogList({this.name});

  @override
  _DialogListState createState() => new _DialogListState();
}
class _DialogListState extends State<DialogList> {

  Color _c = Colors.redAccent;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('BLE Device List'),
      content: Container(
        color: _c,
        height: 20.0,
        width: 20.0,
      ),
      actions: <Widget>[
        FlatButton(
            child: Text('Switch'),
            onPressed: () => setState(() {
              _c == Colors.redAccent
                  ? _c = Colors.blueAccent
                  : _c = Colors.redAccent;
            }))
      ],
    );
  }
}