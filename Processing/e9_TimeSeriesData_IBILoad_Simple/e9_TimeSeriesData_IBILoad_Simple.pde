//*********************************************
// Time-Series Physiological Signal Processing
// e9_TimeSeriesData_IBILoad
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

ArrayList<Float> HRList;
float currHR = 0;

ArrayList<Float> SDNNList;
float currSDNN = 0;

PrintWriter output;
boolean bSave = false;

ArrayList LoadIBIList;
ArrayList<Float> LoadSDNNList;
ArrayList<Float> LoadHRList;

//Filtering
int lastIBI = 0;
float ratio = 0.25;
float IBI_UB = 1500; //40 bpm
float IBI_LB = 400; //150 bpm

void setup() {
  size(500, 500);

  //Initiate the serial port
  for (int i = 0; i < Serial.list().length; i++) println("[", i, "]:", Serial.list()[i]);
  String portName = Serial.list()[Serial.list().length-1];//check the printed list
  //String portName = Serial.list()[0]; //For windows PC
  port = new Serial(this, portName, 115200);
  port.bufferUntil('\n'); // arduino ends each data packet with a carriage return 
  port.clear();           // flush the Serial buffer

  //Reset HR and SDNN Calculation for the Files
  LoadIBIList = loadIBIData("5-3-15-2-50.txt");
  LoadSDNNList = getSDNNList(LoadIBIList);
  LoadHRList = getHRList(LoadIBIList);

  //IBIList for LiveDrawing
  IBIList = new ArrayList<Float>();
  HRList = new ArrayList<Float>();
  SDNNList = new ArrayList<Float>();
  initHR();
  initSDNN();
}

void draw() {
  background(255);
  //set styles
  fill(255, 0, 0);
  //visualize the serial data
  float h = height/5;
  float scale = 1. * (float)round((map(mouseX, 0, width, 1, 5)));
  if (!bDrawOnly) {
    lineGraph(sensorHist, 0, 1023, 0, 0*h, width, h, color(255, 0, 0));
    lineGraph(beatHist, 0, 1, 0, 0*h, width, h, color(0, 0, 255));
    lineGraph(IBIHist, 0, 1500, 0, 1*h, width, h, color(255, 0, 255));//History of sensor data
    drawInfo(scale, h);
  }

  pushMatrix();
  translate(0, 3*h);
  drawLiveList(scale, h, IBIList, HRList, SDNNList);
  popMatrix();

  pushMatrix();
  translate(0, 4*h);
  drawLiveList(scale, h, LoadIBIList, LoadHRList, LoadSDNNList);
  popMatrix();

  if (bClear) {
    IBIList.clear();
    HRList.clear();
    SDNNList.clear();
    lastCapture = ts;
    bClear = false;
  }

  if (bSave) {
    saveIBIFile(month()+"-"+day()+"-"+hour()+"-"+minute()+"-"+second()+".txt");
    bSave = false;
  }
}

void drawInfo(float scale, float h) {
  fill(0);
  textAlign(RIGHT, CENTER);
  text("Press 'c' to restart capturing", width, 0.1*h);
  text("Press 'd' to hide the raw data", width, 0.2*h);
  text("Press 's' to save the data", width, 0.3*h);
  text("Move 'MouseX' to change time scale", width, 0.4*h);
  stroke(0);
  line(0, 1*h, width, 1*h);

  fill(0);
  textAlign(LEFT, CENTER);
  text("Last IBI: "+currIBI+" ms", 0, 1.1*h);
  text("IBI collected: "+IBIList.size()+"/"+maxFileSize, 0, 1.2*h);
  text("Time Lapsed: "+nf((float)(ts-lastCapture)/1000., 0, 1)+" (s)", 0, 1.3*h);
  stroke(0);
  line(0, 2*h, width, 2*h);
  fill(0);
  textAlign(LEFT, CENTER);
  text("Current IBI", 0, 2.1*h);
  text(0+"s", 0, 2.9*h);
  textAlign(RIGHT, CENTER);
  text(60*scale+"s", width, 2.9*h);
  line(0, 3*h, width, 3*h);
  fill(0);
  textAlign(LEFT, CENTER);
  //text("IBI_file:"+fileNameList.get(0), 0, 3.1*h);
  text(0+"s", 0, 3.9*h);
  textAlign(RIGHT, CENTER);
  text(60*scale+"s", width, 3.9*h);
  line(0, 4*h, width, 4*h);
}

