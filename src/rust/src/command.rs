
#[derive(Debug, PartialEq)]
pub enum Command {
    IncPtr,
    DecPtr,
    IncHead,
    DecHead,
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
            '+' => Some(Command::IncHead),
            '-' => Some(Command::DecHead),
            '.' => Some(Command::PutChar),
            ',' => Some(Command::GetChar),
            '[' => Some(Command::OpenBr),
            ']' => Some(Command::CloseBr),
            _ => None
        }
    }
}

