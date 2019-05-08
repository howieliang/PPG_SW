int SDNN_WINDOW = 16;
float[] dataSDNN = new float[SDNN_WINDOW];

void initSDNN() {
  dataSDNN = new float[SDNN_WINDOW];
}

float nextValueSDNN(float val) {
  appendArray(dataSDNN, val);
  return standardDeviation(dataSDNN);
}

ArrayList<Float> getSDNNList(ArrayList<Float> IBIList) {
  ArrayList<Float> sdnnList = new ArrayList<Float>();
  float lastIBI = 0;
  float currSDNN = 0;
  if (IBIList!=null) {
    initSDNN();
    for (int i = 0; i < IBIList.size(); i++) {
      float ibi = (float)IBIList.get(i);
      boolean flagAB = false; // abnormal beat
      float diff = abs(ibi-lastIBI);
      float diffRatio = (lastIBI == 0 ? 1: diff/lastIBI);
      if (diffRatio>ratio) {
        flagAB = true;
      }
      if (!flagAB) {
        currSDNN = nextValueSDNN(ibi);
        if (sdnnList.size()<SDNN_WINDOW) {
          sdnnList.add((float)0);
        } else {
          sdnnList.add(currSDNN);
        }
      }else{
        sdnnList.add(currSDNN);
      }
      lastIBI = ibi;
    }
  }
  return sdnnList;
}


float standardDeviation(float[] data) {

  float sum_data=0;
  float avg_data=0;
  float sum_quadata=0;
  float sd=0;

  for (int i=0; i<data.length; i=i+1) {
    sum_data = sum_data+data[i];
  }
  avg_data = sum_data/data.length;

  for (int i=0; i<data.length; i=i+1) {
    sum_quadata=sum_quadata+sq(data[i]-avg_data);
  }

  sd=sqrt(sum_quadata/data.length);
  return sd;
}
