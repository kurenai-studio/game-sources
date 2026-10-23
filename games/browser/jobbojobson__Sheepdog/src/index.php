<!DOCTYPE html>
<html>
    <head>
        <?php 
            function isMobile() {
                return preg_match("/(android|avantgo|blackberry|bolt|boost|cricket|docomo|fone|hiptop|mini|mobi|palm|phone|pie|tablet|up\.browser|up\.link|webos|wos)/i", $_SERVER["HTTP_USER_AGENT"]);
            }
        ?>
        <title>Sheepdog</title>
        <link rel="stylesheet" type="text/css" href="css/styles.css">
    </head>
    <body>

		<p class="score">Round: <span id="roundNumLabel"></span> | Time: <span id="roundTimeLabel"></span></p>

        <div class="game-container">
            <div class="row">
                <?php
                if(isMobile()){
                ?>
                <div class="control-panel">
                    <div class="control-row">
                        <div class="control-button">
                            <div id="upButton" class="button-layer" ontouchstart="touchStart(this)" ontouchend="touchEnd(this)"></div>
                            <div class="button-area"></div>
                        </div>
                    </div>
                    <div class="control-row">
                        <div class="control-button">
                            <div id="downButton" class="button-layer" ontouchstart="touchStart(this)" ontouchend="touchEnd(this)"></div>
                            <div class="button-area"></div>
                        </div>
                    </div>
                </div>
                <?php
                }
                ?>
                <div class="game-panel">
                    <canvas id="gameCanvas" width="600" height="400"></canvas>
                </div>
                <?php
                if(isMobile()){
                ?>
                <div class="control-panel">
                    <div class="control-row">
                        <div class="control-button">
                            <div id="leftButton" class="button-layer" ontouchstart="touchStart(this)" ontouchend="touchEnd(this)"></div>
                            <div class="button-area"></div>
                        </div>
                        <div class="control-button">
                            <div id="rightButton" class="button-layer" ontouchstart="touchStart(this)" ontouchend="touchEnd(this)"></div>
                            <div class="button-area"></div>
                        </div>
                    </div>
                </div>
                <?php
                }
                ?>
            </div>
        </div>
        <script src="js/constants.js?v=1"></script>
        <script src="js/Sheep.js?v=1"></script>
        <script src="js/Dog.js?v=1"></script>
        <script src="js/Round.js?v=1"></script>
        <script src="js/Timer.js?v=1"></script>
        <script src="js/Game.js?v=1"></script>
    </body>

</html>
