program depend;

uses dos, crt;

var
   curfile : SearchRec;

function examine (filename: string) : boolean;
var stri : string;
    unitfile : string;
    srcfile : text;
    i, j : word;
    found, done, nowrite : boolean;
begin
     found:= false;
     done:= false;
     nowrite:= false;
     {$I-}
     assign (srcfile, filename);
     i:= 1;
     j:= 1;
     while (i < ord(filename[0])) and (filename[i] <> '.') do
     begin
          if (filename[i] >= 'A') and (filename[i] <= 'Z') then
             filename[i]:= chr (ord (filename[i]) + 32);
          inc (i);
     end;
     filename[0]:= chr (i-1);

     reset (srcfile);
     if (ioresult > 0) then
     begin
          writeln (filename);
          examine:= false;
          exit;
     end;
     {$I+}

     while (i < ord(filename[0])) and (filename[i] <> '.') do
     begin
          if (filename[i] >= 'A') and (filename[i] <= 'Z') then
             filename[i]:= chr (ord (filename[i]) + 32);
          inc (i);
     end;
     filename[0]:= chr (i-1);
     write (filename, ' <- ');
     while not eof (srcfile) do
     begin
          readln (srcfile, stri);
          if (ord(stri[0]) < 5) then continue;
          if not found then
          begin
               for i:= 1 to ord(stri[0]) - 3 do
               begin
                    if ((stri[i] = 'u') or (stri[i] = 'U')) and
                       ((stri[i+1] = 's') or (stri[i+1] = 'S')) and
                       ((stri[i+2] = 'e') or (stri[i+2] = 'E')) and
                       ((stri[i+3] = 's') or (stri[i+3] = 'S')) then
                    begin
                         i:= i + 4;
                         found:= true;
                         break;
                    end;
               end;
          end;
          if found then
          begin
               while (i <= ord(stri[0])) do
               case stri[i] of
               '{': begin nowrite:= true; inc (i); end;
               '}': begin nowrite:= false; inc (i); end;
               ' ': inc (i);
               ',': begin
                         if not nowrite then
                         begin
                              unitfile[j]:= '.';
                              unitfile[j+1]:= 'p';
                              unitfile[j+2]:= 'a';
                              unitfile[j+3]:= 's';
                              unitfile[0]:= chr(j+3);
                              if not (examine (unitfile)) then
                                 write (filename);
                              write (' <- ');
                              j:= 1;
                         end;
                         inc (i);
                    end;
               ';': begin
                         if not nowrite then
                         begin
                              unitfile[j]:= '.';
                              unitfile[j+1]:= 'p';
                              unitfile[j+2]:= 'a';
                              unitfile[j+3]:= 's';
                              unitfile[0]:= chr(j+3);
                              if not (examine (unitfile)) then
                                 write (filename);
                              j:= 1;
                              done:= true;
                              write (' <- ');
                              break;
                         end
                         else inc (i);
                    end;
               else begin
                         if not nowrite then
                         begin
                              unitfile[j]:= stri[i];
                              inc (j);
                         end;
                         inc (i);
                    end;
               end;
          end;
          i:= 1;
          if done then break;
     end;
     close (srcfile);
     examine:= true;
end;

begin
     if (ParamCount = 0) then
     begin
          writeln ('usage: depend <filename>');
          halt (0);
     end;
     writeln ('Dependence analyzer 0.1  (c) 1994  Prinssoft Corp.  All rights reserved.');
     writeln;
     (* UNCOMMENT FOR PROTOTYPES: *)
       writeln ('NOTICE: This version is below 1.0, and is likely to contain bugs.');
       writeln ('        Hence, the output may be invalid. Press a key to continue...');
       repeat until keypressed;
     examine (ParamStr (1));
end.

