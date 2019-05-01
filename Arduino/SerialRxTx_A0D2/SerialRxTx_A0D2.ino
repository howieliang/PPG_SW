//*********************************************
// Time-Series Physiological Signal Processing
// SerialRxTx_A0.ino
// Rong-Hao Liang: r.liang@tue.nl
//*********************************************
//Before use, make sure your Arduino has 1 sensor connected to A0

#define MICRO_S 2000 //500Hz = 1M/MICRO_S;

int data = 0;
long timer = micros(); //timer
int ledOn = 0;

int beat = 0;

void setup() {// put your setup code here, to run once:
  Serial.begin(115200); //initialize a serial port at a 115200 baud rate.
  pinMode(LED_BUILTIN, OUTPUT); //set the built-in LED to output
}

void loop() {// put your main code here, to run repeatedly:
  if (micros() - timer > MICRO_S) { //Timer: send sensor data in every 2ms
    timer = micros();
    getDataFromProcessing(); //Receive before sending out the signals
    Serial.flush(); //Flush the serial buffer
    data = analogRead(A0); //get the analog reading
    sendDataToProcessing('A', data); //Put the data into buffer to sent it out later.
    beat = digitalRead(2);
    sendDataToProcessing('B', beat); //Put the beat into buffer to sent it out later.
  }
}

void getDataFromProcessing() {
  while (Serial.available()) {
    char inChar = (char)Serial.read();
    if (inChar == 'a') { //when an 'a' charactor is received.
      ledOn = 1 - ledOn;
      digitalWrite(LED_BUILTIN, ledOn); //turn on the built in LED on Arduino Uno 
    }
  }
}

void sendDataToProcessing(char symbol, int data) {
  Serial.print(symbol);  // symbol prefix of data type
  Serial.println(data);  // the integer data with a carriage return
}
