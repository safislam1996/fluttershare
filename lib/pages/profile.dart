import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/edit_profile.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/post.dart';
import 'package:fluttershare/widgets/post_tile.dart';
import 'package:fluttershare/widgets/progress.dart';

class Profile extends StatefulWidget {
  final String profileId;

  Profile({this.profileId});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final String currentUserId = currentUser?.id;
  bool isLoading = false;
  bool isFollowing=false;
  int postCount = 0;
  List<Post> posts = [];
  String postOrentiation = "grid";
  int followerCount=0;
  int followingCount=0;

  @override
  void initState() {
    super.initState();
    getProfilePosts();
    getFollower();
    getFollowing();
    checkIfFollowing();
  }

  getProfilePosts() async {
    setState(() {
      isLoading = true;
    });
    QuerySnapshot snapshot = await postRef
        .document(widget.profileId)
        .collection('userPosts')
        .orderBy('timestamp', descending: true)
        .getDocuments();
    setState(() {
      isLoading = false;
      postCount = snapshot.documents.length;
      posts = snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
    });
  }

  checkIfFollowing() async {
    DocumentSnapshot snapshot=await followerRef.document(widget.profileId).collection('followUser').document(currentUserId).get();
    setState(() {
      isFollowing=snapshot.exists;
    });

  }
  getFollower() async {
    QuerySnapshot snapshot=await followerRef.document(widget.profileId).collection('followUser').getDocuments();
    setState(() {
      followerCount=snapshot.documents.length;
    });

  }
  getFollowing() async {

   QuerySnapshot snapshot= await followingRef.document(widget.profileId).collection('UserFollowing').getDocuments();

   setState(() {
     followingCount=snapshot.documents.length;
   });
  }




  Column buildCountColumn(String label, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          count.toString(),
          style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
        ),
        Container(
          margin: EdgeInsets.only(top: 4.0),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 15.0,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  editProfile() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => EditProfile(currentUserId: currentUserId)));
  }

  handleUnfollowUser(){
    setState(() {
      isFollowing=false;

      followerRef.
      document(widget.profileId)
          .collection('followUser')
          .document(currentUserId)
          .get().then((doc){
            if(doc.exists){

              doc.reference.delete();
            }

      },);

      followingRef.
      document(currentUserId)
          .collection('UserFollowing')
          .document(widget.profileId)
          .get().then((doc){
        if(doc.exists){

          doc.reference.delete();
        }

      });

      activityFeedRef.
          document(widget.profileId)
          .collection('feedItems')
          .document(currentUserId)
          .get().then((doc){
      if(doc.exists){

      doc.reference.delete();
      }

      });



    });


  }
  handleFollowUser(){
    setState(() {
      isFollowing=true;


      followerRef.
      document(widget.profileId)
          .collection('followUser')
          .document(currentUserId)
          .setData({});

      followingRef.
      document(currentUserId)
          .collection('UserFollowing')
          .document(widget.profileId)
          .setData({

      });

      activityFeedRef.document(widget.profileId).collection('feedItems').document(currentUserId).setData({
        "type":"follow",
        "ownerId":widget.profileId,
        "username":currentUser.username,
        "userId":currentUserId,
        "userphotoUrl":currentUser.photoUrl,
        "timestamp":timestamp
      });
    });

  }




  Container buildButton({String text, Function function}) {
    return Container(
      padding: EdgeInsets.only(top: 2.0),
      child: FlatButton(
        onPressed: function,
        child: Container(
          width: 250.0,
          height: 27.0,
          child: Text(
            text,
            style: TextStyle(
              color: isFollowing?Colors.black:Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isFollowing?Colors.white:Colors.blue,
            border: Border.all(
              color: isFollowing?Colors.grey:Colors.blue,
            ),
            borderRadius: BorderRadius.circular(5.0),
          ),
        ),
      ),
    );
  }

  buildProfileButton() {
    // viewing your own profile - should show edit profile button
    bool isProfileOwner = currentUserId == widget.profileId;

    if (isProfileOwner) {
      return buildButton(text: "Edit Profile", function: editProfile);
    }
    else if(isFollowing){
     return buildButton(text: "Unfollow",function: handleUnfollowUser);
    }
    else if(!isFollowing){
      return buildButton(text: "Follow",function: handleFollowUser);
    }
  }

  buildProfileHeader() {
    return FutureBuilder(
      future: userRef.document(widget.profileId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        User user = User.fromDocument(snapshot.data);
        return Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 40.0,
                    backgroundColor: Colors.grey,
                    backgroundImage: CachedNetworkImageProvider(user.photoUrl),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            buildCountColumn("posts", postCount),
                            buildCountColumn("followers", followerCount),
                            buildCountColumn("following", followingCount),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            buildProfileButton(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 12.0),
                child: Text(
                  user.username,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 4.0),
                child: Text(
                  user.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 2.0),
                child: Text(
                  user.bio,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  setPostOrentiation(String postOrentiation) {
    setState(() {
      this.postOrentiation = postOrentiation;
    });
  }

  buildPostOrentiation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
            icon: Icon(Icons.grid_on),
            color: postOrentiation == "grid"
                ? Theme.of(context).primaryColor
                : Colors.grey,
            onPressed: () => setPostOrentiation("grid")),


        IconButton(
          icon: Icon(Icons.list),
          color: postOrentiation == "list"
              ? Theme.of(context).primaryColor
              : Colors.grey,
          onPressed: () => setPostOrentiation("list"),
        )
      ],
    );
  }

  buildProfilePosts() {
    if (isLoading) {
      return circularProgress();
    }
    else if(posts.isEmpty){
      return Container(
        color: Theme.of(this.context).accentColor.withOpacity(0.6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              "assets/images/no_content.svg",
              height: 260.0,
            ),
            Padding(
              padding: EdgeInsets.only(top: 20.0),
              child: Text(
                'No content',
                style: TextStyle(color: Colors.redAccent, fontSize: 40.0,fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      );

    }
    else if (postOrentiation == "grid") {
      List<GridTile> gridtile = [];
      posts.forEach((post) {
        gridtile.add(GridTile(child: PostTile(post)));
      });
      return GridView.count(
        children: gridtile,
        crossAxisCount: 3,
        childAspectRatio: 1.5,
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
      );
    } else if (postOrentiation == "list") {
      return Column(
        children: posts,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleText: "Profile"),
      body: ListView(
        children: <Widget>[
          buildProfileHeader(),
          buildPostOrentiation(),
          Divider(
            height: 0.0,
          ),
          buildProfilePosts(),
          Divider(),
        ],
      ),
    );
  }
}
