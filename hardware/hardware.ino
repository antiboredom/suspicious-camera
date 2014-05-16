//accelstepper documentation at:
//http://www.airspayce.com/mikem/arduino/AccelStepper/
#include <AccelStepper.h>

AccelStepper horizontalStepper(1, 9, 8);
AccelStepper verticalStepper(1, 7, 6);

int minX = -200;
int maxX = 200;
int minY = -200;
int maxY = 200;

//camera is: Logitech HD Pro Webcam C920
//http://logitech-en-amr.custhelp.com/app/answers/detail/a_id/28927/section/troubleshoot/crid/405/lt_product_id/9442/tabs/1,3,2,4,5/cl/us,en
//field of view of camera is 78.8 - aspect ratio is 16:9
//http://4.bp.blogspot.com/-RSulTVMGSfs/UXU15YyZmjI/AAAAAAAACH8/cR17IgIpdqo/s1600/diagonal+fov.jpg
float hfieldOfView = 69.7;
float vfieldOfView = 39.2;

//how far can we be offcenter by?
int threshold = 5;

void setup() {
  Serial.begin(9600);

  horizontalStepper.setMaxSpeed(3600);
  horizontalStepper.setAcceleration(1200);
  horizontalStepper.moveTo(0);

  verticalStepper.setMaxSpeed(3600);
  verticalStepper.setAcceleration(1200);
  verticalStepper.moveTo(0);
}

void loop() {
  while (Serial.available() > 0) {
    int x = Serial.parseInt();
    int y = Serial.parseInt();
    if (Serial.read() == '!') {
      moveHead(x, y);
    }
  }

  horizontalStepper.run();
  verticalStepper.run();

}

void moveHead(int x, int y) {
  //  if (abs(50 - x) > threshold) {
  //    moveStepper(horizontalStepper, x, hfieldOfView, minX, maxX);
  //  }
  //
  //  if (abs(50 - y) > threshold) {
  //    //moveStepper(verticalStepper, y, vfieldOfView, minY, maxY);
  //  }


  //  int xpos = horizontalStepper.currentPosition();
  //  if (abs(50 - x) > 10) {
  //    if (x > 50) xpos += map(x, 50, 100, 10, 30);
  //    else xpos -= map(x, 0, 50, 10, 30);
  //    horizontalStepper.moveTo(xpos);
  //  }

  if (abs(50 - x) > threshold) {
    int currentXPos = horizontalStepper.currentPosition();
    float currentAngle = map(currentXPos, minX, maxX, -45, 45);
    float newAngle = hfieldOfView * float(x)/100 - hfieldOfView/2 + currentAngle;
    int xpos = (int)map(newAngle, -45, 45, minX, maxX);
    xpos = constrain(xpos, minX, maxX);
    horizontalStepper.moveTo(xpos);
  }

  if (abs(50 - y) > threshold) {
    int currentYPos = verticalStepper.currentPosition();
    float currentAngle = map(currentYPos, minY, maxY, -45, 45);
    float newAngle = vfieldOfView * float(y)/100 - vfieldOfView/2 + currentAngle;
    int ypos = (int)map(newAngle, -45, 45, minY, maxY);
    ypos = constrain(ypos, minY, maxY);
    verticalStepper.moveTo(ypos);
  }
  //convert pixel offset to degrees
  //int xpos = horizontalStepper.currentPosition();
  //xpos = xpos + x;
  //xpos = constrain(xpos, maxRight, maxLeft);
  //  if (abs(x) > 30) {
  //    x = constrain(x, maxRight, maxLeft);
  //    horizontalStepper.moveTo(x);
  //  } else {
  //    horizontalStepper.stop();
  //  }
}

void moveStepper(AccelStepper stepper, int pos, float fieldOfView, int minPos, int maxPos) {
  int currentPos = stepper.currentPosition();
  float currentAngle = map(currentPos, minPos, maxPos, -45, 45);
  float newAngle = fieldOfView * float(100-pos)/100 - fieldOfView/2 + currentAngle;
  int newPos = (int)map(newAngle, -45, 45, minPos, maxPos);
  stepper.moveTo(newPos);
}

void serialEvent() {
}










