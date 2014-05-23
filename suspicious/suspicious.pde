import gab.opencv.*;
import java.awt.Rectangle;
import processing.video.*;
import processing.serial.*;

final int JUSTFACE = 0;
final int EDGE = 1;
final int WIDEFACE = 2;
final int ZOOMFACE = 3;

Capture video;
OpenCV opencv;
Rectangle[] faces;
Serial myPort;

boolean recording = false, debug = false, drawLines = true, makeRecordings = true;

PImage buffer, faceBufferImg, zoomBufferImg;
PGraphics faceBuffer, zoomBuffer;

int ratio = 4, startFrame, currentFrame = 1, lastRecorded = 0, recordTime = 100, biggest;

int captureType = ZOOMFACE;

int defaultFacePadding = 20, minFacePadding = 0, maxFacePadding = 500;
int facePadding = maxFacePadding;

int faceWidth, faceHeight, faceX, faceY;

float zoomSpeed = 10;
float zX = 0, zY = 0, zW, zH;

//change the length of this array to affect camera sensitivity
//and acuracy. Larger array = less false positives but less sensitivity.
PVector[] faceRecords = new PVector[2];
int faceRecordIndex = 0;

void setup() {
  String[] cameras = Capture.list();
  for (int i = 0; i < cameras.length; i++) {
    println(i + " " + cameras[i]);
  }

  if (debug) {
    //FOR TESTING
    String portName = Serial.list()[0];
    myPort = new Serial(this, portName, 9600);
    size(1280, 720);
    video = new Capture(this, width, height);
  } 
  else {
    //FOR LIVE
    println(Serial.list());
    String portName = Serial.list()[7];
    myPort = new Serial(this, portName, 9600);
    size(1280, 720);
    video = new Capture(this, width, height, "Logitech Camera #2", 30);
  }

  zW = width;
  zH = height;

  opencv = new OpenCV(this, width/ratio, height/ratio);
  buffer = createImage(width/ratio, height/ratio, RGB);
  faceBuffer = createGraphics(500, 500);
  faceBufferImg = createImage(faceBuffer.width, faceBuffer.height, RGB);

  zoomBuffer = createGraphics(width, height);
  zoomBufferImg = createImage(zoomBuffer.width, zoomBuffer.height, RGB);

  opencv.loadCascade("haarcascade_frontalface_alt2.xml");

  video.start();
}


void draw() {
  image(video, 0, 0);
  findFaces();

  if (recording && makeRecordings) {
    if (frameCount - startFrame < recordTime) {
      if (captureType == EDGE || captureType == WIDEFACE) {
        saveAFrame();
      } 
      else if (captureType == JUSTFACE) {
        savePartialFrame(defaultFacePadding);
      } 
      else if (captureType == ZOOMFACE) {
        saveZoomFrame();
      }
    } 
    else {
      recording = false;
      lastRecorded = frameCount;
      exportFramesToMP4(startFrame);
      zX = 0;
      zY = 0;
      zW = width;
      zH = height;
    }
  }
}

void captureEvent(Capture c) {
  c.read();
  
  //how frequently should we detect faces?
  if (frameCount % 1 == 0) {
    buffer.copy(c, 0, 0, c.width, c.height, 0, 0, width/ratio, height/ratio);
    opencv.loadImage(buffer);
  }
}

void saveAFrame() {
  saveFrame(String.format("data/frames/frame-%06d.tif", currentFrame));
  currentFrame ++;
}

void savePartialFrame(int padding) {
  if (faces.length > 0 && biggest >= 0 && biggest < faces.length) {
    faceBufferImg.copy(video, faces[biggest].x*ratio - padding, faces[biggest].y*ratio - padding, faces[biggest].height*ratio + padding*2, faces[biggest].height*ratio + padding*2, 0, 0, faceBuffer.width, faceBuffer.height);
    faceBuffer.beginDraw();
    faceBuffer.image(faceBufferImg, 0, 0);
    faceBuffer.save(String.format("data/frames/frame-%06d.tif", currentFrame));
    faceBuffer.endDraw();
    currentFrame ++;
  }
}

void saveZoomFrame() {
  if (faces.length > 0 && biggest >= 0 && biggest < faces.length) {
    zH -= zoomSpeed;
    zH = constrain(zH, faces[biggest].height * ratio, height);
    zW = (zH / height) * width;

    zY += zoomSpeed;
    zX += zoomSpeed;
    zX = constrain(zX, 0, faces[biggest].x * ratio - (zW - faces[biggest].width*ratio)/2);
    if (zX < 0) zX = 0;
    zY = constrain(zY, 0, faces[biggest].y * ratio);

    zoomBufferImg.copy(video, int(zX), int(zY), int(zW), int(zH), 0, 0, zoomBuffer.width, zoomBuffer.height);
    zoomBuffer.beginDraw();
    zoomBuffer.image(zoomBufferImg, 0, 0);
    zoomBuffer.save(String.format("data/frames/frame-%06d.tif", currentFrame));
    zoomBuffer.endDraw();
    currentFrame ++;

    if (drawLines || debug) {
      noFill();
      stroke(0, 0, 255);
      rect(zX, zY, zW, zH);
    }
  }
}

