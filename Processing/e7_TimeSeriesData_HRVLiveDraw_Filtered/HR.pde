int HR_WINDOW = 10;
float[] dataIBI = new float[HR_WINDOW];

void initHR() {
  dataIBI = new float[HR_WINDOW]; 
}

float nextValueHR(float val) {
  float totalIBI = 0;
  appendArray(dataIBI, val);
  for(int i = 0 ; i < dataIBI.length; i++){
    totalIBI += dataIBI[i];
  }
  return 60000./(totalIBI/(float)HR_WINDOW);
}
