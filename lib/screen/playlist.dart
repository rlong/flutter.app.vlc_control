

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:vlc_control/vlc/model.dart';



import '../vlc/vlc.dart';
import '../session.dart';
import '../screen.control/control.dart';

//Need to pass Node into PlaylistScreenState and then have PlaylistEntry be able to create a new PlaylistScreen with it's node
class PlaylistScreen extends StatefulWidget {

  Node? parent;

  PlaylistScreen( {this.parent} ) {}

  @override
  createState() => new PlaylistScreenState( parent: parent );
}


class PlaylistScreenState extends State<PlaylistScreen> with TickerProviderStateMixin {

  static final Logger log = new Logger('PlaylistScreenState');

  Node? parent;
  List<PlaylistEntry> _playlistEntries = <PlaylistEntry>[];
//  bool _retrievePlaylist = false;
  final TextEditingController _textController = new TextEditingController();
  VlcService _service =  SessionContext.instance.vlcService;

  PlaylistScreenState( {this.parent} ) {

    if( null == parent ) {

      log.fine( "null == parent" );
    } else {

      log.fine( parent!.name );

    }
  }

  @override
  initState() {

    super.initState();
    if( null == this.parent ) {

      initStateAsync();
    } else {
      _setupPlaylistEntries();
    }

  }

  initStateAsync() async {

    log.fine( "initStateAsync" );

    Playlist playlist = await _service.playlist();
    this.parent = playlist.root;
    _setupPlaylistEntries();
  }

  _setupPlaylistEntries() {

    List<PlaylistEntry> messages = <PlaylistEntry>[];
    {
      List<Node> children = parent!.children;
      for( Node child in children ) {

        PlaylistEntry playlistEntry = new PlaylistEntry(
          node: child,
          animationController: new AnimationController(
              duration: new Duration(microseconds: 700),
              vsync: this),
        );
        messages.add( playlistEntry );
      }
    }

    setState( () {

      _playlistEntries = messages;
    } );

  }

  @override
  Widget build( BuildContext context ) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text( "playlist" ),
        ),
        body: new Column(
          children: <Widget>[
            new Flexible(
                child: new ListView.builder(
                  padding: new EdgeInsets.all(8.0),
                  itemBuilder: (_, int index) => _playlistEntries[index],
                  itemCount: _playlistEntries.length,
                )
            ),
            new Divider( height: 1.0 ),
          ],
        )
    );
  }

  @override
  void dispose() {
    for( PlaylistEntry message in _playlistEntries ) {
      message.animationController.dispose();
    }
    super.dispose();
  }
}

const String _name = "Your Name";

class PlaylistEntry extends StatelessWidget {

  static final Logger log = new Logger('PlaylistEntry');

  final Node node;
  final AnimationController animationController;

  PlaylistEntry({ required this.node, required this.animationController});

  @override
  Widget build( BuildContext context ) {

    return new InkWell(

      child: new Container(
          margin: const EdgeInsets.symmetric(vertical: 10.0),
          child: new Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              new Container(
                  margin: const EdgeInsets.only( right: 16.0),
                  child: new CircleAvatar(
                      child: new Text(_name[0]))
              ),
              new Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  new Text( _name,
                    style: Theme.of(context).textTheme.subhead,
                  ),
                  new Container(
                    margin: const EdgeInsets.only(top:5.0),
                    child: new Text(node.name),
                  )
                ],
              )
            ],
          )
      ),
      onTap: () { this._onTap(context); } ,
    );

  }

  _onTap(BuildContext context) {
    log.fine( "onTap: ${node.name}" );
    if( node.type == NodeType.node ) {

      // vvv https://stackoverflow.com/questions/44729512/flutter-push-and-get-value-between-routes

      Navigator.push( context, new MaterialPageRoute(
        builder: (BuildContext context) => new PlaylistScreen( parent: this.node ),
      ));


      // ^^^ https://stackoverflow.com/questions/44729512/flutter-push-and-get-value-between-routes
    } else {

      SessionContext.instance.vlcService.pl_play( node as LeafNode );
      print( "Playback" );
      Navigator.pushNamed(context, ControlScreen.ROUTE );

    }
  }

}



