import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:pytorch_lite/pytorch_lite.dart';
import 'dart:io';
import 'dart:async';
import 'package:image/image.dart' as img;
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:convert';
import 'package:async/async.dart';
import 'package:flutter_isolate/flutter_isolate.dart';


// TODO: consider init method to set the values of above 'consts' according to model type etc, considering config file
const DEV_NUM_OF_CHUNK_FRAMES = 60;
const DEV_MODEL_MAX_FRAME_SIDE = 640;
const CHUNK_FRAMES_INTERVAL = 0.25;
const NUM_OF_LABELS = 82;
const DETECTION_COEFF = 0.4;
const IOU_THRESHOLD = 0.5;

final Logger _logger = Logger();

// !!! large parts are commented out to preserve previous algorithm of 2-isolates parallel work.
class ObjectTracking {
  // static List<String> pathQueue = [];
  // static ReceivePort? receivePort;
  // static SendPort? sendPortLateBind;



  // loading a detection model from a .torchscript file.
  static Future<ModelObjectDetection?> initModel() async {
    ModelObjectDetection? objectModel;
    try {
      objectModel = await PytorchLite
          .loadObjectDetectionModel(
          "assets/yolov8s_LP_TS_220224v1.torchscript",
          //This specific model trained on 640*640 resolution format
          NUM_OF_LABELS,
          DEV_MODEL_MAX_FRAME_SIDE,
          DEV_MODEL_MAX_FRAME_SIDE,
          labelPath: "assets/labels.txt",
          objectDetectionModelType: ObjectDetectionModelType.yolov8);
    } on Exception catch (e) {
      _logger.e('Error during object detection model initialization: $e');
    }
    return objectModel;
  }


  static Future<void> addWork(String pathToChunk) async {
    //var isos = await FlutterIsolate.runningIsolates;
    // if ((await FlutterIsolate.runningIsolates).isEmpty) {
    //   receivePort = ReceivePort();
    //   receivePort!.listen((sPortIsolate) {
    //     ObjectTracking.sendPortLateBind = sPortIsolate;
    //     pathQueue.forEach(sendPortLateBind!.send);
    //     pathQueue = [];
    //   });
    //   var managerIsolate = await FlutterIsolate.spawn(
    //       managerIsolateRoutine, [receivePort!.sendPort, pathToChunk]);
    // } else {
    //   pathQueue.add(pathToChunk);
    //   if (sendPortLateBind != null) {
    //     pathQueue.forEach(sendPortLateBind!.send);
    //     pathQueue = [];
    //   }
    // }
    try {
      ReceivePort receivePort = ReceivePort();
      var workerIsolate = await FlutterIsolate.spawn(
          workerIsolateInit, [pathToChunk, receivePort.sendPort]);
      await receivePort.first;
      receivePort.close();
    }on Exception catch(e){
      _logger.e('Error during object detection model addWork: $e');
    }
  }

  // static Future<void> managerIsolateRoutine(List<dynamic> args) async {
  //   SendPort sPort = args[0];
  //   String pathToChunk = args[1];
  //   ReceivePort isolateRPort = ReceivePort();
  //   var chunksPathsEvents = StreamQueue<String>(isolateRPort.asBroadcastStream().map((event) => event.toString()));
  //   sPort.send(isolateRPort.sendPort);
  //   while (pathToChunk.substring(pathToChunk.lastIndexOf(".")) == ".mp4") {
  //     ReceivePort workerPort = ReceivePort();
  //     var workerIsolate = await FlutterIsolate.spawn(
  //         workerIsolateInit, [pathToChunk, workerPort.sendPort]);
  //     await workerPort.first;
  //     workerIsolate.kill();
  //     if(!(await chunksPathsEvents.hasNext.timeout(const Duration(seconds: 2), onTimeout: ()=>false))){break;}
  //     pathToChunk = await chunksPathsEvents.next;
  //   }
  //   chunksPathsEvents.cancel();
  //   isolateRPort.close();
  //   Isolate.current.kill();
  // }



  static Future<bool> workerIsolateInit(List<dynamic> args) async {
    try {
      String pathToChunk = args[0];
      SendPort sendCompletePort = args[1];
      ObjectTracking.detect([pathToChunk, sendCompletePort]);
    } on Exception catch (e) {
      _logger.e('Error in detectChunkObjects method of ObjectTracking class: $e');
      return false;
    }

    return true;
  }

