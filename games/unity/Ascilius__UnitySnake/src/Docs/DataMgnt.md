# DataMgnt

```DataMgnt``` relies on ```JsonUtility``` to convert serialized fields from game objects into a string in JSON format.
To streamline the saving/loading process, have your game object class implement the ```Saveable``` interface. This requires the class to implement the ```Save()``` and ```Load()``` functions. Use these functions to prepare your object to have its serialized fields read/loaded by JsonUtility.

This implementation allows for the separation of duties, wherein the programmer for each game object must determine how the object's data is saved/loaded. The programmer for ```DataMgnt``` can simply call the object's ```Save()```/```Load()``` function, without the need to coordinate explicitly how its data should be saved/loaded, and the order of which objects are saved/loaded can be determined alone by the ```DataMgnt``` programmer.

### Saving

For example in ```FoodBehavior```, the object's ```Transform``` cannot be converted into JSON using JsonUtility, so the object's position stored in ```transform.position``` is copied and saved into a serialized field in the ```FoodBehavior``` class, ```loc```. This process occurs in the ```Save()``` function.

When the command to save is detected by ```DataMgnt```, it calls its own ```Save()``` function, which then calls on each object's ```Save()``` function. Then, ```DataMgnt``` uses ```JsonUtility``` to convert the serialized fields from each object into a line of JSON. ```DataMgnt``` acculumates each object's JSON string, then writes it all to the save file, separated by a newline.

### Loading

When the command to load is detected by ```DataMgnt```, it calls its own  ```Load()``` function, reading one line at a time from the save file. Consequently, the order in which objects are loaded must be the same as they are saved. For each object, when its JSON string is read, it is parsed by ```JSONUtility``` and overwrites the respective serialized fields in each object. 

Continuing with the example for ```FoodBehavior```, when its serialized ```loc``` field is overwritten by ```JSONUtility```, ```DataMgnt``` then calls ```FoodBehavior```'s ```Load()``` function, which then copies the position data from ```loc``` into its ```transform.position```.