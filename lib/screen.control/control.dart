




import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:vlc_control/vlc/model.dart';

import '../vlc/vlc.dart';
import '../session.dart';

class ControlScreen extends StatefulWidget {

  static final ROUTE = '/control';

  @override
  createState() => new ControlScreenState();

}

class ControlScreenState extends State<ControlScreen> with TickerProviderStateMixin {

  static final Logger log = new Logger('ControlScreenState');

  VlcService _service =  SessionContext.instance.vlcService;





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
        title: new Text("Playback"),
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


            _buildSkip5m(),
            _buildSkip30s(),
            _buildSkip10s(),
            _buildVolumeRow(),
            _buildPlayPause(),

          ],
        ),
      ),
    );
  }

  _buildSkip5m() {

    return new Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Expanded(
              child:new RaisedButton(
                  onPressed: () => _skipBackward(300),
                  child: new Text('- 5:00')
              )
          ),
          new Expanded(
              child:new RaisedButton(
                  onPressed: () => _skipForward(300),
                  child: new Text('+ 5:00')
              )
          ),
        ]
    );
  }


  _buildSkip30s() {

    return new Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Expanded(
              child:new RaisedButton(
                  onPressed: () => _skipBackward(30),
                  child: new Text('- 0:30')
              )
          ),
          new Expanded(
              child:new RaisedButton(
                  onPressed: () => _skipForward(30),
                  child: new Text('+ 0:30')
              )
          ),
        ]
    );
  }


  _buildSkip10s() {

    return new Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Expanded(
              child:new RaisedButton(
                  onPressed: () => _skipBackward(10),
                  child: new Text('- 0:10')
              )
          ),
          new Expanded(
              child:new RaisedButton(
                  onPressed: () => _skipForward(10),
                  child: new Text('+ 0:10')
              )
          ),
        ]
    );
  }

  _buildPlayPause() {
    return new Row(
      children: <Widget>[
        new Expanded(
            child:new RaisedButton(
                onPressed: _playPauseOnPress,
                child: new Text('Play/Pause')
            )
        )
      ],
    );
//    return new RaisedButton( onPressed: _playPauseOnPress,
//        child: new Text('Play/Pause'));
  }

  Row _buildVolumeRow() {

    return new Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Expanded(
              child:new RaisedButton(
                  onPressed: _quieterOnPress,
                  child: new Text('Quieter')
              )
          ),
          new Expanded(
              child:new RaisedButton(
                  onPressed: _muteOnPress,
                  child: new Text('Mute')
              )
          ),
          new Expanded(
              child:new RaisedButton(
                  onPressed: _louderOnPress,
                  child: new Text('Louder')
              )
          ),
        ]
    );

  }



  _skipBackward( int seconds ) {

    _handleFutureStatus( _service.skipBackward( seconds ) );

  }

  _skipForward( int seconds ) {

    _handleFutureStatus( _service.skipForward( seconds ) );
  }

  _louderOnPress() {

    var currentVolume = _service.lastStatus.volume + 32;
    _handleFutureStatus( _service.setVolume( currentVolume ) );

  }

  _muteOnPress() {

    _handleFutureStatus( _service.toggleMute() );
  }

  _playPauseOnPress() {

    print( "Play/Pause" );
    _handleFutureStatus( _service.playPause() );

  }

  _quieterOnPress() {

    var currentVolume = _service.lastStatus.volume - 32;
    _handleFutureStatus( _service.setVolume( currentVolume ) );
  }


  _handleFutureStatus( Future<Status> futureStatus ) {

    futureStatus.then( (status) {

      log.fine( 'version: ${status.version}' );

    }).catchError( (reason)  {

      log.severe( reason );
    });

  }

}




