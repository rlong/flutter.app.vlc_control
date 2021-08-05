




import 'package:flutter/material.dart';
import '../screen.control/control.dart';

class HomePage extends StatefulWidget {
  HomePage({
    Key? key,
    required this.title
  }) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _HomePageState createState() => new _HomePageState();
}

class _HomePageState extends State<HomePage> {


  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return new Scaffold(
      appBar: new AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: new Text(widget.title),
      ),
      body: new Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: new Column(
          // Column is also layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug paint" (press "p" in the console where you ran
          // "flutter run", or select "Toggle Debug Paint" from the Flutter tool
          // window in IntelliJ) to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[

            _playlistBuild(),
            _playbackBuild(),

          ],
        ),
      ),
    );
  }

  _playlistBuild() {
    return new Row(
      children: <Widget>[
        new Expanded(
            child:new RaisedButton(
                onPressed: _playlistButtonOnPressed,
                child: new Text('Playlist')
            )
        )
      ],
    );
  }

  _playlistButtonOnPressed() {
    print( "Playlist" );

    Navigator.pushNamed(context, '/playlist');
  }

  _playbackBuild() {
    return new Row(
      children: <Widget>[
        new Expanded(
            child:new RaisedButton(
                onPressed: _playbackButtonOnPressed,
                child: new Text('Playback')
            )
        )
      ],
    );
  }

  _playbackButtonOnPressed() {
    print( "Playback" );
    Navigator.pushNamed(context, ControlScreen.ROUTE );
  }


}


