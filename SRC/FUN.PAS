unit fun;

interface

uses universe, fileinpr, mystrings, strings, player, monster, room, item, ifun, fund, dos, err;

procedure fun_envset (who : PlayerPtr; arguments : pchar; universe : UniversePtr);

procedure fill_funtab (var funtab : FunDaemon);


implementation

var
   startmem : longint;
   u        : UniversePtr;
   me       : PlayerPtr;
   argstr,
   tempptr,
   txt      : pchar;

procedure fun_envset (who : PlayerPtr; arguments : pchar; universe : UniversePtr);
var i: word;
begin
     for i:= 0 to StrLen (arguments) do
          if ((arguments[i] <> '/') and (arguments[i] <> '\')) then break;
     argstr:= @arguments[i];
     u:= universe;
     me:= who;
end;

function no_args : boolean;
begin
     no_args:= (argstr[0] = #0);
end;

procedure do_malloc; far;
var tempstr : string;
begin
     me^.console.cwrite ('A. Total data memory   : ');
     str (startmem, tempstr);
     StrPCopy (tempptr, tempstr);
     me^.console.cwriteln (tempptr);

     me^.console.cwrite ('B. Data allocated      : ');
     str (startmem - memavail, tempstr);
     StrPCopy (tempptr, tempstr);
     me^.console.cwriteln (tempptr);

     me^.console.cwrite ('C. Free memory (A - B) : ');
     str (memavail, tempstr);
     StrPCopy (tempptr, tempstr);
     me^.console.cwriteln (tempptr);
end;

procedure do_say; far;
var playptr : PlayerPtr;
begin
     if no_args then
     begin
          me^.console.cwriteln ('Say what?');
          exit;
     end;
     if (u^.pd^.find_first) then
     repeat
           u^.pd^.retrieve (playptr);
           if ((playptr^.env = me^.env) and (not (playptr = me))) then
           begin
                playptr^.console.cwrite (me^.retrieve_strvar ('short'));
                playptr^.console.cwrite (' says: ');
                playptr^.console.cwriteln (argstr);
           end;
     until not u^.pd^.find_next;
     me^.console.cwrite ('You say: ');
     me^.console.cwriteln (argstr);
end;

procedure do_shout; far;
var playptr : PlayerPtr;
begin
     if no_args then
     begin
          me^.console.cwriteln ('Shout what?');
          exit;
     end;
     if (u^.pd^.find_first) then
     repeat
           u^.pd^.retrieve (playptr);
           if (playptr = me) then continue;
           playptr^.console.cwrite (me^.retrieve_strvar ('short'));
           playptr^.console.cwrite (' shouts: ');
           playptr^.console.cwriteln (argstr);
     until not u^.pd^.find_next;
     me^.console.cwrite ('You shout: ');
     me^.console.cwriteln (argstr);
end;

procedure do_tell; far;
var playptr : PlayerPtr;
begin
     if no_args then
     begin
          me^.console.cwriteln ('Tell who?');
          exit;
     end;
     if (u^.pd^.find_first) then
     repeat
           u^.pd^.retrieve (playptr);
           if (StrLIComp (argstr, playptr^.retrieve_strvar ('short'),
               StrLen (playptr^.retrieve_strvar ('short'))) = 0) and
              (StrLen (playptr^.retrieve_strvar ('short')) > 0)
           then
           begin
                argstr:= shift_str (argstr);
                if no_args then
                begin
                     me^.console.cwrite ('Tell ');
                     me^.console.cwrite (playptr^.retrieve_strvar ('short'));
                     me^.console.cwriteln (' what?');
                     exit;
                end;
                playptr^.console.cwrite (me^.retrieve_strvar ('short'));
                playptr^.console.cwrite (' tells you: ');
                playptr^.console.cwriteln (argstr);
                me^.console.cwrite ('You tell ');
                me^.console.cwrite (playptr^.retrieve_strvar ('short'));
                me^.console.cwrite (': ');
                me^.console.cwriteln (argstr);
                exit;
           end;
     until not u^.pd^.find_next;
     me^.console.cwriteln ('Player not found!');
end;

procedure do_echo; far;
var playptr : PlayerPtr;
begin
     if no_args then
     begin
          me^.console.cwriteln ('Echo what?');
          exit;
     end;
     if (u^.pd^.find_first) then
     repeat
           u^.pd^.retrieve (playptr);
           if ((playptr^.env = me^.env) and (not (playptr = me))) then
                playptr^.console.cwrite (argstr);
     until not u^.pd^.find_next;
end;

procedure do_examine; far;
var playptr : PlayerPtr;
    itmptr  : ItemPtr;
    mnptr   : MonsterPtr;
begin
     if no_args then
     begin
          me^.console.cwriteln ('Examine what?');
          exit;
     end;
     if (u^.pd^.find_first) then
     repeat
           u^.pd^.retrieve (playptr);
           if (StrLIComp (playptr^.retrieve_strvar ('short'), argstr, StrLen (playptr^.retrieve_strvar ('short'))) = 0) and
              (StrLen (playptr^.retrieve_strvar ('short')) > 0) then
           begin
                if (playptr^.long.find_first) then
                repeat
                     me^.console.cwriteln (playptr^.long.retrieve_line);
                until not playptr^.long.find_next;
                exit;
           end;
     until not u^.pd^.find_next;
     if (u^.md^.find_first) then
     repeat
           u^.md^.retrieve (mnptr);
           if (StrLIComp (mnptr^.retrieve_strvar ('short'), argstr, StrLen (mnptr^.retrieve_strvar ('short'))) = 0) then
           begin
                if (mnptr^.long.find_first) then
                repeat
                      me^.console.cwriteln (mnptr^.long.retrieve_line);
                until not mnptr^.long.find_next;
                exit;
           end;
     until not u^.md^.find_next;
     if ((not (me^.env = nil)) and (me^.env^.inv.find_first)) then
     repeat
           me^.env^.inv.retrieve (itmptr);
           if (StrLIComp (itmptr^.retrieve_strvar ('short'), argstr, StrLen (itmptr^.retrieve_strvar ('short'))) = 0) then
           begin
                if (itmptr^.long.find_first) then
                repeat
                      me^.console.cwriteln (itmptr^.long.retrieve_line);
                until not itmptr^.long.find_next;
                exit;
           end;
     until not me^.env^.inv.find_next;
     if (me^.inv.find_first) then
     repeat
           me^.inv.retrieve (itmptr);
           if (StrLIComp (itmptr^.retrieve_strvar ('short'), argstr, StrLen (itmptr^.retrieve_strvar ('short'))) = 0)  then
           begin
                if (itmptr^.long.find_first) then
                repeat
                      me^.console.cwriteln (itmptr^.long.retrieve_line);
                until not itmptr^.long.find_next;
                exit;
           end;
     until not me^.inv.find_next;
     me^.console.cwriteln ('Object not found!');
end;

procedure do_look; far;
var playptr : PlayerPtr;
    itmptr  : ItemPtr;
    mnptr   : MonsterPtr;
    dir     : pchar;
    long    : pchar;
begin
     if ((StrLIComp (argstr, 'at', 2))  = 0) then
     begin
          argstr:= shift_str (argstr);
          do_examine;
          exit;
     end;
     if not (me^.env = nil) then
     begin
          {print short of the room}
          me^.console.cwriteln (me^.env^.retrieve_strvar ('short'));
          {print long of the room}
          if (me^.env^.long.find_first) then
          repeat
                me^.console.cwriteln (
                   me^.env^.long.retrieve_line);
          until not me^.env^.long.find_next;
          {print exits of the room}
          me^.console.cwrite ('Possible exits: ');
          if (me^.env^.retrieve_strvar ('exits') = nil) then
              me^.console.cwriteln ('none')
          else
              me^.console.cwriteln (me^.env^.retrieve_strvar ('exits'));
          {print players in the room}
          if (u^.pd^.find_first) then
          repeat
                u^.pd^.retrieve (playptr);
                if (playptr^.env = me^.env) and (not (playptr = me)) then
                begin
                   me^.console.cwrite (playptr^.retrieve_strvar ('prename'));
                   me^.console.cwrite (playptr^.retrieve_strvar ('short'));
                   me^.console.cwrite (' ');
                   me^.console.cwriteln (playptr^.retrieve_strvar ('title'));
                end;
          until not u^.pd^.find_next;
          {print items in the room}
          if (me^.env^.inv.find_first) then
          repeat
                me^.env^.inv.retrieve (itmptr);
                me^.console.cwriteln (itmptr^.retrieve_strvar ('short'));
          until not me^.env^.inv.find_next;
          {print monsters in the room}
          if (u^.md^.find_first) then
          repeat
                u^.md^.retrieve (mnptr);
                if (mnptr^.env = me^.env) then
                   me^.console.cwriteln (mnptr^.retrieve_strvar ('short'));
          until not u^.md^.find_next;
     end
     else
         me^.console.cwriteln
           ('You are nowhere!');
end;

procedure do_goto; far;
var found : boolean;
    rmptr : RoomPtr;
    playptr : PlayerPtr;
    mnptr : MonsterPtr;
begin
     found:= false;
     if no_args then
     begin
          me^.console.cwriteln ('Goto where?');
          exit;
     end;

     {look for roomname}
     if (u^.rd^.find_first) then
     repeat
           u^.rd^.retrieve (rmptr);
           if (StrLIComp (argstr, rmptr^.retrieve_strvar ('short'),
               StrLen (rmptr^.retrieve_strvar ('short'))) = 0)
           then begin
                found:= true;
                break;
           end;
     until not u^.rd^.find_next;

     {maybe a player is referred to?}
     if not found then
        if (u^.pd^.find_first) then
        repeat
              u^.pd^.retrieve (playptr);
              if (StrLIComp (argstr, playptr^.retrieve_strvar ('short'),
                  StrLen (playptr^.retrieve_strvar ('short'))) = 0)
              then begin
                   found:= true;
                   rmptr:= playptr^.env;
                   break;
              end;
        until not u^.pd^.find_next;

     {maybe a monster is referred to?}
     if not found then
        if (u^.md^.find_first) then
        repeat
              u^.md^.retrieve (mnptr);
              if (StrLIComp (argstr, mnptr^.retrieve_strvar ('short'),
                  StrLen (mnptr^.retrieve_strvar ('short'))) = 0)
              then begin
                   found:= true;
                   rmptr:= mnptr^.env;
                   break;
              end;
        until not u^.md^.find_next;

     {maybe a filename is referred to?}
     if not found then
     begin
          rmptr:= find_room_file (u, me, StrPas (argstr));
          if (rmptr = nil) then
          begin
               interpret (StrPas (argstr), u, me);
               rmptr:= find_room_file (u, me, StrPas (argstr));
          end;
          found:= true;
     end;

     if found and not (rmptr = nil) then
     begin
          tell_room (u, me^.env, me^.retrieve_strvar ('short'), me, nil);
          tell_room (u, me^.env, ' leaves for ', me, nil);
          tell_room (u, me^.env, rmptr^.retrieve_strvar ('short'), me, nil);
          tell_room (u, me^.env, '^', me, nil);
          me^.env:= rmptr;
          do_look;
          tell_room (u, me^.env, me^.retrieve_strvar ('short'), me, nil);
          tell_room (u, me^.env, ' arrives^', me, nil);
     end
     else
         me^.console.cwriteln ('Room, player or monster not found!');
end;

procedure do_list; far;
var rmptr : RoomPtr;
begin
     if (u^.rd^.find_first) then
     begin
          u^.rd^.retrieve (rmptr);
          me^.console.cwrite (rmptr^.retrieve_strvar ('short'));
          if (u^.rd^.find_next) then
          repeat
                me^.console.cwrite (', ');
                u^.rd^.retrieve (rmptr);
                me^.console.cwrite (rmptr^.retrieve_strvar ('short'));
          until not u^.rd^.find_next
     end
     else
         me^.console.cwrite ('No rooms found!');
     me^.console.cwrite ('^');
end;

procedure do_who; far;
var playptr : PlayerPtr;
begin
     if (u^.pd^.find_first) then
     repeat
           u^.pd^.retrieve (playptr);
           me^.console.cwrite ('[');
           me^.console.cwrite (playptr^.console.id);
           me^.console.cwrite ('] ');
           if (playptr^.status < 2) then
              me^.console.cwriteln ('Logon the title less is nowhere')
           else
           begin
                me^.console.cwrite (playptr^.retrieve_strvar ('prename'));
                me^.console.cwrite (playptr^.retrieve_strvar ('short'));
                me^.console.cwrite (' ');
                me^.console.cwrite (playptr^.retrieve_strvar ('title'));
                me^.console.cwrite (' is in ');
                if (playptr^.env = nil) then
                   me^.console.cwriteln ('nowhere')
                else
                    me^.console.cwriteln (playptr^.env^.retrieve_strvar ('short'));
           end;
    until not u^.pd^.find_next;
end;

procedure do_inv; far;
var itmptr : ItemPtr;
begin
     if (me^.retrieve_intvar ('ghost') = 1) then
     begin
          me^.console.cwriteln ('You are in a immaterial state!');
          exit;
     end;
     me^.console.cwriteln ('You have:');
     if (me^.inv.find_first) then
     repeat
           me^.inv.retrieve (itmptr);
           me^.console.cwriteln (itmptr^.retrieve_strvar ('short'));
     until not me^.inv.find_next
     else
         me^.console.cwriteln ('nothing');
end;

procedure do_have; far;
var itmptr : ItemPtr;
begin
     if (me^.retrieve_intvar ('ghost') = 1) then
     begin
          me^.console.cwriteln ('You are in a immaterial state!');
          exit;
     end;
     if no_args then
     begin
          me^.console.cwriteln ('Have what?');
          exit;
     end;
     if not (me^.inv.add (argstr)) then
     begin
          me^.console.cwriteln ('Out of memory');
          exit;
     end;
     me^.console.cwrite ('You now have ');
     me^.inv.retrieve (itmptr);
     me^.console.cwriteln (itmptr^.retrieve_strvar ('short'));
     tell_room (u, me^.env, me^.retrieve_strvar ('short'), me, nil);
     tell_room (u, me^.env, ' now has something new^', me, nil);
end;

procedure do_drop; far;
var itmptr : ItemPtr;
    found  : boolean;
begin
     if (me^.retrieve_intvar ('ghost') = 1) then
     begin
          me^.console.cwriteln ('You are in a immaterial state!');
          exit;
     end;
     found:= false;
     if no_args then
     begin
          me^.console.cwriteln ('Drop what?');
          exit;
     end;
     if (me^.env = nil) then
     begin
          me^.console.cwriteln ('You are nowhere!');
          exit;
     end;
     if (StrLIComp (argstr, 'all', 3) = 0) then
     begin
          me^.inv.find_first;
          while not me^.inv.empty do
          begin
               me^.inv.retrieve (itmptr);
               if not (me^.env^.inv.insert (itmptr)) then
               begin
                    me^.console.cwriteln ('Out of memory');
                    exit;
               end;
               me^.inv.delete (false);
               me^.console.cwrite ('You drop: ');
               me^.env^.inv.retrieve (itmptr);
               me^.console.cwriteln (itmptr^.retrieve_strvar ('short'));
               tell_room (u, me^.env, me^.retrieve_strvar ('short'), me, nil);
               tell_room (u, me^.env, ' drops ', me, nil);
               tell_room (u, me^.env, itmptr^.retrieve_strvar ('short'), me, nil);
               tell_room (u, me^.env, '^', me, nil);
          end;
          exit;
     end;
     if (me^.inv.find_first) then
     repeat
           me^.inv.retrieve (itmptr);
           if (StrLIComp (argstr, itmptr^.retrieve_strvar ('short'), StrLen (itmptr^.retrieve_strvar ('short'))) = 0) then
           begin
                found:= true;
                break;
           end;
     until not me^.inv.find_next;
     if found then
     begin
          if not (me^.env^.inv.insert (itmptr)) then
          begin
               me^.console.cwriteln ('Out of memory');
               exit;
          end;
          me^.inv.delete (false);
          me^.console.cwrite ('You drop: ');
          me^.env^.inv.retrieve (itmptr);
          me^.console.cwriteln (itmptr^.retrieve_strvar ('short'));
          tell_room (u, me^.env, me^.retrieve_strvar ('short'), me, nil);
          tell_room (u, me^.env, ' drops ', me, nil);
          tell_room (u, me^.env, itmptr^.retrieve_strvar ('short'), me, nil);
          tell_room (u, me^.env, '^', me, nil);
     end
     else
     begin
          me^.console.cwrite ('You have no ');
          me^.console.cwrite (argstr);
          me^.console.cwriteln ('!');
     end;
end;

procedure do_take; far;
var itmptr : ItemPtr;
    found  : boolean;
begin
     if (me^.retrieve_intvar ('ghost') = 1) then
     begin
          me^.console.cwriteln ('You are in a immaterial state!');
          exit;
     end;
     found:= false;
     if no_args then
     begin
          me^.console.cwriteln ('Take what?');
          exit;
     end;
     if (me^.env = nil) then
     begin
          me^.console.cwriteln ('You are nowhere!');
          exit;
     end;
     if (StrLIComp (argstr, 'all', 3) = 0) then
     begin
          me^.env^.inv.find_first;
          while not me^.env^.inv.empty do
          begin
               me^.env^.inv.retrieve (itmptr);
               if not (me^.inv.insert (itmptr)) then
               begin
                    me^.console.cwriteln ('Out of memory');
                    exit;
               end;
               me^.env^.inv.delete (false);
               me^.console.cwrite ('You take: ');
               me^.inv.retrieve (itmptr);
               me^.console.cwriteln (itmptr^.retrieve_strvar ('short'));
               tell_room (u, me^.env, me^.retrieve_strvar ('short'), me, nil);
               tell_room (u, me^.env, ' takes ', me, nil);
               tell_room (u, me^.env, itmptr^.retrieve_strvar ('short'), me, nil);
               tell_room (u, me^.env, '^', me, nil);
          end;
          exit;
     end;
     if (me^.env = nil) then
     begin
          me^.console.cwriteln ('You are nowhere!');
          exit;
     end;
     if (me^.env^.inv.find_first) then
     repeat
           me^.env^.inv.retrieve (itmptr);
           if (StrLIComp (argstr, itmptr^.retrieve_strvar ('short'), StrLen (itmptr^.retrieve_strvar ('short'))) = 0)
           then begin
               found:= true;
               break;
           end;
     until not me^.env^.inv.find_next;
     if found then
     begin
          if not (me^.inv.insert (itmptr)) then
          begin
               me^.console.cwriteln ('Out of memory');
               exit;
          end;
          me^.env^.inv.delete (false);
          me^.console.cwrite ('You take: ');
          me^.inv.retrieve (itmptr);
          me^.console.cwriteln (itmptr^.retrieve_strvar ('short'));
          tell_room (u, me^.env, me^.retrieve_strvar ('short'), me, nil);
          tell_room (u, me^.env, ' takes ', me, nil);
          tell_room (u, me^.env, itmptr^.retrieve_strvar ('short'), me, nil);
          tell_room (u, me^.env, '^', me, nil);
      end
     else
     begin
          me^.console.cwrite ('There is no ');
          me^.console.cwrite (argstr);
          me^.console.cwriteln (' here!');
     end;
end;

procedure do_die (bywho, who : pchar); far;
var playptr : PlayerPtr;
    mnptr   : MonsterPtr;
begin
     playptr:= find_player (u, bywho);
     if not (playptr = nil) then
     begin
          mnptr:= find_monster (u, who, playptr^.env);
          if not (mnptr = nil) then
          begin
               playptr^.stop_fight;
               playptr^.console.cwrite ('You killed ');
               playptr^.console.cwriteln (mnptr^.retrieve_strvar ('short'));
               tell_room (u, playptr^.env, playptr^.retrieve_strvar ('short'), playptr, nil);
               tell_room (u, playptr^.env, ' killed ', playptr, nil);
               tell_room (u, playptr^.env, mnptr^.retrieve_strvar ('short'), playptr, nil);
               tell_room (u, playptr^.env, '^', playptr, nil);
               u^.md^.delete;
          end
          else
              playptr^.console.cwriteln ('Your monster has disappeared!');
     end;
     playptr:= find_player (u, who);
     if not (playptr = nil) then
     begin
          playptr^.console.cwriteln ('You die... ');
          playptr^.console.cwriteln ('Suddenly you see your own body from above');
          playptr^.console.cwriteln ('It seems like you have a less solid form now..');
          tell_room (u, playptr^.env, playptr^.retrieve_strvar ('short'), playptr, nil);
          tell_room (u, playptr^.env, ' dies..^', playptr, nil);
          if not (playptr^.set_strvar ('prename', 'Ghost of ')) then
               playptr^.console.cwriteln ('Out of memory');
          playptr^.set_intvar ('ghost', 1);
          playptr^.stop_fight;
     end
     else
         error ('fun.do_die: player or monster does not exist^',0);
end;

procedure do_hit (attacker, attacked : pchar); far;
var playattacker,
    playattacked : PlayerPtr;
    monattacker,
    monattacked  : MonsterPtr;
begin
     playattacked:= find_player (u, attacked);
     if not (playattacked = nil) then
     begin
        monattacker:= find_monster (u, attacker, playattacked^.env);
        if not (monattacker = nil) then
        begin
             playattacked^.console.cwrite (monattacker^.retrieve_strvar ('short'));
             playattacked^.console.cwriteln (' hits you');
             playattacked^.start_fight (do_hit, attacker);
             tell_room (u, playattacked^.env, monattacker^.retrieve_strvar ('short'), playattacked, nil);
             tell_room (u, playattacked^.env, ' hits ', playattacked, nil);
             tell_room (u, playattacked^.env, playattacked^.retrieve_strvar ('short'), playattacked, nil);
             tell_room (u, playattacked^.env, '^', playattacked, nil);
             if not (playattacked^.add_hp (-3)) then
                 do_die (attacker, attacked);
        end
        else
        begin
            playattacker:= find_player (u, attacker);
            if (not (playattacker = nil)) and
               (playattacker^.env = playattacked^.env) then
            begin
                 playattacker^.console.cwrite ('You hit ');
                 playattacker^.console.cwriteln (playattacked^.retrieve_strvar ('short'));
                 playattacked^.console.cwrite (playattacker^.retrieve_strvar ('short'));
                 playattacked^.console.cwriteln (' hits you');
                 playattacked^.start_fight (do_hit, attacker);
                 tell_room (u, playattacker^.env, playattacker^.retrieve_strvar ('short'), playattacker, playattacked);
                 tell_room (u, playattacker^.env, ' hits ', playattacker, playattacked);
                 tell_room (u, playattacker^.env, playattacked^.retrieve_strvar ('short'), playattacker, playattacked);
                 tell_room (u, playattacker^.env, '^', playattacker, playattacked);
                 if not (playattacked^.add_hp (-3)) then
                 begin
                      playattacker^.add_exp (playattacked^.reward_exp);
                      playattacker^.add_money (playattacked^.retrieve_intvar ('money'));
                      do_die (attacker, attacked);
                 end;
             end
             else
                 if (playattacker = nil) then playattacked^.stop_fight;
        end;
     end
     else
     begin
         playattacker:= find_player (u, attacker);
         if not (playattacker = nil) then
         begin
              monattacked:= find_monster (u, attacked, playattacker^.env);
              if not (monattacked = nil) then
              begin
                   playattacker^.console.cwrite ('You hit ');
                   playattacker^.console.cwriteln (monattacked^.retrieve_strvar ('short'));
                   tell_room (u, playattacker^.env, playattacker^.retrieve_strvar ('short'), playattacker, nil);
                   tell_room (u, playattacker^.env, ' hits ', playattacker, nil);
                   tell_room (u, playattacker^.env, monattacked^.retrieve_strvar ('short'), playattacker, nil);
                   tell_room (u, playattacker^.env, '^', playattacker, nil);
                   if not (monattacked^.add_hp (-3)) then
                   begin
                        playattacker^.add_exp (monattacked^.reward_exp);
                        playattacker^.add_money (monattacked^.retrieve_intvar ('money'));
                        do_die (attacker, attacked);
                   end;
              end
              else
              begin
                   playattacker^.console.cwrite ('Your victim has disappeared!');
                   playattacker^.stop_fight;
              end;
         end
     end;
end;

procedure do_kill; far;
var playptr: PlayerPtr;
    mnptr  : MonsterPtr;
    found  : boolean;
begin
     if (me^.retrieve_intvar ('ghost') = 1) then
     begin
          me^.console.cwriteln ('You are in a immaterial state!');
          exit;
     end;
     found:= false;
     if (u^.md^.find_first) then
     repeat
           u^.md^.retrieve (mnptr);
           if (StrLIComp (argstr, mnptr^.retrieve_strvar ('short'), StrLen (mnptr^.retrieve_strvar ('short'))) = 0)
           and (mnptr^.env = me^.env) then
           begin
                found:= true;
                break;
           end;
     until not u^.md^.find_next;
     if found then
     begin
        me^.start_fight (do_hit, mnptr^.retrieve_strvar ('short'));
        mnptr^.start_fight (do_hit, me^.retrieve_strvar ('short'));
        exit;
     end;

     if (u^.pd^.find_first) then
     repeat
           u^.pd^.retrieve (playptr);
           if (StrLIComp (argstr, playptr^.retrieve_strvar ('short'), StrLen (playptr^.retrieve_strvar ('short'))) = 0)
           and (playptr^.env = me^.env) then
           begin
                found:= true;
                break;
           end;
     until not u^.pd^.find_next;
     if found then
     begin
          if (playptr^.retrieve_intvar ('ghost') = 1) then
               me^.console.cwriteln ('You cannot kill a ghost!')
          else
          begin
               me^.start_fight (do_hit, playptr^.retrieve_strvar ('short'));
               playptr^.start_fight (do_hit, me^.retrieve_strvar ('short'));
          end;
     end
     else
         me^.console.cwriteln ('Monster or player not found!');
end;

procedure do_stop; far;
var playptr : PlayerPtr;
    mnptr   : MonsterPtr;
begin
     if (me^.retrieve_intvar ('ghost') = 1) then
     begin
          me^.console.cwriteln ('You are in a immaterial state!');
          exit;
     end;
     if (me^.retrieve_intvar ('fight') = 0) then
     begin
          me^.console.cwriteln ('You were fighting no one!');
          exit;
     end;
     playptr:= find_player (u, me^.attacked);
     if not (playptr = nil) then
     begin
          playptr^.stop_fight;
          tell_room (u, me^.env, me^.retrieve_strvar ('short'), me, nil);
          tell_room (u, me^.env, ' stops fighting^', me, nil);
          me^.console.cwrite ('You stop fighting ');
          me^.console.cwriteln (playptr^.retrieve_strvar ('short'));
     end
     else
     begin
         mnptr:= find_monster (u, me^.attacked, me^.env);
         if not (mnptr = nil) then
         begin
            mnptr^.stop_fight;
            tell_room (u, me^.env, me^.retrieve_strvar ('short'), me, nil);
            tell_room (u, me^.env, ' stops fighting^', me, nil);
            me^.console.cwrite ('You stop fighting ');
            me^.console.cwriteln (mnptr^.retrieve_strvar ('short'));
         end
         else
               me^.console.cwriteln ('Player or monster not found!');
     end;
     me^.stop_fight;
end;

procedure do_destruct; far;
var rmptr : RoomPtr;
    mnptr : MonsterPtr;
    itmptr : ItemPtr;
    playptr: PlayerPtr;
begin
     if no_args then
     begin
          me^.console.cwriteln ('Destruct what?');
          exit;
     end;
     if (u^.md^.find_first) then
     repeat
           u^.md^.retrieve (mnptr);
           if ((StrLIComp (mnptr^.retrieve_strvar ('short'), argstr, StrLen (mnptr^.retrieve_strvar ('short'))) = 0)
           and (mnptr^.env = me^.env)) then
           begin
                u^.md^.delete;
                me^.console.cwriteln ('Monster destructed');
                exit;
           end;
     until not u^.md^.find_next;
     if (not (me^.env = nil)) and (me^.env^.inv.find_first) then
     repeat
           me^.env^.inv.retrieve (itmptr);
           if (StrLIComp (itmptr^.retrieve_strvar ('short'), argstr, StrLen (itmptr^.retrieve_strvar ('short'))) = 0) then
           begin
                me^.env^.inv.delete (true);
                me^.console.cwriteln ('Item in your environment destructed');
                exit;
           end;
     until not me^.env^.inv.find_next;
     if (me^.inv.find_first) then
     repeat
           me^.inv.retrieve (itmptr);
           if (StrLIComp (itmptr^.retrieve_strvar ('short'), argstr, StrLen (itmptr^.retrieve_strvar ('short'))) = 0)  then
           begin
                me^.inv.delete (true);
                me^.console.cwriteln ('Item in your inventory destructed');
                exit;
           end;
     until not me^.inv.find_next;
     if (u^.rd^.find_first) then
     repeat
           u^.rd^.retrieve (rmptr);
           if (StrLIComp (rmptr^.retrieve_strvar ('short'), argstr, StrLen (rmptr^.retrieve_strvar ('short'))) = 0) or
              (not (find_room_file (u, me, StrPas (argstr)) = nil)) then
           begin
                if (rmptr = nil) then
                begin
                     rmptr:= find_room_file (u, me, StrPas (argstr));
                     if (rmptr = nil) then
                     begin
                          me^.console.cwriteln ('Object not found!');
                          exit;
                     end;
                end;
                if (u^.md^.find_first) then
                repeat
                     u^.md^.retrieve (mnptr);
                     if (mnptr^.env = rmptr) then
                     begin
                          tell_room (u, rmptr, mnptr^.retrieve_strvar ('short'), nil, nil);
                          tell_room (u, rmptr, ' suddenly dissolves^', nil, nil);
                          u^.md^.delete;
                     end;
                until not u^.md^.find_next;
                if (u^.pd^.find_first) then
                repeat
                      u^.pd^.retrieve (playptr);
                      if (playptr^.env = rmptr) then
                      begin
                           playptr^.console.cwriteln ('Your environment suddenly dissolves!');
                           playptr^.env:= nil;
                      end;
                until not u^.pd^.find_next;
                u^.rd^.delete;
                me^.console.cwriteln ('Room destructed (will be loaded at next reference)');
                exit;
           end;
     until not u^.rd^.find_next;
     me^.console.cwriteln ('Object not found!');
end;

procedure do_load; far;
var savearg : string [254];
    rmptr   : RoomPtr;
    transfer: boolean;
begin
     if (me^.retrieve_intvar ('ghost') = 1) then
     begin
          me^.console.cwriteln ('You are in a immaterial state!');
          exit;
     end;
     if no_args then
     begin
          me^.console.cwriteln ('Load what file?');
          exit;
     end;
     transfer:= false;
     rmptr:= find_room_file (u, me, StrPas (argstr));
     if not (rmptr = nil) then
     begin
          if (me^.env = rmptr) then transfer:= true;
          me^.console.cwriteln ('Room is already loaded, replacing it');
          savearg:= StrPas (argstr);
          StrMove (argstr, rmptr^.retrieve_strvar ('short'), StrLen (rmptr^.retrieve_strvar ('short')));
          do_destruct;
          me^.console.cwriteln ('Loading room..');
          StrPCopy (argstr, savearg);
     end;
     if ((argstr[1] = ':') or (argstr[0] = '\')) then
        interpret (StrPas (argstr), u, me)
     else
     begin
          if (me^.retrieve_strvar ('curdir') = nil) then
               me^.console.cwriteln ('warning: current dir not known!');
          interpret (Concat (StrPas (me^.retrieve_strvar ('curdir')), '\', StrPas (argstr)), u, me);
     end;
     if transfer then
     begin
          rmptr:= find_room (u, rmptr^.retrieve_strvar ('short'));
          if not (rmptr = nil) then
          begin
               me^.env:= rmptr;
               me^.console.cwriteln ('Transporting you back..');
          end;
     end;
end;

procedure do_score; far;
var tempstr : string;
begin
     if (me^.retrieve_intvar ('ghost') = 1) then
     begin
          me^.console.cwriteln ('You are in a immaterial state!');
          exit;
     end;
     me^.console.cwrite (me^.retrieve_strvar ('prename'));
     me^.console.cwrite (me^.retrieve_strvar ('short'));
     me^.console.cwrite (' ');
     me^.console.cwriteln (me^.retrieve_strvar ('title'));
     me^.console.cwrite ('Hitpoints: ');
     str (me^.retrieve_intvar ('hp'), tempstr);
     StrPCopy (tempptr, tempstr);
     me^.console.cwrite (tempptr);
     me^.console.cwrite (' (');
     str (me^.retrieve_intvar ('maxhp'), tempstr);
     StrPCopy (tempptr, tempstr);
     me^.console.cwrite (tempptr);
     me^.console.cwrite (')     Experience: ');
     str (me^.retrieve_intvar ('exp'), tempstr);
     StrPCopy (tempptr, tempstr);
     me^.console.cwrite (tempptr);
     me^.console.cwrite ('     Money: ');
     str (me^.retrieve_intvar ('money'), tempstr);
     StrPCopy (tempptr, tempstr);
     me^.console.cwriteln (tempptr);
end;

procedure do_ls; far;
var dirinfo: SearchRec;
begin
     findfirst (Concat (StrPas (me^.retrieve_strvar ('curdir')), '\*.*'), Anyfile, dirinfo);
     if (doserror > 0) then me^.console.cwrite ('Directory not found!');
     while (doserror = 0) do
     begin
          StrPCopy (tempptr, dirinfo.name);
          me^.console.cwrite (tempptr);
          me^.console.cwrite ('  ');
          findnext (dirinfo);
     end;
     me^.console.cwrite ('^');
end;

procedure do_cd; far;
var savedir, newdir: string;
begin
     getdir (0, savedir);
     {$I-}
     chdir (StrPas (me^.retrieve_strvar ('curdir')));
     chdir (StrPas (argstr));
     if (IOResult < 0) then me^.console.cwrite ('Directory not found!')
     else
     begin
          getdir (0, newdir);
          StrPCopy (tempptr, newdir);
          if not (me^.set_strvar ('curdir', tempptr)) then
               me^.console.cwriteln ('Out of memory');
          me^.console.cwriteln (me^.retrieve_strvar ('curdir'));
     end;
     {$I+}
     chdir (savedir);
end;

procedure do_quit; far;
var i : word;
begin
     argstr:= 'all';
     do_drop;
     tell_room (u, me^.env, me^.retrieve_strvar ('short'), me, nil);
     tell_room (u, me^.env, ' left this world^', me, nil);
     me^.status:= 0;
     if not (me^.set_strvar ('short','')) then
          me^.console.cwriteln ('Out of memory');
     me^.env:= nil;
     me^.console.set_owner  ('Logon');
     me^.console.clear_buf;
     me^.console.redraw_screen;
     me^.console.cwrite ('What is your name: ');
end;

procedure do_shutdown; far;
begin
     u^.run:= false;
end;

procedure fill_funtab (var funtab : FunDaemon);
begin
     funtab.insert ('malloc',do_malloc);
     funtab.insert ('say',do_say);
     funtab.insert ('shout',do_shout);
     funtab.insert ('tell',do_tell);
     funtab.insert ('echo',do_echo);
     funtab.insert ('look',do_look);
     funtab.insert ('exa',do_examine);
     funtab.insert ('goto',do_goto);
     funtab.insert ('who',do_who);
     funtab.insert ('list',do_list);
     funtab.insert ('inv',do_inv);
     funtab.insert ('have',do_have);
     funtab.insert ('drop',do_drop);
     funtab.insert ('take',do_take);
     funtab.insert ('kill',do_kill);
     funtab.insert ('stop',do_stop);
     funtab.insert ('dest',do_destruct);
     funtab.insert ('load',do_load);
     funtab.insert ('score',do_score);
     funtab.insert ('ls',do_ls);
     funtab.insert ('cd',do_cd);
     funtab.insert ('quit',do_quit);
     funtab.insert ('shutdown',do_shutdown);
end;

begin
     startmem:= memavail;
     if (maxavail < 255) then error ('fun: out of memory',1);
     getmem (tempptr, 254);
end.
