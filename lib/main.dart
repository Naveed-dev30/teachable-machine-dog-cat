import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';

void main() => runApp(
      MaterialApp(
        home: MyApp(),
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
      ),
    );

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List _outputs;
  PickedFile _image;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loading = true;

    loadModel().then((value) {
      setState(() {
        _loading = false;
      });
    });
  }

  double dogprobability;
  String animal;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    dogprobability = _outputs != null ? _outputs[0]['confidence'] : 0.0;
    animal = _outputs != null ? _outputs[0]['label'] : '';
    return Scaffold(
      body: _loading
          ? Container(
              alignment: Alignment.center,
              child: CircularProgressIndicator(),
            )
          : Container(
              child: Stack(
                children: [
                  Positioned(
                    height: size.height * 0.4,
                    width: size.width,
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                            image: AssetImage(
                              _image?.path ?? 'assets/dog_cover.jpg',
                            ),
                            fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  Positioned(
                    top: size.height * 0.35,
                    height: size.height * 0.65,
                    width: size.width,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: 20),
                          Text(
                            'Prediction',
                            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          Text(
                            dogprobability != 0.0 ? '${dogprobability.toStringAsFixed(2)}% ${animal.split(' ')[1]}' : '',
                            style: TextStyle(
                              color: Colors.green,
                            ),
                          ),
                          SizedBox(height: 90),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  OutlineButton(
                                    onPressed: () async {
                                      pickImage(ImageSource.camera);
                                    },
                                    highlightedBorderColor: Colors.orange,
                                    highlightElevation: 10.0,
                                    color: Colors.white,
                                    textColor: Colors.white,
                                    padding: EdgeInsets.all(16),
                                    child: Icon(
                                      Icons.camera_alt,
                                      color: Colors.orange,
                                    ),
                                    shape: CircleBorder(),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Take Photo',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  OutlineButton(
                                    onPressed: () async {
                                      pickImage(ImageSource.gallery);
                                    },
                                    highlightedBorderColor: Colors.blue,
                                    highlightElevation: 10.0,
                                    color: Colors.white,
                                    textColor: Colors.white,
                                    padding: EdgeInsets.all(16),
                                    child: Icon(
                                      Icons.photo,
                                      color: Colors.blue,
                                    ),
                                    shape: CircleBorder(),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Pick Photo',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  pickImage(ImageSource source) async {
    final picker = ImagePicker();
    var image = await picker.getImage(
      source: source,
    );
    if (image == null) return null;
    setState(() {
      _loading = true;
      _image = image;
    });
    classifyImage(image);
  }

  classifyImage(PickedFile image) async {
    var output = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 2,
      threshold: 0.5,
      imageMean: 127.5,
      imageStd: 127.5,
    );
    setState(() {
      _loading = false;
      _outputs = output;
    });
  }

  loadModel() async {
    await Tflite.loadModel(
      model: "assets/model_unquant.tflite",
      labels: "assets/labels.txt",
    );
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }
}
