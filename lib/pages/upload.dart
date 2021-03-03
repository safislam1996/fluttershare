import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart'as Im;
import 'package:uuid/uuid.dart';

class Upload extends StatefulWidget {
  final User currentUser;


  Upload({this.currentUser});

  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload> {
  File file;
  bool isUpload=false;
  String postId=Uuid().v4();

  TextEditingController locationController=TextEditingController();
  TextEditingController captionController=TextEditingController();

  handleTakePicture() async {
    Navigator.pop(context);
    File file = await ImagePicker.pickImage(
        source: ImageSource.camera, maxHeight: 675, maxWidth: 960);

    setState(() {
      this.file = file;
    });
  }

  handleFromGallery() async {
    Navigator.pop(context);
    File file = await ImagePicker.pickImage(source: ImageSource.gallery);

    setState(() {
      this.file = file;
    });
  }

  selectImage(parentContext) {
    return showDialog(
        context: parentContext,
        builder: (context) {
          return SimpleDialog(
            title: Text(
              'Upload Image',
              style: TextStyle(
                fontSize: 22.0,
              ),
            ),
            children: [
              SimpleDialogOption(
                child: Text('Take Image with Camera'),
                onPressed: () => handleTakePicture(),
              ),
              SimpleDialogOption(
                child: Text('Take Image from Gallery'),
                onPressed: () => handleFromGallery(),
              ),
              SimpleDialogOption(
                child: Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              )
            ],
          );
        });
  }

  Container buildSplashScreen() {
    return Container(
      color: Theme.of(this.context).accentColor.withOpacity(0.6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            "assets/images/upload.svg",
            height: 260.0,
          ),
          Padding(
            padding: EdgeInsets.only(top: 20.0),
            child: RaisedButton(
              child: Text(
                'Upload Image',
                style: TextStyle(color: Colors.white, fontSize: 22.0),
              ),
              color: Colors.deepOrange,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              onPressed: () {
                return selectImage(context);
              },
            ),
          )
        ],
      ),
    );
  }

  clearImage() {
    setState(() {
      file = null;
    });
  }

   uploadImage(File imageFile) async{
    StorageUploadTask uploadTask=storageRef.child('post_$postId.jpg').putFile(imageFile);//upload the file to the postId related firebase storage
     StorageTaskSnapshot storageTaskSnapshot=await uploadTask.onComplete;
     String downloadUrl= await storageTaskSnapshot.ref.getDownloadURL();//takes the reference to the created post snapshot and create a download url
     return downloadUrl;
   }

  compressImage() async {
    final tempDir=await getTemporaryDirectory();//temporary directory to set the image in
    final path=tempDir.path;//set the path for the temporary directory
    Im.Image image=Im.decodeImage(file.readAsBytesSync());//decode the file and read the file as a list of byte, stores it as an image object
    final compressedImage=File('$path/img_$postId.jpg')..writeAsBytesSync(Im.encodeJpg(image,quality: 75));

    setState(() {
      file=compressedImage;
    });
  }

  createPostInFirestore({String mediaUrl,String location,String description}){  //create a post collection of user's posts
    postRef.
    document(widget.currentUser.id).
    collection("userPosts").
    document(postId).
    setData(
        {
          "postId":postId,
          "ownerId" : widget.currentUser.id,
          "username" : widget.currentUser.username,
          "mediaUrl" : mediaUrl,
          "description" : description,
          "location" : location,
          "timestamp":timestamp,
          "likes":{}
        },
    );

    captionController.clear();
    locationController.clear();

    setState(() {
      file=null;
      isUpload=false;
      postId=Uuid().v4();
    });

  }
  getCurrentLocation()async{
    Position position=await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
    List<Placemark> placemarks=await Geolocator().placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark placemark=placemarks[0];

    String formatAddress='${placemark.locality},${placemark.country}';
    locationController.text=formatAddress;
  }

  handleSubmit() async {
    setState(() {
      isUpload=true;
    });
    await compressImage();
    String mediaUrl=await uploadImage(file);
    createPostInFirestore(
      mediaUrl: mediaUrl,
      location: locationController.text,
      description: captionController.text

    );
  }


  Scaffold buildUploadForm() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white70,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            clearImage();
          },
        ),
        title: Center(
          child: Text(
            'Create a post',
            style: TextStyle(color: Colors.black),
          ),
        ),
        actions: [
          FlatButton(
              onPressed: isUpload?null:()=>handleSubmit(),
              child: Text(
                "Post",
                style: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0),
              ))
        ],
      ),
      body: ListView(

        children: <Widget>[
          isUpload?linearProgress():Text(""),
          Container(
            height: 220.0,
            width: MediaQuery.of(context).size.width * 0.8,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: FileImage(file),
                  ),
                ),
              ),
            ),
          ),
          Padding(padding: EdgeInsets.only(top: 10.0)),
          ListTile(
            leading: CircleAvatar(
              backgroundImage:
                  CachedNetworkImageProvider(widget.currentUser.photoUrl),
            ),
            title: Container(
              width: 250.0,
              child: TextField(
                controller: captionController,
                decoration: InputDecoration(
                    hintText: "Write a caption", border: InputBorder.none),
              ),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(
              Icons.pin_drop,
              color: Colors.orange,
              size: 35.0,
            ),
            title: Container(
              width: 250.0,
              child: TextField(
                controller: locationController,
                decoration: InputDecoration(
                    hintText: "Where was this taken?",
                    border: InputBorder.none),
              ),
            ),
          ),
          Container(
            width: 200.0,
            height: 100.0,
            alignment: Alignment.center,
            child: RaisedButton.icon(
              color: Colors.blue,
              onPressed: () => getCurrentLocation(),
              icon: Icon(
                Icons.my_location,
                color: Colors.white,
              ),
              label: Text(
                "Use Current Location",
                style: TextStyle(color: Colors.white),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return file == null ? buildSplashScreen() : buildUploadForm();
  }


}
