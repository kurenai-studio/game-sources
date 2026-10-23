package fi.tamk.sunkensoft;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Rectangle;

public class Calculator {
    public Texture numPlate;
    public Texture numPlate2;

    public Rectangle num1Rect;
    public Rectangle num2Rect;
    public Rectangle num3Rect;
    public Rectangle num4Rect;
    public Rectangle num5Rect;
    public Rectangle num6Rect;
    public Rectangle num7Rect;
    public Rectangle num8Rect;
    public Rectangle num9Rect;

    // Score
    public int score = 0;

    // Random number for calculation answer
    public float answerNum;

    // Random symbol (+, -, /, *)
    public char randChar;
    public String allSymbols = "-+*:";

    // Clicked numbers and their calculated result
    public float Selection1 = 0;
    public float Selection2 = 0;
    public float calcResult = 0;

    // answerState (0 = Pending Answer, 1 = Wrong Answer, 2 = Right Answer)
    public int answerState = 0;

    // introduce numbers for rectangles
    int num1;
    int num2;
    int num3;
    int num4;
    int num5;
    int num6;
    int num7;
    int num8;
    int num9;

    // Selected two number plates
    int selectNum1;
    int selectNum2;

    int random1;
    int random2;

    // Font position
    int fontPos;

    // For checking click rate
    public int lastClick = 0;

    // Combo system
    public int comboValue = 0;
    public int correct = 0;

    // Yellow numPlate
    float numPlateX = -300;
    float numPlateY = -300;
    float numPlate2X = -300;
    float numPlate2Y = -300;

    // Timer
    long startTime;
    boolean timerTriggered = false;

    /**
     * Main class create Textures and Rectangles also call genNumbers(); and numSelect();
     * and randomizes symbol.
     */
    public Calculator () {
        genNumbers();

        // Texture & 9 rectangles for all buttons
        numPlate = new Texture("button.png");
        numPlate2 = new Texture("button2.png");
        num1Rect = new Rectangle(60, 490, numPlate.getWidth(), numPlate.getHeight());
        num2Rect = new Rectangle(260, 490, numPlate.getWidth(), numPlate.getHeight());
        num3Rect = new Rectangle(460, 490, numPlate.getWidth(), numPlate.getHeight());
        num4Rect = new Rectangle(60, 290, numPlate.getWidth(), numPlate.getHeight());
        num5Rect = new Rectangle(260, 290, numPlate.getWidth(), numPlate.getHeight());
        num6Rect = new Rectangle(460, 290, numPlate.getWidth(), numPlate.getHeight());
        num7Rect = new Rectangle(60, 90, numPlate.getWidth(), numPlate.getHeight());
        num8Rect = new Rectangle(260, 90, numPlate.getWidth(), numPlate.getHeight());
        num9Rect = new Rectangle(460, 90, numPlate.getWidth(), numPlate.getHeight());

        numSelect();
        randChar = allSymbols.charAt(MathUtils.random.nextInt(allSymbols.length())); // Picks random symbol
        answerNum = answerGen();
    }

