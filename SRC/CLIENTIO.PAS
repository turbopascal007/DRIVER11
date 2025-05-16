unit clientio;

interface

uses parser, ifun, player, universe, strings, logon, err;

procedure client_command (who : PlayerPtr; inputstr : pchar; u : UniversePtr);


implementation


procedure client_command (who : PlayerPtr; inputstr : pchar; u : UniversePtr);
var i, j : integer;
    plyptr : PlayerPtr;
    plyname : pchar;
begin
     i:= 0;
     while (inputstr[i] = #32) do inc (i);
     while not ((inputstr[i] = #0) or (inputstr[i] = #32)) do inc (i);
     if (maxavail < i) then
     begin
          error ('clientio.client_command: out of memory^', 0);
          exit;
     end;
     getmem (plyname, i);
     i:= 0;
     j:= 0;
     while (inputstr[i] = #32) do inc (i);
     while not ((inputstr[i] = #0) or (inputstr[i] = #32)) do
     begin
          plyname[j]:= inputstr[i];
          inc (i);
          inc (j);
     end;
     plyname[j]:= #0;
     while (inputstr[i] = #32) do inc (i);

     if (StrIComp (plyname, 'client') = 0) then
     begin
          if (maxavail < sizeof (PlayerObject)) then
          begin
               error ('client.client_command: out of memory^', 0);
               exit;
          end;
          getmem (plyptr, sizeof (PlayerObject));
          plyptr^.init;
          if not (who^.console.id[1] = 'o') then   (* client is not on cOm *)
          begin
            plyptr^.console.init_on_disk (StrPas (@inputstr[i]));
            who^.console.cwrite ('Driver tells you: Redirected new client to disk!^');
          end
          else
            plyptr^.console.init_on_client (@inputstr[i], who^.console.port);
          log_on (plyptr, @inputstr[i], u);
          if (plyptr^.status > 0) then
               if not (u^.pd^.insert (plyptr)) then
               begin
                    plyptr^.console.cwriteln ('Out of memory');
                    exit;
               end;
     end
     else
     begin
          plyptr:= find_player (u, plyname);
          if not (plyptr = nil) then
          begin
               if not ((plyptr^.console.id[1] = 'l') or
                       (plyptr^.console.id[1] = 'i')) then
                  who^.console.cwrite ('Driver tells you: Not your client!')
               else
               begin
                 if (plyptr^.status > 1) then
                   parse_command (plyptr, @inputstr[i], u)
                 else
                   log_on (plyptr, @inputstr[i], u);
               end;
          end
          else
          begin
               who^.console.cwrite ('Driver tells you: Associated player ');
               who^.console.cwrite (plyname);
               who^.console.cwriteln (' not found!');
          end;
     end;
     freemem (plyname, StrLen (plyname) + 1);
end;

end.
