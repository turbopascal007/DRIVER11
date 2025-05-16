unit verbinpr;

interface

uses universe, player, fun, fund, vard, stringd, task, mystrings,
     strings, syscons, room, item, monster, err2;

function exec_verb (tptr : TaskPtr; universe : UniversePtr) : boolean;


implementation

const {$I defines.inc}

var
   funtab,
   ifuntab    : FunDaemon;
   argstr,
   verbargstr,
   tempptr    : pchar;
   me         : PlayerPtr;
   globrmptr  : RoomPtr;
   globitmptr : ItemPtr;
   globmnptr  : MonsterPtr;
   u          : UniversePtr;
   globverbs  : StringDPtr;
   if_set     : array [1..MAXDEPTH] of boolean;
   if_depth   : word;
   start_while: array [1..MAXDEPTH] of StringPtr;
   while_depth: word;


procedure memerr;
begin
     error (argstr, 0, me);
     error (': out of memory^', 0, me);
end;

function find_first_var : boolean;
begin
     if not (globrmptr = nil) then
     begin
          find_first_var:= globrmptr^.vartab.find_first;
          exit;
     end;
     if not (globitmptr = nil) then
     begin
          find_first_var:= globitmptr^.vartab.find_first;
          exit;
     end;
     if not (globmnptr = nil) then
     begin
          find_first_var:= globmnptr^.vartab.find_first;
          exit;
     end;
     find_first_var:= me^.vartab.find_first;
end;

procedure retrieve_var (var varr : vartabptr);
begin
     if not (globrmptr = nil) then
     begin
          globrmptr^.vartab.retrieve (varr);
          exit;
     end;
     if not (globitmptr = nil) then
     begin
          globitmptr^.vartab.retrieve (varr);
          exit;
     end;
     if not (globmnptr = nil) then
     begin
          globmnptr^.vartab.retrieve (varr);
          exit;
     end;
     me^.vartab.retrieve (varr);
end;

function find_next_var : boolean;
begin
     if not (globrmptr = nil) then
     begin
          find_next_var:= globrmptr^.vartab.find_next;
          exit;
     end;
     if not (globitmptr = nil) then
     begin
          find_next_var:= globitmptr^.vartab.find_next;
          exit;
     end;
     if not (globmnptr = nil) then
     begin
          find_next_var:= globmnptr^.vartab.find_next;
          exit;
     end;
     find_next_var:= me^.vartab.find_next;
end;

procedure do_write; far;
begin
     me^.console.cwrite (argstr);
end;

procedure do_writevar; far;
var stri : string[9];
    tempptr : pchar;
    varr : vartabptr;
begin
     if find_first_var then
     repeat
           retrieve_var (varr);
           if (StrIComp (varr^.id, argstr) = 0) then
           begin
                if (varr^.typ = s) then
                begin
                     me^.console.cwrite (varr^.str);
                     break;
                end
                else
                begin
                     if (maxavail < 10) then
                     begin
                          me^.console.cwriteln ('Out of memory');
                          exit;
                     end;
                     getmem (tempptr, 10);
                     str (varr^.int, stri);
                     StrPCopy (tempptr, stri);
                     me^.console.cwrite (tempptr);
                     freemem (tempptr, 10);
                     break;
                end;
           end;
     until not find_next_var;
end;

procedure do_echo; far;
var playptr : PlayerPtr;
begin
     if (u^.pd^.find_first) then
     repeat
           u^.pd^.retrieve (playptr);
           if ((playptr^.env = me^.env) and (not (playptr = me))) then
              playptr^.console.cwrite (argstr);
     until not u^.pd^.find_next;
end;

procedure do_echovar; far;
var stri : string[9];
    tempptr : pchar;
    varr : vartabptr;
    playptr : PlayerPtr;
