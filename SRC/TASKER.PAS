unit tasker;

interface

uses universe, verbinpr, taskd, task, player, room, item, monster, dos,
     syscons, stringd, strings, crt;

procedure start_task (verbs : StringDPtr; who : PlayerPtr;
                      stri : pchar; fore : boolean;
                      rmptr : RoomPtr; itmptr : ItemPtr; mnptr : MonsterPtr;
                      u : UniversePtr);

procedure run_tasks (u : UniversePtr);

procedure dump_tasks (who : PlayerPtr);


implementation

var
   hr, min, sec, oldsec, sec100, count : word;
   td : TaskDaemon;


procedure heart_beat (u : UniversePtr); forward;

procedure start_task (verbs : StringDPtr; who : PlayerPtr;
                      stri : pchar; fore : boolean;
                      rmptr : RoomPtr; itmptr : ItemPtr; mnptr : MonsterPtr;
                      u : UniversePtr);
begin
     td.insert (verbs, who, stri, fore, rmptr, itmptr, mnptr, u);
end;

procedure run_tasks (u : UniversePtr);
var
   playptr,
   play2ptr : PlayerPtr;
   found : boolean;
   tptr : TaskPtr;
begin
     gettime (hr, min, sec, sec100);
     if not (sec = oldsec) then
     begin
          oldsec:= sec;
          heart_beat (u);
          sys_status (count);
          count:= 0;
     end;
     inc (count);

     if (td.find_first) then
     repeat
       td.retrieve (tptr);
       if (tptr^.run) then
         exec_verb (tptr, u)
       else
         td.delete;
     until not td.find_next;
end;

procedure dump_tasks (who : PlayerPtr);
var tptr: TaskPtr;
begin
  if (td.find_first) then
  repeat
    td.retrieve (tptr);
    who^.console.cwrite ('@[');
    if not (tptr^.playptr = nil) then
      who^.console.cwrite (tptr^.playptr^.retrieve_strvar ('short'));
    who^.console.cwrite ('] ');
    who^.console.cwrite (tptr^.id);
    who^.console.cwrite ('^');
  until not td.find_next;
end;

procedure heart_beat (u: UniversePtr);
var playptr,
    play2ptr : PlayerPtr;
    mnptr,
    mn2ptr   : MonsterPtr;
    found    : boolean;
    complen  : word;
begin
     if (u^.pd^.find_first) then
     repeat
           u^.pd^.retrieve (playptr);
           if (playptr^.status > 1) then
           begin
                playptr^.heart_beat;

                if (playptr^.verbtab.find_first) then
                repeat
                  if (playptr^.verbtab.current^.verb^.find_first) then
                  begin
                    if (StrLen (playptr^.verbtab.current^.verb^.current^.line) > 2)
                    then
                      complen:= StrLen (playptr^.verbtab.current^.verb^.current^.line)
                    else
                      complen:= 2;
                    if (StrLIComp ('hb', playptr^.verbtab.current^.verb^.current^.line,
                      complen) = 0)
                    then
                    begin
                      start_task (playptr^.verbtab.current^.verb, playptr, '', false, nil, nil, nil, u);
                      break;
                    end;
                  end;
                until not playptr^.verbtab.find_next;

                if (maxavail < 25000) and (random (maxavail div 1000) = 0) then
                   playptr^.console.cwrite ('Driver shouts: We are low on memory!^');

                {now refind the current (to proceed the outer loop right)}
                found:= false;
                if (u^.pd^.find_first) then
                repeat
                      u^.pd^.retrieve (play2ptr);
                      if not (play2ptr^.retrieve_strvar ('short') = nil) and
                             (play2ptr^.retrieve_strvar ('short') = playptr^.retrieve_strvar ('short')) then
                      begin
                           found:= true;
                           break;
                      end;
                until not u^.pd^.find_next;
                if not found then break;
           end;

     until not u^.pd^.find_next;

     if (u^.md^.find_first) then
     repeat
           u^.md^.retrieve (mnptr);
           mnptr^.heart_beat;

           {refind the current (to proceed the outer loop right)}
           found:= false;
           if (u^.md^.find_first) then
           repeat
                u^.md^.retrieve (mn2ptr);
                if not (mn2ptr^.retrieve_strvar ('short') = nil) and
                       (mn2ptr^.retrieve_strvar ('short') = mnptr^.retrieve_strvar ('short')) then
                begin
                     found:= true;
                     break;
                end;
           until not u^.md^.find_next;
           if not found then break;

     until not u^.md^.find_next;
end;


begin
     gettime (hr, min, oldsec, sec100);
     count:= 0;
     td.init;
end.

