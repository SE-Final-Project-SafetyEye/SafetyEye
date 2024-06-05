import 'dart:math';
import 'dart:typed_data';
import 'package:logger/logger.dart';
import 'package:pytorch_lite/pytorch_lite.dart';
import 'dart:io';
import 'dart:async';
import 'package:image/image.dart' as img;
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:convert';
import 'package:flutter_isolate/flutter_isolate.dart';

// TODOs PLACED AT THE END OF THE FILE

// consider to create a config file to setup those parameters
const DEV_NUM_OF_CHUNK_FRAMES = 60;
const DEV_MODEL_MAX_FRAME_SIDE = 640;
const CHUNK_FRAMES_INTERVAL = 0.25;
const NUM_OF_LABELS = 82;
const DETECTION_COEFF = 0.4;
const IOU_THRESHOLD = 0.5;

final Logger _logger = Logger();

// possible init method to set the values of 'consts' according to model type etc.
// void initODModule() {
//   try {
//
//   } on Exception catch (_) {
//     // log the exception;
//   }
// }

class ModelObjectDetectionSingleton {
  static final  ModelObjectDetectionSingleton _instance = ModelObjectDetectionSingleton._internal();
  ModelObjectDetection? _odModel;

  ModelObjectDetectionSingleton._internal(){setModel();}

  factory ModelObjectDetectionSingleton() {
    return _instance;
  }

  Future<bool> setModel() async {
    _odModel ??= await initModel();
    return true;
  }
  ModelObjectDetection get odModel => _odModel!;
}

// loading a detection model from a .torchscript file.
Future<ModelObjectDetection> initModel() async{
  ModelObjectDetection objectModel = ModelObjectDetection(0, DEV_MODEL_MAX_FRAME_SIDE, DEV_MODEL_MAX_FRAME_SIDE, []); // empty model
  try {
    objectModel = await PytorchLite
        .loadObjectDetectionModel(
        "assets/yolov8s_LP_TS_220224v1.torchscript", //This specific model trained on 640*640 resolution format
        NUM_OF_LABELS,
        DEV_MODEL_MAX_FRAME_SIDE,
        DEV_MODEL_MAX_FRAME_SIDE,
        labelPath: "assets/labels.txt",
        objectDetectionModelType: ObjectDetectionModelType.yolov8);
  }on Exception catch (e){
    _logger.e('Error during object detection model initialization: $e');
  }
  return objectModel;
}


runObjectModule(String pathToChunk){
  try{
  FlutterIsolate.spawn(detectChunkObjects, pathToChunk); // isolate init
  }on Exception catch (e){
    _logger.e('Error during FlutterIsolate spawn of ObjectTracking class: $e');
  }
}

@pragma('vm:entry-point')
Future<bool> detectChunkObjects(String pathToChunk) async {
  try {
    var redundantBool = await ModelObjectDetectionSingleton().setModel();
    ObjectTracking ot = ObjectTracking();
    ot.detect(pathToChunk);
  } on Exception catch (e) {
    _logger.e('Error in detectChunkObjects method of ObjectTracking class: $e');
    return false;
  }

  return true;
}


class ObjectTracking {

  ModelObjectDetection objectModel = ModelObjectDetectionSingleton()._odModel!;


  Future<void> detect(String pathToChunk) async {
    try{
    String EMULATED_PATH =
    pathToChunk.substring(0, pathToChunk.lastIndexOf('/'));

    String chunkNameNoExtension =
    pathToChunk.substring(pathToChunk.lastIndexOf('/') + 1);
    chunkNameNoExtension = chunkNameNoExtension.substring(
        0, chunkNameNoExtension.lastIndexOf('.'));


    // captures the frames of the video file
    final cap = cv.VideoCapture.fromFile(pathToChunk);
    var fps = cap.get(cv.CAP_PROP_FPS);

    int fpsCoeff = min((fps / 4), fps).toInt(); // for retrieving only 4 fps

    var (ret, frame) = cap.read();

    double frameHeight = cap.get(cv.CAP_PROP_FRAME_HEIGHT);
    double frameWidth = cap.get(cv.CAP_PROP_FRAME_WIDTH);

    double xRatio = 1;
    double yRatio = 1;
    if (frameWidth > frameHeight) {
      yRatio = frameHeight / frameWidth;
    } else {
      xRatio = frameWidth / frameHeight;
    }

    int frameIndex = 1;
    List<List> chunkMetadata = [];
    File tempFile = File('$EMULATED_PATH/filled_resized_colored.png');

    while (ret) {
      var blackFrameMat = await preprocessImage(
          frame, xRatio, yRatio, frameWidth, frameHeight, EMULATED_PATH);

      cv.imwrite(tempFile.path, blackFrameMat);

      Uint8List tempFileBytes = await tempFile.readAsBytes();

      // restore those lines if the objectModel facing a bad input image format
      // img.Image blackFrameImage = img.decodeImage(tempFileBytes)!;
      // tempFileBytes = img.encodePng(blackFrameImage);

      List<ResultObjectDetection> objDetect =
      await objectModel.getImagePrediction(tempFileBytes,
          minimumScore: DETECTION_COEFF,
          iOUThreshold: IOU_THRESHOLD,
          boxesLimit: 13);

      // get FrameMetadata and add metadata to list
      List<dynamic> frameMetadata = await getFrameMetadata(
          objDetect, frameIndex, blackFrameMat, EMULATED_PATH);

      // TODO: frameMetadata = mapLicensePlatesToCars(frameMetadata, platesText);

      chunkMetadata.add(frameMetadata);

      var next = 0;
      while (fpsCoeff > next) {
        cap.read();
        next++;
        frameIndex++;
      }

      var (capret, capframe) = cap.read();
      frameIndex++;
      ret = capret;
      frame = capframe;
    }
    tempFile.delete();
    cap.release();
    var jsonText = jsonEncode(chunkMetadata);
    tempFile =
        File('$EMULATED_PATH/obj_detect_metadata_$chunkNameNoExtension.json');
    tempFile.writeAsString(jsonText);
    }on Exception catch (e) {
      _logger.e(
          'Error during main detect() method of ObjectTracking class: $e');
    }
  }

