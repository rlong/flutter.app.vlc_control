




import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {

  @override
  createState() => new ChatScreenState();

}

class ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {

  final List<ChatMessage> _messages = <ChatMessage>[];
  final TextEditingController _textController = new TextEditingController();


  @override
  Widget build( BuildContext context ) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text( "ChatScreen" ),
        ),
        body: new Column(
          children: <Widget>[
            new Flexible(
                child: new ListView.builder(
                  padding: new EdgeInsets.all(8.0),
                  reverse: true,
                  itemBuilder: (_, int index) => _messages[index],
                  itemCount: _messages.length,
                )
            ),
            new Divider( height: 1.0 ),
            new Container(
                decoration: new BoxDecoration(
                  color: Theme.of( context ).cardColor,
                ),
                child: _buildTextComposer()
            )
          ],
        )

    );
  }

  Widget _buildTextComposer() {

    new Row(children: <Widget>[],);
    return new IconTheme(
        data: new IconThemeData( color: Theme.of(context).accentColor ),
        child: new Container(
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            child: new Row(
                children: <Widget>[
                  new Flexible(
                      child: new TextField(
                        controller: _textController,
                        onSubmitted: _handleSubmitted,
                        decoration: new InputDecoration.collapsed(
                            hintText: "Send a message"),
                      )
                  ),
                  new Container(
                      margin: const EdgeInsets.symmetric( horizontal: 4.0 ),
                      child: new IconButton(
                          icon: new Icon( Icons.send ),
                          onPressed: () => _handleSubmitted(_textController.text))
                  )
                ]
            )
        )
    );
  }

  void _handleSubmitted( String text ) {
    _textController.clear();
    ChatMessage message = new ChatMessage(
      text: text,
      animationController: new AnimationController(
          duration: new Duration(microseconds: 700),
          vsync: this),
    );
    setState( (){
      _messages.insert( 0, message);
    });
    message.animationController.forward();
  }
  @override
  void dispose() {
    for( ChatMessage message in _messages ) {
      message.animationController.dispose();
    }
    super.dispose();
  }
}

const String _name = "Your Name";

class ChatMessage extends StatelessWidget {

  ChatMessage({
    required this.text,
    required this.animationController
  });

  final String text;
  final AnimationController animationController;

  @override
  Widget build( BuildContext context ) {

//    return new FadeTransition(
//        opacity:  new CurvedAnimation(
//            parent: animationController,
//            curve: Curves.easeOut),
    return new SizeTransition(
      sizeFactor:  new CurvedAnimation(
          parent: animationController,
          curve: Curves.easeOut),
      axisAlignment: 0.0,
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
                    child: new Text(text),
                  )
                ],
              )
            ],
          )
      ),
    );
  }
}