    /**
     * Update renders everything needed for the calculator
     *
     * @param game is part of Screens and it's needed here to use variables
     *             from CastleGame class.
     */
    public void update(CastleGame game) {
        game.batch.draw(numPlate, num1Rect.getX(), num1Rect.getY());
        game.batch.draw(numPlate, num2Rect.getX(), num2Rect.getY());
        game.batch.draw(numPlate, num3Rect.getX(), num3Rect.getY());
        game.batch.draw(numPlate, num4Rect.getX(), num4Rect.getY());
        game.batch.draw(numPlate, num5Rect.getX(), num5Rect.getY());
        game.batch.draw(numPlate, num6Rect.getX(), num6Rect.getY());
        game.batch.draw(numPlate, num7Rect.getX(), num7Rect.getY());
        game.batch.draw(numPlate, num8Rect.getX(), num8Rect.getY());
        game.batch.draw(numPlate, num9Rect.getX(), num9Rect.getY());

        game.batch.draw(numPlate2, numPlateX, numPlateY);
        game.batch.draw(numPlate2, numPlate2X, numPlate2Y);

        game.calcFont.draw(game.batch, "" + num1, num1Rect.getX() + numPosition(num1), num1Rect.getY()+140);
        game.calcFont.draw(game.batch,""+num2,num2Rect.getX()+numPosition(num2), num2Rect.getY()+140);
        game.calcFont.draw(game.batch,""+num3,num3Rect.getX()+numPosition(num3), num3Rect.getY()+140);
        game.calcFont.draw(game.batch,""+num4,num4Rect.getX()+numPosition(num4), num4Rect.getY()+140);
        game.calcFont.draw(game.batch,""+num5,num5Rect.getX()+numPosition(num5), num5Rect.getY()+140);
        game.calcFont.draw(game.batch,""+num6,num6Rect.getX()+numPosition(num6), num6Rect.getY()+140);
        game.calcFont.draw(game.batch,""+num7,num7Rect.getX()+numPosition(num7), num7Rect.getY()+140);
        game.calcFont.draw(game.batch,""+num8,num8Rect.getX()+numPosition(num8), num8Rect.getY()+140);
        game.calcFont.draw(game.batch,""+num9,num9Rect.getX()+numPosition(num9), num9Rect.getY()+140);

        game.calcFont.draw(game.batch,""+randChar,215,790);
        game.calcFont.draw(game.batch,"= "+(int)answerNum,420,790);

        /*if(answerState == 2){
            game.font.setColor(Color.GREEN);
            game.font.draw(batch, "CORRECT ANSWER!",70,70);
        }else if(answerState == 1){
            game.font.setColor(Color.RED);
            game.font.draw(batch, "WRONG ANSWER!",100,70);
        }*/

        if(Selection1 != 0) {
            game.calcFont.draw(game.batch, "" + (int) Selection1, 95, 790);
        }else{
            game.calcFont.draw(game.batch, "_", 130, 790);
        }

        if(Selection2 != 0){
            if(answerState == 2){
                game.calcFont.setColor(Color.GREEN);
            }else if(answerState == 1){
                game.calcFont.setColor(Color.RED);
            }
            game.calcFont.draw(game.batch,""+(int)Selection1,95,790);
            game.calcFont.draw(game.batch,""+(int)Selection2,295,790);
            game.calcFont.draw(game.batch,""+randChar,215,790);
            game.calcFont.draw(game.batch,"= "+(int)answerNum,420,790);
            game.calcFont.setColor(Color.WHITE);
        }else{
            game.calcFont.draw(game.batch, "_", 300, 790);
        }

        if(timerTriggered){
            if((System.currentTimeMillis() - startTime) >= 1000){

                resetSelection();
                randChar = allSymbols.charAt(MathUtils.random.nextInt(allSymbols.length()));
                genNumbers();
                numSelect();
                answerNum = answerGen();

                // Timer ends
                Gdx.app.log("TIMER","Timer ends");
                timerTriggered = false;
            }
        }
    }

    /**
     * Resets everything when timer ends and calls this.
     */
    public void resetSelection(){
        numPlate2X = -300;
        numPlate2Y = -300;
        numPlateX = -300;
        numPlateY = -300;
        Selection1 = 0;
        Selection2 = 0;
        calcResult = 0;
        lastClick = 0;
    }

    /**
     * numPosition return correct X position where the font should be drawn.
     *
     * @param num integer which size we compare
     * @return new X position for the font.
     */
    public int numPosition(int num) {
        if (num < 10) {
            fontPos = 70;
        }else{
            fontPos = 50;
        }
        return fontPos;
    }

    /**
     * numSelection is called when user presses one of the number plates on 3x3 grid
     * this method then checks if it was your first selection and if it was second we
     * check if calculation was correct.
     *
     * @param num integer which is selected when user presses one of the number plates on 3x3 grid
     * @param tRect Rectangle position is set here so we can draw yellow 'numPlate2' to that position
     */
    public void numSelection(int num, Rectangle tRect){
        answerState = 0;
        if(Selection1 == 0){
            Selection1 = num;
            numPlateX = tRect.getX();
            numPlateY = tRect.getY();
        }
        else{
            Selection2 = num;
            calcResult = selectNum1+randChar+selectNum2;
            if(randChar == '-'){ calcResult = Selection1-Selection2; }
            if(randChar == '+'){ calcResult = Selection1+Selection2; }
            if(randChar == ':'){ calcResult = Selection1/Selection2; }
            if(randChar == '*'){ calcResult = Selection1*Selection2; }
            //Gdx.app.log("CALCULATION",Selection1+" "+randChar+" "+Selection2+" = "+answerNum+"?");
            if(calcResult == answerNum){
                Gdx.app.log("SUM","Correct answer! Randomizing new number..");
                score+=MathUtils.random(2,6);
                correct = 1;
                comboValue = comboValue+1;
                answerState = 2;
            }else{
                Gdx.app.log("SUM","FAIL! Randomizing new number..");
                comboValue = 0;
                answerState = 1;
            }
            numPlate2X = tRect.getX();
            numPlate2Y = tRect.getY();
            startTime = System.currentTimeMillis();
            timerTriggered = true;
        }
    }

