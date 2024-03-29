// 2019-10-13, Mike Stebbins, mstebbins.com
//
// Just like the game PickIt (from Discovery Toys, sometime in the late 80's), you have 5 sticks in a configuration. You can move only move stick 
// to a new position, and they all must remain connected. This starts at a straight horizontal line, then looks for a stick with a free end and 
// places it at a node where it can go, while fulfilling the criteria. 
// The first check is the number of unique nodes over all the segments. Most of the time 6 or fewer unique nodes means that they are all connected,
// except for a box (4 sticks) and 1 other stick floating somewhere. So, with 6 or fewer unique nodes, the algo then checks to see if any one 
// stick has no connections. If all successful, it draws that new configuration, and then repeats.
//
// TODO:
// - Figure out how to add a transition state, where the stick moving disappears at it's current spot and simultaneously slowly appears at the new
// - make that a sub-loop in draw, and change the On/Off state to include a transition level with those two segments
//
// Below, segment (sticks) as letters, and node numbers at each end:
//      5 f  6 g  7 h  8 
//      m    n    p    q
// 1 a  2 b 13 c 14 d  3 e  4
//      r    s    t    u
//      9 j 10 k 11 l 12
//
// Below, each segment by it's number:
//      -6-   -7-   -8-
//     12   13   14   15
//  -1-  -2-  -3-  -4-  -5- 
//     16   17   18   19
//      -9-  -10-  -11- 

// User Input stuff
boolean savePics = false;

int segLength = 128;
int spc = 22;
//int thisWide = 1280;  // also need to set equivalent values below
int thisWide = 720;
int thisHigh = 720;
int thick = 14;

// Set-up some variables
boolean currentlyTransitioning = false;
boolean[] onOrOff = new boolean[18];
boolean proceed = false;
boolean firstRun = true;
int[] activeSegments = new int[18];
int[] inActiveSegments = new int[18];
int[] noNeighbors = new int[18];
int[] activeNodes = new int[36];
int[] freeNodes = new int[36];
int moveFrom;
int moveTo;
IntList uniqueNodes;
IntList uniqueNodes2;

// Calculate the XY location of each stick's end nodes
int X13 = thisWide/2 - segLength/2;
int X14 = thisWide/2 + segLength/2;
int X2  = X13 - segLength;
int X1  = X2 - segLength;
int X3  = X14 + segLength;
int X4  = X3 + segLength;
int X5  = X2;
int X9  = X2;
int X6  = X13;
int X10 = X13;
int X7  = X14;
int X11 = X14;
int X8  = X3;
int X12 = X3;
int Y1  = thisHigh/2;
int Y2  = Y1;
int Y13 = Y1;
int Y14 = Y1;
int Y3  = Y1;
int Y4  = Y1;
int Y5  = Y1 - segLength;
int Y6  = Y5;
int Y7  = Y5;
int Y8  = Y5;
int Y9  = Y1 + segLength;
int Y10 = Y9;
int Y11 = Y9;
int Y12 = Y9;

// each array in the array is {segment number, node A, node B}
int[][] segmentNodes = { 
  {1, 1, 2}, 
  {2, 2, 13}, 
  {3, 13, 14},
  {4, 14, 3},
  {5, 3, 4},
  {6, 5, 6},
  {7, 6, 7},
  {8, 7, 8},
  {9, 9, 10},
  {10, 10, 11},
  {11, 11, 12},
  {12, 2, 5},
  {13, 13, 6},
  {14, 14, 7},
  {15, 3, 8},
  {16, 2, 9},
  {17, 13, 10},
  {18, 14, 11},
  {19, 3, 12} } ;