begin
     if find_first_var then
     repeat
           retrieve_var (varr);
           if (StrIComp (varr^.id, argstr) = 0) then
           begin
                if (varr^.typ = s) then
                begin
                     if (u^.pd^.find_first) then
                     repeat
                          u^.pd^.retrieve (playptr);
                          if ((playptr^.env = me^.env) and (not (playptr = me))) then
                              playptr^.console.cwrite (varr^.str);
                     until not u^.pd^.find_next;
                     break;
                end
                else
                begin
                     if (maxavail < 10) then
                     begin
                          me^.console.cwriteln ('Out of memory');
                          exit;
                     end;
                     getmem (tempptr, 10);
                     str (varr^.int, stri);
                     StrPCopy (tempptr, stri);
                     if (u^.pd^.find_first) then
                     repeat
                           u^.pd^.retrieve (playptr);
                           if ((playptr^.env = me^.env) and (not (playptr = me))) then
                               playptr^.console.cwrite (tempptr);
                     until not u^.pd^.find_next;
                     freemem (tempptr, 10);
                     break;
                end;
           end;
     until not find_next_var;
end;

function bool_eval (str : pchar) : boolean;
var i, j, k, exp1len, exp2len, code : word;
    exp1, exp2 : pchar;
    operand : char;
    varr : vartabptr;
    found : boolean;
