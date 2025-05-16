use cranelift::prelude::*;
use cranelift_jit::{JITBuilder, JITModule};
use cranelift_module::{Linker, Module};
use std::collections::HashMap;
use std::io::{Read, Write};
use std::mem;

struct JITState {
    memory: Vec<u8>,
    memory_ptr: usize,
    stdin: Box<dyn Read>,
    stdout: Box<dyn Write>,
}

impl JITState {
    fn new() -> Self {
        JITState {
            memory: vec![0],
            memory_ptr: 0,
            stdin: Box::new(std::io::stdin()),
            stdout: Box::new(std::io::stdout()),
        }
    }

    fn grow_memory(&mut self, amount: usize) {
        self.memory.extend(std::iter::repeat(0).take(amount));
    }
}

fn jit_putchar(state_ptr: *mut JITState) {
    unsafe {
        let state = &mut *state_ptr;
        if state.memory_ptr >= state.memory.len() {
            state.grow_memory(state.memory_ptr - state.memory.len() + 1);
        }
        if let Some(c) = char::from_u32(state.memory[state.memory_ptr] as u32) {
            let _ = state.stdout.write(&[state.memory[state.memory_ptr]]);
            let _ = state.stdout.flush();
        }
    }
}

fn jit_getchar(state_ptr: *mut JITState) {
    unsafe {
        let state = &mut *state_ptr;
        if state.memory_ptr >= state.memory.len() {
            state.grow_memory(state.memory_ptr - state.memory.len() + 1);
        }
        let mut buffer = [0u8; 1];
        let _ = state.stdin.read_exact(&mut buffer);
        state.memory[state.memory_ptr] = buffer[0];
    }
}