// neighboring segments for each segment, {segment in questions, neighbor A, neighbor B, neighbor C, ....}  
int[][] segmentNeighbors = { 
  { 1,  2, 12, 16}, 
  { 2,  1, 12, 16, 13, 17, 3},
  { 3,  2, 13, 17, 14, 18, 4},
  { 4,  3, 14, 18, 15, 19, 5},
  { 5,  4, 15, 19},
  { 6, 12, 13,  7},
  { 7,  6, 13, 14,  8},
  { 8,  7, 14, 15},
  { 9, 16, 17, 10},
  {10,  9, 17, 18, 11},
  {11, 10, 18, 19},
  {12,  1,  2,  6, 16},
  {13,  2,  6,  7,  3, 17},
  {14,  3,  7,  8,  4, 18},
  {15,  4,  8,  5, 19},
  {16,  1,  2, 12,  9},
  {17,  9, 10,  2,  3, 13},
  {18, 10, 11,  3,  4, 14},
  {19, 11,  4,  5, 15}      };
  
//----------------------------------------------------------------------------------------------------------------------
void setup() {
  //size(1280, 720);
  size(720, 720);
  background(0);
  //randomSeed(0);
  strokeWeight(thick);
  strokeCap(ROUND);
  stroke(255, 255, 255);
  initialize();
  //noLoop();
}

//----------------------------------------------------------------------------------------------------------------------
void draw() {
  background(0);
  if (firstRun == false)  {
    proceed = false;
    findActiveSegments();
    findInActiveSegments();
    while (proceed == false)  {
      tryMovingOne();
    }
  }
  else  {
    firstRun = false;
  }
  //if (currentlyTransitioning == false)  {
  //  drawSegments();
  //  delay(800);
  //  currentlyTransitioning = true;
  //}
  //else  {
  //  drawSegmentsTrans();
  //  delay(10);
  //}
  drawSegments();
  delay(500);

  if (savePics == true)  {
    saveFrame("number-######.png");
  }
  println("-------------------------------------");
}

//----------------------------------------------------------------------------------------------------------------------
void drawSegmentsTrans()  {
  findActiveSegments();
//TODO: WORK SOME MAGIC HERE
// FIGURE OUT HOW TO GRAB ACTIVE SEGMENTS, AND MAKE TO/FROM TRANSPARENT TO VARYING DEGREES, THEN DRAW SEGMENTS
}



//----------------------------------------------------------------------------------------------------------------------
void findActiveSegments()  {
  for (int j = 0; j < activeSegments.length; j++)  {
    activeSegments[j] = 0;
  }
  int tempIndex = 0;
  for (int i = 0; i < onOrOff.length; i++)  {
    if (onOrOff[i] == true)  {
     activeSegments[tempIndex] = (i+1);
     tempIndex++;
   }
 }
 printAnArray("activeSegments = ",activeSegments);
}

//------------------------------------------------------------------------
void findUniqueActiveNodes()  {
  uniqueNodes = new IntList();
  for (int i = 0; i < activeNodes.length; i++ )  {
    if (activeNodes[i] > 0)  {
      uniqueNodes.append(activeNodes[i]);
    }
  }
  uniqueNodes.sort();
  
  println();
  print("uniqueNodes = ");
  for (int i = 0; i < uniqueNodes.size(); i++)  {
    print(uniqueNodes.get(i));
    print(", ");
  }
  
  uniqueNodes2 = new IntList();
  for (int i = 0; i < (uniqueNodes.size()); i++ )  {
    int temp = uniqueNodes.get(i);
    if (uniqueNodes2.hasValue(temp) == false)  {
      uniqueNodes2.append(temp);
    }
  }
  println();
  print("uniqueNodes2 = ");
  for (int i = 0; i < uniqueNodes2.size(); i++)  {
    print(uniqueNodes2.get(i));
    print(", ");
  }
  if (uniqueNodes2.size() > 6)  {
    proceed = false;
  }
  else  {
    proceed = true;
  }
  println();
  println("proceed = ",proceed);
}

//------------------------------------------------------------------------
void findInActiveSegments()  {
  for (int j = 0; j < inActiveSegments.length; j++)  {
    inActiveSegments[j] = 0;
  }
  int tempIndex = 0;
  for (int i = 0; i < onOrOff.length; i++)  {
    if (onOrOff[i] == false)  {
     inActiveSegments[tempIndex] = (i+1);
     tempIndex++;
   }
 }
 //printAnArray("inActiveSegments = ",inActiveSegments);  
}

