
import 'dart:async';
import 'dart:math';

import 'package:ez_bot_guid/controller/controller.dart';
import 'package:ez_bot_guid/custom_widgets/custom_texfield.dart';
import 'package:ez_bot_guid/custom_widgets/custom_textbutton.dart';
import 'package:ez_bot_guid/model/record_path.dart';
import 'package:ez_bot_guid/tools/my_colors.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ntp/ntp.dart';
import 'package:uuid/uuid.dart';
import '../model/transactions.dart';
import '../model/user.dart';
import 'package:intl/intl.dart';
import 'package:chat_bubbles/chat_bubbles.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart' as locationm;

import 'login.dart';


class Family extends StatefulWidget{
  Family({Key? key,required this.userModel}) : super(key: key);
  UserModel userModel;

  @override
  State<Family> createState() => _FamilyState();

}

class _FamilyState extends State<Family> {
  late DateTime _ntpTime;
  MapboxMapController? mapController;

  @override
  void initState() {

    super.initState();
  }

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
  TextEditingController messageController = TextEditingController();
  TextEditingController familyNumber = TextEditingController();
  TextEditingController destination = TextEditingController();
  TextEditingController currentAddress = TextEditingController();
  bool isRecording = false;
  Future<String> GetAddressFromLatLong(LatLng position)async {
    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

    Placemark place = placemarks[0];
    return '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}';

  }
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        body: TabBarView(
          children: [
            SingleChildScrollView(
              child: SizedBox(
                height: MediaQuery.of(context).size.height,
                child: Container(
                  height: MediaQuery.of(context).size.height,
                  color: Colors.black87,
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.all(10),
                          // color: Colors.amber,
                          child: StreamBuilder<DocumentSnapshot>(
                              stream: LiveLocationController.getLiveLocation(id: widget.userModel.id),
                              builder: (context,snapshot) {
                                if(!snapshot.hasData)return Center(child: CircularProgressIndicator(),);
                                LiveLocation liveLocation = LiveLocation.toObject(snapshot.data!.data());
                                String address = "";
                                GetAddressFromLatLong(LatLng(liveLocation.lat, liveLocation.long)).then((value) {
                                  currentAddress.text = value;
                                });

                                if(mapController!=null){
                                  mapController!.clearCircles();
                                  mapController!.addCircle(CircleOptions(
                                      geometry: LatLng(liveLocation.lat, liveLocation.long),
                                      circleColor: "#FF006C",
                                      circleStrokeColor: "#00B2FF",
                                      circleStrokeWidth: 5,
                                      circleOpacity: 0.7,
                                      circleStrokeOpacity: 0.7,
                                      circleRadius: 10
                                  ));
                                  mapController!.animateCamera(CameraUpdate.newLatLng( LatLng(liveLocation.lat, liveLocation.long)));
                                  MyDestinationController.getDestinationDoc(id: widget.userModel.id).then((event) {
                                    if(event.exists&&mapController!=null){
                                      MyDestination myDestination = MyDestination.toObject(event.data());
                                      List<LatLng> geometry = [];
                                      myDestination.path.forEach((element) {
                                        List<String> latlong = (element as String).split("-");
                                        double lat = double.parse(latlong[0]);
                                        double long = double.parse(latlong[1]);
                                        geometry.add(LatLng(lat, long));
                                      });
                                      mapController!.clearLines();
                                      mapController!.addLine(LineOptions(
                                        geometry: geometry,
                                        lineColor: "#FF006C",
                                        lineWidth:10,
                                        lineOpacity: 0.7,
                                      ));
                                      GetAddressFromLatLong(LatLng(geometry.last.latitude, geometry.last.longitude)).then((value) {
                                        destination.text = value;
                                      });

                                    }


                                  });
                                }


                                return StatefulBuilder(
                                    builder: (context,setState) {

                                      return Column(
                                        children: [

                                          CustomTextField(
                                              rBottomRight: 0,
                                              rBottomLeft: 0,
                                              color: MyColors.deadBlue,
                                              readonly: true,
                                              hint: "Current Location",
                                              padding: EdgeInsets.zero,
                                              controller:currentAddress
                                          ),

                                          Expanded(
                                            child:   StatefulBuilder(
                                                builder: (context,setState) {
                                                  return Container(
                                                      height: 300,
                                                      child:  MapboxMap(
                                                        // compassEnabled: true,
                                                        // rotateGesturesEnabled: false,
                                                        // doubleClickZoomEnabled: false,
                                                        zoomGesturesEnabled: true,
                                                        // tiltGesturesEnabled: true,
                                                        scrollGesturesEnabled: false,
                                                        // myLocationTrackingMode: MyLocationTrackingMode.TrackingCompass,
                                                        // compassViewPosition: CompassViewPosition.BottomRight,
                                                        // // myLocationEnabled: true,
                                                        // myLocationRenderMode: MyLocationRenderMode.COMPASS,
                                                        // trackCameraPosition: true,
                                                        styleString:"mapbox://styles/linoqui14/cl2tlttkv006814pchtcxxjkg",
                                                        accessToken: "sk.eyJ1IjoibGlub3F1aTE0IiwiYSI6ImNsMnUyNGpqNzAzbHMza3BobjVxZGt0MXEifQ.Oj_-khaiKFsMrTb96CFM7A",
                                                        onMapCreated: _onMapCreated,
                                                        initialCameraPosition: CameraPosition(target: LatLng(liveLocation.lat,liveLocation.long),zoom: 18),
                                                        onStyleLoadedCallback: _onStyleLoadedCallback,
                                                        // onCameraIdle: (){
                                                        //
                                                        // },
                                                      )

                                                  );
                                                }
                                            ),
                                          ),
                                        ],
                                      );
                                    }
                                );
                              }
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.all(10),
                          child: StatefulBuilder(
                              builder: (context,setState) {
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    CustomTextField(
                                      rBottomRight: 0,
                                      rBottomLeft: 0,
                                      color: MyColors.deadBlue,
                                      hint: "Destination",
                                      padding: EdgeInsets.zero,
                                      controller: destination,

                                    ),
                                    CustomTextField(
                                      rBottomRight: 0,
                                      rBottomLeft: 0,
                                      color: MyColors.deadBlue,
                                      hint: "Set Family Number",
                                      padding: EdgeInsets.zero,
                                      controller: familyNumber,
                                      suffix:CustomTextButton(
                                        width: 50,
                                        rTl: 0,
                                        rBL: 0,
                                        rBR: 0,
                                        rTR: 0,
                                        color: MyColors.deadBlue,
                                        text: "Set",
                                        onPressed: (){
                                          setState((){
                                            widget.userModel.familyNumber = familyNumber.text;
                                            UserController.upSert(user: widget.userModel);
                                            familyNumber.text = "";
                                          });

                                        },
                                      ) ,
                                    ),
                                    Expanded(
                                      child: Container(
                                        color: Colors.white.withAlpha(250),
                                        child: StreamBuilder<QuerySnapshot>(
                                            stream: MessageController.getMessages(id: widget.userModel.id),
                                            builder: (context,snapshot) {
                                              if(!snapshot.hasData)return Center(child: CircularProgressIndicator(),);
                                              if(snapshot.data!.docs.isEmpty)return Center(child: CircularProgressIndicator(),);
                                              List<Message> messages = [];
                                              List<String> messegesStr = [];
                                              snapshot.data!.docs.forEach((element) {
                                                Message message = Message.toObject(element.data());
                                                messages.add(message);
                                                messegesStr.add(message.message);
                                              });
                                              messages.sort((a,b)=>b.time.compareTo(a.time));

                                              return StatefulBuilder(
                                                  builder: (context,setState) {
                                                    return ListView(
                                                      reverse: true,
                                                      children: messages.map((message){
                                                        return Column(
                                                          children: [
                                                            Text(DateFormat.yMMMEd().add_jms().format(DateTime.fromMillisecondsSinceEpoch(message.time))),
                                                            BubbleSpecialThree(
                                                              text:message.message,
                                                              color: message.isFamily?Color(0xFF1B97F3):Colors.blueGrey,
                                                              isSender: message.isFamily,
                                                              textStyle: TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 16
                                                              ),
                                                            ),
                                                          ],
                                                        );
                                                      }).toList(),
                                                    );
                                                  }
                                              );
                                            }
                                        ),
                                      ),
                                    ),
                                    CustomTextField(
                                      rTopRight: 0,
                                      rTopLeft: 0,
                                      color: MyColors.deadBlue,
                                      hint: "Message",
                                      padding: EdgeInsets.zero,
                                      controller: messageController,
                                      suffix:CustomTextButton(
                                        width: 50,
                                        rTl: 0,
                                        rBL: 0,
                                        color: Colors.transparent,
                                        text: "Send",
                                        onPressed: (){
                                          var uuid = Uuid();
                                          NTP.now().then((value) {
                                            setState(() {
                                                Message messagem = Message(chatID: widget.userModel.id, id: uuid.v1(), message: messageController.text, isFamily: true, time: value.millisecondsSinceEpoch);
                                                MessageController.upSert(messagem: messagem);
                                                messageController.text = "";

                                            });

                                          });

                                        },

                                      ) ,
                                    )
                                  ],
                                );


                              }
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            Container(
              color: Colors.black87,
              height: double.infinity,
              child: StreamBuilder<QuerySnapshot>(
                stream: MyLocationController.getLocationWithUserID(id: widget.userModel.id),
                builder: (context,snapshot){
                  if(!snapshot.hasData)return Center(child: CircularProgressIndicator(),);
                  if(snapshot.data!.docs.isEmpty)return Center(child: CircularProgressIndicator(),);
                  List<MyLocation> myLocations = [];
                  snapshot.data!.docs.forEach((element) {
                    MyLocation myLocation = MyLocation.toObject(element.data());
                    myLocations.add(myLocation);
                  });
                  myLocations.sort((b,a)=>a.time.compareTo(b.time));
                  return ListView(
                    children: myLocations.map((e) {

                      return FutureBuilder<String>(
                        future: GetAddressFromLatLong(LatLng(e.lat, e.long)),
                        builder: (context,future){
                          if(!future.hasData)return Center(child: CircularProgressIndicator(),);
                          return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.black45,

                              ),
                              margin: EdgeInsets.all(5),
                              padding: EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(future.data!,style: TextStyle(color: Colors.white,fontSize: 15,fontWeight: FontWeight.bold),),
                                  Text(DateFormat.yMMMMd().add_jms().format(DateTime.fromMillisecondsSinceEpoch(e.time)),style: TextStyle(color: Colors.white,fontWeight: FontWeight.w100),),
                                ],
                              )
                          );
                        },
                      );
                    }).toList(),

                  );
                  // return Center();
                },
              ),
            ),
            SizedBox(
              height:500,
              child: Scaffold(
                backgroundColor: Colors.black87,
                body: Container(
                  child: SingleChildScrollView(
                    child: StreamBuilder<QuerySnapshot>(
                        stream: RecordController.getRecordWhereUserID(id: widget.userModel.id),
                        builder: (context,snapshot){
                          if(!snapshot.hasData)return Center(child: CircularProgressIndicator(),);
                          if(snapshot.data!.docs.isEmpty)return Center(child: CircularProgressIndicator(),);
                          List<RecordPath> recordPaths = [];
                          snapshot.data!.docs.forEach((element) {

                            RecordPath recordPath = RecordPath.toObject(element.data());
                            print(recordPath.name);
                            recordPaths.add(recordPath);
                          });
                          return Container(
                            height: MediaQuery. of(context). size. height*0.87,
                            child: ListView(
                              children: recordPaths.map((e) {
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(e.name,style: TextStyle(color: Colors.white,fontSize: 25,fontWeight: FontWeight.bold),),
                                          Text(e.id,style: TextStyle(color: Colors.white,fontSize: 13,fontWeight: FontWeight.w100),),
                                        ],
                                      ),
                                      IconButton(
                                          onPressed:(){
                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                              content: Row(
                                                children: [
                                                  CustomTextButton(
                                                    text: "Confirm",
                                                    color: MyColors.darkBlue,
                                                    onPressed: (){
                                                        RecordController.delete(id: e.id);
                                                        setState(() {

                                                        });
                                                    },
                                                  )
                                                ],
                                              ),
                                              backgroundColor: Colors.blue,
                                              duration: Duration(seconds: 3),
                                            ));
                                          },
                                          icon: Icon(Icons.clear,color: Colors.redAccent,)
                                      )
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        }
                    ),
                  ),
                ),
                floatingActionButton: Container(
                  child: CustomTextButton(
                    text: "Record Path",
                    color: MyColors.darkBlue,
                    onPressed: (){
                            List<String> path = [];
                            TextEditingController name = TextEditingController();
                            if(!isRecording){
                              showDialog(
                                  context: context,
                                  builder: (context){

                                    return StatefulBuilder(
                                        builder: (context, setState) {
                                          return WillPopScope(
                                            onWillPop: () async => false,
                                            child: AlertDialog(
                                              title: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text("Record path",style: TextStyle(fontSize: 30,fontWeight: FontWeight.w100),),
                                                  Text("Press the button to add path."),
                                                  StreamBuilder<locationm.LocationData>(
                                                      stream: locationm.Location.instance.onLocationChanged,
                                                      builder: (context, snapshot) {
                                                        if(!snapshot.hasData)return Center();
                                                        return CustomTextButton(

                                                          text: "Add",
                                                          onPressed: (){
                                                            if(name.text.isNotEmpty){
                                                              setState(() {

                                                                path.add(snapshot.data!.latitude.toString()+"-"+snapshot.data!.longitude.toString());

                                                              });
                                                            }

                                                          },
                                                        );
                                                      }
                                                  ),
                                                  CustomTextField(hint: "Name", padding:EdgeInsets.zero, controller:name,color: Colors.black87, )
                                                ],
                                              ),
                                              content: Container(
                                                child: SizedBox(
                                                  height: 500,
                                                  width: 500,
                                                  child: ListView(
                                                    children: path.map((e) {
                                                      return Text(e);
                                                    }).toList(),
                                                  ),
                                                ),
                                              ),
                                              actions: [
                                                CustomTextButton(
                                                  color: Colors.amber,
                                                  text:"Cancel",
                                                  onPressed: (){
                                                    Navigator.pop(context);
                                                  },
                                                ),
                                                CustomTextButton(
                                                  text:"Save",
                                                  onPressed: (){
                                                    var uuid = Uuid();
                                                    RecordController.upSert(recordPath: RecordPath(id: uuid.v1(), name: name.text, path: path,userID: widget.userModel.id));
                                                    Navigator.pop(context);
                                                  },
                                                )
                                              ],
                                            ),
                                          );
                                        }
                                    );
                                  }
                              ).whenComplete(() {
                                setState(() {
                                  isRecording = false;
                                });
                              });
                            }
                    },
                  ),
                ),

              ),
            ),
            SizedBox(
              height:500,
              child: Scaffold(
                backgroundColor: Colors.black87,
                body: Container(
                  child: SingleChildScrollView(
                    child: StreamBuilder<QuerySnapshot>(
                        stream: DestinationReachedController.getDestinationReachStreamWhereUserID(userID: widget.userModel.id),
                        builder: (context,snapshot){
                          if(!snapshot.hasData)return Center(child: CircularProgressIndicator(),);
                          if(snapshot.data!.docs.isEmpty)return Center(child: CircularProgressIndicator(),);
                          List<DestinationReached> destinationsReached = [];
                          snapshot.data!.docs.forEach((element) {
                            // print(element.data());
                            DestinationReached des = DestinationReached.toObject(element.data());
                            destinationsReached.add(des);

                          });
                          return Container(
                            height: MediaQuery. of(context). size. height*0.87,
                            child: ListView(
                              children: destinationsReached.map((e) {
                                return StreamBuilder<DocumentSnapshot>(
                                  stream: MyLocationController.getLocation(id: e.myLocationID),
                                  builder: (context, snapshot) {
                                    if(!snapshot.hasData)return Center(child: CircularProgressIndicator(),);

                                    MyLocation myLocation = MyLocation.toObject(snapshot.data);
                                    return FutureBuilder<String>(
                                      future: GetAddressFromLatLong(LatLng(myLocation.lat, myLocation.long)),
                                      builder: (context,future){
                                        if(!future.hasData)return Center(child: CircularProgressIndicator(),);
                                        return Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(10),
                                              color: Colors.black45,

                                            ),
                                            margin: EdgeInsets.all(5),
                                            padding: EdgeInsets.all(10),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(future.data!,style: TextStyle(color: Colors.white,fontSize: 15,fontWeight: FontWeight.bold),),
                                                Text(DateFormat.yMMMMd().add_jms().format(DateTime.fromMillisecondsSinceEpoch(myLocation.time)),style: TextStyle(color: Colors.white,fontWeight: FontWeight.w100),),
                                              ],
                                            )
                                        );
                                      },
                                    );
                                  }
                                );
                              }).toList(),
                            ),
                          );
                        }
                    ),
                  ),
                ),

              ),
            ),
            Container(
              color: Colors.black87,
              child: Center(
                child: CustomTextButton(
                  color: MyColors.darkBlue,
                  onPressed: (){
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => Login()),
                          (Route<dynamic> route) => false,
                    );
                  },
                  text: "Sign out",
                ),
              ),
            )
          ],
        ),
        bottomNavigationBar: Container(
          color: Colors.black87,
          height: 50,
          child: TabBar(
            tabs: [
              Icon(Icons.dashboard),
              Icon(Icons.query_stats),
              Icon(Icons.add_location),
              Icon(Icons.where_to_vote),
              Icon(Icons.settings),

            ],
          ),
        ),
      ),
    );
  }
}