void drawLiveList(float scale, float h, ArrayList<Float> IBIList, ArrayList<Float> HRList, ArrayList<Float> SDNNList) {
  if (IBIList!=null) {
    float lastX = 0;
    float lastY = 0;
    int visLength = min(IBIList.size(), min(HRList.size(), SDNNList.size()));
    for (int i = 0; i < visLength; i++) {
      float ibi = IBIList.get(i);
      float hr =  HRList.get(i);
      float sdnn = SDNNList.get(i);
      float x = map(ibi, 0, 60000*scale, 0, width); //60000ms = 1 min;
      float yIBI = map(ibi, 0, 1500, 0, h);
      float yHR = map(hr, 0, 120, 0, h);
      float ySDNN = map(sdnn, 0, 100, 0, h);

      if (ibi > 0) {
        stroke(0, 255, 255);
      } else {
        stroke(255, 0, 255);
        x = map(-ibi, 0, 60000*scale, 0, width); //60000ms = 1 min;
        yIBI = map(-ibi, 0, 1500, 0, h);
      }

      noStroke();
      if (ibi > 0) {
        fill(0, 255, 255);
      } else {
        fill(255, 0, 255);
      }
      ellipse(lastX, -yHR, 10/scale, 10/scale);

      noStroke();
      if (ibi > 0) {
        fill(0, 255, 0);
      } else {
        fill(255, 0, 255);
      }
      ellipse(lastX, -ySDNN, 10/scale, 10/scale);

      stroke(255, 0, 0);
      noFill();
      line(lastX, 0, lastX, -yIBI); 
      lastX+=x;
      lastY=yIBI;
    }
  }
}

void saveIBIFile(String fileName) {
  output = createWriter(dataPath("")+"/"+fileName);
  for (float d : IBIList) { 
    if (d>0) output.println(nf(d/1000., 1, 3));
    else output.println(nf(-d/1000., 1, 3));
  }
  output.flush(); // Writes the remaining data to the file
  output.close(); // Finishes the file
  println("File Saved: "+fileName);
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
          if (IBIList.size() < maxFileSize) {
            boolean flagAB = false; // abnormal beat
            //check ther filter
            float diff = (float)abs(currIBI-lastIBI);
            float diffRatio = (lastIBI == 0 ? 1: diff/(float)lastIBI);
            if (diffRatio>ratio && IBIList.size()>0) {
              flagAB = true;
            }
            if (!flagAB) {
              IBIList.add((float)currIBI); //add the currIBI to the IBIList
              currHR = nextValueHR((float)currIBI);
              if (HRList.size()<HR_WINDOW) {
                HRList.add((float)0);
              } else {
                HRList.add(currHR);
              }
              currSDNN = nextValueSDNN((float)currIBI);
              if (SDNNList.size()<SDNN_WINDOW) {
                SDNNList.add((float)0);
              } else {
                SDNNList.add(currSDNN);
              }
            } else {
              IBIList.add((float)-currIBI); //add the currIBI to the IBIList
              SDNNList.add(currSDNN);
              HRList.add(currHR);
            }
            lastIBI = currIBI;
          }
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
  if (key == 's' || key == 'S') {
    bSave = true;
  }
}

ArrayList<Float> loadIBIData(String fileName) {
  ArrayList<Float> ibiList = new ArrayList<Float>();
  String lines[] = loadStrings(fileName);
  if (lines!=null && fileName.charAt(0)!='.') {
    for (int i = 0; i < lines.length; i++) {
      ibiList.add(1000.*Float.parseFloat(lines[i])); //convert from s to ms
    }
  } else {
    println("No such file");
  }
  return ibiList;
}