//------------------------------------------------------------------------
void tryMovingOne()  {
  proceed = false;
  int[] onlyActiveSegments = {};
  int[] onlyInActiveSegments = {};
  for (int i = 0; i < activeSegments.length; i++)  {
    if (activeSegments[i] != 0)  {
      onlyActiveSegments = append(onlyActiveSegments,activeSegments[i]);
    }
  }
  for (int i = 0; i < inActiveSegments.length; i++)  {
    if (inActiveSegments[i] != 0)  {
      onlyInActiveSegments = append(onlyInActiveSegments,inActiveSegments[i]);
    }      
  }
  //printAnArray("onlyActiveSegments = ",onlyActiveSegments);  
  //printAnArray("onlyInActiveSegments = ",onlyInActiveSegments);  
  
  // RANDOMLY CHOOSE ONE OF THE ACTIVE SEGMENTS TO MOVE
  int segmentToMoveFrom = onlyActiveSegments[(int)random(onlyActiveSegments.length)];
  
  println();
  println("segment to move from = ", segmentToMoveFrom);
  
  // RANDOMLY CHOOSE ONE OF THE INACTIVE LOCATIONS TO MOVE IT TO
  int segmentToMoveTo = onlyInActiveSegments[(int)random(onlyInActiveSegments.length)];
  
  println("segment to move to = ", segmentToMoveTo);
  
  int[] tempOnlyActiveSegments = {};
  tempOnlyActiveSegments = append(tempOnlyActiveSegments,segmentToMoveTo);
  
  for (int i = 0; i < onlyActiveSegments.length; i++)  {
    if (onlyActiveSegments[i] != segmentToMoveFrom)  {
      tempOnlyActiveSegments = append(tempOnlyActiveSegments,onlyActiveSegments[i]);
    }
  }
  printAnArray("tempOnlyActiveSeg = ",tempOnlyActiveSegments); 

  findActiveNodes(tempOnlyActiveSegments);
  findUniqueActiveNodes();

  if (uniqueNodes2.size() < 7)  {
    if (connectedOrNot(tempOnlyActiveSegments) == true)  {
      proceed = true;
      generateOnsAndOffs(tempOnlyActiveSegments);
      moveFrom = segmentToMoveFrom;
      moveTo = segmentToMoveTo;
    }
    else  {
      proceed = false;
    }
  }
  else  {
    proceed = false;
  }
}

//------------------------------------------------------------------------
boolean connectedOrNot(int inputSegmentArray[])  {
  boolean keepGoing = true;
  //set the result to true, we'll make it false if any one of these doesn't find a neighbor match in the input array
  boolean result = true;

  // for each member of the input array
  for (int i = 0; i < inputSegmentArray.length; i++)  {
    if (keepGoing == false)  {
      break;
    }
  else  {
  
  //first build an array of every member of the input array except the one we're iterating on above
  int[] restOfArray = {};
    for (int j = 0; j < inputSegmentArray.length; j++)  {
      if (inputSegmentArray[j] != inputSegmentArray[i])  {
        restOfArray = append(restOfArray,inputSegmentArray[j]);
      }
    }
    //printAnArray("restOfArray = ",restOfArray);
    // then, find all the potential neighbors of this member of the input array
    int[] tempNeighbors = segmentNeighbors[(inputSegmentArray[i] - 1)];
    //printAnArray("tempNeighbors = ",tempNeighbors);
    
    // go through each member of the this inputarray values, neighbors, and see if matches any values in the other member array
    // if there is a match, continue on. if there isn't a match, then stop (you've found an "island" segment
    int matches = 0;
    for (int k = 0; k < tempNeighbors.length; k++)  {
      for (int l = 0; l < restOfArray.length; l++)  {
        //println("matches = ",matches);
        if (tempNeighbors[k] == restOfArray[l])  {
          matches++;   
        }
      }
    }
    //println();
    //println("matches = ",matches);
    if (matches == 0)  {
      result = false;
      keepGoing = false;
      //println();
      //println("keepGoing = ",keepGoing);
    }

  //println();
  //println("result = ",result);
  }
  if (result == true)  {
    proceed = true; 
    generateOnsAndOffs(inputSegmentArray);
  }
}
  return result;
}

