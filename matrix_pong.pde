//Include LED control
#include "LedControl.h"
//Include header to handle text output
#include "font.h"

//New instance of LedControl. d12 = DataIn(1), d11 = CLK(13), 10 = LOAD(12)
LedControl lc=LedControl(12,11,10,1);

//Regulate ball speed
int ballDelayLimit = 500;
int ballDelay = 0;

//Controller Analog input pin
int controller = 0;

//Define byte-map for bat
byte bat = B11100000;

int cval = 0;
int pos = 0;
float epos = 2;
float eskill = 1;
float br = 4;
float bc = 2;
float brr = 1;
float bcc = 1;

//Scores, 0 = you, 1 = enemy
int score[2] = {0, 0};
boolean gameOver = false;

//Setup code
void setup() {
  //Wake up the driver IC
  lc.shutdown(0, false);

  //Set a medium brightness for the LEDs
  lc.setIntensity(0, 8);

  //Clear the display
  lc.clearDisplay(0);

  //Seed random number generator
  randomSeed(analogRead(0));
}


//Game code
void loop(){
  if(gameOver){
    animExplode();
    //Run endgame sequence
    if(score[0] < 3 && score[1] < 3){
      showScores();
    }else{
      showScores();
      endGame();
    }

    //Reset game
    br = (int)random(2, 5);
    bc = (int)random(2, 5);
    brr = 1;
    bcc = 1;
    eskill = 1;
    gameOver = false;
    ballDelayLimit = 500;
    delay(1000);
    lc.clearDisplay(0);
  }else{
    //Read controller value
    cval = analogRead(controller);
    //Map the value
    pos = map(cval, 50, 950, 5, 0);
    //Draw my bat
    drawBat(pos, 0);

    //Update ball position/enemy position with delay
    if(ballDelayLimit == 70){
      eskill = 0.9;
    }
    if(ballDelay > ballDelayLimit){
      //Turn off current ball
      lc.setLed(0, br, bc, false);
      //Make new position
      br = br + brr;
      bc = bc + bcc;
      //Draw the new ball
      lc.setLed(0, br, bc, true);

      //Reset the delay
      ballDelay = 0;

      //Increase ball speed
      ballDelayLimit = max(ballDelayLimit - 0.5, 70);

      //Move the enemy bat
      if(bc < epos){
        epos = epos - eskill;
      }else if(bc > epos+2){
        epos = epos + eskill;
      }

      //Draw enemy bat
      drawBat(epos, 7);

      //Figure out bounces/angles for next draw
      bounce();
    }else{
      ballDelay++;
    }
  }
}

void drawBat(int offset, int row){
  offset = constrain(offset, 0, 5);
  lc.setRow(0, row, bat>>offset);
}

void bounce(){
  //Add bouncing on top/bottom walls (column checks)
  if(bc <= 0){
    bcc = bcc * -1;
  }else if(bc >= 7){
    bcc = 0-bcc;
  }

  //Add bouncing off bats with angles for where on the bat got hit (row checks)
  if(br < 2 && br >= 1 && brr < 0){
    if((int)bc == pos){
      brr = brr * -1;
      if(bcc > 0){
        bcc = bcc * 0.9;
      }else{
        bcc = bcc * 1.1;
      }
    }else if((int)bc == pos+1){
      brr = brr * -1;
    }else if((int)bc == pos+2){
      brr = brr * -1;
      if(bcc > 0){
        bcc = bcc * 1.1;
      }else{
        bcc = bcc * 0.9;
      }
    }
    return;
  }else if(br < 7 && br >= 6 && brr > 0){
    if((int)bc == epos){
      brr = 0-brr;
      if(bcc > 0){
        bcc = bcc * 0.9;
      }else{
        bcc = bcc * 1.1;
      }
    }else if((int)bc == epos+1){
      brr = 0-brr;
    }else if((int)bc == epos+2){
      brr = 0-brr;
      if(bcc > 0){
        bcc = bcc * 1.1;
      }else{
        bcc = bcc * 0.9;
      }
    }
    return;
  }

  //Check for losers
  if(br < 0){
    //Game over, you lose
    score[1] = score[1]+1;
    gameOver = true;
  }else if(br > 7){
    //Game over, they lose
    score[0] = score[0]+1;
    gameOver = true;
  }
}

//Code to show scores
void showScores(){
  byte* cpu[3] = {C,P,U};
  byte* you[3] = {Y,O,U};
  blitWord(cpu, 3);
  switch(score[1]) {
    case 0:
      blitChar(n0);
      break;
    case 1:
      blitChar(n1);
      break;
    case 2:
      blitChar(n2);
      break;
    case 3:
      blitChar(n3);
      break;
  }
  delay(700);
  blitWord(you, 3);
  switch(score[0]) {
    case 0:
      blitChar(n0);
      break;
    case 1:
      blitChar(n1);
      break;
    case 2:
      blitChar(n2);
      break;
    case 3:
      blitChar(n3);
      break;
  }
  delay(700);
}

//Game over message
void endGame(){
  byte* gameover[10] = {G, lca, lcm, lce, space, O, lcv, lce, lcr, period};
  byte* youwin[8] = {Y, lco, lcu, space, W, lci, lcn, exclamation};
  byte* youlose[9] = {Y, lco, lcu, space, L, lco, lcs, lce, exclamation};
  blitWord(gameover, 10);
  if(score[0] > score[1]){
    blitWord(youwin, 8);
  }else{
    blitWord(youlose, 9);
    animPC();
  }
  score[0] = 0;
  score[1] = 0;
}

void blitChar(byte charMap[]){
  lc.clearDisplay(0);
  for(int row = 0; row <= 7; row++){
    lc.setRow(0, row, charMap[7 - row]);
  }
}
void blitWord(byte* aryChars[], int arySize){
  for(int c = 0; c < arySize; c++){
    blitChar(aryChars[c]);
    delay(300);
  }
  delay(700);
}
void blitScrollChar(byte charMap[]){
  for(int offset = 0; offset <= 7; offset++){
    lc.setRow(0, (offset-1), 0);
    lc.setRow(0, 7, 0);
    for(int row = 0; row <= 7; row++){
      lc.setRow(0, (row+offset), charMap[7 - row]);
    }
  }
}

void animPC(){
  for(int i = 0; i < 10; i++){
    blitChar(pc1);
    delay(70);
    blitChar(pc2);
    delay(70);
  }
}

void animExplode(){
    blitChar(b1);
    delay(90);
    blitChar(b2);
    delay(90);
    blitChar(b3);
    delay(90);
    blitChar(b4);
    delay(90);
    blitChar(b5);
    delay(90);
    blitChar(b6);
    delay(90);
    blitChar(b7);
    delay(90);
    blitChar(b8);
    delay(90);
    blitChar(b9);
    delay(90);
    blitChar(b10);
    delay(90);
    blitChar(b11);
    delay(90);
    blitChar(b12);
    delay(90);
    blitChar(b13);
    delay(90);
    blitChar(b14);
    delay(90);
    blitChar(b15);
    delay(90);
    blitChar(b16);
    delay(90);
    blitChar(b17);
    delay(90);
    blitChar(b18);
    delay(90);
    blitChar(b19);
    delay(90);
    blitChar(b20);
    delay(90);
    blitChar(b21);
    delay(50);
    blitChar(b22);
    delay(50);
    blitChar(b21);
    delay(50);
    blitChar(b22);
    delay(50);
    blitChar(b21);
    delay(50);
    blitChar(b22);
    delay(50);
    blitChar(b21);
    delay(50);
    blitChar(b22);
    delay(50);
    blitChar(b21);
    delay(600);
}
