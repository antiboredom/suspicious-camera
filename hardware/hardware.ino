//accelstepper documentation at:
//http://www.airspayce.com/mikem/arduino/AccelStepper/
#include <AccelStepper.h>

AccelStepper horizontalStepper(1, 9, 8);
AccelStepper verticalStepper(1, 7, 6);

int minX = -200;
int maxX = 200;
int minY = -200;
int maxY = 200;

int miA = -40;
int maA = 40;

//camera is: Logitech HD Pro Webcam C920
//http://logitech-en-amr.custhelp.com/app/answers/detail/a_id/28927/section/troubleshoot/crid/405/lt_product_id/9442/tabs/1,3,2,4,5/cl/us,en
//field of view of camera is 78.8 - aspect ratio is 16:9
//http://4.bp.blogspot.com/-RSulTVMGSfs/UXU15YyZmjI/AAAAAAAACH8/cR17IgIpdqo/s1600/diagonal+fov.jpg
float hfieldOfView = 69.7;
float vfieldOfView = 39.2;

//how far can we be offcenter by?
//int xThreshold = 10;
//int yThreshold = 15;
int xThreshold = 7;
int yThreshold = 12;

void setup() {
  Serial.begin(9600);

  horizontalStepper.setMaxSpeed(4600);
  horizontalStepper.setAcceleration(900);
  horizontalStepper.moveTo(0);

  verticalStepper.setMaxSpeed(4600);
  verticalStepper.setAcceleration(900);
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
  if (abs(50 - x) > xThreshold) {
    int currentXPos = horizontalStepper.currentPosition();
    float currentAngle = map(currentXPos, minX, maxX, miA, maA);
    float newAngle = hfieldOfView * float(100-x)/100 - hfieldOfView/2 + currentAngle;
    int xpos = (int)map(newAngle, miA, maA, minX, maxX);
    xpos = constrain(xpos, minX, maxX);
    horizontalStepper.moveTo(xpos);
  }

  if (abs(50 - y) > yThreshold) {
    int currentYPos = verticalStepper.currentPosition();
    float currentAngle = map(currentYPos, minY, maxY, miA, maA);
    float newAngle = vfieldOfView * float(y)/100 - vfieldOfView/2 + currentAngle;
    int ypos = (int)map(newAngle, miA, maA, minY, maxY);
    ypos = constrain(ypos, minY, maxY);
    verticalStepper.moveTo(ypos);
  }
}