//------------------------------------------------------------------------
void findActiveNodes(int tempOnlyActiveSegments[])  {
    for (int j = 0; j < activeNodes.length; j++)  {
    activeNodes[j] = 0;
  }

  int tempIndex = 0;
  for (int i = 0; i < tempOnlyActiveSegments.length; i++)  {
    if (tempOnlyActiveSegments[i] > 0)  {
      int activeSegmentNumber = tempOnlyActiveSegments[i] - 1;
      int tempNode1 = segmentNodes[activeSegmentNumber][1];
      int tempNode2 = segmentNodes[activeSegmentNumber][2]; 
      activeNodes[tempIndex] = tempNode1;
      activeNodes[(tempIndex + 1)] = tempNode2;
      tempIndex++;
      tempIndex++;
   }
 }
 printAnArray("activeNodes = ",activeNodes);
}

//------------------------------------------------------------------------
void generateOnsAndOffs (int[] input)  {
   for (int i = 0; i < onOrOff.length; i++)  {
    onOrOff[i] = boolean (0);
  }
  for (int i = 0; i < onOrOff.length; i++)  {
    for (int j = 0; j < input.length; j++)  {
      int temp = (input[j]) - 1;
      onOrOff[temp] = boolean (1);
    }
  }
}

//------------------------------------------------------------------------
void printAnArray(String name, int input[])  {
  println();
  print(name);
  for (int i = 0; i < input.length; i++ )  {
   print(input[i]);
   print(", ");
 }
}

//------------------------------------------------------------------------
void generateRandoms() {
  for (int i = 0; i < onOrOff.length; i++) {
    onOrOff[i] = randomBool();
  }
}

//------------------------------------------------------------------------
void initialize() {
  for (int i = 1; i < (onOrOff.length + 1); i++) {
    if ((i==1) || (i==2) || (i==3) || (i==4) || (i==5)) {
    //if ((i==3) || (i==1) || (i==2) || (i==12) || (i==16)) {
      onOrOff[i-1] = boolean (1);
    }
    else {
      onOrOff[i-1] = boolean (0);
    }      
  }
}

//------------------------------------------------------------------------
boolean randomBool() {
  return random(1) > .5;
}

//------------------------------------------------------------------------
void drawSegments()  {
  for (int j = 0; j < onOrOff.length; j++ )  {
    println();
    print(onOrOff[j]);
    print(", ");
  }  
  
  for (int i = 0; i < onOrOff.length; i++ )  {
    if (onOrOff[i] == true)  {
      int temp = i + 1;
      drawLine(temp, 255);
      println(temp);
    }
  }
}
    
  //if (onOrOff[0] == true) {
  //  drawA(); 
  //}
  //if (onOrOff[1] == true) { 
  //  drawB(); 
  //}
  //if (onOrOff[2] == true) { 
  //  drawC(); 
  //}
  //if (onOrOff[3] == true) { 
  //  drawD();
  //}
  //if (onOrOff[4] == true) { 
  //  drawE();
  //}
  //if (onOrOff[5] == true) { 
  //  drawF();
  //}
  //if (onOrOff[6] == true) { 
  //  drawG();
  //}
  //if (onOrOff[7] == true) {
  //  drawH();
  //}
  //if (onOrOff[8] == true) {
  //  drawJ();
  //}
  //if (onOrOff[9] == true) {
  //  drawK();
  //}
  //if (onOrOff[10] == true) {
  //  drawL();
  //}
  //if (onOrOff[11] == true) {
  //  drawM();
  //}
  //if (onOrOff[12] == true) {
  //  drawN();
  //}
  //if (onOrOff[13] == true) {
  //  drawP();
  //}
  //if (onOrOff[14] == true) {
  //  drawQ();
  //}
  //if (onOrOff[15] == true) {
  //  drawR();
  //}
  //if (onOrOff[16] == true) {
  //  drawS();
  //}
  //if (onOrOff[17] == true) {
  //  drawT();
  //}

