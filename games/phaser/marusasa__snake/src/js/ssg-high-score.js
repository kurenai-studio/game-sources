/**
 * Project url: https://github.com/marusasa/ssg-high-score
 * Version: 1.0
 * Date: 2024-09-29
 * Author: Sasagu Maruyama
 * License: MIT License
 */

/** 
 * Class representing a high score list. 
 * */
class SsgGameObj{
    /**
     * Create an object representing a high score list.
     * @param {string} highscore_id - highscore_id.
     * @param {string} dom_elem_id - HTML Dom element id where the high score will be rendered in.
     */
    constructor(highscore_id, dom_elem_id){
        this.highscore_id = highscore_id;
        this.dom_elem_id = dom_elem_id;
        this.url_base = 'https://highscore.sasagu.com/api/v1';
        this.bottom_score = 0;
        this.hs_list = [];
        this.score_to_keep = 0;
        this.data_loaded = false;
    }

    /**
     * Chech if a new score is high enough to be added.
     * @param {number} score 
     * @returns {boolean} result
     */
    isNewHS(score){
        let result = false;
        if(this.data_loaded && score != 0){
            if(this.score_to_keep > this.hs_list.length){
                if(score >= this.bottom_score){
                    result = true;
                }
            }else{
                if(score > this.bottom_score){
                    result = true;
                }
            }
        }
        return result;        
    }

    /**
     * Add a score to a high score list
     * @param {number} score 
     * @param {string} name 
     */
    addScore(score, name){
        let reqBody = {
            "highscore_id": this.highscore_id,
            "name": name,
            "score": score
        }
        let obj = {
            method: 'POST', 
            headers: {
                'Content-Type': 'application/json',
            }, 
            body: JSON.stringify(reqBody)
        };
        try{
            fetch(this.url_base + '/add-score',obj)
                .then((response) => {
                    if (!response.ok) {
                        throw Error(response.statusText);
                    }
                    return response.json();
                })
                .then((data) => {
                    if(data.success){
                        this.hs_list = data.scores;
                        this.score_to_keep = data.score_to_keep;
                        this.bottom_score = data.bottom_score;
                        this.render();
                    }else{
                        throw Error(data.errors);
                    }
                });
        }catch(err){
            console.error(err);
            alert("Error adding score. Reason: " + err);
        }
    }

    /**
     * Retrieves high score list and renders it to screen.
     */
    reload(){
        try{
            fetch(this.url_base + '/scores/' + this.highscore_id)                
                .then((response) => {
                    if (!response.ok) {
                        throw Error(response.statusText);
                    }
                    return response.json();
                })
                .then((data) => {
                    if(data.success){
                        this.hs_list = data.scores;
                        this.score_to_keep = data.score_to_keep;
                        this.bottom_score = data.bottom_score;
                        this.data_loaded = true;
                        this.render();
                    }else{
                        throw Error(data.errors);
                    }
                })
                .catch((err) => {
                    console.error(err);
                    this.renderError();
                });
        }catch(err){
            console.error(err);
            this.renderError();
        }
    }

    /**
     * Renders the high score list to screen.
     */
    render(){
        //clear dom children
        const parent = document.getElementById(this.dom_elem_id);
        while (parent.firstChild) {
            parent.firstChild.remove();
        }
        //create html for list
        const liChild = document.createElement('li');
        liChild.textContent = ' # SCORE NAME';
        parent.appendChild(liChild);
        for(let x = 0;x < this.score_to_keep;x++){
            let score = 0;
            let name = '..........';
            if(x < this.hs_list.length){
                score = this.hs_list[x].score;
                name  = this.hs_list[x].name;
            }
            const liChild = document.createElement('li');
            liChild.textContent = String(x+1).padStart(2,' ') + ' ' + String(score).padStart(5,' ') + ' ' + name.padEnd(10,' ');
            parent.appendChild(liChild);
         }
    }

    /**
     * Renders error message to screen
     */
    renderError(){
        const parent = document.getElementById(this.dom_elem_id);
        while (parent.firstChild) {
            parent.firstChild.remove();
        }
        const liChild = document.createElement('li');
        liChild.textContent = 'ERROR!';
        parent.appendChild(liChild);
        const liChild2 = document.createElement('li');
        liChild2.textContent = 'DATA NOT OBTAINED.';
        parent.appendChild(liChild2);
    }
}
/**
 * A class that can handle multiple high score list for one game.
 */
class SsgHighScore {
    /**
     * Constructor
     * @param {[Object]} game_obj_array - list of SsgGameObj
     */
    constructor(game_obj_array){
        this.game_obj_array = [];
        //validate parameter
        game_obj_array.forEach(gameObj =>{
            if(gameObj.constructor.name != 'SsgGameObj'){
                console.error("Invalid High Score parameter object: " + gameObj.constructor.name
                        + ". High Score will not work.");  
            }else{
                this.game_obj_array.push(gameObj);
            }
        });
    }

    /**
     * Checks if a score can be added to any of the high score list.
     * If this returns 'true', the game should display a dialog 
     * asking for a name to use.
     * @param {number} score 
     * @returns {boolean} result
     */
    isNewHS(score){
        let result = false;
        this.game_obj_array.every(gameObj => {
            if(gameObj.isNewHS(score)){
                result = true;
                return false;   //this breaks out of 'every' loop.
            }
            return true;
        });
        return result;
    }

    /**
     * Reloads high score data for each games.
     */
    loadHS(){
        this.game_obj_array.forEach(gameObj => {
            gameObj.reload();
        });
    }

    /**
     * Add a score to the applicable high score list.
     * Call this after you get the name to use.
     * @param {number} score 
     * @param {string} name 
     */
    addScore(score, name){
        this.game_obj_array.forEach(gameObj => {
            if(gameObj.isNewHS(score)){
                gameObj.addScore(score, name);
            }
        })
    }

    /**
     * Validate the score and the name before you submit it to the server.
     * @param {number} score 
     * @param {string} name - max length is 10.
     * @returns {boolean} result
     */
    validate(score, name){
        let result = false;
        let errors = [];
        if(score == 0){
            errors.push("Score cannot be 0.");
        }
        if(name.trim() == ""){
            errors.push("Name is missing.");
        }
        if(name.length > 10){
            errors.push("Name longer than 10 characters.");
        }
        if(errors.length == 0){
            result = true;
        }else{
            alert(errors);
        }
        return result;
    }    
}