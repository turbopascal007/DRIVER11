unit basicobj;

interface

uses strings, stringd, vard, verbd, err;

type
    BasicObject = object
                        long     : StringDaemon;
                        vartab   : VarDaemon;
                        verbtab  : VerbDaemon;

                        constructor init;

                        function set_strvar (idstr, cstr : pchar) : boolean;
                        function retrieve_strvar (idstr : pchar) : pchar;

                        function set_intvar (idstr : pchar; cint : integer) : boolean;
                        function retrieve_intvar (idstr : pchar) : integer;

                        destructor destruct;
                  end;

    BasicPtr = ^BasicObject;


implementation

constructor BasicObject.init;
begin
     long.init;
     vartab.init;
     verbtab.init;
end;

function BasicObject.set_strvar (idstr, cstr : pchar) : boolean;
var varr : vartabptr;
begin
     set_strvar:= false;
     if (vartab.find_first) then
     repeat
           vartab.retrieve (varr);
           if ((StrComp (varr^.id, idstr) = 0) and (varr^.typ = s)) then
           begin
                vartab.delete;
                set_strvar:= vartab.insert_str (idstr, cstr);
                exit;
           end;
     until not vartab.find_next;
     set_strvar:= vartab.insert_str (idstr, cstr);
end;

function BasicObject.retrieve_strvar (idstr : pchar) : pchar;
var varr : vartabptr;
begin
     if (vartab.find_first) then
     repeat
           vartab.retrieve (varr);
           if ((StrIComp (varr^.id, idstr) = 0) and (varr^.typ = s)) then
           begin
                retrieve_strvar:= varr^.str;
                exit;
           end;
     until not vartab.find_next;
     retrieve_strvar:= nil;
end;

function BasicObject.set_intvar (idstr : pchar; cint : integer) : boolean;
var varr : vartabptr;
begin
     set_intvar:= false;
     if (vartab.find_first) then
     repeat
           vartab.retrieve (varr);
           if ((StrComp (varr^.id, idstr) = 0) and (varr^.typ = i)) then
           begin
                vartab.delete;
                set_intvar:= vartab.insert_int (idstr, cint);
                exit;
           end;
     until not vartab.find_next;
     set_intvar:= vartab.insert_int (idstr, cint);
end;

function BasicObject.retrieve_intvar (idstr : pchar) : integer;
var varr : vartabptr;
begin
     if (vartab.find_first) then
     repeat
           vartab.retrieve (varr);
           if ((StrIComp (varr^.id, idstr) = 0) and (varr^.typ = i)) then
           begin
                retrieve_intvar:= varr^.int;
                exit;
           end;
     until not vartab.find_next;
     retrieve_intvar:= 0;
end;

destructor BasicObject.destruct;
begin
     verbtab.destruct;
     vartab.destruct;
     long.destruct;
end;

end.
