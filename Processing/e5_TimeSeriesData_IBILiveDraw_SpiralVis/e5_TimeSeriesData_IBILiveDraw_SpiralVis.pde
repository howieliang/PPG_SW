//*********************************************
// Time-Series Physiological Signal Processing
// e5_TimeSeriesData_IBILiveDraw
// Rong-Hao Liang: r.liang@tue.nl
//*********************************************
//Before use, please make sure your Arduino has 1 sensor connected
//to the analog input, and SerialTx_A0D2.ino was uploaded. 

import processing.serial.*;
Serial port; 

int dataNum = 500; //number of data to show
int rawData = 0; //raw data from serial port

float[] sensorHist = new float[dataNum]; //history data to show

int beatData = 0; //raw data from serial port
float[] beatHist = new float[dataNum]; //history data to show

boolean beatDetected = false;

int ts = 0; //global timestamp (updated by the incoming data)
float[] IBIHist   = new float[dataNum];  //history interbeat intervals (IBI)
int currIBI = 0;
int lastBeatTime = 0;

ArrayList<Float> IBIList;
int maxFileSize = 1000;
int lastCapture = 0;
boolean bClear = false;
boolean bDrawOnly = false;
boolean bPictureIt = false;

void setup() {
  size(500, 500);

  //Initiate the serial port
  for (int i = 0; i < Serial.list().length; i++) println("[", i, "]:", Serial.list()[i]);
  String portName = Serial.list()[Serial.list().length-1];//check the printed list
  //String portName = Serial.list()[0]; //For windows PC
  port = new Serial(this, portName, 115200);
  port.bufferUntil('\n'); // arduino ends each data packet with a carriage return 
  port.clear();           // flush the Serial buffer

  //IBIList for LiveDrawing
  IBIList = new ArrayList<Float>();
}

void draw() {
  background(255);
  //set styles
  fill(255, 0, 0);
  //visualize the serial data
  float h = height/3;
  float scale = 1. * (float)round((map(mouseX, 0, width, 1, 5)));
  if (!bDrawOnly) {
    lineGraph(sensorHist, 0, 1023, 0, 0*h, width, h, color(255, 0, 0));
    lineGraph(beatHist, 0, 1, 0, 0*h, width, h, color(0, 0, 255));
    fill(0);
    textAlign(RIGHT, CENTER);
    text("Press 'c' to restart capturing", width, 0.1*h);
    text("Press 'd' to hide the raw data", width, 0.2*h);
    text("Move 'MouseX' to change time scale", width, 0.3*h);

    stroke(0);
    line(0, 1*h, width, 1*h);
    lineGraph(IBIHist, 0, 1500, 0, 1*h, width, h, color(255, 0, 255));//History of sensor data
    fill(0);
    textAlign(LEFT, CENTER);
    text("Last IBI: "+currIBI+" ms", 0, 1.1*h);
    text("IBI collected: "+IBIList.size()+"/"+maxFileSize, 0, 1.2*h);
    text("Time Lapsed: "+nf((float)(ts-lastCapture)/1000., 0, 1)+" (s)", 0, 1.3*h);
    stroke(0);
    line(0, 2*h, width, 2*h);
  }

  //Example spiralVis
  pushMatrix();
  translate(width/2, height/2);
  float H1 = map(mouseX, 0, width, 50, 150);
  float H2 = map(mouseY, 0, height, 10, 150);
  if (IBIList!=null) { 
    float tempT = 0;
    for (int i = 0; i < IBIList.size(); i++) {
      float ibi = IBIList.get(i);
      tempT+=ibi;
      if (i>0) {
        float last_ibi = IBIList.get(i-1);
        float y = map(ibi, 0, 1000, 0, H1);
        float last_y = map(last_ibi, 0, 1000, 0, H1);
        float offsetY = map(tempT, 0, 60000, 0, H2);
        float last_offsetY = map(tempT-ibi, 0, 60000, 0, H2);
        float deg = radians(map(tempT, 0, 60000, 180, -180));
        float lastdeg = radians(map(tempT-ibi, 0, 60000, 180, -180));
        float v0y = (offsetY)*cos(deg);
        float v0x = (offsetY)*sin(deg);
        float v1y = (last_offsetY)*cos(lastdeg);
        float v1x = (last_offsetY)*sin(lastdeg);
        float v2y = (last_y+last_offsetY)*cos(lastdeg);
        float v2x = (last_y+last_offsetY)*sin(lastdeg);
        float v3y = (y+offsetY)*cos(deg);
        float v3x = (y+offsetY)*sin(deg);
        noStroke();
        fill(255, 0, 0, map(constrain(ibi, 500, 1000), 500, 1000, 52, 128));
        beginShape();
        vertex(v0x, v0y);
        vertex(v1x, v1y);
        vertex(v2x, v2y);
        vertex(v3x, v3y);
        endShape(CLOSE);
        if (i==IBIList.size()-1 && !bDrawOnly) {
          noFill();
          stroke(52);
          line(0, 0, v0x, v0y);
          stroke(192);
          line(v0x, v0y, v0x+(H1)*sin(deg), v0y+(H1)*cos(deg));
        }
      }
    }
  }
  popMatrix();

  if (bClear) {
    IBIList.clear();
    lastCapture = ts;
    bClear = false;
  }
}

