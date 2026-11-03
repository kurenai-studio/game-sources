using System;

namespace org.flauschhaus.Panza {

public static class Program {

[STAThread]
static 
void Main()
{
  using (var runner = new Runner())
  {
    runner.Run();
  }
}

} // Program

} // ns
