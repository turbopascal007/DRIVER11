unit task;

interface

uses player, monster, room, item, stringd, strings;

type
    TaskPtr = ^TaskObject;

    TaskObject = object
                       id : pchar;
                       playptr : PlayerPtr;
                       monptr : MonsterPtr;
                       itemptr : ItemPtr;
                       current : StringDPtr;
                       argstr : pchar;
                       run : boolean;
                       foreground : boolean;
                       rmptr : RoomPtr;
                       mnptr : MonsterPtr;
                       itmptr : ItemPtr;
                       if_set : array [1..MAXDEPTH] of boolean;
                       if_depth : word;
                       start_while : array [1..MAXDEPTH] of StringPtr;
                       while_depth : word;

                       constructor init (idstr: pchar);

                       destructor destruct;
                 end;


implementation

constructor TaskObject.init (idstr: pchar);
begin
  getmem (id, StrLen (idstr) + 1);
  StrMove (id, idstr, StrLen (idstr) + 1);
end;

destructor TaskObject.destruct;
begin
  freemem (id, StrLen (id) + 1);
end;

end.
