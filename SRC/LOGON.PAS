unit logon;

interface

uses fileinpr, ifun, player, universe, strings;

procedure log_on (who : PlayerPtr; name : pchar; u : UniversePtr);


implementation

procedure log_on (who : PlayerPtr; name : pchar; u : UniversePtr);
var playptr : PlayerPtr;
begin
     if (who^.status < 1) then
     begin
          if (name[0] = #0) or (not (find_player (u, name) = nil)) then
          begin
               who^.console.cwriteln ('That player is already logged on, sorry!^');
               who^.console.cwrite ('What is your name: ');
               exit;
          end;

          if ((name[0] >= 'a') and (name[0] <= 'z')) then
             name[0]:= chr (ord (name[0]) - 32);
          if not (who^.set_strvar ('short', name)) then
          begin
               who^.console.cwriteln ('Connection refused by system: Out of memory^');
               who^.console.cwrite ('What is your name: ');
               exit;
          end;

          who^.status:= 1;

          who^.console.cwrite ('Access code: ');
          exit;
     end;

     who^.status:= 2;
     who^.console.init2 (who^.retrieve_strvar ('short'));

     if (StrIComp (who^.retrieve_strvar ('short'), 'client') = 0) then
     begin
          if (StrIComp (name, 'client') = 0) then
          begin
               who^.console.cwriteln ('driver:hello');
               if not (who^.console.id[1] = 'o') then
               begin
                    who^.console.cwrite ('Driver tells you: Not a serial logon, use for testing only!^');
                    who^.console.cwrite ('Driver tells you: "client <name>" to create^');
                    who^.console.cwrite ('Driver tells you: "<name> <command>" to execute a command^');
               end;
               who^.status:= 3;
               if not ((who^.set_strvar ('title','the serial daemon')) and
                       (who^.set_strvar ('prename',''))) then
                    who^.console.cwriteln ('Out of memory');
               who^.env:= nil;
               exit;
          end;
     end;

     if not ( (who^.set_strvar ('prename', '')) and
              (who^.set_strvar ('title', '')) and
              (who^.set_strvar ('curdir', get_libdir)) ) then
             who^.console.cwriteln ('Driver tells you: Welcome, although the system is out of memory');

     if not (who^.verbtab.find_first) then interpret ('player.ini', u, who);

     if (u^.rd^.size = 0) then
     begin
          who^.console.cwriteln ('You have no environment!');
          who^.env:= nil;
     end
     else
     begin
         u^.rd^.retrieve (who^.env);
         who^.console.cwrite ('You are in ');
         who^.console.cwriteln (who^.env^.retrieve_strvar ('short'));
         tell_room (u, who^.env, who^.retrieve_strvar ('short'), who, nil);
         tell_room (u, who^.env, ' enters this world^', who, nil);
     end;

     who^.console.cwrite ('>');
end;

end.