//------------------------------------------------------------------------
void drawLine(int segNumber, int opacity) {
 //stroke(255,255,255,opacity);
 switch(segNumber)  {
   case 1:
     line(X1+spc, Y1, X2-spc, Y2);
     break;
   case 2:
     line(X2+spc, Y2, X13-spc, Y13);
     break;
   case 3:
     line(X13+spc, Y13, X14-spc, Y14);
     break;
   case 4:
     line(X14+spc, Y14, X3-spc, Y3);
     break;     
   case 5:
     line(X3+spc, Y3, X4-spc, Y4);
     break;     
   case 6:
     line(X5+spc, Y5, X6-spc, Y6);
     break;     
   case 7:
     line(X6+spc, Y6, X7-spc, Y7);
     break;     
   case 8:
     line(X7+spc, Y7, X8-spc, Y8);
     break;    
   case 9:
     line(X9+spc, Y9, X10-spc, Y10);
     break;     
   case 10:
     line(X10+spc, Y10, X11-spc, Y11);
     break;     
   case 11:
     line(X11+spc, Y11, X12-spc, Y12);
     break;     
   case 12:
     line(X2, Y2-spc, X5, Y5+spc);
     break;     
   case 13:
     line(X13, Y13-spc, X6, Y6+spc);
     break;     
   case 14:
     line(X14, Y14-spc, X7, Y7+spc);
     break;     
   case 15:
     line(X3, Y3-spc, X8, Y8+spc);
     break;     
   case 16:
     line(X2, Y2+spc, X9, Y9-spc);
     break;     
   case 17:
     line(X13, Y13+spc, X10, Y10-spc);
     break;     
   case 18:
     line(X14, Y14+spc, X11, Y11-spc);
     break;     
   case 19:
     line(X3, Y3+spc, X12, Y12-spc);
     break;     
   }
}

//------------------------------------------------------------------------
void drawA() {
  line(X1+spc, Y1, X2-spc, Y2);
}
void drawB() {
  line(X2+spc, Y2, X13-spc, Y13);
}
void drawC() {
  line(X13+spc, Y13, X14-spc, Y14);
}
void drawD() {
  line(X14+spc, Y14, X3-spc, Y3);
}
void drawE() {
  line(X3+spc, Y3, X4-spc, Y4);
}
void drawF() {
  line(X5+spc, Y5, X6-spc, Y6);
}
void drawG() {
  line(X6+spc, Y6, X7-spc, Y7);
}
void drawH() {
  line(X7+spc, Y7, X8-spc, Y8);
}
void drawJ() {
  line(X9+spc, Y9, X10-spc, Y10);
}
void drawK() {
  line(X10+spc, Y10, X11-spc, Y11);
}
void drawL() {
  line(X11+spc, Y11, X12-spc, Y12);
}
void drawM() {
  line(X2, Y2-spc, X5, Y5+spc);
}
void drawN() {
  line(X13, Y13-spc, X6, Y6+spc);
}
void drawP() {
  line(X14, Y14-spc, X7, Y7+spc);
}
void drawQ() {
  line(X3, Y3-spc, X8, Y8+spc);
}
void drawR() {
  line(X2, Y2+spc, X9, Y9-spc);
}
void drawS() {
  line(X13, Y13+spc, X10, Y10-spc);
}
void drawT() {
  line(X14, Y14+spc, X11, Y11-spc);
}
void drawU() {
  line(X3, Y3+spc, X12, Y12-spc);
}
//------------------------------------------------------------------------
