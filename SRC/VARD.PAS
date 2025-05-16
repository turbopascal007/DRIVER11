unit vard;

interface

uses strings, err;

type
    vartyp = (s, i);

    vartabptr = ^vartabrec;
    
    vartabrec = record
                      next : vartabptr;
                      id : pchar;
                      case typ : vartyp of
                      s : (str : pchar);
                      i : (int : integer);
                end;
                 
    VarDaemon = object
                      vartab : vartabrec;
                      current, head : vartabptr;
                      size : word;
                      
                      constructor init;
                      
                      function  insert_str (idstr, cstr : pchar) :  boolean;
                      function  insert_int (idstr : pchar; cint : integer) : boolean;
                      procedure delete;
                      
                      procedure retrieve (var varr : vartabptr);
                      
                      function find_first : boolean;
                      function find_next  : boolean;
                      function empty      : boolean;
                                            
                      destructor destruct;
                end;
                
implementation

constructor VarDaemon.init;
begin
     current:= nil;
     head:= nil;
     size:= 0;
end;     

function VarDaemon.insert_str (idstr, cstr : pchar)  : boolean;
var  ptr : vartabptr;
begin
     insert_str:= false;
     if (maxavail < sizeof (vartabrec) + StrLen (idstr) + StrLen (cstr) + 2) then
     begin
          error ('vard.insert_str: out of memory^',0);
          exit;
     end;
     getmem (ptr, sizeof (vartabrec));
     ptr^.typ:= s;
     getmem (ptr^.str, StrLen (cstr) + 1);
     getmem (ptr^.id, StrLen (idstr) + 1);
     StrMove (ptr^.str, cstr, StrLen (cstr) + 1);
     StrMove (ptr^.id, idstr, StrLen (idstr) + 1);
     ptr^.next:= head;
     head:= ptr;
     current:= ptr;
     inc (size);
     insert_str:= true;
end;

function VarDaemon.insert_int (idstr : pchar; cint : integer) : boolean;
var ptr : vartabptr;
begin
     insert_int:= false;
     if (maxavail < sizeof (vartabrec) + StrLen (idstr) + 1) then
     begin
          error ('vard.insert_int: out of memory^',0);
          exit;
     end;
     getmem (ptr, sizeof (vartabrec));
     ptr^.typ:= i;
     getmem (ptr^.id, StrLen (idstr) + 1);
     StrMove (ptr^.id, idstr, StrLen (idstr) + 1);
     ptr^.int:= cint;
     ptr^.next:= head;
     head:= ptr;
     current:= ptr;
     inc (size);
     insert_int:= true;
end;

procedure VarDaemon.delete;
var ptr : vartabptr;
begin
     if not (current = head) then
     begin
          ptr:= head;
          while not (ptr^.next = current) do
                ptr:= ptr^.next;
          ptr^.next:=current^.next;
     end
     else
         head:= head^.next;
     freemem (current^.id, StrLen (current^.id) + 1);
     if (current^.typ = s) then freemem (current^.str, StrLen (current^.str) + 1);
     freemem (current, sizeof (vartabrec));
     current:= head;
     if size > 0 then dec (size);
end;
 
procedure VarDaemon.retrieve (var varr : vartabptr);
begin
     varr:= current;
end;

function VarDaemon.find_first : boolean;
begin
     current:= head;
     if (current = nil) then find_first:= false else find_first:= true;
end;

function VarDaemon.find_next : boolean;
begin
     if ((current^.next = nil) or (current = nil)) then
          find_next:= false
     else
     begin
          current:= current^.next;
          find_next:= true;
     end;
end;

function VarDaemon.empty : boolean;
begin
     empty:= (head = nil);
end;

destructor VarDaemon.destruct;
begin
     find_first;
     while not empty do delete;
end;

end.
