unit cdriver;

interface

uses comm_tp4, ccomport, cswitch, cconsd, cconsole, crt, strings;

procedure enter_client_mode (port : byte; consd : ConsoleDPtr);


implementation

var
   name,
   inputstr : pchar;

procedure exit_client_mode;
begin
     writeln ('Disabling protocol..');
end;

procedure cls;
var i, j : word;
begin
     textcolor (7);
     textbackground (0);
     for i:= 1 to 80 do
        for j:= 1 to 24 do
        begin
             gotoxy (i, j);
             write (#176);
        end;
end;


procedure enter_client_mode (port : byte; consd : ConsoleDPtr);
var ch : char;
    cmd : pchar;
    ActiveCons, cons : ConsolePtr;
    status : byte;
    i, cur : word;
begin
     hand_shake (port);
     cls;
     switch_cons (consd);
     status:= 0;
     repeat
           if (get_next_ch (port, ch)) then
           begin
                case ord (ch) of
                1:
                begin
                     cur:= 0;
                     status:= 1;
                end;
                2:
                begin
                     cur:= 0;
                     status:= 2;
                end;
                3:
                begin
                     consd^.find_first;
                     repeat
                           consd^.retrieve (cons);
                           if (StrIComp (cons^.owner, name) = 0) then
                           begin
                                cons^.cwrite (inputstr);
                           end;
                     until not consd^.find_next;
                     status:= 0;
                     name[0]:= #0;
                     inputstr[0]:= #0;
                end;
                else
                begin
                     case status of
                     1:
                     begin
                          name[cur]:= ch;
                          inc (cur);
                          name[cur]:= #0;
                     end;
                     2:
                     begin
                          inputstr[cur]:= ch;
                          inc (cur);
                          inputstr[cur]:= #0;
                     end;
                     end;
                end;
                end;
           end;
           if (keypressed) then
           begin
                get_cons (ActiveCons);
                ch:= readkey;
                case ord (ch) of
                27 :
                begin
                     exit_client_mode;
                     exit;
                end;
                0 :
                begin
                     ch:= readkey;
                     case ord (ch) of
                     94 : halt (0);
                     59 : switch_cons (consd);
                     end;
                end;
                else
                    if ActiveCons^.receive (ch, cmd) then
                    begin
                         if (ActiveCons^.name_known) then
                         begin
                              send_str (port, ActiveCons^.owner);
                              send_str (port, ' ');
                              send_str (port, cmd);
                              send_str (port, '^');
                         end
                         else
                         begin
                              ActiveCons^.init2 (cmd);
                              ActiveCons^.name_known:= true;
                              send_str (port, 'client ');
                              send_str (port, ActiveCons^.owner);
                              send_str (port, '^');
                              if (not (wait_for (port, 'code:', 20000))) then
                              begin
                                   ActiveCons^.name_known:= false;
                                   ActiveCons^.cwriteln ('Client tells you: That player is already logged on, sorry!^');
                                   ActiveCons^.cwrite ('What is your name: ');
                              end
                              else
                              begin
                                   ActiveCons^.cwrite ('Client tells you: ');
                                   ActiveCons^.cwriteln ('Okay, you are validated by the driver.. good luck!');
                                   ActiveCons^.cwrite ('Access code: ');
                              end;
                         end;
                    end;
                end;
           end;
     until false;
end;

begin
     getmem (name, 50);
     getmem (inputstr, 255);
     name[0]:= #0;
     inputstr[0]:= #0;
end.
