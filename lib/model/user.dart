class UserModel{
  String id,status,familyNumber;

  UserModel({required this.id,required this.status,this.familyNumber = ""});

  Map<String,dynamic> toMap(){
    return {
      'id':id,
      'status':status,
      'familyNumber':familyNumber
    };
  }

  static UserModel toObject(data){
    return UserModel(
        id:data['id'],
        status:data['status'],
        familyNumber:data['familyNumber']
    );
  }
}