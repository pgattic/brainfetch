"use strict";
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

function optimizeCode(code) {
  let result = [];

  if (code.length == 0) return result;

  const repeatCmds = [ INC_PTR, DEC_PTR, INC_VAL, DEC_VAL ];

  // Basically, the goal of the loop is to keep track of repeating repeatable commands and append 
  // to `result` when a repeatable command is done repeating, and after each non-repeatable
  // command

  let i = 1;
  let last_cmd = code[0];
  let count = 1;

  while (i < code.length) {
    const cmd = code[i];

    // Fix: Detect and replace `[-]` with ZERO before doing anything else
    // if (last_cmd === OPEN_BR && cmd === DEC_VAL && code[i + 1] === CLOSE_BR) {
    //   result.push([ZERO, 1]);
    //   i += 2;
    //   last_cmd = code[i];
    //   count = 1;
    //   continue;
    // }

    if (cmd === last_cmd && repeatCmds.includes(cmd)) {
      count += 1;
    } else {
      result.push([last_cmd, count]);
      last_cmd = cmd;
      count = 1;
    }

    i += 1;
  }

  result.push([last_cmd, count]);

// Add jumps to brackets
  let unsolved = [];
  for (let i = 0; i < result.length; i++) {
    const cmd = result[i][0];
    if (cmd === OPEN_BR) {
      unsolved.push(i);
    } else if (cmd === CLOSE_BR) {
      const connection = unsolved.pop();
      result[connection][1] = i;
      result[i][1] = connection;
    }
  }

  if (unsolved.length > 0) {
    console.log("shoot");
  }

  return result;
}

function executeProgram(program) {
  let memory = [0];
  let memPtr = 0;
  let prgHead = 0;

  while (prgHead < program.length) {
    const [cmd, count] = program[prgHead];
    switch (cmd) {
      case INC_PTR:
        memPtr += count;
        while (memory.length <= memPtr) {
          memory.push(0);
        }
        break;
      case DEC_PTR:
        memPtr -= count;
        break;
      case INC_VAL:
        memory[memPtr] = (memory[memPtr] + count) % 256;
        break;
      case DEC_VAL:
        memory[memPtr] = (memory[memPtr] + 256 - count) % 256;
        break;
      case PUT_CHAR:
        process.stdout.write(String.fromCharCode(memory[memPtr]));
        break;
      case GET_CHAR:
        break;
      case OPEN_BR:
        if (memory[memPtr] === 0) {
          prgHead = count;
        }
        break;
      case CLOSE_BR:
        if (memory[memPtr] !== 0) {
          prgHead = count;
        }
        break;
    }
    prgHead++;
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
    const optimized = optimizeCode(program);
    executeProgram(optimized);
  });
}

main();