pub fn execute_jit(prg: &Vec<CommandOpt>) -> Result<(), String> {
    let builder = JITBuilder::new(cranelift_module::default_jit_config().unwrap()).unwrap();
    let mut module = JITModule::new(builder);
    let mut ctx = module.make_context();
    let mut func_ctx = FunctionBuilderContext::new();
    let mut builder = FunctionBuilder::new(&mut ctx.func, &mut func_ctx);

    let state_ptr_type = module.target_config().pointer_type();
    let i64_type = types::I64;
    let i8_type = types::I8;
    let i32_type = types::I32;
    let usize_type = module.target_config().pointer_type();

    let state_param = builder.append_block_param(builder.create_entry_block(), state_ptr_type);

    builder.switch_to_block(builder.create_entry_block());

    let mut blocks: HashMap<usize, Block> = HashMap::new();
    let mut block_params: HashMap<usize, VecValue> = HashMap::new();
    for i in 0..prg.len() {
        blocks.insert(i, builder.create_block());
    }
    let exit_block = builder.create_block();

    builder.ins().jump(*blocks.get(&0).unwrap(), &[]);

    for (prg_head, command) in prg.iter().enumerate() {
        builder.switch_to_block(*blocks.get(&prg_head).unwrap());

        match command {
            CommandOpt::ChPtr(amt) => {
                let state_ptr_val = state_param;
                let offset = builder.ins().iconst(i64_type, *amt as i64);

                // Load memory_ptr
                let memory_ptr_ptr = builder.ins().struct_field(state_ptr_val, 1); // Offset of memory_ptr in JITState
                let memory_ptr_val = builder.ins().load(usize_type, MemFlags::new(), memory_ptr_ptr, 0);

                let new_ptr_val = if *amt >= 0 {
                    builder.ins().iadd(memory_ptr_val, offset)
                } else {
                    builder.ins().isub(memory_ptr_val, builder.ins().ineg(offset))
                };

                // Store new memory_ptr
                builder.ins().store(MemFlags::new(), new_ptr_val, memory_ptr_ptr, 0);

                // Grow memory if needed (simplified for now, could be optimized)
                let memory_len_ptr = builder.ins().struct_field(state_ptr_val, 0); // Offset of memory in JITState
                let memory_len_val = builder.ins().load(usize_type, MemFlags::new(), memory_len_ptr, 8); // Assuming Vec length is 8 bytes after ptr

                let cmp = builder.ins().icmp(IntCC::UnsignedLessThanOrEqual, memory_len_val, new_ptr_val);
                let grow_block = builder.create_block();
                let continue_block = builder.create_block();
                builder.ins().brif(cmp, grow_block, &[], continue_block, &[]);

                builder.switch_to_block(grow_block);
                let grow_amount = builder.ins().isub(new_ptr_val, memory_len_val);
                let call_grow = builder.ins().call(module.declare_function("grow_memory", CallConv::SystemV, &[], &[state_ptr_type, usize_type]).unwrap(), &[state_ptr_val, grow_amount]);
                builder.ins().jump(continue_block, &[]);

                builder.switch_to_block(continue_block);

                if prg_head + 1 < prg.len() {
                    builder.ins().jump(*blocks.get(&(prg_head + 1)).unwrap(), &[]);
                } else {
                    builder.ins().jump(exit_block, &[]);
                }
            }
            CommandOpt::ChVal(amt) => {
                let state_ptr_val = state_param;

                // Load memory_ptr
                let memory_ptr_ptr = builder.ins().struct_field(state_ptr_val, 1);
                let memory_ptr_val = builder.ins().load(usize_type, MemFlags::new(), memory_ptr_ptr, 0);

                // Load memory
                let memory_ptr = builder.ins().struct_field(state_ptr_val, 0);
                let base_ptr = builder.ins().load(state_ptr_type, MemFlags::new(), memory_ptr, 0); // Pointer to the start of the Vec

                let byte_offset = builder.ins().iadd(base_ptr, memory_ptr_val);
                let value = builder.ins().load(i8_type, MemFlags::new(), byte_offset, 0);
                let new_value = builder.ins().iadd_imm(value, *amt as i64);
                builder.ins().store(MemFlags::new(), new_value, byte_offset, 0);

                if prg_head + 1 < prg.len() {
                    builder.ins().jump(*blocks.get(&(prg_head + 1)).unwrap(), &[]);
                } else {
                    builder.ins().jump(exit_block, &[]);
                }
            }
            CommandOpt::PutChar => {
                let state_ptr_val = state_param;
                builder.ins().call(
                    module
                        .declare_function("putchar", CallConv::SystemV, &[state_ptr_type], &[])
                        .unwrap(),
                    &[state_ptr_val],
                );
                if prg_head + 1 < prg.len() {
                    builder.ins().jump(*blocks.get(&(prg_head + 1)).unwrap(), &[]);
                } else {
                    builder.ins().jump(exit_block, &[]);
                }
            }
            CommandOpt::GetChar => {
                let state_ptr_val = state_param;
                builder.ins().call(
                    module
                        .declare_function("getchar", CallConv::SystemV, &[state_ptr_type], &[])
                        .unwrap(),
                    &[state_ptr_val],
                );
                if prg_head + 1 < prg.len() {
                    builder.ins().jump(*blocks.get(&(prg_head + 1)).unwrap(), &[]);
                } else {
                    builder.ins().jump(exit_block, &[]);
                }
            }
            CommandOpt::Zero => {
                let state_ptr_val = state_param;

                // Load memory_ptr
                let memory_ptr_ptr = builder.ins().struct_field(state_ptr_val, 1);
                let memory_ptr_val = builder.ins().load(usize_type, MemFlags::new(), memory_ptr_ptr, 0);

                // Load memory
                let memory_ptr = builder.ins().struct_field(state_ptr_val, 0);
                let base_ptr = builder.ins().load(state_ptr_type, MemFlags::new(), memory_ptr, 0);

                let byte_offset = builder.ins().iadd(base_ptr, memory_ptr_val);
                builder.ins().store(MemFlags::new(), builder.ins().iconst(i8_type, 0), byte_offset, 0);

                if prg_head + 1 < prg.len() {
                    builder.ins().jump(*blocks.get(&(prg_head + 1)).unwrap(), &[]);
                } else {
                    builder.ins().jump(exit_block, &[]);
                }
            }
            CommandOpt::LoopForever => {
                let state_ptr_val = state_param;

                // Load memory_ptr
                let memory_ptr_ptr = builder.ins().struct_field(state_ptr_val, 1);
                let memory_ptr_val = builder.ins().load(usize_type, MemFlags::new(), memory_ptr_ptr, 0);

                // Load memory
                let memory_ptr = builder.ins().struct_field(state_ptr_val, 0);
                let base_ptr = builder.ins().load(state_ptr_type, MemFlags::new(), memory_ptr, 0);

                let byte_offset = builder.ins().iadd(base_ptr, memory_ptr_val);
                let value = builder.ins().load(i8_type, MemFlags::new(), byte_offset, 0);
                let is_zero = builder.ins().icmp_imm(IntCC::Equal, value, 0);

                builder.ins().brif(is_zero, *blocks.get(&(prg_head + 1)).unwrap_or(&exit_block), &[], *blocks.get(&(prg_head - 1)).unwrap(), &[]);
            }
            CommandOpt::OpenBr(target) => {
                let state_ptr_val = state_param;

                // Load memory_ptr
                let memory_ptr_ptr = builder.ins().struct_field(state_ptr_val, 1);
                let memory_ptr_val = builder.ins().load(usize_type, MemFlags::new(), memory_ptr_ptr, 0);

                // Load memory
                let memory_ptr = builder.ins().struct_field(state_ptr_val, 0);
                let base_ptr = builder.ins().load(state_ptr_type, MemFlags::new(), memory_ptr, 0);

                let byte_offset = builder.ins().iadd(base_ptr, memory_ptr_val);
                let value = builder.ins().load(i8_type, MemFlags::new(), byte_offset, 0);
                let is_zero = builder.ins().icmp_imm(IntCC::Equal, value, 0);

                builder.ins().brif(
                    is_zero,
                    *blocks.get(target).unwrap_or(&exit_block),
                    &[],
                    *blocks.get(&(prg_head + 1)).unwrap_or(&exit_block),
                    &[],
                );
            }
            CommandOpt::CloseBr(target) => {
                let state_ptr_val = state_param;

                // Load memory_ptr
                let memory_ptr_ptr = builder.ins().struct_field(state_ptr_val, 1);
                let memory_ptr_val = builder.ins().load(usize_type, MemFlags::new(), memory_ptr_ptr, 0);

                // Load memory
                let memory_ptr = builder.ins().struct_field(state_ptr_val, 0);
                let base_ptr = builder.ins().load(state_ptr_type, MemFlags::new(), memory_ptr, 0);

                let byte_offset = builder.ins().iadd(base_ptr, memory_ptr_val);
                let value = builder.ins().load(i8_type, MemFlags::new(), byte_offset, 0);
                let is_not_zero = builder.ins().icmp_imm(IntCC::NotEqual, value, 0);

                builder.ins().brif(
                    is_not_zero,
                    *blocks.get(target).unwrap_or(&exit_block),
                    &[],
                    *blocks.get(&(prg_head + 1)).unwrap_or(&exit_block),
                    &[],
                );
            }
        }
    }

    builder.switch_to_block(exit_block);
    builder.ins().return_(&[]);

    let func_id = module
        .declare_function("brainfuck", CallConv::SystemV, &[state_ptr_type], &[])
        .map_err(|e| e.to_string())?;

    module.define_function(func_id, &mut ctx).unwrap();
    module.clear_context(&mut ctx);

    let putchar_id = module
        .declare_function("putchar", CallConv::SystemV, &[state_ptr_type], &[])
        .map_err(|e| e.to_string())?;
    module.define_function(
        putchar_id,
        &mut Context {
            func: Function::with_name_signature(ExternalName::user(0, 0), Signature::new(CallConv::SystemV, &[state_ptr_type], &[])),
            isa: module.isa(),
            memory_pool: &mut module.memory_pool,
            data_layout: module.target_config().data_layout().clone(),
        },
    )
    .unwrap();

    let getchar_id = module
        .declare_function("getchar", CallConv::SystemV, &[state_ptr_type], &[])
        .map_err(|e| e.to_string())?;
    module.define_function(
        getchar_id,
        &mut Context {
            func: Function::with_name_signature(ExternalName::user(0, 1), Signature::new(CallConv::SystemV, &[state_ptr_type], &[])),
            isa: module.isa(),
            memory_pool: &mut module.memory_pool,
            data_layout: module.target_config().data_layout().clone(),
        },
    )
    .unwrap();

    let grow_memory_id = module
        .declare_function("grow_memory", CallConv::SystemV, &[state_ptr_type, usize_type], &[])
        .map_err(|e| e.to_string())?;
    module.define_function(
        grow_memory_id,
        &mut Context {
            func: Function::with_name_signature(ExternalName::user(0, 2), Signature::new(CallConv::SystemV, &[state_ptr_type, usize_type], &[])),
            isa: module.isa(),
            memory_pool: &mut module.memory_pool,
            data_layout: module.target_config().data_layout().clone(),
        },
    )
    .unwrap();

    module.link(Linker::new()).map_err(|e| e.to_string())?;
    module.finish();

    let code = module.get_finalized_function(func_id);
    let ptr_to_code = code.as_ptr() as *mut u8;

    let mut jit_state = JITState::new();
    let state_ptr = &mut jit_state as *mut JITState;

    let jit_func = unsafe { mem::transmute::<*mut u8, extern "C" fn(*mut JITState)>(ptr_to_code) };
    jit_func(state_ptr);

    Ok(())
}

