

class LiveLocation{
  String id;
  double long,lat;

  LiveLocation({required this.id, required this.long, required this.lat});
  Map<String,dynamic> toMap(){
    return {
      'id':id,
      'long':long,
      'lat':lat,
    };
  }

  static LiveLocation toObject(data){
    return LiveLocation(
        id:data['id'],
        long:data['long'],
        lat:data['lat']
    );
  }
}

class MyLocation{
  String id,userID;
  double long,lat;
  int time;
  MyLocation({required this.id,required this.userID, required this.long, required this.lat,required this.time});

  Map<String,dynamic> toMap(){
    return {
      'id':id,
      'userID':userID,
      'long':long,
      'lat':lat,
      'time':time,
    };
  }

  static MyLocation toObject(data){
    return MyLocation(
      id:data['id'],
      long:data['long'],
      lat:data['lat'],
      userID:data['userID'],
      time:data['time'],
    );
  }

}
class MyDestination{
  String userID,id,name;
  List<dynamic> path;
  int time;
  MyDestination({required this.userID, required this.path,required this.time,this.id = "",this.name=""});

  Map<String,dynamic> toMap(){
    return {
      'userID':userID,
      'path':path,
      'time':time,
      'id':id
    };
  }

  static MyDestination toObject(data){
    String tempID = "";
    String nameTemp = "";
    try{
      tempID = data['id'];
      tempID = data['name'];

    }catch(e){

    }
    return MyDestination(
        path:data['path'],
        userID:data['userID'],
        time:data['time'],
        id: tempID,
        name: nameTemp
    );
  }

}


class Chat{
  String userID;
  List<dynamic> messages;

  Chat({required this.userID,required this.messages});

  Map<String,dynamic> toMap(){
    return {
      'userID':userID,
      'messages':messages,

    };
  }

  static Chat toObject(data){
    return Chat(
      userID:data['userID'],
      messages:data['messages'],

    );
  }



}
class DestinationReached{
  String userID;
  List<dynamic> messages;

  DestinationReached({required this.userID,required this.messages});

  Map<String,dynamic> toMap(){
    return {
      'userID':userID,
      'messages':messages,

    };
  }

  static DestinationReached toObject(data){
    return DestinationReached(
      userID:data['userID'],
      messages:data['messages'],

    );
  }



}
class Message{
  String chatID,id,message;
  bool isFamily,read;
  int time;

  Message({required this.chatID,required this.id,required this.message,required this.isFamily,required this.time,this.read = false});



  Map<String,dynamic> toMap(){
    return {
      'id':id,
      'chatID':chatID,
      'message':message,
      'isFamily':isFamily,
      'time':time,
      'read':read,
    };
  }

  static Message toObject(data){
    return Message(
      id:data['id'],
      chatID:data['chatID'],
      message:data['message'],
      isFamily:data['isFamily'] ,
      time:data['time'],
      read:data['read'],

    );
  }

}