begin
     exp1len:= 0;
     exp2len:= 0;
     bool_eval:= false;
     found:= false;

     if (StrLen (str) > 4) then
     begin
          i:= 4;
          while not (((str[i-3] = #32) and (str[i-2] = 'o') and
                      (str[i-1] = 'r') and (str[i] = #32)) or (str[i] = #0))
                do inc (i);
          if not (str[i] = #0) then
          begin
               if (maxavail < (i-2) + (StrLen (str) - i + 1)) then
               begin
                    error (str, 0, me);
                    error (': out of memory^', 0, me);
                    exit;
               end;
               getmem (exp1, i - 2);
               for exp1len:= 0 to i-4 do exp1[exp1len]:= str[exp1len];
               exp1[i - 3]:= #0;
               getmem (exp2, StrLen (str) - i + 1);
               for exp2len:= i to StrLen (str) do exp2[exp2len - i]:= str[exp2len];
               exp2[StrLen (str) + 1]:= #0;
               bool_eval:= (bool_eval (exp1)) or (bool_eval (exp2));
               freemem (exp1, i - 2);
               freemem (exp2, StrLen (str) - i + 1);
               exit;
          end;
     end;

     if (StrLen (str) > 5) then
     begin
          i:= 5;
          while not (((str[i-4] = #32) and (str[i-3] = 'a') and
                      (str[i-2] = 'n') and (str[i-1] = 'd') and
                      (str[i] = #32)) or (str[i] = #0))
                do inc (i);
          if not (str[i] = #0) then
          begin
               if (maxavail < (i-3) + (StrLen (str) - i + 1)) then
               begin
                    error (str, 0, me);
                    error (': out of memory^', 0, me);
                    exit;
               end;
               getmem (exp1, i - 3);
               for exp1len:= 0 to i-5 do exp1[exp1len]:= str[exp1len];
               exp1[i - 4]:= #0;
               getmem (exp2, StrLen (str) - i + 1);
               for exp2len:= i to StrLen (str) do exp2[exp2len - i]:= str[exp2len];
               exp2[StrLen (str) + 1]:= #0;
               bool_eval:= (bool_eval (exp1)) and (bool_eval (exp2));
               freemem (exp1, i - 3);
               freemem (exp2, StrLen (str) - i + 1);
               exit;
          end;
     end;

     i:= 0;
     j:= 0;
     exp1len:= 0;
     exp2len:= 0;
     while (str[i] = #32) do inc (i);
     if (str[i] = '(') then inc (i);
     while (str[i] = #32) do inc (i);

     while not ((str[i + exp1len] = #32) or (str[i + exp1len] = #0)) do inc (exp1len);

     if (exp1len = 0) then
     begin
          error (str, 0, me);
          error (':^left value of comparison absent in boolean evaluation (returning false)^', 0, me);
          exit;
     end;
     if (maxavail < exp1len) then
     begin
          error (str, 0, me);
          error (': out of memory^', 0, me);
          exit;
     end;
     getmem (exp1, exp1len);

     while not ((str[i] = #32) or (str[i] = #0)) do
     begin
          exp1[j]:= str[i];
          inc (i);
          inc (j);
     end;
     exp1[j]:= #0;
     while (str[i] = #32) do inc(i);
     operand:= str[i];

     if (str[i] = #0) then
     begin
          error (str, 0, me);
          error (':^operand in comparison absent in boolean evaluation (returning false)^', 0, me);
          freemem (exp1, exp1len);
          exit;
     end;

     while not ((str[i] = #32) or (str[i] = #0)) do inc (i);
     while (str[i] = #32) do inc (i);
     while not ((str[i + exp2len] = #32) or (str[i + exp2len] = ')') or
                (str[i + exp2len] = #0)) do inc (exp2len);

     if (exp2len = 0) then
     begin
          error (str, 0, me);
          error (':^right value of comparison absent in boolean evaluation (returning false)^',0, me);
          freemem (exp1, exp1len);
          exit;
     end;
     if (maxavail < exp2len) then
     begin
          error (str, 0, me);
          error (': out of memory^', 0, me);
          exit;
     end;
     getmem (exp2, exp2len);

     k:= i;
     while not ((str[i] = #32) or (str[i] = ')') or (str[i] = #0)) do
     begin
          exp2[i-k]:= str[i];
          inc (i);
     end;
     exp2[i-k]:= #0;

     if find_first_var then
     repeat
           retrieve_var (varr);
           if (StrIComp (varr^.id, exp1) = 0) then
           begin
                found:= true;
                freemem (exp1, exp1len);
                if (varr^.typ = s) then
                case operand of
                '=': if (StrIComp (varr^.str, exp2) = 0) then
                     begin
                          bool_eval:= true;
                          freemem (exp2, exp2len);
                          exit;
                     end;
                '<': if (StrIComp (varr^.str, exp2) < 0) then
                     begin
                          bool_eval:= true;
                          freemem (exp2, exp2len);
                          exit;
                     end;
                '>': if (StrIComp (varr^.str, exp2) > 0) then
                     begin
                          bool_eval:= true;
                          freemem (exp2, exp2len);
                          exit;
                     end;
                else
                    begin
                         error (str, 0, me);
                         error (':^operand mismatch in boolean evaluation (returning false)^', 0, me);
                         freemem (exp2, exp2len);
                         exit;
                    end;
                end
                else
                begin
                     val (StrPas (exp2), i, code);
                     if (code <> 0) then
                     begin
                          error (str, 0, me);
                          error (':^', 0, me);
                          error (exp2, 0, me);
                          error (' is not a numeric value (returning false)^',0, me);
                          freemem (exp2, exp2len);
                          exit;
                     end;

                     case operand of
                     '=': if (varr^.int = i) then
                          begin
                               bool_eval:= true;
                               freemem (exp2, exp2len);
                               exit;
                          end;
                     '<': if (varr^.int < i) then
                          begin
                               bool_eval:= true;
                               freemem (exp2, exp2len);
                               exit;
                          end;
                     '>': if (varr^.int > i) then
                          begin
                               bool_eval:= true;
                               freemem (exp2, exp2len);
                               exit;
                          end;
                     else
                         begin
                              error (str, 0, me);
                              error (':^operand mismatch in boolean evaluation (returning false)^', 0, me);
                              freemem (exp2, exp2len);
                              exit;
                         end;
                     end;
                end;
           end;
     until not find_next_var;

     if not found then
     begin
          error (str, 0, me);
          error (':^variable ',0, me);
          error (exp1, 0, me);
          error (' in boolean evaluation not found (returning false)^', 0, me);
          freemem (exp1, exp1len);
     end;

     freemem (exp2, exp2len);
end;

procedure do_endif; far;
begin
     if_set[if_depth]:= false;
     if (if_depth > 0) then dec (if_depth);
end;

procedure do_if; far;
begin
     inc (if_depth);
     if_set[if_depth]:= bool_eval (argstr);
     if not if_set[if_depth] then
     begin
          while globverbs^.find_next do
          begin
               if (StrLIComp (globverbs^.current^.line, 'endif', 5) = 0) then
               begin
                    do_endif;
                    exit;
               end;
               if (StrLIComp (globverbs^.current^.next^.line, 'if', 2) = 0) then exit;
               if (StrLIComp (globverbs^.current^.line, 'else', 4) = 0) then exit;
         end;
         error ('if without endif (execution aborted)^', 0 , me);
         dec (if_depth);
     end;
end;

procedure do_else; far;
begin
     if not if_set[if_depth] then
     begin
          error ('else without if (skipping)^', 0, me);
          exit;
     end;
     if_set[if_depth]:= false;
     while globverbs^.find_next do
     begin
          if (StrLIComp (globverbs^.current^.line, 'endif', 5) = 0) then
          begin
               do_endif;
               exit;
          end;
          if (StrLIComp (globverbs^.current^.next^.line, 'if', 2) = 0) then exit;
     end;
     error ('else without endif (execution aborted)^', 0, me);
     dec (if_depth);
end;

procedure do_while; far;
begin
     inc (while_depth);
     start_while[while_depth]:= globverbs^.current;
     if not (bool_eval (argstr)) then
     begin
          if (while_depth > 0) then dec (while_depth);
          while globverbs^.find_next do
             if (StrLIComp (globverbs^.current^.line, 'endwhile', 8) = 0) then exit;
          error ('while without endwhile (execution aborted)^', 0, me);
     end;
end;

procedure do_endwhile; far;
begin
     argstr:= shift_str (start_while[while_depth]^.line);
     if not (bool_eval (argstr)) then
     begin
          if (while_depth > 0) then dec (while_depth);
          exit;
     end;
     globverbs^.current:= start_while[while_depth];
end;

procedure set_str; far;
var i, j : word;
    argbuf : pchar;
begin
     i:= 0;
     while (argstr[i] = #32) do inc (i);
     j:= i;
     while not ((argstr[j] = #32) or (argstr[j] = #0)) do inc (j);
     if (maxavail < j) then
     begin
          error (globverbs^.current^.line, 0, me);
          error (': out of memory^', 0, me);
          exit;
     end;
     getmem (argbuf, j);
     j:= 0;
     while not ((argstr[i] = #32) or (argstr[i] = #0)) do
     begin
          argbuf[j]:= argstr[i];
          inc (i);
          inc (j);
     end;
     argbuf[j]:= #0;
     argstr:= shift_str (argstr);
     if not (globrmptr = nil) then
     begin
          if not (globrmptr^.set_strvar (argbuf, argstr)) then memerr;
          freemem (argbuf, StrLen (argbuf) + 1);
          exit;
     end;
     if not (globitmptr = nil) then
     begin
          if not (globitmptr^.set_strvar (argbuf, argstr)) then memerr;
          freemem (argbuf, StrLen (argbuf) + 1);
          exit;
     end;
     if not (globmnptr = nil) then
     begin
          if not (globmnptr^.set_strvar (argbuf, argstr)) then memerr;
          freemem (argbuf, StrLen (argbuf) + 1);
          exit;
     end;
     if not (me^.set_strvar (argbuf, argstr)) then memerr;
     freemem (argbuf, StrLen (argbuf) + 1);
end;

procedure set_int; far;
var i, j : integer;
    argbuf : pchar;
begin
     i:= 0;
     while (argstr[i] = #32) do inc (i);
     j:= i;
     while not ((argstr[j] = #32) or (argstr[j] = #0)) do inc (j);
     if (maxavail < j) then
     begin
          error (globverbs^.current^.line, 0, me);
          error (': out of memory^', 0, me);
          exit;
     end;
     getmem (argbuf, j);
     j:= 0;
     while not ((argstr[i] = #32) or (argstr[i] = #0)) do
     begin
          argbuf[j]:= argstr[i];
          inc (i);
          inc (j);
     end;
     argbuf[j]:= #0;
     argstr:= shift_str (argstr);
     val (StrPas (argstr), i, j);
     if (j <> 0) then
     begin
          error (argstr, 0, me);
          error (': integer value expected^',0, me);
          exit;
     end;
     if not (globrmptr = nil) then
     begin
          if not (globrmptr^.set_intvar (argbuf, i)) then memerr;
          freemem (argbuf, StrLen (argbuf) + 1);
          exit;
     end;
     if not (globitmptr = nil) then
     begin
          if not (globitmptr^.set_intvar (argbuf, i)) then memerr;
          freemem (argbuf, StrLen (argbuf) + 1);
          exit;
     end;
     if not (globmnptr = nil) then
     begin
          if not (globmnptr^.set_intvar (argbuf, i)) then memerr;
          freemem (argbuf, StrLen (argbuf) + 1);
          exit;
     end;
     if not (me^.set_intvar (argbuf, i)) then memerr;
     freemem (argbuf, StrLen (argbuf) + 1);
end;

procedure set_var; far;
var varr : vartabptr;
    i : word;
begin
     i:= 0;
     while (argstr[i] = #32) do inc (i);
     while not ((argstr[i] = #32) or (argstr[i] = #0)) do inc (i);
     if find_first_var then
     repeat
           retrieve_var (varr);
           if (StrLIComp (varr^.id, argstr, i - 1) = 0) then
           begin
                if (varr^.typ = s) then
                begin
                     set_str;
                     exit;
                end
                else
                begin
                     set_int;
                     exit;
                end;
           end;
     until not find_next_var;
     error (argstr, 0, me);
     error (': variable in this assignment not found (skipping)^', 0, me);
end;

procedure do_inc; far;
var i, j : integer;
    argbuf : pchar;
begin
     i:= 0;
     while (argstr[i] = #32) do inc (i);
     j:= i;
     while not ((argstr[j] = #32) or (argstr[j] = #0)) do inc (j);
     if (maxavail < j) then
     begin
          error (globverbs^.current^.line, 0, me);
          error (': out of memory^', 0, me);
          exit;
     end;
     getmem (argbuf, j);
     j:= 0;
     while not ((argstr[i] = #32) or (argstr[i] = #0)) do
     begin
          argbuf[j]:= argstr[i];
          inc (i);
          inc (j);
     end;
     argbuf[j]:= #0;
     argstr:= shift_str (argstr);
     val (StrPas (argstr), i, j);
     if (j <> 0) then
     begin
          error (argstr, 0, me);
          error (': integer value expected^',0, me);
          exit;
     end;
     if not (globrmptr = nil) then
     begin
          if not (globrmptr^.set_intvar (argbuf, globrmptr^.retrieve_intvar (argbuf) + i)) then memerr;
          freemem (argbuf, StrLen (argbuf) + 1);
          exit;
     end;
     if not (globitmptr = nil) then
     begin
          if not (globitmptr^.set_intvar (argbuf, globitmptr^.retrieve_intvar (argbuf) + i)) then memerr;
          freemem (argbuf, StrLen (argbuf) + 1);
          exit;
     end;
     if not (globmnptr = nil) then
     begin
          if not (globmnptr^.set_intvar (argbuf, globmnptr^.retrieve_intvar (argbuf) + i)) then memerr;
          freemem (argbuf, StrLen (argbuf) + 1);
          exit;
     end;
     if not (me^.set_intvar (argbuf, me^.retrieve_intvar (argbuf) + i)) then memerr;
     freemem (argbuf, StrLen (argbuf) + 1);
end;

procedure do_player; far;
var savemnptr : MonsterPtr;
    saveitmptr : ItemPtr;
    savermptr : RoomPtr;
    found : boolean;
    cmd_len, complen : word;
begin
     savemnptr:= globmnptr;
     saveitmptr:= globitmptr;
     savermptr:= globrmptr;
     globmnptr:= nil;
     globrmptr:= nil;
     globitmptr:= nil;

     cmd_len:= 0;
     found:= false;

     while not ((argstr[cmd_len] = #0) or
           (argstr[cmd_len] = #32)) do
         inc (cmd_len);

     if (funtab.find_first) then
     repeat
           if (StrLen (funtab.retrieve_cmdname) > cmd_len)
           then
               complen:= StrLen (funtab.retrieve_cmdname)
           else
               complen:= cmd_len;
           if (StrLIComp (argstr, funtab.retrieve_cmdname,
                          complen) = 0)
           then
           begin
               found:= true;
               argstr:= shift_str (argstr);
               funtab.exec_cmd;
               break;
           end;
     until not funtab.find_next;

     if not found then
     begin
          error ('syntax error in player call (skipping)^', 0, me);
     end;

     globmnptr:= savemnptr;
     globitmptr:= saveitmptr;
     globrmptr:= savermptr;
end;

procedure do_internal; far;
var found : boolean;
begin
     if (ifuntab.find_first) then
     repeat
           if (StrLIComp (ifuntab.retrieve_cmdname, argstr,
                         StrLen (ifuntab.retrieve_cmdname)) = 0) then
           begin
                argstr:= shift_str (argstr);
                if argstr[0]= '%' then
                   fun_envset (me, verbargstr, u)
                else
                    fun_envset (me, argstr, u);
                ifuntab.exec_cmd;
                found:= true;
                break;
           end;
     until not ifuntab.find_next;

     if not found then
     begin
          error (argstr, 0, me);
          error (': internal verb not found (skipping)^', 0, me);
     end;
end;


function exec_verb (tptr : TaskPtr ; universe : UniversePtr) : boolean;
var cmd_len, complen, i : word;
    found : boolean;
begin
     exec_verb:= false;

     me:= tptr^.playptr;
     u:= universe;
     globverbs:= tptr^.current;
     globrmptr:= tptr^.rmptr;
     globmnptr:= tptr^.mnptr;
     globitmptr:= tptr^.itmptr;
     verbargstr:= tptr^.argstr;
     if_depth:= tptr^.if_depth;
     while_depth:= tptr^.while_depth;
     for i:= 1 to MAXDEPTH do
     begin
          if_set[i]:= tptr^.if_set[i];
          start_while[i]:= tptr^.start_while[i];
     end;

     cmd_len:= StrLen (verbargstr) + 9;
     if (maxavail < cmd_len) then
     begin
          error (globverbs^.current^.line, 0, me);
          error (': out of memory^', 0, me);
          tptr^.run:= false;
          exit;
     end;
     getmem (tempptr, cmd_len);
     StrPCopy (tempptr, 'verbarg ');
     StrCat (tempptr, verbargstr);
     argstr:= tempptr;
     set_str;
     freemem (tempptr, cmd_len);

     if not globverbs^.find_next then
     begin
          tptr^.run:= false;
          if not (if_depth = 0) then error ('warning: not all ifs were closed with endif (unexpected results?)^', 0, me);
 if not (while_depth = 0) then error ('warning: not all whiles were closed with endwhile (unexpected results?)^', 0, me);
          if (tptr^.foreground) then me^.console.cwrite ('Ok.^>');
          exit;
     end;

     found:= false;
     cmd_len:= 0;

     argstr:= shift_str (globverbs^.current^.line);

     while not ((globverbs^.current^.line[cmd_len] = #0) or
                (globverbs^.current^.line[cmd_len] = #32)) do
           inc (cmd_len);

     if (funtab.find_first) then
     repeat
           if (StrLen (funtab.retrieve_cmdname) > cmd_len)
           then
               complen:= StrLen (funtab.retrieve_cmdname)
           else
               complen:= cmd_len;
           if (StrLIComp (globverbs^.current^.line, funtab.retrieve_cmdname,
                          complen) = 0)
           then
           begin
               found:= true;
               funtab.exec_cmd;
               break;
           end;
     until not funtab.find_next;

     if not found then
     begin
          error (globverbs^.current^.line, 0, me);
          error (': syntax error (skipping)^', 0, me);
     end;

     tptr^.if_depth:= if_depth;
     tptr^.while_depth:= while_depth;
     for i:= 1 to MAXDEPTH do
     begin
          tptr^.if_set[i]:= if_set[i];
          tptr^.start_while[i]:= start_while[i];
     end;

     exec_verb:= true;
end;

begin
     funtab.init;
     funtab.insert ('write',do_write);
     funtab.insert ('writevar',do_writevar);
     funtab.insert ('echo',do_echo);
     funtab.insert ('echovar',do_echovar);
     funtab.insert ('if',do_if);
     funtab.insert ('else',do_else);
     funtab.insert ('endif',do_endif);
     funtab.insert ('while',do_while);
     funtab.insert ('endwhile',do_endwhile);
     funtab.insert ('str',set_str);
     funtab.insert ('int',set_int);
     funtab.insert ('set',set_var);
     funtab.insert ('inc',do_inc);
     funtab.insert ('player',do_player);
     funtab.insert ('internal',do_internal);
     ifuntab.init;
     fill_funtab (ifuntab);
end.
