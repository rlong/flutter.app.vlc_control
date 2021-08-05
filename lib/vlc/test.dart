


import 'package:logging/logging.dart';
import 'package:vlc_control/vlc/vlc.dart';

import '../session.dart';
import 'model.dart';

class TestVlc {

  static final Logger log = new Logger('TestVlc');


  VlcService _service =  SessionContext.instance.vlcService;


  test() {

    _handleFutureStatus( _service.playPause() );

  }


  _handleFutureStatus( Future<Status> futureStatus ) {

    futureStatus.then( (status) {

      log.fine( 'version: ${status.version}' );

    }).catchError( (reason)  {

      log.severe( reason );
    });

  }


}
