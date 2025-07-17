
local INCVAL = 1
local DECVAL = 2
local INCPTR = 3
local DECPTR = 4
local PUTCHAR = 5
local GETCHAR = 6
local OPENBR = 7
local CLOSEBR = 8

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

function execute(prg)
  local pc = 1
  local mem = {}
  for i = 1, 30000 do mem[i] = 0 end
  local mem_ptr = 1

  while pc <= #prg do
    cmd = prg[pc]
    if     cmd == INCVAL then mem[mem_ptr] = mem[mem_ptr] + 1
    elseif cmd == DECVAL then mem[mem_ptr] = mem[mem_ptr] - 1
    elseif cmd == INCPTR then mem_ptr = mem_ptr + 1
    elseif cmd == DECPTR then mem_ptr = mem_ptr - 1
    elseif cmd == PUTCHAR then io.write(string.char(mem[mem_ptr]))
    elseif cmd == GETCHAR then print("yeet")
    elseif cmd == OPENBR then
      if mem[mem_ptr] == 0 then
        local out = 1
        while out > 0 do
          pc = pc + 1
          if     prg[pc] == OPENBR then out = out + 1
          elseif prg[pc] == CLOSEBR then out = out - 1 end
        end
      end
    elseif cmd == CLOSEBR then
      if mem[mem_ptr] ~= 0 then
        local out = 1
        while out > 0 do
          pc = pc - 1
          if     prg[pc] == CLOSEBR then out = out + 1
          elseif prg[pc] == OPENBR then out = out - 1 end
        end
      end
    end
    pc = pc + 1
  end
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
  execute(program)
end

main()

