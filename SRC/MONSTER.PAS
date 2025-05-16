unit monster;

interface

uses living;

type
    MonsterObject = object (LivingObject)
                           constructor init;

                           destructor destruct;
                    end;

    MonsterPtr = ^MonsterObject;

implementation

constructor MonsterObject.init;
begin
     inherited init;
end;

destructor MonsterObject.destruct;
begin
     inherited destruct;
end;

end.
