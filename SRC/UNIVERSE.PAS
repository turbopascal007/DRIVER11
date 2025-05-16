unit universe;

interface

uses playerd, roomd, monsterd, err;

type
    UniverseObject = object
                           run : boolean;

                           pd : PlayerDPtr;
                           rd : RoomDPtr;
                           md : MonsterDPtr;

                           constructor init;

                           destructor destruct;
                     end;

    UniversePtr = ^UniverseObject;

implementation

constructor UniverseObject.init;
begin
     if (maxavail < (sizeof (PlayerDaemon) +
                     sizeof (RoomDaemon) +
                     sizeof (MonsterDaemon))) then
     error ('universe.init: out of memory',1);

     getmem (pd, sizeof (PlayerDaemon));
     getmem (rd, sizeof (RoomDaemon));
     getmem (md, sizeof (MonsterDaemon));
     pd^.init;
     rd^.init;
     md^.init;
     run:= true;
end;

destructor UniverseObject.destruct;
begin
     pd^.destruct;
     rd^.destruct;
     md^.destruct;
end;

end.
