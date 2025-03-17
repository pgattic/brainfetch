
#[derive(Debug, PartialEq)]
pub enum Command {
    IncPtr,
    DecPtr,
    IncVal,
    DecVal,
    PutChar,
    GetChar,
    OpenBr,
    CloseBr,
}

impl Command {
    pub fn from_char(ch: char) -> Option<Self> {
        match ch {
            '>' => Some(Command::IncPtr),
            '<' => Some(Command::DecPtr),
            '+' => Some(Command::IncVal),
            '-' => Some(Command::DecVal),
            '.' => Some(Command::PutChar),
            ',' => Some(Command::GetChar),
            '[' => Some(Command::OpenBr),
            ']' => Some(Command::CloseBr),
            _ => None
        }
    }
}

pub fn parse(code: &str) -> Vec<Command> {
    return code.chars().filter_map(|ch| Command::from_char(ch)).collect();
}

//pub fn verify(code: &Vec<Command>) -> Result<(), &'static str> {
//    let mut bracket_bal = 0;
//    for com in code {
//        match com {
//            Command::OpenBr => {bracket_bal += 1;},
//            Command::CloseBr => {bracket_bal -= 1;},
//            _ => {}
//        }
//    }
//    if bracket_bal != 0 {
//        return Err("Unbalanced Brackets")
//    }
//    Ok(())
//}

//pub fn execute_prg(prg: &Vec<Command>) {
//    let mut prg_head = 0;
//    let mut mem: Vec<u8> = vec![0];
//    let mut mem_ptr = 0;
//
//    while prg_head < prg.len() {
//        match prg[prg_head] {
//            Command::IncPtr => {mem_ptr += 1; if mem_ptr == mem.len() {mem.push(0)}},
//            Command::DecPtr => mem_ptr -= 1,
//            Command::IncVal => mem[mem_ptr] = mem[mem_ptr].wrapping_add(1),
//            Command::DecVal => mem[mem_ptr] = mem[mem_ptr].wrapping_sub(1),
//            Command::PutChar => print!("{}", char::from_u32(mem[mem_ptr] as u32).unwrap()),
//            Command::GetChar => (),
//            Command::OpenBr => {
//                if mem[mem_ptr] == 0 {
//                    let mut bracket_bal = 1;
//                    while bracket_bal > 0 {
//                        prg_head += 1;
//                        if prg[prg_head] == Command::OpenBr { bracket_bal += 1; }
//                        if prg[prg_head] == Command::CloseBr { bracket_bal -= 1; }
//                    }
//                }
//            },
//            Command::CloseBr => {
//                let mut bracket_bal = 1;
//                while bracket_bal > 0 {
//                    prg_head -= 1;
//                    if prg[prg_head] == Command::OpenBr { bracket_bal -= 1; }
//                    if prg[prg_head] == Command::CloseBr { bracket_bal += 1; }
//                }
//                prg_head -= 1;
//            },
//        }
//        prg_head += 1;
//    }
//}

