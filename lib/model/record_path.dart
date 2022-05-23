
class RecordPath{
  String id,name,userID;
  List<dynamic> path;

  RecordPath({required this.id, required this.name, required this.path,required this.userID});

  Map<String,dynamic> toMap(){
    return {
      'id':id,
      'name':name,
      'path':path,
      'userID':userID,
    };
  }

  static RecordPath toObject(data){
    return RecordPath(
      userID:data['userID'],
      id:data['id'],
      name:data['name'],
      path:data['path'],

    );
  }
}