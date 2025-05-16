unit player;

interface

uses living, console, stringd, room, monster, item;

const {$I defines.inc}

type
    PlayerObject   = object (LivingObject)
                            console : ConsoleObject;
                            status  : byte;

                            constructor init;

                            destructor destruct;
                     end;

    PlayerPtr = ^PlayerObject;

implementation

constructor PlayerObject.init;
begin
     inherited init;
     set_intvar ('ghost', 0);
     status:= 0;
end;

destructor PlayerObject.destruct;
begin
     inherited destruct;
     console.cwriteln ('Exiting.. see you next time!');
     console.destruct;
end;

end.
