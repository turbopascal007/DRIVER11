unit parser;

interface

uses mystrings, strings, universe, player, monster, item, tasker, err;

procedure parse_command (who : PlayerPtr; inputstr : pchar; u : UniversePtr);


implementation

var argstr : pchar;


procedure parse_command (who : PlayerPtr; inputstr : pchar; u : UniversePtr);

var complen,
    cmd_len   : word;
    found,
    list      : boolean;
    tempstr: string;
    itmptr : ItemPtr;
    mnptr  : MonsterPtr;
begin
     found:= false;
     list:= false;
     argstr:= shift_str (inputstr);
     if (inputstr[0] = '?') then list:= true;
     if (inputstr[0] = '@') then
     begin
       who^.console.cwrite ('@Internal dump of running threaded tasks:^');
       dump_tasks (who);
       who^.console.cwrite ('@Ok.^>');
       exit;
     end;

     cmd_len:= 0;
     while not ((inputstr[cmd_len] = #0) or (inputstr[cmd_len] = #32)) do
           inc (cmd_len);

     {search in the room the player is in}
     if (not (who^.env = nil)) and (who^.env^.verbtab.find_first) then
     repeat
           if (who^.env^.verbtab.current^.verb^.find_first) then
           begin
                if list then
                begin
                     who^.console.cwrite (who^.env^.verbtab.current^.verb^.current^.line);
                     who^.console.cwrite (', ');
                end;
                if (StrLen (who^.env^.verbtab.current^.verb^.current^.line) >
                    cmd_len)
                then
                     complen:= StrLen (who^.env^.verbtab.current^.verb^.current^.line)
                else
                    complen:= cmd_len;
                if (StrLIComp (inputstr, who^.env^.verbtab.current^.verb^.current^.line,
                               complen) = 0)
                then
                begin
                     start_task (who^.env^.verbtab.current^.verb, who, argstr, true, who^.env, nil, nil, u);
                     found:= true;
                     break;
                end;
           end;
     until not who^.env^.verbtab.find_next;

     {search in the items in the room the player is in}
     if (not found) and
        (not (who^.env = nil)) and
        (who^.env^.inv.find_first) then
     repeat
           who^.env^.inv.retrieve (itmptr);
           if (itmptr^.verbtab.find_first) then
           repeat
                 if (itmptr^.verbtab.current^.verb^.find_first) then
                 begin
                      if list then
                      begin
                           who^.console.cwrite (itmptr^.verbtab.current^.verb^.current^.line);
                           who^.console.cwrite (', ');
                      end;
                      if (StrLen (itmptr^.verbtab.current^.verb^.current^.line) >
                          cmd_len)
                      then
                           complen:= StrLen (itmptr^.verbtab.current^.verb^.current^.line)
                      else
                          complen:= cmd_len;
                      if (StrLIComp (inputstr, itmptr^.verbtab.current^.verb^.current^.line,
                                     complen) = 0)
                      then
                      begin
                           start_task (itmptr^.verbtab.current^.verb, who, argstr, true, nil, itmptr, nil, u);
                           found:= true;
                           break;
                      end;
                 end;
           until not itmptr^.verbtab.find_next;
     until not who^.env^.inv.find_next;

     {search in the items the player has}
     if (not found) and
        (who^.inv.find_first) then
     repeat
           who^.inv.retrieve (itmptr);
           if (itmptr^.verbtab.find_first) then
           repeat
                 if (itmptr^.verbtab.current^.verb^.find_first) then
                 begin
                      if list then
                      begin
                           who^.console.cwrite (itmptr^.verbtab.current^.verb^.current^.line);
                           who^.console.cwrite (', ');
                      end;
                      if (StrLen (itmptr^.verbtab.current^.verb^.current^.line) >
                          cmd_len)
                      then
                           complen:= StrLen (itmptr^.verbtab.current^.verb^.current^.line)
                      else
                          complen:= cmd_len;
                      if (StrLIComp (inputstr, itmptr^.verbtab.current^.verb^.current^.line,
                                     complen) = 0)
                      then
                      begin
                           start_task (itmptr^.verbtab.current^.verb, who, argstr, true, nil, itmptr, nil, nil);
                           found:= true;
                           break;
                      end;
                 end;
           until not itmptr^.verbtab.find_next;
     until not who^.inv.find_next;

     {search in the monsters in the room the player is in}
     if (not found) and
        (u^.md^.find_first) then
     repeat
           u^.md^.retrieve (mnptr);
           if (mnptr^.env = who^.env) and
              (mnptr^.verbtab.find_first) then
           repeat
                 if (mnptr^.verbtab.current^.verb^.find_first) then
                 begin
                      if list then
                      begin
                           who^.console.cwrite (mnptr^.verbtab.current^.verb^.current^.line);
                           who^.console.cwrite (', ');
                      end;
                      if (StrLen (mnptr^.verbtab.current^.verb^.current^.line) >
                          cmd_len)
                      then
                           complen:= StrLen (mnptr^.verbtab.current^.verb^.current^.line)
                      else
                          complen:= cmd_len;
                      if (StrLIComp (inputstr, mnptr^.verbtab.current^.verb^.current^.line,
                                     complen) = 0)
                      then
                      begin
                           start_task (mnptr^.verbtab.current^.verb, who, argstr, true, nil, nil, mnptr, u);
                           found:= true;
                           break;
                      end;
                 end;
           until not mnptr^.verbtab.find_next;
     until not u^.md^.find_next;

     {search in the player}
     if (not found) and
        (who^.verbtab.find_first) then
     repeat
           if (who^.verbtab.current^.verb^.find_first) then
           begin
                if list then
                begin
                     who^.console.cwrite (who^.verbtab.current^.verb^.current^.line);
                     who^.console.cwrite (', ');
                     found:= true;
                end;
                if (StrLen (who^.verbtab.current^.verb^.current^.line) >
                   cmd_len)
                then
                    complen:= StrLen (who^.verbtab.current^.verb^.current^.line)
                else
                    complen:= cmd_len;
                if (StrLIComp (inputstr, who^.verbtab.current^.verb^.current^.line,
                   complen) = 0)
                then
                begin
                     start_task (who^.verbtab.current^.verb, who, argstr, true, nil, nil, nil, u);
                     found:= true;
                     break;
                end;
           end;
     until not who^.verbtab.find_next;

     if list then who^.console.cwrite ('?^Ok.^>');

     if (not found) and (who^.status > 1) then
     begin
          who^.console.cwrite ('What?^>');
     end;
end;


end.
