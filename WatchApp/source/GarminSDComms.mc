using Toybox.Communications as Comm;


class GarminSDComms {
  var listener;
  var mAccelHandler = null;

  function initialize(accelHandler) {
    listener = new CommListener();
    mAccelHandler = accelHandler;
  }

  function onStart() {
    Comm.registerForPhoneAppMessages(method(:onMessageReceived));
    Comm.transmit("Hello World.", null, listener);

  }

  function sendAccelData() {
    var dataObj = {
      "HR"=> mAccelHandler.mHR,
      "X" => mAccelHandler.mSamplesX,
      "Y" => mAccelHandler.mSamplesY,
      "Z" => mAccelHandler.mSamplesZ
    };
    // FIXME - THIS CRASHED WITH OUT OF MEMORY ERROR AFTER 5 or 10 minutes.
    //Comm.transmit(dataObj,null,listener);
  }

  function onMessageReceived(msg) {
    var i;
    System.print("GarminSdApp.onMessageReceived - ");
    System.println(msg.data.toString());
  }
  
  /////////////////////////////////////////////////////////////////////
  // Connection listener class that is used to log success and failure
  // of message transmissions.
  class CommListener extends Comm.ConnectionListener {
    function initialize() {
      Comm.ConnectionListener.initialize();
    }
    
    function onComplete() {
      System.println("Transmit Complete");
    }
    
    function onError() {
      System.println("Transmit Failed");
    }
  }

}
