//*********************************************
// Time-Series Physiological Signal Processing
// e0_TimeSeriesData_SerialRx
// Rong-Hao Liang: r.liang@tue.nl
//*********************************************
//Before use, please make sure your Arduino has 1 sensor connected
//to the analog input, and SerialTx_A0D2.ino was uploaded. 

import processing.serial.*;
Serial port; 

int rawData = 0; //raw data from serial port

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
  fill(255,0,0);
  stroke(255,0,0);
  //visualize the serial data
  float y = map(rawData, 0, 1023, 0, height);
  line(0,height-y,width,height-y);
  ellipse(width,height-y,50,50);
}

void serialEvent(Serial port) {   
  String inData = port.readStringUntil('\n');  // read the serial string until seeing a carriage return
  int dataIndex = -1;
    if (inData.charAt(0) == 'A') {  
      dataIndex = 0;
    }
    //data processing
    if (dataIndex>=0) {
      rawData = int(trim(inData.substring(1))); //store the value
      println(rawData);
      return;
    }
}