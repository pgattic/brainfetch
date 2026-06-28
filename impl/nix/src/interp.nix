with builtins; let
  h = import ./helpers.nix;

  new_bf_state = {
    output = [];
    left = [];
    curr = 0;
    right = [];
  };

  add = x: state: state // { curr = h.mod (state.curr + x) 256; };
  set = x: state: state // { curr = x; };
  next = state: state // (if state.right == [] then {
    curr = 0;
  } else {
    right = tail state.right;
    curr = head state.right;
  }) // {
    left = [ state.curr ] ++ state.left;
  };

  prev = state: state // (if state.left == [] then {
    curr = 0;
  } else {
    left = tail state.left;
    curr = head state.left;
  }) // {
    right = [ state.curr ] ++ state.right;
  };

  move = x: state:
    if x > 0 then
      h.repeat x next state
    else if x < 0 then
      h.repeat (-x) prev state
    else state;

  put_char = state: state // {
    output = state.output ++ [ (h.asciiCodeToString state.curr) ];
  };

  iter_until = test: fn: input:
    if test input then input else
    iter_until test fn (fn input);

  interp_one = cmd:
    if cmd.type == "Add" then add cmd.count
    else if cmd.type == "Move" then move cmd.count
    else if cmd.type == "PutChar" then put_char
    else if cmd.type == "GetChar" then throw "GetChar not implemented"
    else if cmd.type == "Loop" then iter_until (st: st.curr == 0) (interp_many cmd.nodes)
    else if cmd.type == "Zero" then set 0
    else throw "Invalid Token";

  interp_many = prog: state:
    if prog == [] then state else
    interp_many (tail prog) (interp_one (head prog) state);

  interp = prog: concatStringsSep "" (interp_many prog new_bf_state).output;
in {
  inherit interp;
}
