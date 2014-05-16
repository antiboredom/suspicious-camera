import gab.opencv.*;
import java.awt.Rectangle;
import processing.video.*;
import processing.serial.*;

Capture video;
OpenCV opencv;
int ratio = 4;
PImage buffer;
Serial myPort;  // Create object from Serial class
boolean recording = false;
int startFrame;
int lastRecorded = 0;
int recordTime = 70;
boolean debug = false;

void setup() {
  frameRate(30);
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



  opencv = new OpenCV(this, width/ratio, height/ratio);
  buffer = createImage(width/ratio, height/ratio, RGB);
  //display = createImage(width, height);
  //opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE);
  opencv.loadCascade("haarcascade_frontalface_alt2.xml");
  //opencv.loadCascade(OpenCV.CASCADE_PROFILEFACE);

  video.start();
}


void draw() {
  image(video, 0, 0);
  findFaces();

  if (recording) {
    if (frameCount - startFrame < recordTime) {
      saveAFrame();
      //thread("saveAFrame");
    } 
    else {
      recording = false;
      lastRecorded = frameCount;
      exportFramesToMP4(startFrame);
    }
  }
}

void captureEvent(Capture c) {
  c.read();
  if (frameCount % 2 == 0) {
    buffer.copy(c, 0, 0, c.width, c.height, 0, 0, width/ratio, height/ratio);
    opencv.loadImage(buffer);
  }
}

void saveAFrame() {
  saveFrame("data/frames/frame-######.tif");
}

void exportFramesToMP4(int start) {
  //to save a movie:
  //ffmpeg -r 25 -start_number 84 -i screen-%04d.tif -c:v libx264 -r 30 -pix_fmt yuv420p out.mp4
  String[] cmd = {
    "/usr/local/bin/ffmpeg", 
    "-r", "30", 
    "-start_number", str(start), 
    "-i", dataPath("") + "/frames/frame-%06d.tif", 
    "-c:v", "libx264", 
    "-r", "30", 
    "-pix_fmt", "yuv420p", 
    dataPath("export_" + str(start) + ".mp4")
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
    "-i", dataPath("") + "/frame-%06d.tif",
    "-pix_fmt", "rgb24",
    dataPath("export_" + str(start) + ".gif")
    };
  exec(cmd);
  println(cmd);
}

void center(int x, int y) {
  if (debug) {
    ellipse(x * ratio, y * ratio, 20, 20);
  }
  
  int centerX = width/2;
  int centerY = height/2;
  int dX = int((float(x) * float(ratio) / width)*100.0);
  int dY = int((float(y) * float(ratio) / height)*100.0);
  String command = str(dX) + "," + str(dY) + "!";

  if ((dX < 30 || dX > 70 || dY < 30 || dY > 70) && !recording && frameCount - lastRecorded > 100) {
    recording = true;
    startFrame = frameCount;
  }

  //println(command);
  myPort.write(command);
}

void findFaces() {
  Rectangle[] faces = opencv.detect();
  if (faces.length > 0) {
    int biggest = 0;
    float biggestWidth = 0;
    
    for (int i = 0; i < faces.length; i++) {
      if (debug) {
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

    if (debug) {
      stroke(255, 0, 0);
      rect(faces[biggest].x * ratio, faces[biggest].y * ratio, faces[biggest].width * ratio, faces[biggest].height * ratio);
    }

    //center the camera
    center(faces[biggest].x + faces[biggest].width/2, faces[biggest].y + faces[biggest].height/2);
  }
}