void serialEvent(Serial port) {   
  String inData = port.readStringUntil('\n');  // read the serial string until seeing a carriage return
  int dataIndex = -1;
  if (inData.charAt(0) == 'A') {  
    dataIndex = 0;
  }
  if (inData.charAt(0) == 'B') {  
    dataIndex = 1;
  }
  //data processing
  if (dataIndex==0) {
    rawData = int(trim(inData.substring(1))); //store the value
    appendArray(sensorHist, rawData); //store the data to history (for visualization)
    ts+=2; //update the timestamp
    return;
  }
  if (dataIndex==1) {
    beatData = int(trim(inData.substring(1))); //store the value
    if (!beatDetected) {
      if (beatData==1) { 
        beatDetected = true; 
        appendArray(beatHist, 1); //store the data to history (for visualization)
        if (lastBeatTime>0) {
          currIBI = ts-lastBeatTime;
          if (IBIList.size() < maxFileSize) IBIList.add((float)currIBI); //add the currIBI to the IBIList
        } 
        lastBeatTime = ts;
      } else {
        appendArray(beatHist, 0); //store the data to history (for visualization)
      }
    } else {
      if (beatData==0) beatDetected = false;
      appendArray(beatHist, 0); //store the data to history (for visualization)
    }
    appendArray(IBIHist, currIBI); //store the data to history (for visualization)
    return;
  }
}

//Append a value to a float[] array.
float[] appendArray (float[] _array, float _val) {
  float[] array = _array;
  float[] tempArray = new float[_array.length-1];
  arrayCopy(array, 1, tempArray, 0, tempArray.length);
  array[array.length-1] = _val;
  arrayCopy(tempArray, 0, array, 0, tempArray.length);
  return array;
}

//Draw a line graph to visualize the sensor stream
//lineGraph(float[] data, float lowerbound, float upperbound, float x, float y, float width, float height, color c)
void lineGraph(float[] data, float _l, float _u, float _x, float _y, float _w, float _h, color _c) {
  pushStyle();
  noFill();
  stroke(_c);
  float delta = _w/data.length;
  beginShape();
  for (float i : data) {
    float y = map(i, _l, _u, 0, _h);
    vertex(_x, _y+(_h-y));
    _x = _x + delta;
  }
  endShape();
  popStyle();
}

void keyPressed() {
  if (key == 'r' || key == 'R') {
    ts = 0;
    lastBeatTime = 0;
    currIBI = 0;
  }
  if (key == 'c' || key == 'C') {
    bClear = true;
  }
  if (key == 'd' || key == 'D') {
    bDrawOnly = (bDrawOnly? false: true);
  }
}
