



import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:ez_bot_guid/custom_widgets/custom_texfield.dart';
import 'package:ez_bot_guid/custom_widgets/custom_textbutton.dart';
import 'package:ez_bot_guid/model/record_path.dart';
import 'package:ez_bot_guid/model/transactions.dart';
import 'package:ez_bot_guid/model/user.dart';
import 'package:ez_bot_guid/tools/my_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ez_bot_guid/util/tts.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart' as locationm;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:ntp/ntp.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:uuid/uuid.dart';
import 'package:telephony/telephony.dart';
import '../controller/controller.dart';
import 'login.dart';
import 'package:perfect_volume_control/perfect_volume_control.dart';

// import 'package:flutter_mapbox_navigation/library.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
// import 'package:flutter_mapbox_navigation/library.dart';



class Home extends StatefulWidget{
  Home({Key? key,required this.userModel}) : super(key: key);
  UserModel userModel;


  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home>{


  final Telephony telephony = Telephony.instance;
  late FlutterTts flutterTts;
  late DateTime _ntpTime;
  String mode = "",currentMode = "";
  TextEditingController currentLocation = TextEditingController();
  TextEditingController destination = TextEditingController();
  bool dragup = false;
  bool dragdown = false;
  bool isManualSetLocation = false;
  bool send = false;

  SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  bool onlyOnce = false;
  List<LatLng> steps =[];





  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }
  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
  }
  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
    });
  }
  int count = 0;
  int updateLocationCount = 0;
  int passLocationBT = 0;
  bool connected = false;
  int findDeviceCount = 0;
  BluetoothConnection? connection;
  locationm.LocationData? currentPos;
  locationm.LocationData? destinationPos;
  late Timer _timer;
  late Timer _timer2;
  int timeOut = 5;
  int timeOutCounter = 0;
  int timOutCount = 0;
  int pathSize = 0;
  int pathIndex = 0;
  LatLng near = LatLng(0, 0);
  LatLng prevNear = LatLng(0, 0);
  LatLng nextStep = LatLng(0, 0);
  bool reached = false;
  String directionS = "";
  void startTimer() {
    const oneSec = const Duration(seconds: 1);
    _timer =  Timer.periodic(
        oneSec,
            (Timer timer) {
          _timer = timer;
          if(count==1){
            flutterTts.speak("Welcome to  LAYA BOT! Double tap at the bottom of the device to manually use the device. single tap to automatic. swipe up to know your current location. Swipe down to repeat the message.Swipe left to repeat last family message.Hold bottom right corner of your phone and speak to reply to your family");
            // _timer.cancel();
          }
          if(updateLocationCount==60){
            updateLocationCount = 0;
            currentStepSteped = false;
          }


          if (!connected){

            FlutterBluetoothSerial.instance.getBondedDevices().then((value) {
              setState(() {
                value.forEach((dev) {
                  if(dev.name!.contains("LIEAHBOT")){
                    device = dev;
                    if(dev.isConnected){
                      setState(() {
                        BluetoothConnection.toAddress(dev.address).then((value) {
                          if(value.input!=null){
                            connection = value;
                            connected = true;
                          }
                        });
                      });
                      return;
                    }
                    else{
                      try {
                        BluetoothConnection.toAddress(device!.address).then((value) {
                          setState(() {
                            if(value.input!=null){
                              connection = value;
                              connected = true;
                            }
                          });
                        });
                      }
                      catch (exception) {
                        print('Cannot connect, exception occured');
                      }
                      return;
                    }
                  }
                });
              });
            });
          }
          if(findDeviceCount==10&&!connected&&device==null){
            FlutterBluetoothSerial.instance.startDiscovery().forEach((element) {
              if(element.device.name!.contains("LIEAHBOT")){
                setState(() {
                  device = element.device;
                  connected = true;
                });

              }
            });
            findDeviceCount = 0;
          }
          if(device!=null&&connection==null){

          }

          count++;
          updateLocationCount++;
          passLocationBT++;
          findDeviceCount++;
        });
    _timer2 =  Timer.periodic(
        Duration(milliseconds: 500),
            (Timer timer) {
          _timer2 = timer;
          int modeL = 0;
          if(mode=="Manual"){
            modeL = 2;
          }
          if(mode=="Automatic"){
            modeL = 4;
          }
          if(mode=="LineTracking"){
            modeL = 3;
          }
          if(connection!=null&&currentPos!=null&&mapController!=null){
            LatLng nearMe = LatLng(0,0);
            bool tooFar = true;
            steps.forEach((element) {
              double nearDistance = Geolocator.distanceBetween(currentPos!.latitude!, currentPos!.longitude!, element.latitude, element.longitude);
              if(nearDistance<(isCustom?5:10)){
                nearMe = element;
                tooFar = false;
              }
            });
            if(tooFar&&steps.isNotEmpty){
              nearMe = LatLng(steps.first.latitude,steps.first.longitude);
            }
            if(steps.indexOf(nearMe)!=steps.length-1){
              nextStep = steps[steps.indexOf(nearMe)+1];
            }

            double x,y,deltalog,deltalat,bearing;
            deltalog= nextStep.longitude-currentPos!.longitude!;
            deltalat=nextStep.latitude-currentPos!.latitude!;
            bearing = Geolocator.bearingBetween(currentPos!.latitude!, currentPos!.longitude!, nextStep.latitude, nextStep.longitude);
            double finalv,heading;
            heading =mapController!.cameraPosition!.bearing;
            // if(heading < 0) {
            //   heading+=360;
            //   if(heading>360) heading=360-heading;
            // }
            if(bearing < 0) {
              bearing+=360;
              if(bearing>360) bearing=360-bearing;
            }


            finalv=heading/bearing;
            print(bearing.toString()+" - "+heading.toString()+" - "+finalv.toString());
            int diInt = 0;
            if(finalv>=0&&finalv<=1.2)
            {
              directionS = "FORWARD";
              diInt = 1;
            }

            else if(finalv >1.2 && finalv <=8)
            {
              directionS = "RIGHT";
              diInt = 2;
            }

            else if(finalv <=13 && finalv >=8)
            {
              directionS = "LEFT";
              diInt = 3;
            }
            else{
              print("NO!");
            }

            int isReachInt = 0;
            if(reached)isReachInt = 1;
            connection!.output.add(ascii.encode(isReachInt.toString()+","+diInt.toString()+","+modeL.toString()+";")); // Sendi
          }



        });
  }

  BluetoothDevice? device;
  RecordPath? recordPath;
  double? direction;

  locationm.LocationData? locationData;
  Future<void> initializeNavi() async {
    if (!mounted) return;
  }
  LatLng lastLatLong = LatLng(0, 0);
  bool isCustom = false;
  bool currentStepSteped = false;
  String ordinal(int number) {
    if(!(number >= 1 && number <= 100)) {//here you change the range
      throw Exception('Invalid number');
    }

    if(number >= 11 && number <= 13) {
      return 'th';
    }

    switch(number % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }
  @override
  void initState() {
    initializeNavi();
    locationm.Location.instance.getLocation().then((value) {
      setState(() {
        locationData = value;
      });
    });

    locationm.Location.instance.onLocationChanged.listen((event) {
      currentPos = event;
      var uuid = Uuid();
      MyLocation myLocation = MyLocation(id: uuid.v1(), userID: widget.userModel.id, long: event.longitude!, lat: event.latitude!, time: DateTime.now().millisecondsSinceEpoch);
      LiveLocation liveLocation = LiveLocation(id: widget.userModel.id, long: event.longitude!, lat: event.latitude!);
      LiveLocationController.upSert(liveLocationm: liveLocation);
      MyLocationController.upSert(myLocationm: myLocation);
      if(lastLatLong.latitude==0){
        lastLatLong = LatLng(event.latitude!, event.longitude!);
      }
      else if(mapController!=null){
        // print(Geolocator.distanceBetween(lastLatLong.latitude, lastLatLong.longitude, event.latitude!, event.longitude!));
        if(Geolocator.distanceBetween(lastLatLong.latitude, lastLatLong.longitude, event.latitude!, event.longitude!)>=0.8){
          mapController!.animateCamera(CameraUpdate.tiltTo(90)).whenComplete(() {
            mapController!.updateMyLocationTrackingMode(MyLocationTrackingMode.TrackingCompass);
          });
        }
        else{
          mapController!.animateCamera(CameraUpdate.tiltTo(0)).whenComplete(() {
            mapController!.updateMyLocationTrackingMode(MyLocationTrackingMode.TrackingCompass);
          });
        }
        lastLatLong = LatLng(event.latitude!, event.longitude!);
      }
      if(steps.isNotEmpty){
        mapController!.clearCircles();

        if(near!=prevNear){
          currentStepSteped = false;
          prevNear = near;
        }
        else{
          double nearDistance = Geolocator.distanceBetween(currentPos!.latitude!, currentPos!.longitude!, near.latitude, near.longitude);

          if(nearDistance<(isCustom?5:10)&&!currentStepSteped&&mode!="Speak"){
            print(ordinal(steps.indexOf(near)+1));
            flutterTts.speak("You have reach your "+(steps.indexOf(near)+1).toString()+ordinal(steps.indexOf(near)+1)+" step. Please be careful").then((value) {
              currentStepSteped = true;
            });
          }

        }
        if(Geolocator.distanceBetween(currentPos!.latitude!, currentPos!.longitude!, steps.last.latitude, steps.last.longitude)<(isCustom?5:10)){
          flutterTts.speak("You have reach your final destination. Congrats!").then((value) {
            telephony.sendSms(to: widget.userModel.familyNumber, message: "Destination reached!\nTime:"+DateFormat.yMMMEd().add_jms().format(value)).whenComplete(() {
              NTP.now().then((value) {
                var uuid = Uuid();
                MyDestination myDestination = MyDestination(userID: widget.userModel.id, path: this.steps, time:value.millisecondsSinceEpoch,id: uuid.v1(),name: destination.text);
                MyDestinationController.upSert(destinationm: myDestination);
              });
            });
            setState(() {
              reached = true;
            });

          });
        }
        mapController!.clearCircles();
        steps.forEach((element) {
          double nearDistance = Geolocator.distanceBetween(currentPos!.latitude!, currentPos!.longitude!, element.latitude, element.longitude);
          if(nearDistance<(isCustom?5:10)){
            setState(() {
              near = element;
            });

            if(steps.indexOf(element)!=steps.length-1){
              nextStep = steps[steps.indexOf(element)+1];
            }
          }
          mapController!.addCircle(CircleOptions(
              geometry: element,
              circleColor: "#FF006C",
              circleStrokeColor: (element==steps.last)?"#61FF00":nextStep==element?"#FFFF00":nearDistance<10?"#FFFFFF":"#00B2FF",
              circleStrokeWidth: 5,
              circleOpacity: 0.7,
              circleStrokeOpacity:(element==steps.last&&nearDistance<(isCustom?5:10))? 1:0.7,
              circleRadius: 10
          ));
        });

      }

    });
    PerfectVolumeControl.hideUI = false;
    // if(FlutterCompass.events!=null){
    //   FlutterCompass.events!.listen((event) {
    //     direction = event.heading;
    //   });
    // }
    PerfectVolumeControl.stream.listen((volume) {
      flutterTts.speak("LineTracking mode");
      setState(() {
        mode = "LineTracking";
        currentMode = "";
        // flutterTts.stop();
      });
    });


    _initSpeech();


    flutterTts = FlutterTts();

    startTimer();
    flutterTts.setCompletionHandler(() {
      setState(() {
        onlyOnce = false;
      });
      print("Complete!");

      if(mode == "Automatic" &&currentMode!="Automatic"){
        flutterTts.speak("This is Automatic mode, please speak to where you wanted to go. Or you can let your family member to select it for you.Please find assistance to enable GPS. Swipe up to get current location address. Single tap to repeat this message.Hold down and speak to set your destination.");
        setState(() {
          currentMode = "Automatic";
        });
      }
      else if(mode == "Manual" &&currentMode!="Manual"){
        flutterTts.speak("This is Manual mode, please be careful,double tap to repeat this message");
        setState(() {
          currentMode = "Manual";
          mapController!.clearCircles();
          mapController!.clearLines();
          steps.clear();
          destination.text = "";
          MyDestinationController.delete(id: widget.userModel.id);
        });
      }
      else if(mode == "LineTracking" &&currentMode!="LineTracking"){
        flutterTts.speak("This is Line Tracking mode, please be careful,press volume up to repeat this message");
        setState(() {
          currentMode = "LineTracking";
        });
      }
      else if(mode == "Speak" &&currentMode!="Speak"){
        _speechToText.initialize().then((value) {
          if ( value ) {
            _speechToText.listen(
                onResult: (result){
                  _lastWords = (result.recognizedWords);
                  print(_lastWords);
                }
            );
          }
          else {
            print("The user has denied the use of speech recognition.");
          }
        });
        setState(() {
          currentMode = "Speak";
        });
      }
      if(dragup){
        setState(() {
          dragup = false;
        });

      }
    });
    flutterTts.setStartHandler(() {
      print("START");
    });

    // TODO: implement initState
    super.initState();
  }
  @override
  void dispose() {
    _timer2.cancel();
    _timer.cancel();
    flutterTts.stop();
    super.dispose();
  }
  var isLight = true;
  MapboxMapController? mapController;
  _onMapCreated(MapboxMapController controller) {
    mapController = controller;
  }
  _onStyleLoadedCallback() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Style loaded :)"),
      backgroundColor: Theme.of(context).primaryColor,
      duration: Duration(seconds: 1),
    ));
  }
  Future<String> GetAddressFromLatLong(LatLng position)async {
    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

    Placemark place = placemarks[0];
    return '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}';

  }
  void drawRoad({required LatLng start, required LatLng end}){
    reached = false;
    if(mapController==null)return;
    mapController!.clearLines();
    mapController!.clearCircles();
    String url = "https://api.mapbox.com/directions/v5/mapbox/walking/"+start.longitude.toString()+"%2C"+start.latitude.toString()+"%3B"+end.longitude.toString()+"%2C"+end.latitude.toString()+"?alternatives=true&continue_straight=true&geometries=geojson&language=en&overview=simplified&steps=true&access_token=pk.eyJ1IjoibGlub3F1aTE0IiwiYSI6ImNsMnRsaG1ndTA1aGsza25vMDRocjE5YXoifQ.RyE1w-7zHamlAuYrOSwO0Q";
    http.get(Uri.parse(url)).then((value) {
      Map<String,dynamic> data = jsonDecode(value.body)['routes'][0];
      List<LatLng> geometry = [];
      List<dynamic> route = data['geometry']['coordinates'];
      route.forEach((element) {
        double lat = element[1] as double;
        double long = element[0] as double;
        geometry.add(LatLng(lat, long));
        mapController!.addCircle(CircleOptions(
            geometry: LatLng(lat, long),
            circleColor: "#FF006C",
            circleStrokeColor: "#00B2FF",
            circleStrokeWidth: 5,
            circleOpacity: 0.7,
            circleStrokeOpacity: 0.7,
            circleRadius: 10
        ));
      });

      // });
      // mapController!.setGeoJsonSource('rout', geojson);
      mapController!.addLine(LineOptions(
        geometry: isCustom?steps:geometry,
        lineColor: "#FF006C",
        lineWidth:10,
        lineOpacity: 0.7,
      ));
      setState(() {
        if(!isCustom){
          steps = geometry;
        }
        List<String> paths = [];
        steps.forEach((element) {
          paths.add(element.latitude.toString()+"-"+element.longitude.toString());
        });
        NTP.now().then((value) {
          MyDestination myDestination = MyDestination(userID: widget.userModel.id, path: paths, time:value.millisecondsSinceEpoch);
          MyDestinationController.upSert(destinationm: myDestination);
        });

      });
    });

  }
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height ,
          child: Column(
            children: [
              Stack(
                children: [

                  // StreamBuilder<locationm.LocationData>(
                  //     stream: locationm.Location.instance.onLocationChanged,
                  //     builder: (context,snapShot) {
                  //       if(!snapShot.hasData)return Center(child: CircularProgressIndicator(),);
                  //       // controller.setZoom(stepZoom: 5);
                  //       currentPos = snapShot.data;
                  //       return SizedBox(
                  //           height:  MediaQuery.of(context).size.height*0.3,
                  //           child: OSM.OSMFlutter(
                  //             onMapIsReady: (isReady){
                  //
                  //             },
                  //             onLocationChanged: (point){
                  //               controller.setZoom(stepZoom: 18);
                  //             },
                  //             controller:controller,
                  //             trackMyPosition: true,
                  //             initZoom: 19,
                  //             minZoomLevel: 10,
                  //             maxZoomLevel:19,
                  //             stepZoom: 1.0,
                  //             userLocationMarker: OSM.UserLocationMaker(
                  //               personMarker: OSM.MarkerIcon(
                  //                 icon: Icon(
                  //                   Icons.location_history_rounded,
                  //                   color: Colors.red,
                  //                   size: 48,
                  //                 ),
                  //               ),
                  //               directionArrowMarker: OSM.MarkerIcon(
                  //                 icon: Icon(
                  //                   Icons.double_arrow,
                  //                   size: 48,
                  //                 ),
                  //               ),
                  //             ),
                  //             roadConfiguration: OSM.RoadConfiguration(
                  //               startIcon: OSM.MarkerIcon(
                  //                 icon: Icon(
                  //                   Icons.person,
                  //                   size: 64,
                  //                   color: Colors.brown,
                  //                 ),
                  //               ),
                  //               roadColor: Colors.yellowAccent,
                  //             ),
                  //             markerOption: OSM.MarkerOption(
                  //                 defaultMarker: OSM.MarkerIcon(
                  //                   icon: Icon(
                  //                     Icons.person_pin_circle,
                  //                     color: Colors.blue,
                  //                     size: 56,
                  //                   ),
                  //                 )
                  //             ),
                  //           )
                  //
                  //       );
                  //     }
                  // ),


                  if(locationData!=null)
                    StatefulBuilder(
                        builder: (context,setState) {
                          return Container(
                            height: 300,
                            child: MapboxMap(
                              compassEnabled: true,
                              rotateGesturesEnabled: false,
                              doubleClickZoomEnabled: false,
                              zoomGesturesEnabled: true,
                              tiltGesturesEnabled: true,
                              scrollGesturesEnabled: false,
                              myLocationTrackingMode: MyLocationTrackingMode.TrackingCompass,
                              compassViewPosition: CompassViewPosition.BottomRight,
                              myLocationEnabled: true,
                              myLocationRenderMode: MyLocationRenderMode.COMPASS,
                              trackCameraPosition: true,
                              styleString:"mapbox://styles/linoqui14/cl2tlttkv006814pchtcxxjkg",
                              accessToken: "sk.eyJ1IjoibGlub3F1aTE0IiwiYSI6ImNsMnUyNGpqNzAzbHMza3BobjVxZGt0MXEifQ.Oj_-khaiKFsMrTb96CFM7A",
                              onMapCreated: _onMapCreated,
                              initialCameraPosition: CameraPosition(target: LatLng(locationData!.latitude!,locationData!.longitude!),zoom: 18),
                              onStyleLoadedCallback: _onStyleLoadedCallback,
                              onUserLocationUpdated: (location){

                              },
                              // onCameraIdle: (){
                              //
                              // },
                            ),
                          );
                        }
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomTextButton(
                        rTl: 0,
                        rBL: 0,
                        color: MyColors.deadBlue,
                        onHold: (){
                          widget.userModel.status = "logout";
                          UserController.upSert(user: widget.userModel);
                          flutterTts.speak("The user is logging out.").whenComplete(() {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => Login()),
                                  (Route<dynamic> route) => false,
                            );

                            flutterTts.stop();
                          });

                        },
                        text: "Hold to logout",

                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 5),
                          child: CustomTextButton(
                            width: 140,
                            padding: EdgeInsets.zero,
                            rBR: 0,
                            rTR: 0,
                            color: MyColors.deadBlue,
                            onHold: (){
                              setState(() {
                                isManualSetLocation?isManualSetLocation=false:isManualSetLocation=true;
                                flutterTts.speak(isManualSetLocation?"Gesture disabled on manual destination set":"Gesture enabled");
                              });

                            },
                            text: "Manual set location",
                          ),
                        ),
                      ),

                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.all(50),
                    child: Text(locationData!.latitude.toString()+" - "+locationData!.longitude.toString()+" : "+(steps.isNotEmpty?steps.last.latitude.toString()+" - "+steps.last.longitude.toString():""),style: TextStyle(color: Colors.red),),
                  ),
                ],
              ),

              Expanded(
                child: Stack(
                  children: [
                    StreamBuilder<QuerySnapshot>(
                      stream: MessageController.getMessages(id: widget.userModel.id),
                      builder: (context,snapshot){
                        if(!snapshot.hasData)return Center();
                        if(snapshot.data!.docs.isEmpty)return Center();
                        snapshot.data!.docs.forEach((message) {
                          Message messagem = Message.toObject(message.data());
                          if(!messagem.read&&messagem.isFamily) {
                            List<String> location = messagem.message.split(":");
                            // print(location);
                            if(location.length>1){
                              RecordController.getRecordWhereUserIDDoc(id: widget.userModel.id ).then((value) {
                                bool found = false;
                                value.docs.forEach((records){
                                  RecordPath recordPath = RecordPath.toObject(records.data());
                                  if(recordPath.name.toLowerCase().contains(location.last)&&location.last.isNotEmpty){
                                    found = true;
                                    double desStartLat,desStartLong,desEndLat,desEndLong;
                                    // http.get(Uri.parse("));

                                    desStartLat = double.parse((recordPath.path.first as String).split("-")[0]);
                                    desStartLong = double.parse((recordPath.path.first as String).split("-")[1]);
                                    desEndLat = double.parse((recordPath.path.last as String).split("-")[0]);
                                    desEndLong = double.parse((recordPath.path.last as String).split("-")[1]);
                                    flutterTts.speak("Your Destination. "+recordPath.name);
                                    destination.text = recordPath.name;
                                    _speechToText.stop();
                                    drawRoad(start: LatLng(currentPos!.latitude!, currentPos!.longitude!), end: LatLng(desStartLat, desStartLong));
                                    setState(() {
                                      isCustom = true;
                                      steps.clear();
                                      recordPath.path.forEach((element) {
                                        double lat = double.parse((element as String).split("-")[0]);
                                        double long = double.parse((element as String).split("-")[1]);
                                        steps.add(LatLng(lat, long));
                                      });
                                    });

                                    return;
                                  }
                                });
                                if(!found){
                                  var addresses = GeocodingPlatform.instance.locationFromAddress(location.last);
                                  addresses.then((add){

                                    var loc = add.first;
                                    drawRoad(start: LatLng(currentPos!.latitude!, currentPos!.longitude!),end: LatLng(loc.latitude, loc.longitude));

                                    GetAddressFromLatLong(LatLng(add.first.latitude,add.first.longitude)).then((value) {
                                      setState(() {
                                        flutterTts.speak("Your destination: "+value);
                                        _speechToText.stop();
                                        destination.text = value;
                                        isCustom = false;
                                      });
                                    });

                                  });



                                }
                              });
                            }
                            else{
                              flutterTts.speak("Message from family: "+messagem.message);
                            }

                          }
                          messagem.read = true;
                          MessageController.upSert(messagem: messagem);
                        });
                        return Center();
                      },
                    ),
                    if(mode=="Automatic"||isManualSetLocation||mode=="Speak")

                      Container(
                        color: Colors.black87,
                        // padding: EdgeInsets.only(top: 300),
                        child: Column(
                          children: [

                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text("Double tap at the bottom of the device to manually use the device, single tap to automatic. Swipe down to repeat the message.Swipe left to repeat last family message.Hold bottom right corner of your phone and speak to reply to your family",textAlign: TextAlign.center,style: TextStyle(color: Colors.white),),
                            ),

                            Padding(
                              padding: const EdgeInsets.only(top: 60),
                              child: Column(
                                children: [
                                  Text(mode,textAlign: TextAlign.center,style: TextStyle(color: Colors.white,fontSize: 30,fontWeight: FontWeight.bold),),
                                  Text("Mode",textAlign: TextAlign.center,style: TextStyle(color: Colors.white,fontSize: 13,fontWeight: FontWeight.bold),),
                                ],
                              ),
                            ),
                            if(mode=="Automatic")
                              CustomTextField(
                                  readonly: true,
                                  icon: Icons.my_location,
                                  color: MyColors.skyBlueDead,
                                  hint: "Current Location",
                                  padding: EdgeInsets.symmetric(horizontal: 20,vertical: 10),
                                  controller: currentLocation),
                            CustomTextField(
                                suffix: CustomTextButton(
                                  rBL: 0,
                                  rTl: 0,
                                  text: "Go",
                                  width: 50,
                                  color: MyColors.deadBlue,
                                  onHold: (){
                                    RecordController.getRecordWhereUserIDDoc(id: widget.userModel.id ).then((value) {
                                      bool found = false;
                                      value.docs.forEach((records){
                                        RecordPath recordPath = RecordPath.toObject(records.data());
                                        if(recordPath.name.toLowerCase().contains(destination.text.toLowerCase())&&destination.text.isNotEmpty){
                                          found = true;
                                          double desStartLat,desStartLong,desEndLat,desEndLong;
                                          // http.get(Uri.parse("));

                                          desStartLat = double.parse((recordPath.path.first as String).split("-")[0]);
                                          desStartLong = double.parse((recordPath.path.first as String).split("-")[1]);
                                          desEndLat = double.parse((recordPath.path.last as String).split("-")[0]);
                                          desEndLong = double.parse((recordPath.path.last as String).split("-")[1]);
                                          flutterTts.speak("Your Destination. "+recordPath.name);
                                          destination.text = recordPath.name;
                                          _speechToText.stop();
                                          drawRoad(start: LatLng(currentPos!.latitude!, currentPos!.longitude!), end: LatLng(desStartLat, desStartLong));
                                          setState(() {
                                            isCustom = true;
                                            steps.clear();
                                            recordPath.path.forEach((element) {
                                              double lat = double.parse((element as String).split("-")[0]);
                                              double long = double.parse((element as String).split("-")[1]);
                                              steps.add(LatLng(lat, long));
                                            });
                                          });

                                          return;
                                        }
                                      });
                                      if(!found){
                                        print(destination.text.toLowerCase());
                                        var addresses = GeocodingPlatform.instance.locationFromAddress(destination.text.toLowerCase());
                                        addresses.then((add){

                                          var loc = add.first;
                                          drawRoad(start: LatLng(currentPos!.latitude!, currentPos!.longitude!),end: LatLng(loc.latitude, loc.longitude));

                                          GetAddressFromLatLong(LatLng(add.first.latitude,add.first.longitude)).then((value) {
                                            setState(() {
                                              flutterTts.speak("Your destination: "+value);
                                              _speechToText.stop();
                                              destination.text = value;
                                              isCustom = false;
                                            });
                                          });
                                        });



                                      }
                                    });
                                    _speechToText.stop();


                                  },
                                ),
                                icon: Icons.location_on,
                                color: MyColors.skyBlueDead,
                                hint: "Destination",
                                padding: EdgeInsets.symmetric(horizontal: 20,vertical: 10),
                                controller: destination
                            ),

                          ],
                        ),
                      ),
                    if(!isManualSetLocation)
                      GestureDetector(
                        onDoubleTap: (){
                          flutterTts.stop().then((value) {
                            flutterTts.speak("Manual mode");

                            setState(() {
                              mode = "Manual";
                              currentMode = "";
                            });
                          });

                        },
                        onLongPressStart: (details){
                          flutterTts.stop().then((value) {
                            setState(() {
                              flutterTts.speak("Speak after this message.Hold speak release");
                              mode = "Speak";
                              currentMode = "";

                            });
                          });

                        },
                        onLongPressEnd: (details){
                          flutterTts.stop().then((value) {

                            RecordController.getRecordWhereUserIDDoc(id: widget.userModel.id ).then((value) {
                              bool found = false;
                              value.docs.forEach((records){
                                RecordPath recordPath = RecordPath.toObject(records.data());
                                if(recordPath.name.toLowerCase().contains(_lastWords.toLowerCase())&&_lastWords.isNotEmpty){
                                  found = true;
                                  double desStartLat,desStartLong,desEndLat,desEndLong;
                                  // http.get(Uri.parse("));

                                  desStartLat = double.parse((recordPath.path.first as String).split("-")[0]);
                                  desStartLong = double.parse((recordPath.path.first as String).split("-")[1]);
                                  desEndLat = double.parse((recordPath.path.last as String).split("-")[0]);
                                  desEndLong = double.parse((recordPath.path.last as String).split("-")[1]);
                                  flutterTts.speak("Your Destination. "+recordPath.name);
                                  destination.text = recordPath.name;
                                  _speechToText.stop();
                                  drawRoad(start: LatLng(currentPos!.latitude!, currentPos!.longitude!), end: LatLng(desStartLat, desStartLong));
                                  setState(() {
                                    isCustom = true;
                                    steps.clear();
                                    recordPath.path.forEach((element) {
                                      double lat = double.parse((element as String).split("-")[0]);
                                      double long = double.parse((element as String).split("-")[1]);
                                      steps.add(LatLng(lat, long));
                                    });
                                  });

                                  return;
                                }
                              });
                              if(!found){
                                var addresses = GeocodingPlatform.instance.locationFromAddress(_lastWords);
                                addresses.then((add){

                                  var loc = add.first;
                                  drawRoad(start: LatLng(currentPos!.latitude!, currentPos!.longitude!),end: LatLng(loc.latitude, loc.longitude));

                                  GetAddressFromLatLong(LatLng(add.first.latitude,add.first.longitude)).then((value) {
                                    setState(() {
                                      flutterTts.speak("Your destination: "+value);
                                      _speechToText.stop();
                                      destination.text = value;
                                      isCustom = false;
                                    });
                                  });


                                });



                              }
                            });
                            _speechToText.stop();

                            // setState(() {
                            //   _lastWords = "";
                            // });

                            // _getGeoLocationPosition().then((pos){
                            //
                            //   RecordController.getRecordWhereUserIDDoc(id: widget.userModel.id ).then((value) {
                            //
                            //     value.docs.forEach((element) {

                            //       if(recordPath.name.toLowerCase().contains(_lastWords.toLowerCase())&&_lastWords.isNotEmpty){

                            //         String desStartLat,desStartLong,desEndLat,desEndLong;
                            //         desStartLat = (recordPath.path.first as String).split("-")[0];
                            //         desStartLong = (recordPath.path.first as String).split("-")[1];
                            //
                            //         desEndLat = (recordPath.path.last as String).split("-")[0];
                            //         desEndLong = (recordPath.path.last as String).split("-")[1];
                            //         posLat = double.parse(desStartLat);
                            //         posLong = double.parse(desStartLong);
                            //
                            //         desLat = double.parse(desEndLat);
                            //         desLong = double.parse(desEndLong);
                            //         // if(connection!=null&&currentPos!=null){
                            //         //   connection!.output.add(ascii.encode(currentPos!.latitude.toString()+","+currentPos!.longitude.toString()+","+desLat.toString()+","+desLong.toString()+","+direction!.toString()+",4"+";")); // Sendi
                            //         // }
                            //         controller.drawRoad(
                            //           OSM.GeoPoint(latitude: posLat, longitude: posLong),
                            //           OSM.GeoPoint(latitude: desLat, longitude: desLong),
                            //           roadType: OSM.RoadType.foot,
                            //           roadOption: OSM.RoadOption(
                            //             roadWidth: 10,
                            //             roadColor: Colors.deepPurple,
                            //             showMarkerOfPOI: false,
                            //             zoomInto: true,
                            //           ),
                            //
                            //         ).then((value) {
                            //           MyDestinationController.upSert(destinationm: MyDestination(userID: widget.userModel.id, long: desLong, lat: desLat, time: DateTime.now().millisecondsSinceEpoch));
                            //           print(value.route);
                            //           mode = "Automatic";
                            //           currentMode = "";

                            //           setState(() {
                            //             this.recordPath = recordPath;
                            //             pathIndex = 0;
                            //           });
                            //         });
                            //         return;
                            //       }
                            //       else{
                            //         if(desLong==0||desLong==0){


                            //         return;
                            //       }
                            //     });
                            //   });
                            //
                            // });
                          });

                        },
                        onTap: (){
                          flutterTts.stop().then((value) {
                            flutterTts.speak("Automatic mode");
                            setState(() {
                              mode = "Automatic";
                              currentMode = "";
                            });
                          });

                        },
                        onVerticalDragUpdate: (dragdetails) async{
                          if(dragdetails.delta.direction<=0&&!dragup){

                            GetAddressFromLatLong(LatLng(currentPos!.latitude!, currentPos!.longitude!)).then((address) {
                              setState(() {
                                currentLocation.text = address;
                                flutterTts.speak("This is your current Location. "+address);
                                dragup = true;
                              });
                            });

                          }
                          if(dragdetails.delta.direction>=1){
                            // listen();
                            setState(() {
                              dragdown = true;
                              flutterTts.speak("Double tap at the bottom of the device to manually use the device, single tap to automatic. Swipe down to repeat the message.Swipe left to repeat last family message.Hold bottom right corner of your phone and speak to reply to your family");

                            });
                          }
                        },
                        onHorizontalDragUpdate: (dragdetails){
                          if(dragdetails.delta.direction==0&&!onlyOnce){

                            GetAddressFromLatLong(LatLng(currentPos!.latitude!, currentPos!.longitude!)).then((address) {
                              setState(() {
                                flutterTts.speak("Emergency! Emergency! Emergency! Fetch Me ASAP at"+address).whenComplete(() {
                                  //LAKBAYANNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
                                  NTP.now().then((value) {
                                    var uuid = Uuid();
                                    Message message = Message(chatID: widget.userModel.id,message: "Emergency! Emergency! Emergency! Fetch Me ASAP at"+address+"\nTime:"+DateFormat.yMMMEd().add_jms().format(value),read: false,isFamily: false,time:value.microsecondsSinceEpoch, id: uuid.v1());
                                    MessageController.upSert(messagem: message);
                                    print(widget.userModel.familyNumber);
                                    if(widget.userModel.familyNumber.isNotEmpty){
                                      telephony.sendSms(to: widget.userModel.familyNumber, message: "Emergency! Emergency! Emergency! Fetch Me ASAP at"+address+"\nTime:"+DateFormat.yMMMEd().add_jms().format(value)).whenComplete(() {

                                      });
                                    }
                                  });


                                });
                              });
                            });

                          }
                          if(dragdetails.delta.direction>0){
                            MessageController.getMessagesDoC(id: widget.userModel.id).then((value){
                              if(value.docs.isNotEmpty){
                                List<Message> messages = [];
                                value.docs.forEach((element) {
                                  Message messagem = Message.toObject(element.data());
                                  messages.add(messagem);
                                });

                                flutterTts.speak("Message from family: "+messages.lastWhere((element) => element.isFamily).message);
                              }
                            });
                          }
                          print(dragdetails.delta.direction.toInt());
                          setState(() {
                            onlyOnce = true;
                          });
                        },
                        child: Container(
                          color: Colors.black87,
                          height: double.infinity,
                          width: double.infinity,
                          alignment: Alignment.topCenter,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Text("Double tap at the bottom of the device to manually use the device, single tap to automatic. Swipe down to repeat the message.Swipe left to repeat last family message.Hold bottom right corner of your phone and speak to reply to your family",textAlign: TextAlign.center,style: TextStyle(color: Colors.white),),
                              ),
                              Padding(
                                padding: EdgeInsets.all(5),
                                child: Text(directionS,style: TextStyle(color: Colors.white),),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 60),
                                child: Column(
                                  children: [
                                    Text(mode,textAlign: TextAlign.center,style: TextStyle(color: Colors.white,fontSize: 30,fontWeight: FontWeight.bold),),
                                    Text("Mode",textAlign: TextAlign.center,style: TextStyle(color: Colors.white,fontSize: 13,fontWeight: FontWeight.bold),),
                                  ],
                                ),
                              ),
                              if(mode=="Automatic"||mode=="Speak")
                                CustomTextField(
                                    readonly: true,
                                    icon: Icons.my_location,
                                    color: MyColors.skyBlueDead,
                                    hint: "Current Location",
                                    padding: EdgeInsets.symmetric(horizontal: 20,vertical: 10),
                                    controller: currentLocation),
                              if(mode=="Automatic"||mode=="Speak")
                                CustomTextField(
                                    readonly: true,
                                    icon: Icons.location_on,
                                    color: MyColors.skyBlueDead,
                                    hint: "Destination",
                                    padding: EdgeInsets.symmetric(horizontal: 20,vertical: 10),
                                    controller: destination
                                ),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    GestureDetector(
                                      onLongPressStart: (details){
                                        flutterTts.speak("Speak after this message.Hold speak release").then((value) {
                                          setState(() {
                                            mode = "Speak";
                                            currentMode = "";
                                          });
                                        });
                                      },
                                      onLongPressEnd: (details){
                                        flutterTts.speak("Your message: "+_lastWords).whenComplete(() {
                                          flutterTts.speak("Tap on bottom right corner of the device to send. double tap to cancel");
                                          setState(() {
                                            send = true;
                                          });
                                        });

                                      },
                                      onDoubleTap: (){
                                        flutterTts.speak("Send message canceled").whenComplete((){
                                          setState(() {
                                            send = false;
                                          });
                                        });

                                      },
                                      onTap: (){
                                        if(send){
                                          flutterTts.speak("Successfully sent").whenComplete((){
                                            var uuid = Uuid();
                                            NTP.now().then((value) {
                                              setState(() {
                                                Message message = Message(chatID: widget.userModel.id,message: _lastWords,read: false,isFamily: false,time:value.millisecondsSinceEpoch, id: uuid.v1());
                                                MessageController.upSert(messagem: message);


                                                send = false;

                                              });

                                            });

                                          });

                                        }
                                      },
                                      child: CustomTextButton(
                                        rTl: 50,
                                        rBL: 50,
                                        rTR: 0,
                                        text: "Reply",
                                        height: MediaQuery.of(context).size.height*.05,
                                        width: 200,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ),

                    // StreamBuilder<locationm.LocationData>(
                    //     stream:locationm.Location.instance.onLocationChanged,
                    //     builder: (context,snapshot){
                    //       if(!snapshot.hasData)return Center();
                    //       return Row(
                    //         children: [
                    //           Text(snapshot.data!.latitude.toString()+" - "+snapshot.data!.longitude.toString(),style:TextStyle(color:Colors.white)),
                    //           Padding(padding: EdgeInsets.all(10)),
                    //           // Text(desLat.toString()+" - "+desLong.toString(),style:TextStyle(color:Colors.white)),
                    //         ],
                    //       );
                    //     }
                    // )
                  ],
                ),
              ),

              // _buildManualReader(),
              // Expanded(child: _buildCompass()),
            ],
          ),
        ),
      ),
    );
  }

}