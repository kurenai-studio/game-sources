using System;

public interface Saveable {
  void Save(); // save required data into serialized fields
  void Load(); // load data from serialized fields
}