    /**
     * Calls randGenNum() for random numbers on every number plate of the 3x3 grid.
     */
    public void genNumbers(){
        num1 = randGenNum();
        num2 = randGenNum();
        num3 = randGenNum();
        num4 = randGenNum();
        num5 = randGenNum();
        num6 = randGenNum();
        num7 = randGenNum();
        num8 = randGenNum();
        num9 = randGenNum();
    }

    /**
     * Simple random number generator between 1 - 21.
     * @return random number between 1-21
     */
    public int randGenNum(){
        return MathUtils.random(1,21);
    }

    /**
     * Generates answer after random symbol has been assigned and we have 2 numbers which can be found from
     * the 3x3 grid.
     * @return calculated answer which is displayed for the player.
     */
    public float answerGen(){
        if(randChar == ':'){
            if(selectNum1%selectNum2 == 0) calcResult = selectNum1/selectNum2;
            else randChar = allSymbols.charAt(MathUtils.random.nextInt(allSymbols.length()-1));}
        if(randChar == '-'){ calcResult = selectNum1-selectNum2; }
        if(randChar == '+'){ calcResult = selectNum1+selectNum2;  }
        if(randChar == '*'){ calcResult = selectNum1*selectNum2;}
        Gdx.app.log("Calculation",selectNum1+" "+randChar+" "+selectNum2+" = "+calcResult);
        return calcResult;
    }

    /**
     * numSelect chooses one tile from the 3x3 grid and assigns the number inside the tile to selectNum1
     */
    public void numSelect(){

        random1 = MathUtils.random(1,9);

        if (random1 == 1) selectNum1 = num1;
        if (random1 == 2) selectNum1 = num2;
        if (random1 == 3) selectNum1 = num3;
        if (random1 == 4) selectNum1 = num4;
        if (random1 == 5) selectNum1 = num5;
        if (random1 == 6) selectNum1 = num6;
        if (random1 == 7) selectNum1 = num7;
        if (random1 == 8) selectNum1 = num8;
        if (random1 == 9) selectNum1 = num9;

        Selector();
    }

    /**
     * Selector chooses one tile next to random1 at random, then assigns the number inside the tile to selectNum2
     */
    public void Selector(){
        int number = MathUtils.random(1,4);
        int number2 = MathUtils.random(1,3);
        int number3 = MathUtils.random(1,2);
        if(random1 == 1){
            if(number3 == 1) random2 = 2;
            else random2 = 4;
        }
        if(random1 == 2){
            if(number2 == 1) random2 = 1;
            if(number2 == 2) random2 = 3;
            else random2 = 5;
        }
        if(random1 == 3){
            if(number3 == 1) random2 = 2;
            else random2 = 6;
        }
        if(random1 == 4){
            if(number2 == 1) random2 = 1;
            if(number2 == 2) random2 = 5;
            else random2 = 7;
        }
        if(random1 == 5){
            if(number == 1) random2 = 2;
            if(number == 2) random2 = 4;
            if(number == 3) random2 = 6;
            else random2 = 8;
        }
        if(random1 == 6){
            if(number2 == 1) random2 = 3;
            if(number2 == 2) random2 = 5;
            else random2 = 9;
        }
        if(random1 == 7){
            if(number2 == 1) random2 = 4;
            else random2 = 8;
        }
        if(random1 == 8){
            if(number2 == 1) random2 = 5;
            if(number2 == 2) random2 = 7;
            else random2 = 9;
        }
        if(random1 == 9){
            if(number2 == 1) random2 = 6;
            else random2 = 8;
        }
        if (random2 == 1) selectNum2 = num1;
        if (random2 == 2) selectNum2 = num2;
        if (random2 == 3) selectNum2 = num3;
        if (random2 == 4) selectNum2 = num4;
        if (random2 == 5) selectNum2 = num5;
        if (random2 == 6) selectNum2 = num6;
        if (random2 == 7) selectNum2 = num7;
        if (random2 == 8) selectNum2 = num8;
        if (random2 == 9) selectNum2 = num9;

    }

    public void dispose(){
        numPlate.dispose();
        numPlate2.dispose();
    }

}
