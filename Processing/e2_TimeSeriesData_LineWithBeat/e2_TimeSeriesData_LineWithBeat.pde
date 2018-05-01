//*********************************************
// Time-Series Physiological Signal Processing
// e2_TimeSeriesData_LineWithBeat
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

void setup() {
  size(500, 500);

  //Initiate the serial port
  for (int i = 0; i < Serial.list().length; i++) println("[", i, "]:", Serial.list()[i]);
  String portName = Serial.list()[Serial.list().length-1];//check the printed list
  //String portName = Serial.list()[0]; //For windows PC
  port = new Serial(this, portName, 115200);
  port.bufferUntil('\n'); // arduino ends each data packet with a carriage return 
  port.clear();           // flush the Serial buffer
}

void draw() {
  background(255);
  //set styles
  fill(255, 0, 0);
  stroke(255, 0, 0);
  //visualize the serial data
  float y = map(rawData, 0, 1023, 0, height);
  lineGraph(sensorHist, 0, 1023, 0, 0, width, height, color(255, 0, 0));
  lineGraph(beatHist, 0, 2, 0, 0, width, height, color(0, 0, 255));
  ellipse(width, height-y, 10, 10);
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
    return;
  }
  if (dataIndex==1) {
    beatData = int(trim(inData.substring(1))); //store the value
    appendArray(beatHist, beatData); //store the data to history (for visualization)
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