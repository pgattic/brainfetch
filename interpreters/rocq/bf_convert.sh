#!/usr/bin/env bash
# usage: ./bf_convert.sh program.bf

tr -cd '+<>.,[]-' < "$1" | sed '
  s/+/bf_inc; /g
  s/-/bf_dec; /g
  s/>/bf_next; /g
  s/</bf_prev; /g
  s/\./bf_output; /g
  s/,/bf_input; /g
  s/\[/bf_loop [; /g
  s/\]/]; /g
  s/\[; /[/g
  s/; ]/]/g
  s/; $//
'
