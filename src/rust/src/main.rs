use std::fs;
use std::path::PathBuf;
use clap::Parser;

mod command;
use crate::command::Command;

#[derive(Parser)]
#[command(version, about, long_about = None)]
struct Cli {
    /// BrainF*** file to execute
    file: PathBuf,
}

fn parse(code: &str) -> Vec<Command> {
    return code.chars().filter_map(|ch| Command::from_char(ch)).collect();
}

//fn verify(code: &Vec<Command>) -> Result<(), &'static str> {
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

fn execute(prg: &Vec<Command>) {
    let mut prg_head = 0;
    let mut mem: Vec<u8> = vec![0];
    let mut mem_ptr = 0;

    while prg_head < prg.len() {
        match prg[prg_head] {
            Command::IncPtr => {mem_ptr += 1; if mem_ptr == mem.len() {mem.push(0)}},
            Command::DecPtr => mem_ptr -= 1,
            Command::IncHead => mem[mem_ptr] = mem[mem_ptr].wrapping_add(1),
            Command::DecHead => mem[mem_ptr] = mem[mem_ptr].wrapping_sub(1),
            Command::PutChar => print!("{}", char::from_u32(mem[mem_ptr] as u32).unwrap()),
            Command::GetChar => (),
            Command::OpenBr => {
                if mem[mem_ptr] == 0 {
                    let mut bracket_bal = 1;
                    while bracket_bal > 0 {
                        prg_head += 1;
                        if prg[prg_head] == Command::OpenBr { bracket_bal += 1; }
                        if prg[prg_head] == Command::CloseBr { bracket_bal -= 1; }
                    }
                }
            },
            Command::CloseBr => {
                let mut bracket_bal = 1;
                while bracket_bal > 0 {
                    prg_head -= 1;
                    if prg[prg_head] == Command::OpenBr { bracket_bal -= 1; }
                    if prg[prg_head] == Command::CloseBr { bracket_bal += 1; }
                }
                prg_head -= 1;
            },
        }
        prg_head += 1;
    }
}

fn main() {
    let cli = Cli::parse();

    let contents: String = match fs::read_to_string(&cli.file) {
        Ok(data) => data,
        Err(err) => {
            eprintln!("Can't open file '{}': {}", cli.file.to_string_lossy(), err);
            std::process::exit(0x02);
        }
    };

    let program = parse(&contents);

    //println!("{:?}", verify(&program));
    //println!("Program: {:?}", program);

    execute(&program);
}

