int HR_WINDOW = 10;
float[] dataIBI = new float[HR_WINDOW];

void initHR() {
  dataIBI = new float[HR_WINDOW];
}

ArrayList<Float> getHRList(ArrayList<Float> IBIList) {
  ArrayList<Float> hrList = new ArrayList<Float>();
  float lastIBI = 0;
  float currHR = 0;
  if (IBIList!=null) {
    initHR();
    for (int i = 0; i < IBIList.size(); i++) {
      float ibi = (float)IBIList.get(i);
      boolean flagAB = false; // abnormal beat
      float diff = abs(ibi-lastIBI);
      float diffRatio = (lastIBI == 0 ? 1: diff/(float)lastIBI);
      if (diffRatio>ratio) {
        flagAB = true;
      }
      if (!flagAB) {
        currHR = nextValueHR(ibi);
        if (hrList.size()<HR_WINDOW) {
          hrList.add((float)0);
        } else {
          hrList.add(currHR);
        }
      }else{
        hrList.add(currHR);
      }
      lastIBI = ibi;
    }
  }
  return hrList;
}

float nextValueHR(float val) {
  float totalIBI = 0;
  appendArray(dataIBI, val);
  for (int i = 0; i < dataIBI.length; i++) {
    totalIBI += dataIBI[i];
  }
  return 60000./(totalIBI/(float)HR_WINDOW);
}
