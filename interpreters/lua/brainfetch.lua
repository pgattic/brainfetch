
local INCVAL = 1
local DECVAL = 2
local INCPTR = 3
local DECPTR = 4
local PUTCHAR = 5
local GETCHAR = 6
local OPENBR = 7
local CLOSEBR = 8
local ZERO = 9

function tokenize(code)
  local result = {}
  for ch in code:gmatch(".") do
    if     ch == '+' then table.insert(result, INCVAL)
    elseif ch == '-' then table.insert(result, DECVAL)
    elseif ch == '>' then table.insert(result, INCPTR)
    elseif ch == '<' then table.insert(result, DECPTR)
    elseif ch == '.' then table.insert(result, PUTCHAR)
    elseif ch == ',' then table.insert(result, GETCHAR)
    elseif ch == '[' then table.insert(result, OPENBR)
    elseif ch == ']' then table.insert(result, CLOSEBR) end
  end
  return result
end

function is_repeat_cmd(item)
  return item == INCPTR or item == DECPTR or item == INCVAL or item == DECVAL
end

function optimize_code(code)
  local result = {}

  if #code == 0 then return result end

  -- Basically, the goal of the loop is to keep track of repeating repeatable commands and append 
  -- to `result` when a repeatable command is done repeating, and after each non-repeatable
  -- command

  local i = 2
  local prev = code[1]
  local count = 1

  while i <= #code do
    local curr = code[i]

    -- Detect and replace `[-]` with ZERO before doing anything else
    if prev == OPENBR and curr == DECVAL and code[i + 1] == CLOSEBR then
      table.insert(result, { cmd = ZERO, num = 1 })
      i = i + 3
      prev = code[i-1]
      count = 1
      goto continue
    end

    if curr == prev and is_repeat_cmd(curr) then
      count = count + 1;
    else
      table.insert(result, { cmd = prev, num = count });
      prev = curr
      count = 1
    end

    i = i + 1;
    ::continue::
  end

  table.insert(result, {cmd = prev, num = count});

  -- Add jumps to brackets
  local unsolved = {};
  for i = 1, #result do
    local cmd = result[i].cmd;
    if cmd == OPENBR then
      table.insert(unsolved, i)
    elseif cmd == CLOSEBR then
      local connection = unsolved[#unsolved]
      unsolved[#unsolved] = nil
      result[connection].num = i
      result[i].num = connection
    end
  end

  if #unsolved > 0 then
    print("shoot")
  end

  return result
end

function execute(prg)
  local pc = 1
  local mem = {}
  for i = 1, 30000 do mem[i] = 0 end
  local mem_ptr = 1

  while pc <= #prg do
    curr = prg[pc]
    if     curr.cmd == INCVAL then mem[mem_ptr] = mem[mem_ptr] + curr.num % 256
    elseif curr.cmd == DECVAL then mem[mem_ptr] = mem[mem_ptr] - curr.num % 256
    elseif curr.cmd == ZERO then mem[mem_ptr] = 0
    elseif curr.cmd == INCPTR then mem_ptr = mem_ptr + curr.num
    elseif curr.cmd == DECPTR then mem_ptr = mem_ptr - curr.num
    elseif curr.cmd == PUTCHAR then io.write(string.char(mem[mem_ptr]))
    elseif curr.cmd == GETCHAR then mem[mem_ptr] = string.byte(io.read(1))
    elseif curr.cmd == OPENBR then
      if mem[mem_ptr] == 0 then
        pc = curr.num
      end
    elseif curr.cmd == CLOSEBR then
      if mem[mem_ptr] ~= 0 then
        pc = curr.num
      end
    end
    pc = pc + 1
  end
end

function pretty_print_2d(list)
  io.write("{")
  for i = 1, #list do
    io.write("{ cmd: " .. list[i].cmd .. ", num: " .. list[i].num .. "}, ")
  end
  io.write("}\n")
end

function main()
  local fpath = arg[1]
  if fpath == nil then
    print("ERROR: Please specify a file.")
    os.exit(1)
  end
  local f = io.open(fpath, "rb")
  if f == nil then
    print("ERROR: unable to open file: " .. fpath)
    os.exit(1)
  end
  local content = f:read("*all")
  f:close()

  local program = tokenize(content)
  local opt_prog = optimize_code(program)
  -- print(table.concat(program, ", "))
  -- pretty_print_2d(opt_prog)
  execute(opt_prog)
end

main()

