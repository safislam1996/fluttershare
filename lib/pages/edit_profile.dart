import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import "package:flutter/material.dart";
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/progress.dart';

class EditProfile extends StatefulWidget {
  final String currentUserId;

  EditProfile({this.currentUserId});

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
 final _scaffoldKey=GlobalKey<ScaffoldState>();
  bool isLoading = false;
  User user;
  bool _displayNameValid=true;
  bool _bioNameValid=true;

  TextEditingController displayController = TextEditingController();
  TextEditingController bioController = TextEditingController();

  Column buildDisplayNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            "Display Name",
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextField(
          controller: displayController,
          decoration: InputDecoration(hintText: "Update display name",errorText: _displayNameValid?null:"Display Name too short"),

        )
      ],
    );
  }

  Column buildBioFiled() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            "Bio",
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextField(
          controller: bioController,
          decoration: InputDecoration(hintText: "Update user bio",errorText: _bioNameValid?null:"Bio is too long"),
        )
      ],
    );
  }

  updateProfileData(){
    setState(() {
      displayController.text.trim().length<3 || displayController.text.isEmpty?_displayNameValid=false:_displayNameValid=true;

      bioController.text.trim().length >100 || bioController.text.isEmpty?_bioNameValid=false:_bioNameValid=true;
    });

    if(_displayNameValid && _bioNameValid){
      userRef.document(widget.currentUserId).updateData(({
        "displayName":displayController.text,
        "bio":bioController.text,
      }));

      SnackBar snackBar=SnackBar(content: Text("Profile Updated"));
      _scaffoldKey.currentState.showSnackBar(snackBar);
    }

  }

 logout() async{
    await googleSignIn.signOut();
    Navigator.push(context, MaterialPageRoute(builder: (context)=>Home()));
 }

  getUser() async {
    setState(() {
      isLoading = true;
    });

    DocumentSnapshot doc = await userRef.document(widget.currentUserId).get();
    user = User.fromDocument(doc);
    displayController.text = user.displayName;
    bioController.text = user.bio;

    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          "Edit Profile",
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
              icon: Icon(
                Icons.done,
                size: 30.0,
                color: Colors.green,
              ),
              onPressed: () => Navigator.pop(context))
        ],
      ),
      body: isLoading
          ? circularProgress()
          : ListView(
              children: [
                Container(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 16.0, bottom: 8.0),
                        child: CircleAvatar(
                          radius: 50.0,
                          backgroundImage:
                              CachedNetworkImageProvider(user.photoUrl),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: [buildDisplayNameField(), buildBioFiled()],
                        ),
                      )
                    ],
                  ),
                ),
                RaisedButton(
                  onPressed: () => updateProfileData(),
                  child: Text(
                    "Update Profile",
                    style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: FlatButton.icon(
                      onPressed: () => logout(),
                      icon: Icon(
                        Icons.cancel,
                        color: Colors.red,
                      ),
                      label: Text(
                        "Logout",
                        style: TextStyle(color: Colors.red, fontSize: 20.0),
                      )),
                )
              ],
            ),
    );
  }
}
