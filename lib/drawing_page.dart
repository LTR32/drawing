import 'dart:async';

import 'package:drawing_app/drawn_line.dart';
import 'package:drawing_app/sketcher.dart';
import 'package:drawing_app/widget/language_picker_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'dart:ui' as ui;
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';

class DrawingPage extends StatefulWidget {
  @override
  _DrawingPageState createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  GlobalKey _globalKey = new GlobalKey();
  List<DrawnLine> lines = <DrawnLine>[];
  DrawnLine line;
  Color selectedColor = Colors.black;
  double selectedWidth = 5.0;
  Color mycolor = Colors.lightBlue;

  StreamController<List<DrawnLine>> linesStreamController = StreamController<List<DrawnLine>>.broadcast();
  StreamController<DrawnLine> currentLineStreamController = StreamController<DrawnLine>.broadcast();

  Future<void> save() async {
    try {
      final boundary = _globalKey.currentContext.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData.buffer.asUint8List();
      final saved = await ImageGallerySaver.saveImage(
        pngBytes,
        quality: 100,
        name: DateTime.now().toIso8601String() + ".png",
        isReturnImagePathOfIOS: true,
      );
    } catch (e) {
      print(e);
    }
  }

  Future<void> clear() async {
    setState(() {
      lines = [];
      line = null;
    });
  }

  void onPanStart(DragStartDetails details) {
    final box = context.findRenderObject() as RenderBox;
    final point = box.globalToLocal(details.globalPosition);
    setState(() {
      line = DrawnLine([point], selectedColor, selectedWidth);
    });
    currentLineStreamController.add(line);
  }


  void onPanUpdate(DragUpdateDetails details) {
    final box = context.findRenderObject() as RenderBox;
    final point = box.globalToLocal(details.globalPosition);
    final path = List.from(line.path)..add(point);
    List<Offset> offsetList = [];
    offsetList = path.cast<Offset>();
    line = DrawnLine(offsetList, selectedColor, selectedWidth);

    setState(() {
      if (lines.length == 0) {
        lines.add(line);
      } else {
        lines[lines.length - 1] = line;
      }
    });
    currentLineStreamController.add(line);
  }

  void onPanEnd(DragEndDetails details) {
    lines = List.from(lines)..add(line);
    linesStreamController.add(lines);
  }


  GestureDetector buildCurrentPath(BuildContext context) {
    return GestureDetector(
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      child: RepaintBoundary(
        child: Container(
          color: Colors.transparent,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: StreamBuilder<DrawnLine>(
            stream: currentLineStreamController.stream,
            builder: (context, snapshot) {
              return CustomPaint(
                painter: Sketcher(
                  lines: [line]
                ),
              );
            },
          )
          // CustomPaint widget will go here
        ),
      ),
    );
  }


