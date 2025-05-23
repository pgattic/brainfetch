
class Command {
  public static List<Command> Parse(string code) {
    List<Command> result = new List<Command>();
    foreach (char ch in code) {
      switch (ch) {
        case '>':
          result.Add(new IncPtr());
          break;
        case '<':
          result.Add(new DecPtr());
          break;
        case '+':
          result.Add(new IncVal());
          break;
        case '-':
          result.Add(new DecVal());
          break;
        case '.':
          result.Add(new PutChar());
          break;
        case ',':
          result.Add(new GetChar());
          break;
        case '[':
          result.Add(new OpenBr());
          break;
        case ']':
          result.Add(new CloseBr());
          break;
      }
    }
    return result;
  }

  public static void Execute(List<Command> program) {
    byte[] memory = new byte[30000];
    int mem_head = 0;
    int prg_head = 0;

    while (prg_head < program.Count) {
      switch (program[prg_head]) {
        case IncPtr _:
          mem_head++;
          break;
        case DecPtr _:
          mem_head--;
          break;
        case IncVal _:
          memory[mem_head]++;
          break;
        case DecVal _:
          memory[mem_head]--;
          break;
        case PutChar _:
          Console.Write((char)memory[mem_head]);
          break;
        case GetChar _:
          // TODO
          break;
        case OpenBr _:
          if (memory[mem_head] == 0) {
            int bracket_bal = 1;
            while (bracket_bal > 0) {
              prg_head++;
              if (program[prg_head] is OpenBr) {
                bracket_bal++;
              } else if (program[prg_head] is CloseBr) {
                bracket_bal--;
              }
            }
          }
          break;
        case CloseBr _:
          if (memory[mem_head] != 0) {
            int bracket_bal = 1;
            while (bracket_bal > 0) {
              prg_head--;
              if (program[prg_head] is CloseBr) {
                bracket_bal++;
              } else if (program[prg_head] is OpenBr) {
                bracket_bal--;
              }
            }
          }
          break;
      }
      prg_head++;
    }
  }
}

class IncPtr: Command {}
class DecPtr: Command {}
class IncVal: Command {}
class DecVal: Command {}
class PutChar: Command {}
class GetChar: Command {}
class OpenBr: Command {}
class CloseBr: Command {}

