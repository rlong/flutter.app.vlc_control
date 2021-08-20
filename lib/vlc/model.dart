


class MapHelper {


  static T get<T>( Map map, String key ) {
    return map[key];
  }

}

class AudioFilters {


  Map value;

  AudioFilters( { required this.value} ) {}
}





class Category {

  Map value;

  late CategoryMeta _meta;


  Category( {required this.value} ) {}

  getMeta() {
    if( null != _meta ) {
      return _meta;
    }

    _meta = new CategoryMeta( value: this.value["meta"] );
    return _meta;
  }

}

class CategoryMeta {

  Map value;

  late String artist;
  late String filename;
  late String downloadURL;
  late String albumURL;
  late String title;
  late String url;
  late String artworkUrl;

  CategoryMeta( {required this.value} ) {

    artist = MapHelper.get<String>( value, "artist");
    filename = MapHelper.get<String>( value, "filename" );
    downloadURL  = MapHelper.get<String>( value, "Download URL" );
    albumURL = MapHelper.get<String>( value, "Album URL" );
    title = MapHelper.get<String>( value, "title" );
    url = MapHelper.get<String>( value, "url" );
    artworkUrl = MapHelper.get<String>( value, "artwork_url" );
  }
}

class Information {

  Map value;

  late Category _category;
  late int chapter;
  late List<int> chapters;
  late int title;
  late List titles;



  getCategory() {
    if( null != _category ) {
      return _category;
    }

    _category = new Category( value: this.value["category"] );
    return _category;
  }

  Information( {required this.value} ) {


    chapter = MapHelper.get<int>( value, "chapter");
    chapters = MapHelper.get<List<int>>( value, "chapters");
    title = MapHelper.get<int>( value, "title");
    titles = MapHelper.get<List>( value, "titles");

  }

}

class Status  {

  late Map _value;

  late int apiversion;
  late int audiodelay;
  late AudioFilters _audiofilters;
  late int currentplid;
  late List equalizer;
//  bool _fullscreen;
  late Information _information;
  late int length;
  late bool loop;
  late double position;
  late bool random;
  late int rate;
  late String state;
  late int time;
  late VideoEffects _videoeffects;
  late String version;
  late int volume;

  Status( Map value ) {

    _value = value;

    apiversion = MapHelper.get<int>( value, "apiversion" );
    audiodelay = MapHelper.get<int>( value, "audiodelay" );
    currentplid = MapHelper.get<int>( value, "currentplid" );
    equalizer = MapHelper.get<List>( value, "equalizer" );
//    _fullscreen = MapHelper.get<bool>( value, "fullscreen" );
    length = MapHelper.get<int>( value, "length" );
    loop = MapHelper.get<bool>( value, "loop" );
    position = MapHelper.get<double>( value, "position" );
    random = MapHelper.get<bool>( value, "random" );
    rate = MapHelper.get<int>( value, "rate" );
    state = MapHelper.get<String>( value, "state" );
    time = MapHelper.get<int>( value, "time" );
    version = MapHelper.get<String>( value, "version" );
    volume = MapHelper.get<int>( value, "volume" );
  }


}

class VideoEffects {

  Map value;

  late int gamma;
  late int contrast;
  late int saturation;
  late int brightness;
  late int hue;

  VideoEffects( {required this.value}) {

    gamma = MapHelper.get<int>( value, "gamma" );
    contrast = MapHelper.get<int>( value, "contrast" );
    saturation = MapHelper.get<int>( value, "saturation");
    brightness = MapHelper.get<int>( value, "brightness");
    hue = MapHelper.get<int>( value, "hue");
  }

}


enum NodeType {
  leaf,
  node
}

class Node {

  NodeType type = NodeType.node;
  late Map value;
  late String name;
  late String id;
  late List<Node> children;

  Node( {required this.value} ) {

    name = MapHelper.get<String>( value, "name" );
    id = MapHelper.get<String>( value, "id" );
    _initChildren();
  }

  _initChildren() {

    // if( this.type == NodeType.leaf ) {
    //
    //   children = [];
    //   return;
    // }

    print( "id:"+ id );
    List<dynamic> childNodes = MapHelper.get<List<dynamic>>( value , "children");
    print( "id:"+ id );

    children = childNodes.map( (e) {
      if( "node" == e["type"]) {

        return new Node( value: e );
      } else {

        return new LeafNode( e );
      }
    } ).toList(growable: false);


  }

  // List<Node> getChildren() {
  //
  //   if( this.type == NodeType.leaf ) {
  //
  //     return [];
  //   }
  //
  //   if( null == _children ) {
  //     List<Map> childNodes = MapHelper.get<List<Map>>( value , "children");
  //     _children = childNodes.map( (e) {
  //       if( "node" == e["type"]) {
  //
  //         return new Node( value: e );
  //       } else {
  //
  //         return new LeafNode( e );
  //       }
  //     } ).toList(growable: false);
  //   }
  //
  //   return _children;
  //
  // }

  getCurrent() {

    return this.children.firstWhere( (e) {
      if( NodeType.leaf == e.type ) {
        LeafNode leaf = e as LeafNode;
        return leaf.current;
      }

      return false;
    } );
  }
}


class LeafNode extends Node {

  late int duration;
  late String uri;
  late bool current;

  LeafNode( Map value ): super( value:value ) {

    type = NodeType.leaf;

    duration = MapHelper.get<int>( value, "duration" );
    uri = MapHelper.get<String>( value, "uri" );

    if( null == MapHelper.get<String>( value, "current") ) {

      current = true;
    } else {

      current = false;
    }
  }

  _initChildren() {
    children = [];
  }

  }

class Playlist {

  late LeafNode _current;
  late bool _curentResolved = false;
  late Node root;

  Playlist(Map value ) {

    root = new Node( value: value );
  }

  getCurrent() {

    if( !_curentResolved ) {

      _current = root.getCurrent();
      _curentResolved = true;
    }

    return _current;
  }
}

