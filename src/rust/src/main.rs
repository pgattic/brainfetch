use std::fs;
use std::path::PathBuf;
use clap::Parser;

mod command;
mod command_opt;

#[derive(Parser)]
#[command(version, about, long_about = None)]
struct Cli {
    /// BrainF*** file to execute
    file: PathBuf,
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

    let program = command::parse(&contents);
    let program_opt = command_opt::optimize_prg(&program);
    
    //command::execute_prg(&program);
    command_opt::execute_prg(&program_opt);
}

