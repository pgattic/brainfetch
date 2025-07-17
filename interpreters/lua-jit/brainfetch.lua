
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

  return result
end

function execute(prg)
  local prog = "local pc = 1\nlocal mem = {}\nfor i = 1, 30000 do mem[i] = 0 end\nlocal mem_ptr = 1\n"

  for pc = 1, #prg do
    curr = prg[pc]
    if     curr.cmd == INCVAL then prog = prog .. "mem[mem_ptr] = mem[mem_ptr] + " .. curr.num .. " % 256\n"
    elseif curr.cmd == DECVAL then prog = prog .. "mem[mem_ptr] = mem[mem_ptr] - " .. curr.num .. " % 256\n"
    elseif curr.cmd == ZERO then prog = prog .. "mem[mem_ptr] = 0\n"
    elseif curr.cmd == INCPTR then prog = prog .. "mem_ptr = mem_ptr + " .. curr.num .. "\n"
    elseif curr.cmd == DECPTR then prog = prog .. "mem_ptr = mem_ptr - " .. curr.num .. "\n"
    elseif curr.cmd == PUTCHAR then prog = prog .. "io.write(string.char(mem[mem_ptr]))\n"
    elseif curr.cmd == GETCHAR then prog = prog .. "mem[mem_ptr] = string.byte(io.read(1))\n"
    elseif curr.cmd == OPENBR then prog = prog .. "while mem[mem_ptr] ~= 0 do\n"
    elseif curr.cmd == CLOSEBR then prog = prog .. "end\n"
    end
  end
  loadstring(prog)()
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
  execute(opt_prog)
end

main()

