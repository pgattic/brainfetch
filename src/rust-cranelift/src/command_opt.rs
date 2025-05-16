use crate::command::Command;

#[derive(Debug, Clone, PartialEq)]
pub enum CommandOpt {
    ChPtr(isize),
    ChVal(u8), // Doesn't need to be signed lol XD
    PutChar,
    GetChar,
    Zero,
    LoopForever,
    OpenBr(usize),
    CloseBr(usize),
}

pub fn parse(code: &str) -> Result<Vec<CommandOpt>, &'static str> {
    optimize_prg(&crate::command::tokenize(code))
}

struct ParseState {
    counts: ParseCounts,
    unres_brack: Vec<usize>,
    result: Vec<CommandOpt>,
}

/// Data structore to store the current state of parsing the code stream.
enum ParseCounts {
    ChPtr(isize),
    ChVal(isize),
    None,
}

impl ParseState {
    pub fn new() -> Self {
        Self {
            counts: ParseCounts::None,
            unres_brack: Vec::new(),
            result: Vec::new(),
        }
    }

    pub fn feed(&mut self, cmd: &Command) -> Result<(), &'static str> {
        match cmd {
            Command::IncPtr => self.ch_ptr(1),
            Command::DecPtr => self.ch_ptr(-1),
            Command::IncVal => self.ch_val(1),
            Command::DecVal => self.ch_val(-1),
            Command::PutChar => {
                self.apply_counts();
                self.result.push(CommandOpt::PutChar);
            }
            Command::GetChar => {
                self.apply_counts();
                self.result.push(CommandOpt::GetChar);
            }
            Command::OpenBr => {
                self.apply_counts();
                self.unres_brack.push(self.result.len());
                self.result.push(CommandOpt::OpenBr(0));
            }
            Command::CloseBr => {
                let conn = match self.unres_brack.pop() {
                    Some(val) => val,
                    None => return Err("Brackets not balanced. Unexpected ']' found."),
                };
                // Check for `[-]`
                if let (ParseCounts::ChVal(amount), CommandOpt::OpenBr(_)) =
                    (&self.counts, self.result.last().unwrap())
                {
                    let _ = self.result.pop();
                    if amount.rem_euclid(2) == 1 {
                        self.result.push(CommandOpt::Zero);
                    } else {
                        self.result.push(CommandOpt::LoopForever);
                    }
                    self.counts = ParseCounts::None;
                } else {
                    self.apply_counts();
                    self.result[conn] = CommandOpt::OpenBr(self.result.len());
                    self.result.push(CommandOpt::CloseBr(conn));
                }
            }
        }
        Ok(())
    }

    pub fn ch_ptr(&mut self, count: isize) {
        if let ParseCounts::ChPtr(amount) = self.counts {
            self.counts = ParseCounts::ChPtr(amount + count);
        } else {
            self.apply_counts();
            self.counts = ParseCounts::ChPtr(count);
        }
    }

    pub fn ch_val(&mut self, count: isize) {
        if let ParseCounts::ChVal(amount) = self.counts {
            self.counts = ParseCounts::ChVal(amount + count);
        } else {
            self.apply_counts();
            self.counts = ParseCounts::ChVal(count);
        }
    }

    pub fn apply_counts(&mut self) {
        match self.counts {
            ParseCounts::ChPtr(count) => {
                self.result.push(CommandOpt::ChPtr(count));
                self.counts = ParseCounts::None;
            }
            ParseCounts::ChVal(count) => {
                self.result
                    .push(CommandOpt::ChVal(count.rem_euclid(256) as u8));
                self.counts = ParseCounts::None;
            }
            ParseCounts::None => {}
        };
    }

    pub fn get_result(&mut self) -> Result<Vec<CommandOpt>, &'static str> {
        self.apply_counts();
        if self.unres_brack.len() > 0 {
            return Err("Unclosed '['");
        }
        Ok(self.result.clone())
    }
}

fn optimize_prg(prg: &[Command]) -> Result<Vec<CommandOpt>, &'static str> {
    let mut state = ParseState::new();
    for cmd in prg {
        state.feed(cmd)?;
    }
    state.get_result()
}

pub fn execute(prg: &Vec<CommandOpt>) -> Result<(), &'static str> {
    let mut prg_head = 0;
    let mut mem: Vec<u8> = vec![0];
    let mut mem_ptr = 0;

    while prg_head < prg.len() {
        match prg[prg_head] {
            CommandOpt::ChPtr(amt) => {
                if amt >= 0 {
                    mem_ptr += amt as usize;
                    while mem_ptr >= mem.len() {
                        mem.push(0)
                    } // Dynamically growing memory
                } else {
                    match mem_ptr.checked_sub(-amt as usize) {
                        Some(val) => {
                            mem_ptr = val;
                        }
                        None => {
                            return Err(
                                "Pointer underflow (attempted to move read/write head below 0)",
                            );
                        }
                    }
                }
            }
            CommandOpt::ChVal(amt) => mem[mem_ptr] = mem[mem_ptr].wrapping_add(amt),
            CommandOpt::PutChar => match char::from_u32(mem[mem_ptr] as u32) {
                Some(val) => print!("{}", val),
                None => return Err("Invalid char printed"),
            },
            CommandOpt::GetChar => {
                use std::io::Read;
                let mut buffer = [0u8; 1];
                // Throw away error (if no stdin, just keep it at 0)
                let _ = std::io::stdin().read_exact(&mut buffer);
                mem[mem_ptr] = buffer[0];
            }
            CommandOpt::OpenBr(target) => {
                if mem[mem_ptr] == 0 {
                    prg_head = target;
                }
            }
            CommandOpt::CloseBr(target) => {
                if mem[mem_ptr] != 0 {
                    prg_head = target;
                }
            }
            CommandOpt::Zero => mem[mem_ptr] = 0,
            CommandOpt::LoopForever => {
                if mem[mem_ptr] != 0 {
                    prg_head -= 1;
                }
            }
        }
        prg_head += 1;
    }

    Ok(())
}
