unit room;

interface

uses basicobj, itemd;

type
    RoomPtr = ^RoomObject;

    RoomObject = object (BasicObject)
                       inv           : ItemDaemon;

                       constructor init;

                       destructor destruct;
                 end;


implementation

constructor RoomObject.init;
begin
     inherited init;
     inv.init;
end;

destructor RoomObject.destruct;
begin
     inv.destruct;
     inherited destruct;
end;

end.
