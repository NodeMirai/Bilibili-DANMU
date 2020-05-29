import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
        home: Scaffold(
            appBar: AppBar(title: const Text('Home')),
            body: new Wrap(children: [
              new Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                  child: new InputItem())
            ])));
  }
}

class InputItem extends StatefulWidget {

  @override
  InputItemState createState() {
    // TODO: implement createState
     return InputItemState();
  }
}

class InputItemState extends State<InputItem> {
  final TextEditingController _controller = new TextEditingController();

  @override
  Widget build(BuildContext context) {
    Widget InputItem = new Container(
        child: new Wrap(
      children: <Widget>[
        new Row(children: [
          new Container(
            margin: const EdgeInsets.only(right: 6),
            child: new Text(
              '房间id',
              style: new TextStyle(fontSize: 18),
            ),
          ),
          new Expanded(
              child: new TextField(
            controller: _controller,
          ))
        ]),
        new Container(
          margin: EdgeInsets.only(top: 6),
          child: new Row(children: [
            RaisedButton(
              onPressed: () {   // ????
                if (_controller.text == '1')
                  {
                    showMySimpleDialog(context);
                  }
              },
              child: new Text('连接'),
            ),
            RaisedButton(
              onPressed: () => {},
              child: new Text('断开'),
            ),
          ]),
        )
      ],
    ));
    return InputItem;
  }
}

void showMySimpleDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return new SimpleDialog(
            title: new Text("SimpleDialog"),
            children: <Widget>[
              new SimpleDialogOption(
                child: new Text("SimpleDialogOption One"),
                onPressed: () {
                  Navigator.of(context).pop("SimpleDialogOption One");
                },
              ),
              new SimpleDialogOption(
                child: new Text("SimpleDialogOption Two"),
                onPressed: () {
                  Navigator.of(context).pop("SimpleDialogOption Two");
                },
              ),
              new SimpleDialogOption(
                child: new Text("SimpleDialogOption Three"),
                onPressed: () {
                  Navigator.of(context).pop("SimpleDialogOption Three");
                },
              ),
            ],
          );
        });
  }
