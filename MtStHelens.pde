
// bounds for the x and y dimensions of the regular grid that the data are sampled on
int xDim = 240;
int yDim = 346;

// the gridded data are stored in these arrays in column-major order.  that means the entire
// x=0 column is listed first in the array, then the entire x=1 column, and so on.  this is
// a typical way to store data that conceptually fit within a 2D array in a regular 1D array.
// there are helper functions at the bottom of this file that let you access the data directly
// by (x, y) locations in the array, so you don't have to worry too much about this if you
// don't want.
PVector[] beforePoints;
PVector[] beforeNormals;
PVector[] afterPoints;
PVector[] afterNormals;
PVector[] midPoints; // New arrays to hold the interchange between before and after points;
PVector[] midNormals;

// can be switched with the arrow keys
int displayMode = 1;
int inter = 0;
int increment = 500;
boolean forward, stop = true; // controls whether the change is moving forward and if the animation is stopped

// each unit is 10 meters
// model centered around x,y and lowest z (height) value is 0
float xMin = -469.44;   
float xMax = 465.52792;
float yMin = -678.8792; 
float yMax = 674.9551;
float minElevation = 0;
float maxElevation = 199.51196;


void setup() {
  size(1280, 900, P3D);  // Use the P3D renderer for 3D graphics
  
  // load in .csv files
  Table beforeTable = loadTable("beforeGrid240x346.csv", "header"); 
  Table afterTable = loadTable("afterGrid240x346.csv", "header"); 
  
  //initialize Point Cloud data arrays
  beforePoints = new PVector[xDim*yDim];
  afterPoints = new PVector[xDim*yDim];
  midPoints = new PVector[xDim*yDim];
  
  // fill before and after arrays with PVector point cloud data points
  for (int i = 0; i < beforeTable.getRowCount(); i++) {
    beforePoints[i] = new PVector(beforeTable.getRow(i).getFloat("x"), 
                                  beforeTable.getRow(i).getFloat("y"), 
                                  beforeTable.getRow(i).getFloat("z"));
  }
  for (int i = 0; i < afterTable.getRowCount(); i++) {
    afterPoints[i] = new PVector(afterTable.getRow(i).getFloat("x"), 
                                 afterTable.getRow(i).getFloat("y"), 
                                 afterTable.getRow(i).getFloat("z"));
  } 

  
  //Initialize and fill arrays of the before and after data normals
  beforeNormals = new PVector[xDim*yDim];
  afterNormals = new PVector[xDim*yDim];
  midNormals = new PVector[xDim*yDim];
  
  calculateNormals();  // function defined on the bottom

}