  Future<cv.Mat> preprocessImage(cv.Mat frame, double xRatio, double yRatio,
      double frameWidth, double frameHeight, String path) async {
    try {
      var interpolation = cv.INTER_AREA;
      if (DEV_MODEL_MAX_FRAME_SIDE * DEV_MODEL_MAX_FRAME_SIDE >
          frameHeight * frameWidth) {
        interpolation = cv.INTER_CUBIC;
      }

      var resized = cv.resize(frame, (0, 0),
          fx: xRatio * (DEV_MODEL_MAX_FRAME_SIDE / (frameWidth)),
          fy: yRatio * (DEV_MODEL_MAX_FRAME_SIDE / (frameHeight)),
          interpolation: interpolation);

      int top = 0;
      int bottom = DEV_MODEL_MAX_FRAME_SIDE - resized.height;
      int left = 0;
      int right = DEV_MODEL_MAX_FRAME_SIDE - resized.width;
      var filled_resized = cv.copyMakeBorder(
          resized, top, bottom, left, right, cv.BORDER_CONSTANT,
          value: cv.Scalar.fromRgb(0, 0, 0));

      var filled_resized_colored = cv.cvtColor(
          filled_resized, cv.COLOR_BGR2RGB);
      return filled_resized_colored;
    } on Exception catch (e) {
      _logger.e(
          'Error during preprocessImage method of ObjectTracking class: $e');
      return cv.Mat.empty();
    }
  }

  Future<List> getFrameMetadata(List<ResultObjectDetection> objDetect,
      int frameIndex, cv.Mat blackFrameMat, String workingPath) async {
    List<dynamic> frameMetadata = ['frame_$frameIndex'];
    try{
    Map<String, String> detectedObjMetadata = {};
    int i = 1;

    for (ResultObjectDetection res in objDetect) {
      int x1 = (res.rect.left * DEV_MODEL_MAX_FRAME_SIDE).toInt();
      int y1 = (res.rect.bottom * DEV_MODEL_MAX_FRAME_SIDE).toInt();
      int x2 = (res.rect.right * DEV_MODEL_MAX_FRAME_SIDE).toInt();
      int y2 = (res.rect.top * DEV_MODEL_MAX_FRAME_SIDE).toInt();
      String cls = res.className!;
      double conf = res.score;
      String objID = '$frameIndex' + '_$cls' + '_$i';

      MapEntry<String, String> id = MapEntry('objID', objID);
      MapEntry<String, String> xCoord =
      MapEntry('xCoordinateLeft', x1.toString());
      MapEntry<String, String> yCoord =
      MapEntry('yCoordinateBottom', y1.toString());
      MapEntry<String, String> width =
      MapEntry('width', (x2 - x1).abs().toString());
      MapEntry<String, String> height =
      MapEntry('height', (y2 - y1).abs().toString());
      MapEntry<String, String> label = MapEntry('label', cls);
      MapEntry<String, String> confidence =
      MapEntry('confidence', conf.toString().substring(0, 5));
      MapEntry<String, String> licensePlateOpt =
      const MapEntry('licensePlateOpt', '');
      MapEntry<String, String> licensePlateCarOpt =
      const MapEntry('licensePlateCarOpt', '');

      if (cls == 'license_plate') {
        String plateText = await detectLicensePlateNumber(
            blackFrameMat, res, workingPath, objID);
        licensePlateOpt = MapEntry('licensePlateOpt', plateText);
      }

      detectedObjMetadata.addEntries([
        id,
        xCoord,
        yCoord,
        width,
        height,
        label,
        confidence,
        licensePlateOpt,
        licensePlateCarOpt
      ]);

      frameMetadata.add(detectedObjMetadata);
      detectedObjMetadata = {};
      i++;
    }
    } on Exception catch (e) {
      _logger.e(
          'Error during getFrameMetadata method of ObjectTracking class: $e');
    }

    return frameMetadata;
  }

