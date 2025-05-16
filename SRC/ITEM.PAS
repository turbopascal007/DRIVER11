unit item;

interface

uses basicobj;

type
    ItemObject = object (BasicObject)
                        constructor init;

                        destructor destruct;
                  end;

    ItemPtr = ^ItemObject;

implementation

constructor Itemobject.init;
begin
     inherited init;
end;

destructor ItemObject.destruct;
begin
     inherited destruct;
end;

end.
