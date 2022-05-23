
import 'dart:async';

import 'package:ez_bot_guid/controller/controller.dart';
import 'package:ez_bot_guid/custom_widgets/custom_texfield.dart';
import 'package:ez_bot_guid/custom_widgets/custom_textbutton.dart';
import 'package:ez_bot_guid/tools/my_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mobile_number/mobile_number.dart';

import '../model/user.dart';
import 'family.dart';
import 'home.dart';
// import 'home2.dart';
class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}
enum TtsState { playing, stopped, paused, continued }
class _LoginState extends State<Login> {
  late FlutterTts flutterTts;
  TtsState ttsState = TtsState.stopped;
  String _mobileNumber = '';
  TextEditingController mobileNumber = TextEditingController();
  get isPlaying => ttsState == TtsState.playing;
  get isStopped => ttsState == TtsState.stopped;
  get isPaused => ttsState == TtsState.paused;
  get isContinued => ttsState == TtsState.continued;
  double volume = 0.5;
  double pitch = 1.0;
  double rate = 0.5;
  String? _newVoiceText;
  List<SimCard> _simCard = <SimCard>[];
  bool isRegistered = false;
  UserModel? userModel;
  Future<bool> initMobileNumberState() async {
    if (!await MobileNumber.hasPhonePermission) {
      await MobileNumber.requestPhonePermission;
      return false;
    }
    String mobileNumber = '';
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      mobileNumber = (await MobileNumber.mobileNumber)!;
      _simCard = (await MobileNumber.getSimCards)!;
      UserController.getUserDoc(id: _simCard[0].number.toString()).then((value) {
        if(value.exists){
          UserModel userModel = UserModel.toObject(value.data());
          if(userModel.status=="login"){
            _stop();
            flutterTts.stop();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => Home(userModel: userModel,)),
                  (Route<dynamic> route) => false,
            );
            return true;
          }
          else{
            startTimer();
          }

        }
        else{
          _speak("Please be sure that the sim you want to register is in sim slot 1. Double tap to repeat the message. Long press to register.");
        }
      });
    } on PlatformException catch (e) {
      debugPrint("Failed to get mobile number because of '${e.message}'");
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return false;
    setState(() {
      _mobileNumber = mobileNumber;
    });
    return false;

  }

  @override
  void initState() {
    initMobileNumberState();
    flutterTts = FlutterTts();
    // flutterTts.setLanguage("fil-PH");
    // flutterTts.setVoice({"fil-PH-Standard-A":"FEMALE"});
    _setAwaitOptions();
    _getDefaultEngine();
    flutterTts.setStartHandler(() {
      setState(() {
        print("Playing");
        ttsState = TtsState.playing;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        print("Complete");
        ttsState = TtsState.stopped;
        if(isRegistered){
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => Home(userModel:userModel!)),
                (Route<dynamic> route) => false,
          );
          _stop();
        }
      });
    });

    flutterTts.setCancelHandler(() {
      setState(() {
        print("Cancel");
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        print("error: $msg");
        ttsState = TtsState.stopped;
      });
    });


    MobileNumber.listenPhonePermission((isPermissionGranted) {
      if (isPermissionGranted) {
        initMobileNumberState();
      } else {}
    });


    super.initState();
  }
  Future _getDefaultEngine() async {
    var engine = await flutterTts.getDefaultEngine;
    if (engine != null) {
      print(engine);
    }
  }
  Future _speak(String message) async {
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);


    await flutterTts.speak(message);


  }

  void _onChange(String text) {
    setState(() {
      _newVoiceText = text;
    });
  }
  Future _setAwaitOptions() async {
    await flutterTts.awaitSpeakCompletion(true);
  }
  Future _stop() async {
    var result = await flutterTts.stop();
    if (result == 1) setState(() => ttsState = TtsState.stopped);
  }
  Future _pause() async {
    var result = await flutterTts.pause();
    if (result == 1) setState(() => ttsState = TtsState.paused);
  }
  int count = 0;
  late Timer _timer;
  void startTimer() {
    const oneSec = const Duration(seconds: 1);
    _timer =  Timer.periodic(
        oneSec,
            (Timer timer) {
          _timer = timer;
          if(count==1){
            flutterTts.speak("Welcome! You are using the LAYA BOT .Please be sure that the sim you want to register is in sim slot 1. Double tap to repeat the message. Long press to register.");
            _timer.cancel();
          }
          count++;
        });
  }
  @override
  void dispose() {
    super.dispose();
    flutterTts.stop();
  }

  @override
  Widget build(BuildContext context) {
    Widget bigCircle = Container(
        margin: EdgeInsets.all(10),
        width: 20.0,
        height: 20.0,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        )
    );
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 120,
        elevation: 0,
        backgroundColor: Colors.black87,
        centerTitle: true,
        title: Container(
          margin: EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                rBottomLeft: 0,
                rBottomRight: 0,
                icon: Icons.tag,
                color: Colors.white,
                  hint: "Patient's mobile number",
                  padding:EdgeInsets.zero,
                  controller: mobileNumber
              ),
              CustomTextButton(
                width: 300,
                rTl: 0,
                rTR: 0,
                text: "Hold to submit",
                color: MyColors.deadBlue,
                onHold: (){
                  if(mobileNumber.text.isNotEmpty){
                    print(mobileNumber.text.replaceFirst("0", "+63"));
                    UserController.getUserDoc(id: mobileNumber.text.replaceFirst("0", "+63")).then((value){
                      UserModel user = UserModel.toObject(value.data());

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => Family(userModel: user,)),
                            (Route<dynamic> route) => false,
                      );
                    });
                  }

                },
              )
            ],
          ),
        ),
      ),
      body: GestureDetector(
        onDoubleTap: (){
          _speak("Welcome! You are using the LAYA BOT!.Please be sure that the sim you want to register is in sim slot 1. Double tap to repeat the message. Long press to register.");
        },
        onTap: (){

        },
        onLongPress: ()async{

          await UserController.getUserDoc(id:_simCard[0].number.toString() ).then((value){

            print(_simCard[0].number.toString());
            if(!value.exists){
              _speak("Welcome back! This mobile number. "+_simCard[0].number.toString().replaceAll("+63", "0")+".");
              String numberTemp = "";
              if(_simCard[0].number.toString()[0]=='0'){
                numberTemp = _simCard[0].number.toString().replaceAll("0", "+63");

              }
              else if(_simCard[0].number.toString()[0]=='9'){
                String num = "+63";
                numberTemp = (num+_simCard[0].number.toString());
              }
              else{
                numberTemp = _simCard[0].number.toString();
              }
              UserModel userModel = UserModel(id:numberTemp,status: "login" );
              UserController.upSert(user:userModel);
              setState(() {
                this.userModel = userModel;
                isRegistered = true;
              });
            }
            else{
              _speak("Welcome back! This mobile number. "+_simCard[0].number.toString().replaceAll("+63", "0").replaceAll("", ",")+".");
              UserModel userModel = UserModel(id:_simCard[0].number.toString(),status: "login" );
              UserController.upSert(user: UserModel(id:_simCard[0].number.toString() ,status: "login"));
              setState(() {
                this.userModel = userModel;
                isRegistered = true;
              });
            }
          });

        },
        child: Container(
          color: Colors.black87,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: SizedBox(
                      width: 200,
                      child: Text("Please be sure that the sim you want to register is in sim slot 1. Double tap to repeat the message. Long press to register.",style: TextStyle(color: Colors.white,fontWeight: FontWeight.w100),textAlign: TextAlign.center,)
                  ),
                ),
                Text("Long press to register.",style: TextStyle(color: Colors.white,fontSize: 30,fontWeight: FontWeight.bold),),
                bigCircle,
                Padding(padding: EdgeInsets.symmetric(vertical: 10)),

              ],
            ),
          ),
        ),
      ),

    );
  }
}