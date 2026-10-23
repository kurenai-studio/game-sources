

//Collisions (Point, Rect, Circle, Tri)
function collisionPointRect(point, rect) {

    var inverseMat2 = rect.transform.mat2.getInverse();
    var pointRel = inverseMat2.getMultVect(point.transform.pos.getSub(rect.transform.pos));
    
    if(
        Math.abs(pointRel.x) < rect.size.x &&
        Math.abs(pointRel.y) < rect.size.y) {
        return true;
    }
    else {
        return false;
    }
}

function collisionPointCircle(point, circle) {

    return circle.radius * circle.radius >
        point.transform.pos.getSub(circle.transform.pos).getMagnitudeSquared() 
}

function collisionPointTri(point, tri) {

    return false;   //TODO: implement collision logic.
}

function collisionRectRect(rectA, rectB) {

    return false;   //TODO: implement collision logic.
}

function collisionRectCircle(rect, circle) {

    return false;   //TODO: implement collision logic.
}

function collisionRectTri(rect, tri) {

    return false;   //TODO: implement collision logic.
}

function collisionCircleCircle(circleA, circleB) {

    return (circleA.radius + circleB.radius) * (circleA.radius + circleB.radius) >
        circleA.transform.pos.getSub(circleB.transform.pos).getMagnitudeSquared();
}

function collisionCircleTri(circle, tri) {

    return false;   //TODO: implement collision logic.
}

function collisionTriTri(triA, triB) {
    
    return false;   //TODO: implement collision logic.
}

TYPE_COLL = Object.freeze({
    POINT: 0,
    RECT: 1,
    CIRCLE: 2,
    TRI: 3});