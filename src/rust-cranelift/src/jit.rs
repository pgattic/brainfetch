use crate::command_opt::CommandOpt;

fn put_char(ch: u8) {
    match char::from_u32(ch as u32) {
        Some(val) => print!("{}", val),
        None => {},
    }
}

fn get_char() -> u8 {
    use std::io::Read;
    let mut buffer = [0u8];
    // Throw away error (if no stdin, just keep it at 0)
    let _ = std::io::stdin().read_exact(&mut buffer);
    buffer[0]
}

pub fn jit_execute(program: &Vec<CommandOpt>) {
    use cranelift::prelude::*;
    use cranelift_module::{Linkage, Module};
    use cranelift_jit::{JITBuilder, JITModule};

    // Create JIT builder and module
    let mut builder = JITBuilder::new(cranelift_module::default_libcall_names()).unwrap();

    // Register host functions here
    builder.symbol("put_char", put_char as *const u8 as *const _);
    builder.symbol("get_char", get_char as *const u8 as *const _);

    let mut module = JITModule::new(builder);

    let ptr_type = module.target_config().pointer_type();

    let mut sig = module.make_signature();
    sig.params.push(AbiParam::new(ptr_type)); // memory pointer
    sig.params.push(AbiParam::new(ptr_type)); // mem_ptr value

    // Imported function signatures
    let mut put_sig = module.make_signature();
    put_sig.params.push(AbiParam::new(types::I8)); // takes one u8
    put_sig.returns.push(AbiParam::new(types::I32)); // optional (Cranelift requires a return type, but you can ignore it)

    let put_func_id = module.declare_function("put_char", Linkage::Import, &put_sig).unwrap();

    let mut get_sig = module.make_signature();
    get_sig.returns.push(AbiParam::new(types::I8)); // returns u8

    let get_func_id = module.declare_function("get_char", Linkage::Import, &get_sig).unwrap();


    // Declare the function
    let func_id = module
        .declare_function("execute", Linkage::Export, &sig)
        .unwrap();

    // Define the function body
    let mut ctx = module.make_context();
    ctx.func.signature = sig;

    let mut func_ctx = FunctionBuilderContext::new();
    let mut builder = FunctionBuilder::new(&mut ctx.func, &mut func_ctx);

    // Create a block for each command in the program
    let mut blocks: Vec<Block> = program.iter().map(|_| builder.create_block()).collect();
    let exit_block = builder.create_block();
    blocks.push(exit_block);
    builder.append_block_params_for_function_params(blocks[0]);

    // Load function parameters
    let mem_start = builder.block_params(blocks[0])[0]; // Address of start of virtual memory region
    let mem_head_ptr = builder.block_params(blocks[0])[1]; // Address of virtual memory read/write head
    for (i, cmd) in program.iter().enumerate() {
        builder.switch_to_block(blocks[i]);

        let mem_head = builder.ins().load(ptr_type, MemFlags::new(), mem_head_ptr, 0); // Read/write head

        match cmd {
            CommandOpt::ChPtr(value) => {
                let new_val = builder.ins().iadd_imm(mem_head, *value as i64);
                builder.ins().store(MemFlags::new(), new_val, mem_head_ptr, 0);
                builder.ins().jump(blocks[i + 1], &[]);
            }
            CommandOpt::ChVal(value) => {
                // Compute address: mem_start + mem_head
                let curr_cell_ptr = builder.ins().iadd(mem_start, mem_head);

                let old_val = builder.ins().load(types::I8, MemFlags::new(), curr_cell_ptr, 0);
                let new_val = builder.ins().iadd_imm(old_val, i64::from(*value));
                // Wrap as u8 (keep only low 8 bits)
                let new_val_trunc = builder.ins().band_imm(new_val, 0xFF);

                builder.ins().store(MemFlags::new(), new_val_trunc, curr_cell_ptr, 0);

                builder.ins().jump(blocks[i + 1], &[]);
            }
            CommandOpt::PutChar => {
                let curr_cell_ptr = builder.ins().iadd(mem_start, mem_head);
                let ch = builder.ins().load(types::I8, MemFlags::new(), curr_cell_ptr, 0);
                let local_put = module.declare_func_in_func(put_func_id, &mut builder.func);
                builder.ins().call(local_put, &[ch]); // `ch` is already loaded from memory
                builder.ins().jump(blocks[i + 1], &[]);
            }
            CommandOpt::GetChar => {
                let curr_cell_ptr = builder.ins().iadd(mem_start, mem_head);
                let local_get = module.declare_func_in_func(get_func_id, &mut builder.func);
                let call = builder.ins().call(local_get, &[]);
                let result = builder.inst_results(call)[0];
                builder.ins().store(MemFlags::new(), result, curr_cell_ptr, 0);
                builder.ins().jump(blocks[i + 1], &[]);
            }
            CommandOpt::Zero => {
                // Compute address: mem_start + mem_head
                let curr_cell_ptr = builder.ins().iadd(mem_start, mem_head);
                let zero = builder.ins().iconst(types::I8, 0);
                builder.ins().store(MemFlags::new(), zero, curr_cell_ptr, 0);
                builder.ins().jump(blocks[i + 1], &[]);
            }
            CommandOpt::LoopForever => {
                let curr_cell_ptr = builder.ins().iadd(mem_start, mem_head);
                let cmp_val = builder.ins().load(types::I8, MemFlags::new(), curr_cell_ptr, 0);
                builder.ins().brif(cmp_val, blocks[i], &[], blocks[i+1], &[]);
            }
            CommandOpt::OpenBr(dest) => {
                let curr_cell_ptr = builder.ins().iadd(mem_start, mem_head);
                let cmp_val = builder.ins().load(types::I8, MemFlags::new(), curr_cell_ptr, 0);
                builder.ins().brif(cmp_val, blocks[i+1], &[], blocks[*dest], &[]);
            }
            CommandOpt::CloseBr(dest) => {
                let curr_cell_ptr = builder.ins().iadd(mem_start, mem_head);
                let cmp_val = builder.ins().load(types::I8, MemFlags::new(), curr_cell_ptr, 0);
                builder.ins().brif(cmp_val, blocks[*dest], &[], blocks[i+1], &[]);
            }
        }
        builder.seal_block(blocks[i]);
    }
    builder.switch_to_block(exit_block);
    builder.seal_block(exit_block);
    builder.ins().return_(&[]);

    builder.finalize();

    // Define function body in the module
    module.define_function(func_id, &mut ctx).unwrap();
    module.clear_context(&mut ctx);
    let _ = module.finalize_definitions();


    // Get a callable function pointer
    let code_ptr = module.get_finalized_function(func_id);
    let func = unsafe {
        std::mem::transmute::<_, fn(*mut u8, *mut usize)>(code_ptr)
    };

    const TAPE_SIZE: usize = 30_000;
    let mut memory = vec![0u8; TAPE_SIZE];
    let mut mem_ptr: usize = 0;

    // Call the JIT function
    func(memory.as_mut_ptr(), &mut mem_ptr as *mut usize);

}

