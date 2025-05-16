unit mystrings;

interface

uses strings, err;

procedure skip_spaces (srcstr : pchar);
function shift_str (srcstr : pchar) : pchar;


implementation

procedure skip_spaces (srcstr : pchar);
var i : integer;
begin
     while (srcstr[0] = #32) do
           for i:= 0 to StrLen (srcstr) do srcstr[i]:= srcstr[i+1];
end;

function shift_str (srcstr : pchar) : pchar;
var i : integer;
begin

     i:= 0;

     while (srcstr[i] = #32) do inc(i);
     while not ((srcstr[i] = #32) or (srcstr[i] = #0)) do inc(i);
     while (srcstr[i] = #32) do inc(i);

     shift_str:= @srcstr[i];
end;

end.
