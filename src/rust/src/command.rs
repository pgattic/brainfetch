
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

pub fn tokenize(code: &str) -> Vec<Command> {
    return code.chars().filter_map(|ch| Command::from_char(ch)).collect();
}

