import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ez_bot_guid/model/record_path.dart';

import '../model/transactions.dart';
import '../model/user.dart';
class UserController{
  static CollectionReference users = FirebaseFirestore.instance.collection('users');
  static Future<DocumentSnapshot> getUserDoc({required String id}){
    return users.doc(id).get();
  }
  static Stream<DocumentSnapshot> getUser({required String id}){
    return users.doc(id).snapshots();
  }

  static void upSert({required UserModel user}){
    users.doc(user.id).set(user.toMap());
  }
}

class LiveLocationController{
  static CollectionReference liveLocation = FirebaseFirestore.instance.collection('liveLocation');

  static Future<DocumentSnapshot> getLiveLocationDoc({required String id}){
    return liveLocation.doc(id).get();
  }
  static Stream<DocumentSnapshot> getLiveLocation({required String id}){
    return liveLocation.doc(id).snapshots();
  }

  static void upSert({required LiveLocation liveLocationm}){
    liveLocation.doc(liveLocationm.id).set(liveLocationm.toMap());
  }
}

class MyLocationController{
  static CollectionReference myLocation = FirebaseFirestore.instance.collection('myLocation');

  static Future<DocumentSnapshot> getLocationDoc({required String id}){
    return myLocation.doc(id).get();
  }
  static Stream<DocumentSnapshot> getLocation({required String id}){
    return myLocation.doc(id).snapshots();
  }
  static Stream<QuerySnapshot> getLocationWithUserID({required String id}){
    return myLocation.where("userID",isEqualTo: id).snapshots();
  }

  static void upSert({required MyLocation myLocationm}){
    myLocation.doc(myLocationm.id).set(myLocationm.toMap());
  }
}

class ChatController{
  static CollectionReference chat = FirebaseFirestore.instance.collection('chat');

  static Future<DocumentSnapshot> getChatDoc({required String id}){
    return chat.doc(id).get();
  }
  static Stream<DocumentSnapshot> getChat({required String id}){
    return chat.doc(id).snapshots();
  }

  static void upSert({required Chat chatm}){
    chat.doc(chatm.userID).set(chatm.toMap());
  }
}
class RecordController{
  static CollectionReference records = FirebaseFirestore.instance.collection('records');

  static Future<DocumentSnapshot> getRecordDoc({required String id}){
    return records.doc(id).get();
  }
  static Stream<DocumentSnapshot> getRecord({required String id}){
    return records.doc(id).snapshots();
  }
  static Stream<QuerySnapshot> getRecordWhere({required String name}){
    return records.where("name",isEqualTo: name).snapshots();
  }
  static Stream<QuerySnapshot> getRecordWhereUserID({required String id}){
    return records.where("userID",isEqualTo: id).snapshots();
  }
  static Future<QuerySnapshot> getRecordWhereUserIDDoc({required String id}){
    return records.where("userID",isEqualTo: id).get();
  }
  static Future<QuerySnapshot> getRecordWhereUserIDName({required String id,required String name}){
    return records.where("userID",isEqualTo: id).where("name",isEqualTo: name).get();
  }
  static void delete({required String id}){
    records.doc(id).delete();
  }
  static void upSert({required RecordPath recordPath}){
    records.doc(recordPath.id).set(recordPath.toMap());
  }
}

class MessageController{
  static CollectionReference message = FirebaseFirestore.instance.collection('messages');

  static Future<DocumentSnapshot> getMessageDoc({required String id}){
    return message.doc(id).get();
  }
  static Stream<DocumentSnapshot> getMessage({required String id}){
    return message.doc(id).snapshots();
  }
  static Stream<QuerySnapshot> getMessages({required String id}){
    return message.where("chatID",isEqualTo: id).snapshots();
  }
  static Future<QuerySnapshot> getMessagesDoC({required String id}){
    return message.where("chatID",isEqualTo: id).get();
  }

  static void upSert({required Message messagem}){
    message.doc(messagem.id).set(messagem.toMap());
  }
}
class MyDestinationController{
  static CollectionReference destination = FirebaseFirestore.instance.collection('myDestination');

  static Future<DocumentSnapshot> getDestinationDoc({required String id}){
    return destination.doc(id).get();
  }
  static Stream<DocumentSnapshot> getDestination({required String id}){
    return destination.doc(id).snapshots();
  }
  static Stream<QuerySnapshot> getDestinationWhereUserID({required String id}){
    return destination.where("userID",isEqualTo: id).snapshots();
  }
  static void delete({required String id}){
    destination.doc(id).delete();
  }
  static void upSert({required MyDestination destinationm}){
    destination.doc(destinationm.userID).set(destinationm.toMap());
  }
  static void upSertRecord({required MyDestination destinationm}){
    FirebaseFirestore.instance.collection("destinationRecord").doc(destinationm.id).set(destinationm.toMap());
  }
  static Stream<QuerySnapshot> getDestinationRecord({required String id}){
    return FirebaseFirestore.instance.collection("destinationRecord").where("userID",isEqualTo: id).snapshots();
  }
}