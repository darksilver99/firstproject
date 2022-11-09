import 'dart:io';

import 'package:camera_camera/camera_camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User? user = Auth().currentUser;
  final TextEditingController _controller = TextEditingController();
  bool isEditable = false;
  var url = "";

  @override
  void initState() {
    super.initState();
  }

  Future<void> signOut() async {
    await Auth().signOut();
  }

  Widget _title() {
    return const Text('Firebase Auth');
  }

  Widget _userUid() {
    return Text(user?.email ?? 'User email');
  }

  Widget _signOutButton() {
    return ElevatedButton(
      onPressed: signOut,
      child: const Text('Sign Out'),
    );
  }

  final photos = <File>[];

  void openCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CameraCamera(
          cameraSide: CameraSide.back,
          flashModes: const [FlashMode.off],
          enableZoom: false,
          onFile: (file) {
            photos.clear();
            photos.add(file);
            Navigator.pop(context);
            if (photos.isNotEmpty) uploadImg();
          },
        ),
      ),
    );
  }

  uploadImg() async {
    final pathName = "${user!.uid}.jpg";
    final ref = FirebaseStorage.instance.ref().child('uploads').child(pathName);
    await ref.putFile(photos[0]);
    url = await ref.getDownloadURL();
    FirebaseFirestore.instance.collection("users").doc(user?.uid).update({
      "img": url,
    });
    setState(() {});
  }

  getImageProfile() {
    if (url != "") {
      return NetworkImage(url);
    } else if (photos.isNotEmpty) {
      return FileImage(photos[0]);
    } else {
      return NetworkImage("https://i.picsum.photos/id/237/200/300.jpg?hmac=TmmQSbShHz9CdQm0NkEjx1Dyh_Y984R9LpNrpvH2D_U");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: _title(),
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _userUid(),
              const Divider(),
              const Divider(),
              if (!isEditable)
                FutureBuilder(
                  future: FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
                  builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
                      _controller.text = data["fullname"];
                      url = data["img"] ?? "";
                      return Column(
                        children: [
                          GestureDetector(
                            child: Container(
                              width: 100,
                              height: 100,
                              margin: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: getImageProfile(),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            onTap: () {
                              openCamera();
                            },
                          ),
                          Text(data["fullname"]),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                isEditable = true;
                              });
                            },
                            child: const Text('Edit'),
                          ),
                        ],
                      );
                    }

                    return const Text("Loading..");
                  },
                ),
              if (isEditable)
                Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      margin: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: getImageProfile(),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Fullname',
                        ),
                      ),
                    ),
                    Container(
                      child: ElevatedButton(
                        onPressed: () {
                          FirebaseFirestore.instance.collection("users").doc(user?.uid).update({
                            "fullname": _controller.text,
                          });
                          if (photos.isNotEmpty) uploadImg();
                          setState(() {
                            isEditable = false;
                          });
                        },
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              const Divider(),
              _signOutButton(),
            ],
          ),
        ),
      ),
    );
  }
}
