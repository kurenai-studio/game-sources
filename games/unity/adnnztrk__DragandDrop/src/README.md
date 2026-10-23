# DragandDrop Project
It was made in C# language using the Unity game engine. It is a game that works by dragging the green and red balls coming from above to the green and red areas. In this way, points are earned for colors. 

**Ball Script**

When the ball is clicked with the mouse in the Ball script file, it calculates the difference between its position on the world and the mouse position in the camera's screen coordinates. Allows the ball to move with the OnMouseDrag method. The OnCollisionEnter2D method detects the ball touching the finish object.

**Green Script**

In Green Script, it is used to determine which color ball touched and if the green ball touched, to increase the score, if the red ball touched, to decrease the score.

**Red Script**

In Red Script, it is used to determine which color ball touched, and if the red ball touched, the score increases, if the green ball touched, the score decreases.




![Ekran görüntüsü 2025-03-10 023723](https://github.com/user-attachments/assets/a0a3402f-2e43-4c2c-b202-e1c106dd35b6)
