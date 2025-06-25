use std::path::PathBuf;
use clap::Parser;

mod command;
mod command_opt;
mod jit;

#[derive(Parser)]
#[command(version, about, long_about = None)]
struct Cli {
    /// BrainF*** file to execute
    file: PathBuf,
}

fn main() -> Result<(), &'static str> {
    let cli = Cli::parse();

    let contents: String = match std::fs::read_to_string(&cli.file) {
        Ok(data) => data,
        Err(err) => {
            eprintln!("Can't open file '{}': {}", cli.file.to_string_lossy(), err);
            return Err("Unable to open specified file.")
        }
    };

    let tokens = command_opt::tokenize(&contents)?;

    let program = match jit::jit_compile(&tokens) {
        Ok(result) => result,
        Err(error) => {
            eprintln!("{}", error);
            return Err("Failed to generate JIT program.")
        }
    };

    // Set up starting state of program
    let mut memory = [0u8; 30_000];
    let mut mem_ptr: usize = 0;

    // Call the JIT function
    program(memory.as_mut_ptr(), &mut mem_ptr as *mut usize);

    Ok(())
}