  static Future<void> detect(List<dynamic> args) async {
    try {
      String pathToChunk = args[0];
      SendPort sendCompletePort = args[1];
      ModelObjectDetection objectModel = (await initModel())!;
      String EMULATED_PATH =
      pathToChunk.substring(0, pathToChunk.lastIndexOf('/'));

      String chunkNameNoExtension =
      pathToChunk.substring(pathToChunk.lastIndexOf('/') + 1);
      chunkNameNoExtension = chunkNameNoExtension.substring(
          0, chunkNameNoExtension.lastIndexOf('.'));

      File tempFileForOpenCV = File(pathToChunk);
      pathToChunk = "$EMULATED_PATH/od_${DateTime.now().millisecondsSinceEpoch}.mp4";
      tempFileForOpenCV = await tempFileForOpenCV.copy(pathToChunk);


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
      Map<String,List<dynamic>> chunkMetadata = {};
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
        Map<String, List<dynamic>> frameMetadata = await getFrameMetadata(
            objDetect, frameIndex, blackFrameMat, EMULATED_PATH);

        // TODO: frameMetadata = mapLicensePlatesToCars(frameMetadata, platesText);

        chunkMetadata.addAll(frameMetadata);

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
      await tempFile.writeAsString(jsonText);
      await tempFileForOpenCV.delete();
      sendCompletePort.send("done");
    } on Exception catch (e) {
      _logger.e(
          'Error during main detect() method of ObjectTracking class: $e');
    }
  }

  static Future<cv.Mat> preprocessImage(cv.Mat frame, double xRatio, double yRatio,
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

  static Future<Map<String, List<dynamic>>> getFrameMetadata(List<ResultObjectDetection> objDetect,
      int frameIndex, cv.Mat blackFrameMat, String workingPath) async {
    Map<String, List<dynamic>> output = {};
    List<dynamic> frameMetadata = [];
    try {
      Map<String, String> detectedObjMetadata = {};
      int i = 1;

      for (ResultObjectDetection res in objDetect) {
        // PAY ATTENTION!!! Y coordinates start from the top - meaning HIGHER y value is PHYSICALLY LOWER on the image.
        double x1 = res.rect.left;
        double y1 = res.rect.bottom;
        double x2 = res.rect.right;
        double y2 = res.rect.top;
        String cls = res.className!;
        double conf = res.score;
        String objID = '$frameIndex' + '_$cls' + '_$i';

        MapEntry<String, String> id = MapEntry('objID', objID);
        MapEntry<String, String> xCoord =
        MapEntry('xCoordinateLeft', x1.toString().substring(0,5));
        MapEntry<String, String> yCoord =
        MapEntry('yCoordinateBottom', y1.toString().substring(0,5));
        MapEntry<String, String> width =
        MapEntry('width', (x2 - x1).abs().toString().substring(0,5));
        MapEntry<String, String> height =
        MapEntry('height', (y2 - y1).abs().toString().substring(0,5));
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
    output.addAll({'frame_$frameIndex':frameMetadata});
    return output;
  }

  Future<Map<String, String>> mapLicensePlatesToCars(List metadata,
      Map<String, String> platesText) async {
    // pay attention!!!!!! y coordinates start from top - meaning higher y value is physically lower on the image.
    // TODO: assign the LP to a car that contains it using IoU Threshold method

    Map<String, String> out = {};
    try {} on Exception catch (e) {
      _logger.e(
          'Error during mapLicensePlatesToCars method of ObjectTracking class: $e');
    }
    return out;
  }

  static Future<String> detectLicensePlateNumber(cv.Mat blackFrameMat,
      ResultObjectDetection objDetect, String workingPath, String lpID) async {
    var recognizedText = 'not_recognized';
    try {
      final textRecognizer = TextRecognizer(
          script: TextRecognitionScript.latin);

      // PAY ATTENTION!!! Y coordinates start from the top - meaning HIGHER y value is PHYSICALLY LOWER on the image.
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
        RegExpMatch? match = validLicencePlateNumber.firstMatch(
            recognized.text);
        recognizedText = match != null
            ? (match[0] != null ? match[0]! : recognizedText)
            : recognizedText;
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