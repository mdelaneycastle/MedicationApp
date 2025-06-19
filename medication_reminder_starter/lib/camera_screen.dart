import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  late List<CameraDescription> _cameras;
  bool _isReady = false;
  XFile? _takenPhoto;
  String _prompt = '';

  final List<String> _randomPrompts = [
    "Hold the pack with your left hand",
    "Point at the medication",
    "Include your face in the photo",
    "Tilt the bottle sideways",
    "Put the meds in your open palm",
    "Show the back of the pack",
    "Place the pack on a flat surface",
    "Give a thumbs up next to the meds",
    "Angle the camera slightly from above",
    "Hold the box upright"
  ];

  @override
  void initState() {
    super.initState();
    _prompt = _randomPrompts[Random().nextInt(_randomPrompts.length)];
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    _controller = CameraController(_cameras[0], ResolutionPreset.medium);
    await _controller!.initialize();
    setState(() => _isReady = true);
  }

  Future<void> _takePicture() async {
    if (!_controller!.value.isInitialized) return;
    final photo = await _controller!.takePicture();
    setState(() {
      _takenPhoto = photo;
    });
  }

  void _retake() {
    setState(() {
      _takenPhoto = null;
      _prompt = _randomPrompts[Random().nextInt(_randomPrompts.length)];
    });
  }

  void _submit() {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("✅ Medication confirmed!")),
  );

  // Delay going back so the message can be seen
  Future.delayed(const Duration(seconds: 1), () {
    Navigator.pop(context);
  });
}

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady || _controller == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Confirm Medication')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Confirm Medication')),
      body: Column(
        children: [
          Container(
            color: Colors.amber.shade100,
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Text(
              _takenPhoto == null
                  ? "Prompt: $_prompt"
                  : "Did you follow the prompt?\n$_prompt",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 4,
            child: _takenPhoto == null
                ? CameraPreview(_controller!)
                : Image.file(File(_takenPhoto!.path), fit: BoxFit.cover),
          ),
          Expanded(
            flex: 1,
            child: _takenPhoto == null
                ? Center(
                    child: ElevatedButton.icon(
                      onPressed: _takePicture,
                      icon: Icon(Icons.camera),
                      label: Text('Take Photo'),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _retake,
                        icon: Icon(Icons.refresh),
                        label: Text('Retake'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _submit,
                        icon: Icon(Icons.check),
                        label: Text('Confirm'),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}