  Future<Map<String, String>> mapLicensePlatesToCars(
      List metadata, Map<String, String> platesText) async {
    // pay attention!!!!!! y coordinates start from top meaning higher y value is physically lower on the image.
    // TODO: assign the LP to a car that contains it using IoU Threshold method

    Map<String, String> out = {};
    try{} on Exception catch (e) {
      _logger.e(
          'Error during mapLicensePlatesToCars method of ObjectTracking class: $e');
    }
    return out;
  }

  Future<String> detectLicensePlateNumber(cv.Mat blackFrameMat,
      ResultObjectDetection objDetect, String workingPath, String lpID) async {
    var recognizedText = 'not_recognized';
    try{
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    int x1 = (objDetect.rect.left * DEV_MODEL_MAX_FRAME_SIDE).toInt();
    int y1 = (objDetect.rect.bottom * DEV_MODEL_MAX_FRAME_SIDE).toInt();
    int x2 = (objDetect.rect.right * DEV_MODEL_MAX_FRAME_SIDE).toInt();
    int y2 = (objDetect.rect.top * DEV_MODEL_MAX_FRAME_SIDE).toInt();

    // crop and then save the cropped image
    int demandedX = x1;
    int demandedY = y2;
    int width = (x2 - x1).abs();
    int height = (y2 - y1).abs();

    if (width < 32) {
      int diff = (demandedX - (32 - width) / 2).toInt();
      demandedX = min(max(0, diff), (640 - 32));
      width = 32;
    }

    if (height < 32) {
      int diff = (demandedY - (32 - height) / 2).toInt();
      demandedY = min(max(0, diff), (640 - 32));
      height = 32;
    }

    cv.Mat cropped = blackFrameMat
        .colRange(demandedX, demandedX + width)
        .rowRange(demandedY, demandedY + height);

    cv.Mat gray = cv.cvtColor(cropped, cv.COLOR_BGR2GRAY);

    var (_, gray_tres) = cv.threshold(gray, 64, 255, cv.THRESH_BINARY_INV);

    cv.imwrite('$workingPath/gray_tres$lpID.png', gray_tres);

    // scan and read the cropped LP
    final InputImage plateImage =
    InputImage.fromFilePath('$workingPath/gray_tres$lpID.png');
    final RecognizedText recognized =
    await textRecognizer.processImage(plateImage);

    if (recognized.text.trim() != '') {
      final validLicencePlateNumber = RegExp(
          r'[0-9]{2,3}\-?[0-9]{2,3}\-?[0-9]{2,3}|[0-9]{2,3}\-?[0-9]{2,3}|[0-9]{6}');
      RegExpMatch? match = validLicencePlateNumber.firstMatch(recognized.text);
      recognizedText = match![0] ?? recognizedText;
    }
    File deleteMe = File('$workingPath/gray_tres$lpID.png');
    deleteMe.delete();

    } on Exception catch (e) {
      _logger.e(
          'Error during detectLicensePlateNumber method of ObjectTracking class: $e');
    }
    return recognizedText;
  }
}


/*
TODO: make a documentation for the methods
/// Returns a resized copy of the [src] Image.
/// If [height] isn't specified, then it will be determined by the aspect
/// ratio of [src] and [width].
/// If [width] isn't specified, then it will be determined by the aspect ratio
/// of [src] and [height].

*/



//DEV
Future<cv.Mat> drawRectanglesCV(
    cv.Mat img, List<ResultObjectDetection> objDetect) async {
  cv.Mat out = img;
  for (ResultObjectDetection res in objDetect) {
    int x1 = (res.rect.left * DEV_MODEL_MAX_FRAME_SIDE).toInt();
    int y1 = (res.rect.bottom * DEV_MODEL_MAX_FRAME_SIDE).toInt();
    int x2 = (res.rect.right * DEV_MODEL_MAX_FRAME_SIDE).toInt();
    int y2 = (res.rect.top * DEV_MODEL_MAX_FRAME_SIDE).toInt();
    String cls = res.className!;
    double conf = res.score;

    cv.Rect rect = cv.Rect(x1, y2, (x2 - x1).abs(), (y1 - y2).abs());
    out = cv.rectangle(img, rect, cv.Scalar.fromRgb(255, 0, 0), thickness: 1);

    cv.Point pClass = cv.Point(x1, y2 - 5);
    out = cv.putText(out, cls, pClass, cv.FONT_HERSHEY_SIMPLEX, 0.5,
        cv.Scalar.fromRgb(0, 0, 255));

    cv.Point pConf = cv.Point(x1, y2 - 15);
    out = cv.putText(out, conf.toString().substring(0, 4), pConf,
        cv.FONT_HERSHEY_SIMPLEX, 0.5, cv.Scalar.fromRgb(0, 255, 0));
  }

  return out;
}