void draw() {
  float minDist = 200;
  float maxDist = 1500;
  float cameraDistance = lerp(minDist, maxDist, float(mouseY)/height);
  
  camera(cameraDistance, cameraDistance, cameraDistance, 0, 0, 0, 0, 0, -1);
  
  rotateZ(radians(0.50*mouseX));
  directionalLight(255, 255, 255,  1, -0.5, -0.5);
  
  background(0);  // reset background to black
  stroke(255);    // set stroke to white
  
  if (displayMode == 1) {  // point cloud before  // Step One
    for(int i = 0; i < beforePoints.length; i++) {
     point( beforePoints[i].x, beforePoints[i].y, beforePoints[i].z);
    }
  } 
  
  else if (displayMode == 2) {  // point cloud after  // Step One
    for(int i = 0; i < afterPoints.length; i++) {
     point( afterPoints[i].x, afterPoints[i].y, afterPoints[i].z);
    }
  } 
  
  else if (displayMode == 3) {  // mesh before  // Step Three
    noStroke();
    fill(250);
    for(int y = 0; y < yDim-1; y++) {
      beginShape(TRIANGLE_STRIP);
      for(int x = 0; x < xDim; x++){             
        
        normal(getBeforeNormal(x, y+1).x, getBeforeNormal(x, y+1).y, getBeforeNormal(x, y+1).z );
        vertex(getBeforePoint(x, y+1).x, getBeforePoint(x, y+1).y, getBeforePoint(x, y+1).z);    
        
        normal(getBeforeNormal(x, y).x, getBeforeNormal(x, y).y, getBeforeNormal(x, y).z );
        vertex(getBeforePoint(x, y).x, getBeforePoint(x, y).y, getBeforePoint(x, y).z );               
      }
      endShape();
    } 
  } 
  
  else if (displayMode == 4) {  // mesh after  // Step Three
    noStroke();
    fill(250);
    for(int y = 0; y < yDim-1; y++) {
      beginShape(TRIANGLE_STRIP);
      for(int x = 0; x < xDim; x++){
        normal(getAfterNormal(x, y+1).x, getAfterNormal(x, y+1).y, getAfterNormal(x, y+1).z );
        vertex(getAfterPoint(x, y+1).x, getAfterPoint(x, y+1).y, getAfterPoint(x, y+1).z);        
        normal(getAfterNormal(x, y).x, getAfterNormal(x, y).y, getAfterNormal(x, y).z );
        vertex(getAfterPoint(x, y).x, getAfterPoint(x, y).y, getAfterPoint(x, y).z );       
      }      
      endShape();
    }
  } 
  
  else if (displayMode == 5) {  // lines from before to after  // Step Four 
    for(int i = 0; i < beforePoints.length; i++) {
      float heightDiff = afterPoints[i].z - beforePoints[i].z;
      if(heightDiff < 0) {
        stroke(255,0,0);
      }
      else {
        stroke(0,255,0);
      }
      
      line(beforePoints[i].x, beforePoints[i].y, beforePoints[i].z, afterPoints[i].x, afterPoints[i].y, afterPoints[i].z);
    }
  }
  
  else if (displayMode == 6) {  // your choice  // Step Five
  // With my implementation, I added the feature of changing between the before and after points over time. 
  // The before stage is represented in the dullish blue, while the after in dull red.
  // I purposely tried to choose dull yet similar colors in terms of RGB values so as not to pull attention away from the important
  // aspect of the difference in data points, yet contrasting enough so that the difference was clear.
  // When selected, the landscape will start with the before points and interpolate to the after points over time. The change can be stopped 
  // and started at any time with the press of the "TAB" button to pause the simulation if the differnces between 2 adjacent slices side 
  // by side wished to be compared.
    noStroke();
    for(int y = 0; y < yDim-1; y++) {
      beginShape(TRIANGLE_STRIP);
      for(int x = 0; x < xDim; x++){   
        if(midPoints[(x*yDim)+y] == beforePoints[(x*yDim)+y]) {
          fill(100,101,255);
        }
        else if(midPoints[(x*yDim)+y] == afterPoints[(x*yDim)+y] ){
         fill(255,101,100); 
        }
        
        normal(getMidNormal(x, y+1).x, getMidNormal(x, y+1).y, getMidNormal(x, y+1).z );
        vertex(getMidPoint(x, y+1).x, getMidPoint(x, y+1).y, getMidPoint(x, y+1).z);    
        
        normal(getMidNormal(x, y).x, getMidNormal(x, y).y, getMidNormal(x, y).z );
        vertex(getMidPoint(x, y).x, getMidPoint(x, y).y, getMidPoint(x, y).z );
                
      }
         endShape();
    } 
    
    if(forward) {
      if(inter + increment < midPoints.length) {
        for(int i = inter; i < inter+increment; i++){
          midPoints[i] = afterPoints[i];
          midNormals[i] = afterNormals[i];      
        }
        inter+= increment;
      }
      else
        forward = !forward;
    }
    else {
        if(inter - increment > 0) {
          for(int i = inter; i > inter-increment; i--){
            midPoints[i] = beforePoints[i];    
            midNormals[i] = beforeNormals[i];
          }
        inter-= increment;
        }
        else 
          forward = !forward;     
   }
  }
}


// Helper functions for accessing the point data by (x, y) location
PVector getBeforePoint(int x, int y) { 
  PVector beforeVec = beforePoints[(x*yDim)+y];
  return new PVector(beforeVec.x, beforeVec.y, beforeVec.z);
}

PVector getAfterPoint(int x, int y) {
  PVector afterVec = afterPoints[(x*yDim)+y];
  return new PVector(afterVec.x, afterVec.y, afterVec.z);
}

PVector getMidPoint(int x, int y) {
  PVector midVec = midPoints[(x*yDim)+y];
  return new PVector(midVec.x, midVec.y, midVec.z);
}


// Helper functions for accessing the normal data by (x, y) location
PVector getBeforeNormal(int x, int y) { 
  PVector beforeVec = beforeNormals[(x*yDim)+y];
  return new PVector(beforeVec.x, beforeVec.y, beforeVec.z);
}

