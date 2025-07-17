
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

  return result
end

function jit_compile(prg)
  local lines = {
    "local pc = 1",
    "local mem = {}",
    "for i = 1, 30000 do mem[i] = 0 end",
    "local mem_ptr = 1",
    "local put = io.write",
    "local get = function() return string.byte(io.read(1)) or 0 end",
  }

  for pc = 1, #prg do
    curr = prg[pc]
    if     curr.cmd == INCVAL  then table.insert(lines, "mem[mem_ptr] = mem[mem_ptr] + " .. curr.num .. " % 256")
    elseif curr.cmd == DECVAL  then table.insert(lines, "mem[mem_ptr] = mem[mem_ptr] - " .. curr.num .. " % 256")
    elseif curr.cmd == ZERO    then table.insert(lines, "mem[mem_ptr] = 0")
    elseif curr.cmd == INCPTR  then table.insert(lines, "mem_ptr = mem_ptr + " .. curr.num)
    elseif curr.cmd == DECPTR  then table.insert(lines, "mem_ptr = mem_ptr - " .. curr.num)
    elseif curr.cmd == PUTCHAR then table.insert(lines, "put(string.char(mem[mem_ptr]))")
    elseif curr.cmd == GETCHAR then table.insert(lines, "mem[mem_ptr] = get()")
    elseif curr.cmd == OPENBR  then table.insert(lines, "while mem[mem_ptr] ~= 0 do")
    elseif curr.cmd == CLOSEBR then table.insert(lines, "end")
    end
  end
  -- `load` "Compiles" the inputted Lua code and returns a function that executes it
  return load(table.concat(lines, "\n"))
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
  local fn = jit_compile(opt_prog)
  fn()
end

main()

