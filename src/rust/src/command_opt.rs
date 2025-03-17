use crate::command::Command;

#[derive(Debug, PartialEq)]
pub enum CommandOpt {
    IncPtr(usize),
    DecPtr(usize),
    IncVal(u8),
    DecVal(u8),
    PutChar,
    GetChar,
    Zero,
    OpenBr(usize),
    CloseBr(usize),
}

pub fn optimize_prg(prg: &[Command]) -> Vec<CommandOpt> {
    let mut result = Vec::new();
    let mut head = 0;
    let mut unres_brack: Vec<usize> = Vec::new();

    while head < prg.len() {
        if prg.len() > head + 2 && prg[head..head+2] == [Command::OpenBr, Command::DecPtr, Command::CloseBr] {
            result.push(CommandOpt::Zero);
            head += 3;
            continue;
        }
        match prg[head] {
            Command::IncPtr => {
                let mut incs = 1;
                for cmd in &prg[head+1..] {
                    if *cmd == Command::IncPtr {
                        incs += 1;
                    } else {break};
                }
                head += incs as usize;
                result.push(CommandOpt::IncPtr(incs));
            },
            Command::DecPtr => {
                let mut decs = 1;
                for cmd in &prg[head+1..] {
                    if *cmd == Command::DecPtr {
                        decs += 1;
                    } else {break};
                }
                head += decs as usize;
                result.push(CommandOpt::DecPtr(decs));
            },
            Command::IncVal => {
                let mut incs = 1;
                for cmd in &prg[head+1..] {
                    if *cmd == Command::IncVal {
                        incs += 1;
                    } else {break};
                }
                head += incs as usize;
                result.push(CommandOpt::IncVal(incs));
            },
            Command::DecVal => {
                let mut decs = 1;
                for cmd in &prg[head+1..] {
                    if *cmd == Command::DecVal {
                        decs += 1;
                    } else {break};
                }
                head += decs as usize;
                result.push(CommandOpt::DecVal(decs));
            },
            Command::PutChar => { result.push(CommandOpt::PutChar); head += 1; },
            Command::GetChar => { result.push(CommandOpt::GetChar); head += 1; },
            Command::OpenBr => {
                unres_brack.push(result.len());
                result.push(CommandOpt::OpenBr(0)); // 0 is TEMPORARY
                head += 1;
            },
            Command::CloseBr => {
                let br_match = unres_brack.pop().unwrap();
                result[br_match] = CommandOpt::OpenBr(result.len());
                result.push(CommandOpt::CloseBr(br_match));
                head += 1;
            },
        }
    }

    result
}

pub fn execute_prg(prg: &Vec<CommandOpt>) {
    let mut prg_head = 0;
    let mut mem: Vec<u8> = vec![0];
    let mut mem_ptr = 0;

    while prg_head < prg.len() {
        match prg[prg_head] {
            CommandOpt::IncPtr(amt) => {mem_ptr += amt; while mem_ptr >= mem.len() {mem.push(0)}},
            CommandOpt::DecPtr(amt) => mem_ptr -= amt,
            CommandOpt::IncVal(amt) => mem[mem_ptr] = mem[mem_ptr].wrapping_add(amt),
            CommandOpt::DecVal(amt) => mem[mem_ptr] = mem[mem_ptr].wrapping_sub(amt),
            CommandOpt::PutChar => print!("{}", char::from_u32(mem[mem_ptr] as u32).unwrap()),
            CommandOpt::GetChar => (),
            CommandOpt::OpenBr(target) => {
                if mem[mem_ptr] == 0 {
                    prg_head = target;
                }
            },
            CommandOpt::CloseBr(target) => prg_head = target - 1,
            CommandOpt::Zero => mem[mem_ptr] = 0,
        }
        prg_head += 1;
    }
}

