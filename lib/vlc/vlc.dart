



import 'dart:async';
import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:http/http.dart' as http;



import 'package:flutter/services.dart';

import 'model.dart';






// vvv VAVlcHttpService.m
class VlcProxy {


  static final Logger log = new Logger('VlcProxy');

  var _httpClient = http.Client();
  var _baseStatusUrl;
  var _playlistUrl;

  var headers = {'Authorization': 'Basic OnZsY2NvbnRyb2w='};


  VlcProxy() {

    var baseUrl = 'http://127.0.0.1:8080';
    _baseStatusUrl = '$baseUrl/requests/status.json';
    _playlistUrl = '$baseUrl/requests/playlist.json';
  }


  Future<Status> playPause() async  {

    var url = "$_baseStatusUrl?command=pl_pause";
    return _dispatchStatusRequest( url );
  }

  Future<Status> pl_play( LeafNode leafNode ) async  {

    var url = "$_baseStatusUrl?command=pl_play&id=${leafNode.id}";
    return _dispatchStatusRequest( url );
  }


  Future<Status> playlistNext() async  {

    var url = "$_baseStatusUrl?command=pl_next";
    return _dispatchStatusRequest( url );
  }

  Future<Status> playlistPrevious() async  {

    var url = "$_baseStatusUrl?command=pl_previous";
    return _dispatchStatusRequest( url );
  }


  Future<Playlist> playlist() async  {

    var response = await _httpClient.get( _playlistUrl, headers: headers );
    print( response.body );
    Map value = json.decode(response.body);
    return new Playlist( value );
  }



  Future<Status> setVolume( int volume ) async {

    if( 0 > volume  ) {

      log.warning( '0 > volume; volume = $volume' );
      volume = 0;
    } else if ( 320 < volume ) {

      log.warning( '320 < volume; volume = $volume' );
      volume = 320;
    }

    var url = "$_baseStatusUrl?command=volume&val=$volume";


    return this._dispatchStatusRequest( url );
  }

  Future<Status> seek( int position ) async {

    if( 0 > position  ) {

      log.warning( '0 > position; position = $position' );
      position = 0;
    }

    var url = "$_baseStatusUrl?command=seek&val=$position";
    return _dispatchStatusRequest( url );

  }


  Future<Status> status() async {

    return this._dispatchStatusRequest( _baseStatusUrl );
  }


  Future<Status> toggleFullScreen() async  {

    var url = "$_baseStatusUrl?command=fullscreen";
    return _dispatchStatusRequest( url );
  }


  Future<Status> _dispatchStatusRequest( String url ) async {


    log.fine( "url: $url" );
    var response = await _httpClient.get( Uri.parse( url ), headers: headers );

    // log.fine( "response.body: " + response.body );
    // print( response.body );
    Map value = json.decode(response.body);
    var answer = new Status( value );
    log.fine( "answer.state: " + answer.state );

    return answer;
  }
}


class VlcService {

  static final Logger log = new Logger('VlcService');

  VlcProxy proxy;
  late Status lastStatus;
  late int unMutedVolume;
  late bool muted = false;

  VlcService( {required this.proxy} ) {}



  Future<Status> _handle( Future<Status> futureStatus ) async {

    lastStatus = await futureStatus;

    if( !muted ) {

      unMutedVolume = lastStatus.volume;
    }
    return futureStatus;

  }


  Future<Status> playPause() async {
    return this._handle( proxy.playPause() );
  }



  Future<Status> pl_play( LeafNode leafNode ) async  {

    return this._handle( proxy.pl_play( leafNode ) );
  }

  Future<Status> playlistNext() async {

    return this._handle( proxy.toggleFullScreen() );
  }


  Future<Status> playlistPrevious() async {

    return this._handle( proxy.toggleFullScreen() );
  }

  Future<Playlist> playlist() async {

    return proxy.playlist();
  }



  Future<Status> skipBackward( int delta ) async {



//    if( null == lastStatus ) {
//
//      log.warning( "null == lastStatus" );
//      await this.status();
//    }

    await this.status();
    var time = lastStatus.time - delta;
    if( 0 > time )  {
      time = 0;
    }

    return proxy.seek( time );
  }

  Future<Status> skipForward( int delta ) async {

//    if( null == lastStatus ) {
//
//      log.warning( "null == lastStatus" );
//      await this.status();
//    }

    await this.status();
    var time = lastStatus.time + delta;
    if( lastStatus.length <= time )  {
      time = lastStatus.length - 1;
    }

    return proxy.seek( time );
  }


  Future<Status> setVolume( int volume ) async {

    return this._handle( proxy.setVolume( volume ) );
  }

  Future<Status> status() async {

    return this._handle( proxy.status() );
  }

  Future<Status> toggleFullScreen() async {

    return this._handle( proxy.toggleFullScreen() );
  }

  Future<Status> toggleMute() async {

    if( muted ) {

      muted = false;
      return this.setVolume( unMutedVolume );
    } else {

      muted = true;
      return this.setVolume( 0 );
    }
  }


}