PVector getAfterNormal(int x, int y) {
  PVector afterVec = afterNormals[(x*yDim)+y];
  return new PVector(afterVec.x, afterVec.y, afterVec.z);
}
PVector getMidNormal(int x, int y) {
  PVector midVec = midNormals[(x*yDim)+y];
  return new PVector(midVec.x, midVec.y, midVec.z);
}


void keyPressed() {
  if (key == '1') {
    displayMode = 1;
  }
  if (key == '2') {
    displayMode = 2;
  }
  if (key == '3') {
    displayMode = 3;
  }
  if (key == '4') {
    displayMode = 4;
  }
  if (key == '5') {
    displayMode = 5;
  }
  if (key == '6') {
    displayMode = 6;
    for(int k = 0; k < beforePoints.length; k++) {
      midPoints[k] = beforePoints[k];
      midNormals[k] = beforeNormals[k];
    }

    inter = 0;
    forward = true;
  }
  if(key == TAB) {
    if(stop) {
    increment = 0;
    stop = !stop;
    }
    else{
      increment = 500;
      stop = !stop;
    }
  }
}


// Utility routine for calculating the normals of the triangle mash from vertex locations
void calculateNormals() {
  int normalStep = 6;
  for (int x = 0; x < xDim; x+=1) {
    for(int y = 0; y < yDim; y+=1) {
      PVector current = beforePoints[(x*yDim)+y]; //before(x,y);
      PVector north = new PVector(current.x, current.y, current.z);
      PVector south = new PVector(current.x, current.y, current.z);
      PVector west = new PVector(current.x, current.y, current.z);
      PVector east = new PVector(current.x, current.y, current.z);
      
      if (x-normalStep >= 0) {
        PVector w = beforePoints[((x-normalStep)*yDim)+y]; //before(x-normalStep,y);
        west = new PVector(w.x,w.y,w.z);
      }
      if (x+normalStep < xDim) {
        PVector e = beforePoints[((x+normalStep)*yDim)+y]; //before(x+normalStep,y);
        east = new PVector(e.x,e.y,e.z);
      }
      if (y-normalStep >= 0) {
        PVector s = beforePoints[(x*yDim)+(y-normalStep)]; //before(x,y-normalStep);
        south = new PVector(s.x,s.y,s.z);
      }
      if (y+normalStep < yDim) {
        PVector n = beforePoints[(x*yDim)+(y+normalStep)]; //before(x,y+normalStep);
        north = new PVector(n.x,n.y,n.z);
      }
      
      PVector eastVec = PVector.sub(east,west);
      PVector northVec = PVector.sub(north,south);
      eastVec.normalize();
      northVec.normalize();
      
      PVector norm = eastVec.cross(northVec);
      norm.normalize();
      beforeNormals[(x*yDim)+y] = norm; //new PVector(0,0,1);
    }
  }
  for (int x = 0; x < xDim; x+=1) {
    for(int y = 0; y < yDim; y+=1) {
      PVector current = afterPoints[(x*yDim)+y]; //before(x,y);
      PVector north = new PVector(current.x, current.y, current.z);
      PVector south = new PVector(current.x, current.y, current.z);
      PVector west = new PVector(current.x, current.y, current.z);
      PVector east = new PVector(current.x, current.y, current.z);
      
      if (x-normalStep >= 0) {
        PVector w = afterPoints[((x-normalStep)*yDim)+y]; //before(x-normalStep,y);
        west = new PVector(w.x,w.y,w.z);
      }
      if (x+normalStep < xDim) {
        PVector e = afterPoints[((x+normalStep)*yDim)+y]; //before(x+normalStep,y);
        east = new PVector(e.x,e.y,e.z);
      }
      if (y-normalStep >= 0) {
        PVector s = afterPoints[(x*yDim)+(y-normalStep)]; //before(x,y-normalStep);
        south = new PVector(s.x,s.y,s.z);
      }
      if (y+normalStep < yDim) {
        PVector n = afterPoints[(x*yDim)+(y+normalStep)]; //before(x,y+normalStep);
        north = new PVector(n.x,n.y,n.z);
      }
      
      PVector eastVec = PVector.sub(east,west);
      PVector northVec = PVector.sub(north,south);
      eastVec.normalize();
      northVec.normalize();
      
      PVector norm = eastVec.cross(northVec);
      norm.normalize();
      afterNormals[(x*yDim)+y] = norm; //new PVector(0,0,1);
    }
  }
}
