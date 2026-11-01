#pragma strict

function OnTriggerEnter2D(hitInfo: Collider2D) {
    //Ball hits left or right wall
    if (hitInfo.name == "Ball") {
        var wall = transform.name;
        GetComponent.<AudioSource>().Play();
        Scores.Score(wall);
        hitInfo.gameObject.SendMessage("resetBall");
    };
}