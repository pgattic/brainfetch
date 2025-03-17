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

fn main() -> Result<(), &'static str> {
    let cli = Cli::parse();

    let contents: String = match fs::read_to_string(&cli.file) {
        Ok(data) => data,
        Err(err) => {
            eprintln!("Can't open file '{}': {}", cli.file.to_string_lossy(), err);
            return Err("Unable to open specified file.")
        }
    };

    let program = command_opt::parse(&contents)?;
    
    command_opt::execute(&program)?;

    Ok(())
}

