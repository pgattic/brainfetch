
class BrainFetch {
  static void Main(string[] args) {
    if (args.Length < 1) {
      Console.WriteLine("Please specify a file.");
      System.Environment.Exit(1);
    }

    var path = args[0];

    if (!File.Exists(path)) {
      Console.Write("ERROR: File not found: ");
      Console.WriteLine(path);
      System.Environment.Exit(1);
    }

    var code = File.ReadAllText(path);
    var parsed = Command.Parse(code);
    Command.Execute(parsed);
  }
}

