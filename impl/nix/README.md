
# BrainF*** interpreter in raw Nix

No, not as a derivation

Current goal: Try to get this input:

```
++[>++<-].
```

to produce something like:

```nix
[
  { type = "+"; count = 2; }
  {
    type = "loop";
    body = [
      { type = ">"; count = 1; }
      { type = "+"; count = 2; }
      { type = "<"; count = 1; }
      { type = "-"; count = 1; }
    ];
  }
  { type = "."; }
]
```