  Widget buildAllPaths(BuildContext context) {
    return RepaintBoundary(
      key: _globalKey,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: StreamBuilder<List<DrawnLine>>(
          stream: linesStreamController.stream,
          builder: (context, snapshot) {
            return CustomPaint(
              painter: Sketcher(
                lines: lines,
              ),
            );
          },
        ),
      ),
    );
  }


  Widget buildStrokeToolbar() {
    return Positioned(
      bottom: 100.0,
      right: 10.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          buildStrokeButton(5.0),
          buildStrokeButton(10.0),
          buildStrokeButton(15.0),
        ],
      ),
    );
  }

  Widget buildMenu() {
    return SpeedDial(
      animatedIcon: AnimatedIcons.menu_close,
      //openCloseDial: isDialOpen,
      backgroundColor: Colors.redAccent,
      overlayColor: Colors.grey,
      overlayOpacity: 0.5,
      spacing: 15,
      spaceBetweenChildren: 15,
      closeManually: true,
      children: [
        SpeedDialChild(
            child: Icon(Icons.clear_all_outlined),
            label: AppLocalizations.of(context).language,
            onTap: () {
              clear();
            }
        ),
        SpeedDialChild(
            child: Icon(Icons.save),
            label: 'Sauvegarder',
            onTap: () {
              snackBarSave();
            }
        ),
        SpeedDialChild(
            child: Icon(Icons.copy),
            label: 'Copy',
            onTap: () {
              print('Copy Tapped');
            }
        ),
      ],
    );
  }


  Widget buildStrokeButton(double strokeWidth) {
    return GestureDetector(
      onTap: () {
        selectedWidth = strokeWidth;
      },
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Container(
          width: strokeWidth * 2,
          height: strokeWidth * 2,
          decoration: BoxDecoration(color: selectedColor, borderRadius: BorderRadius.circular(20.0)),
        ),
      ),
    );
  }

  Widget showAlertDialog() {
    Future.delayed(Duration.zero,(){
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(AppLocalizations.of(context).parametres),
                  ElevatedButton(
                      onPressed: (){
                        Navigator.pop(context);
                      },
                      child: Icon(Icons.close, color: Colors.blue,),
                    style: ElevatedButton.styleFrom(
                      shape: CircleBorder(),
                      backgroundColor: Colors.white,
                      elevation: 0
                    ),
                  )
                ],
              ),
              content: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(AppLocalizations.of(context).languesettings,),
                        SizedBox(width: 10,),
                        LanguagePickerWidget(),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Tout effacer"),
                        SizedBox(width: 10,),
                        buildClearButton(),
                      ],
                    ),
                    buildColorPicker()
                  ]
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(15))
              ),
            );
          });
    });

    return Scaffold(
        body: Center(
            child: Text("Hello World")
        )
    );
  }

  Widget buildColorToolbar() {
    /*return Positioned(
      top: 40.0,
      right: 10.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          buildClearButton(),
          Divider(
            height: 10.0,
          ),
          buildSaveButton(),
          Divider(
            height: 20.0,
          ),
          buildColorButton(Colors.red),
          buildColorButton(Colors.blueAccent),
          buildColorButton(Colors.deepOrange),
          buildColorButton(Colors.green),
          buildColorButton(Colors.lightBlue),
          buildColorButton(Colors.black),
          buildColorButton(Colors.white),
        ],
      ),
    );*/
    return Positioned(
      top: 40.0,
      right: 10.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          buildSaveButton(),
          Divider(
            height: 10.0,
          ),
          ElevatedButton(
              onPressed: () {
                showAlertDialog();
              },
              child: Icon(Icons.settings_outlined),
            style: ElevatedButton.styleFrom(
              shape: CircleBorder()
            ),
          ),
        ],
      ),
    );
  }


  Widget buildColorButton(Color color) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: FloatingActionButton(
        mini: true,
        backgroundColor: color,
        child: Container(),
        onPressed: () {
          setState(() {
            selectedColor = color;
          });
        },
      ),
    );
  }

  Widget snackBarSave (){
    const snackBar = SnackBar(
      content: Text('Image sauvegardée !', style: TextStyle(color: Colors.white),textAlign: TextAlign.center,),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      width: 200,
      shape: StadiumBorder()
    );

// Find the ScaffoldMessenger in the widget tree
// and use it to show a SnackBar.
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    save();
  }

  Widget buildSaveButton() {
    return GestureDetector(
      onTap: snackBarSave,
      child: CircleAvatar(
        child: Icon(
          Icons.save,
          size: 20.0,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget buildClearButton() {
    return GestureDetector(
      onTap: clear,
      child: CircleAvatar(
        child: Icon(
          Icons.create,
          size: 20.0,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget buildColorPicker() {
    return ElevatedButton(
      onPressed: (){
        showDialog(
            context: context,
            builder: (BuildContext context){
              return AlertDialog(
                title: Text('Choisissez votre couleur'),
                content: SingleChildScrollView(
                  child: ColorPicker(
                    pickerColor: selectedColor, //default color
                    onColorChanged: (Color color){ //on color picked
                      setState(() {
                        selectedColor = color;
                      });
                    },
                  ),
                ),
                actions: <Widget>[
                  ElevatedButton(
                    child: const Text('Valider'),
                    onPressed: () {
                      Navigator.of(context).pop(); //dismiss the color picker
                    },
                  ),
                ],
              );
            }
        );

      },
      child: Icon(Icons.color_lens_outlined),
      style: ButtonStyle(
          shape: MaterialStateProperty.all(
              CircleBorder()
          )
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow[50],
      body: Stack(
        children: [
          buildAllPaths(context),
          buildCurrentPath(context),
          buildColorToolbar(),
          buildStrokeToolbar(),
        ],
      ),
      floatingActionButton: buildMenu(),
    );
  }

  @override
  void dispose() {
    linesStreamController.close();
    currentLineStreamController.close();
    super.dispose();
  }
}