void exportFramesToMP4(int start) {
  //to save a movie:
  //ffmpeg -r 25 -start_number 84 -i screen-%04d.tif -c:v libx264 -r 30 -pix_fmt yuv420p out.mp4
  //OR, use my script: ./converter suspicious/data/ 302 justtesting

  //  String[] cmd = {
  //    "/usr/local/bin/ffmpeg", 
  //    "-r", "30", 
  //    "-start_number", str(start), 
  //    "-i", dataPath("") + "/frames/frame-%06d.tif", 
  //    "-c:v", "libx264", 
  //    "-r", "30", 
  //    "-pix_fmt", "yuv420p", 
  //    dataPath("export_" + (System.currentTimeMillis()/1000) + ".mp4")
  //    };

  String[] cmd = {
    sketchPath("converter"), 
    dataPath("") + "/", 
    str(1), 
    "" + (System.currentTimeMillis()/1000)
    };
    exec(cmd);
  println(cmd);
}

void exportFramesToGif(int start) {
  //to save a gif:
  //ffmpeg -f image2 -start_number 84 -i screen-%04d.tif -pix_fmt rgb24 out.gif
  String[] cmd = {
    "/usr/local/bin/ffmpeg", 
    "-f", "image2", 
    "-start_number", str(start), 
    "-i", dataPath("") + "/frames/frame-%06d.tif", 
    "-pix_fmt", "rgb24", 
    dataPath("export_" + (System.currentTimeMillis()/1000) + ".gif")
    };
    exec(cmd);
  println(cmd);
}

void center(int x, int y) {
  int centerX = width/2;
  int centerY = height/2;
  int dX = int((float(x) * float(ratio) / width)*100.0);
  int dY = int((float(y) * float(ratio) / height)*100.0);
  String command = str(dX) + "," + str(dY) + "!";

  if (captureType == EDGE) {
    if ((dX < 30 || dX > 70 || dY < 30 || dY > 70) && !recording && frameCount - lastRecorded > 100) {
      recording = true;
      startFrame = frameCount;
      currentFrame = 1;
    }
  } 
  else if (captureType == JUSTFACE || captureType == WIDEFACE || captureType == ZOOMFACE) {
    if (faces.length > 0 && !recording && frameCount - lastRecorded > 100) {
      recording = true;
      startFrame = frameCount;
      currentFrame = 1;
      facePadding = maxFacePadding;
      faceWidth = faces[biggest].width;
      faceHeight = faces[biggest].height;
    }
  }

  println(command);
  myPort.write(command);
}

void findFaces() {
  faces = opencv.detect();
  if (faces.length > 0) {
    biggest = 0;
    float biggestWidth = 0;

    for (int i = 0; i < faces.length; i++) {
      if (debug || drawLines) {
        noFill();
        stroke(0, 255, 0);
        strokeWeight(1);
        rect(faces[i].x * ratio, faces[i].y * ratio, faces[i].width * ratio, faces[i].height * ratio);
      }

      if (faces[i].width > biggestWidth) {
        biggestWidth = faces[i].width;
        biggest = i;
      }
    }

    if (debug || drawLines) {
      stroke(255, 0, 0);
      noFill();
      rect(faces[biggest].x * ratio, faces[biggest].y * ratio, faces[biggest].width * ratio, faces[biggest].height * ratio);
    }

    faceRecords[faceRecordIndex] = new PVector(faces[biggest].x, faces[biggest].y);
    faceRecordIndex ++;
    if (faceRecordIndex >= faceRecords.length) faceRecordIndex = 0;

    boolean shouldCenter = true;
    for (int i = 0; i < faceRecords.length; i ++) {
      if (faceRecords[i] != null && dist(faceRecords[i].x, faceRecords[i].y, faces[biggest].x, faces[biggest].y) > 50) {
        shouldCenter = false;
      }
    }
    println(faceRecords);

    if (shouldCenter) {
      center(faces[biggest].x + faces[biggest].width/2, faces[biggest].y + faces[biggest].height/2);
    }

    faceX = faces[biggest].x;
    faceY = faces[biggest].y;
  }
}

