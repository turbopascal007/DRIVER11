unit ifun;

interface

uses monster, player, room, universe, strings, err2;

function find_monster (u : UniversePtr; name : pchar; env : RoomPtr) : MonsterPtr;
function find_player  (u : UniversePtr; name : pchar) : PlayerPtr;
function find_room    (u : UniversePtr; name : pchar) : RoomPtr;
function find_room_file (u : UniversePtr; who : PlayerPtr; filename : string) : RoomPtr;

procedure tell_room (u : UniversePtr; room : RoomPtr;
                     str : pchar; except1, except2 : PlayerPtr);


implementation

function find_monster (u : UniversePtr; name : pchar; env : RoomPtr) : MonsterPtr;
(* WARNING: when called in a u^.md loop, it will be distorted!! *)
var mnptr : MonsterPtr;
begin
     find_monster:= nil;
     if (u^.md^.find_first) then
     repeat
           u^.md^.retrieve (mnptr);
           if (StrLIComp (name, mnptr^.retrieve_strvar ('short'), StrLen (mnptr^.retrieve_strvar ('short'))) = 0)
           then
                if (env = nil) or ((not (env = nil)) and (mnptr^.env = env)) then
                begin
                    find_monster:= mnptr;
                    break;
                end;
     until not u^.md^.find_next;
end;

function find_player (u : UniversePtr; name : pchar) : PlayerPtr;
(* WARNING: when called in a u^.pd loop, it will be distorted!! *)
var playptr : PlayerPtr;
begin
     find_player:= nil;
     if (u^.pd^.find_first) then
     repeat
           u^.pd^.retrieve (playptr);
           if (StrIComp (name, playptr^.retrieve_strvar ('short')) = 0)
           then begin
                find_player:= playptr;
                exit;
           end;
     until not u^.pd^.find_next;
end;

function find_room (u : UniversePtr; name : pchar) : RoomPtr;
(* WARNING: when called in a u^.rd loop, it will be distorted!! *)
var rmptr : RoomPtr;
begin
     find_room:= nil;
     if (u^.rd^.find_first) then
     repeat
           u^.rd^.retrieve (rmptr);
           if (StrLIComp (name, rmptr^.retrieve_strvar ('short'), StrLen (rmptr^.retrieve_strvar ('short'))) = 0)
           then begin
                find_room:= rmptr;
                exit;
           end;
     until not u^.rd^.find_next;
end;

function find_room_file (u : UniversePtr; who : PlayerPtr; filename : string) : RoomPtr;
var rmptr,
    rm2ptr,
    rmsaveptr : RoomPtr;
    roomfilename : pchar;
    ok    : boolean;
    i     : byte;
begin
     u^.rd^.retrieve (rmsaveptr);
     if (who^.retrieve_strvar ('curdir') = nil) then
        error ('warning: current dir not known!^', 0, who);
     if not ((filename[2] = ':') or (filename[1] = '\')) then
         filename:= concat (StrPas (who^.retrieve_strvar ('curdir')), '\', filename);
     find_room_file:= nil;
     if (u^.rd^.find_first) then
     repeat
           u^.rd^.retrieve (rmptr);
           roomfilename:= rmptr^.retrieve_strvar ('filename');
           ok:= true;
           for i:= 1 to ord(filename[0]) do
           begin
                if (filename[i] = '/') then filename[i]:= '\';
                if (roomfilename[i - 1] = '/') then roomfilename[i - 1]:= '\';
                if (ord (filename[i]) > ord ('Z')) then filename[i]:= chr (ord (filename[i]) - 32);
                if (ord (roomfilename[i - 1]) > ord ('Z')) then roomfilename[i - 1]:= chr (ord (roomfilename[i - 1]) - 32);
               if (filename[i] <> roomfilename[i - 1]) then
                begin
                     ok:= false;
                     break;
                end;
           end;
           if ok then
           begin
                find_room_file:= rmptr;
                break;
           end;
     until not u^.rd^.find_next;
     if (u^.rd^.find_first) then
     repeat
           u^.rd^.retrieve (rm2ptr);
           if (not (rm2ptr^.retrieve_strvar ('short') = nil)) and
              (rm2ptr^.retrieve_strvar ('short') = (rmsaveptr^.retrieve_strvar ('short'))) then
            break;
     until not u^.rd^.find_next;
end;

procedure tell_room (u : UniversePtr; room : RoomPtr;
                     str : pchar; except1, except2 : PlayerPtr);
var playptr,
    saveplayptr : PlayerPtr;
begin
     u^.pd^.retrieve (saveplayptr);
     if (u^.pd^.find_first) then
     repeat
           u^.pd^.retrieve (playptr);
           if ((playptr^.env = room) and (not (playptr = except1)) and
               (not (playptr = except2))) then
                playptr^.console.cwrite (str);
     until not u^.pd^.find_next;
     find_player (u, saveplayptr^.retrieve_strvar ('short'));
end;

end.
