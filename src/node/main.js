import { readFile } from 'fs';

const INC_PTR = 1;
const DEC_PTR = 2;
const INC_VAL = 3;
const DEC_VAL = 4;
const PUT_CHAR = 5;
const GET_CHAR = 6;
const OPEN_BR = 7;
const CLOSE_BR = 8;
const ZERO = 9;

function parseCode(code) {
  let result = [];
  const mapping = {
    '>': INC_PTR,
    '<': DEC_PTR,
    '+': INC_VAL,
    '-': DEC_VAL,
    '.': PUT_CHAR,
    ',': GET_CHAR,
    '[': OPEN_BR,
    ']': CLOSE_BR,
  }
  for (let ch of code) {
    if (Object.keys(mapping).includes(ch)) {
      result.push(mapping[ch]);
    }
  }
  return result;
}

function executeProgram(program) {
  let memory = [0];
  let memPtr = 0;
  let readHead = 0;

  while (readHead < program.length) {
    switch (program[readHead]) {
      case INC_PTR:
        memPtr++;
        if (memory.length-1 < memPtr) {
          memory.push(0);
        }
        break;
      case DEC_PTR:
        memPtr--;
        break;
      case INC_VAL:
        memory[memPtr] = (memory[memPtr] + 257) % 256;
        break;
      case DEC_VAL:
        memory[memPtr] = (memory[memPtr] + 255) % 256;
        break;
      case PUT_CHAR:
        process.stdout.write(String.fromCharCode(memory[memPtr]));
        break;
      case GET_CHAR:
        break;
      case OPEN_BR:
        if (memory[memPtr] === 0) {
          let bracketBal = 1;
          while (bracketBal > 0) {
            readHead++;
            if (program[readHead] === OPEN_BR) {
              bracketBal++;
            } else if (program[readHead] === CLOSE_BR) {
              bracketBal--;
            }
          }
        }
        break;
      case CLOSE_BR:
        if (memory[memPtr] !== 0) {
          let bracketBal = 1;
          while (bracketBal > 0) {
            readHead--;
            if (program[readHead] === CLOSE_BR) {
              bracketBal++;
            } else if (program[readHead] === OPEN_BR) {
              bracketBal--;
            }
          }
        }
        break;
    }
    readHead++;
  }
}

function main() {
  let args = process.argv;
  if (args.length < 3) {
    console.log("Please specify a file.");
    return;
  }
  const filePath = args[2];
  readFile(filePath, (err, data) => {
    if (err) {
      if (err.code === 'ENOENT') {
        console.error('Error reading file: File not found.');
      } else if (err.code === 'EACCES') {
        console.error('Error reading file: Permission denied.');
      } else {
        console.error('Error reading file.');
      }
      return;
    }
    const program = parseCode(data.toString());
    executeProgram(program);
  });
}

main();

