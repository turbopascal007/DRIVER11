program makehd;

uses dos;

var
   id : word;
   startpath, path : string;

{$i-}

procedure do_tree (tree, parent : string);
var
   dir : SearchRec;
   idstr : string;
   worldfile : text;
   filename : string;
   i : word;
begin
     write (tree);
     write (', ');
     chdir (tree);

     if (doserror <> 0) then
     begin
          write ('** could not cd to ');
          writeln (tree);
          halt (0);
     end;

     inc (id);
     str (id, idstr);
     filename:= concat (startpath, '\', idstr, '.dir');

     assign (worldfile, filename);
     rewrite (worldfile);

     if (doserror <> 0) then
     begin
          write ('** problem writing to ');
          writeln (filename);
          halt (0);
     end;

     writeln (worldfile, 'unit room');
     writeln (worldfile);
     write (worldfile, 'name ');
     writeln (worldfile, tree);
     writeln (worldfile);
     write (worldfile, 'long This is the area labeled ');
     writeln (worldfile, tree);
     writeln (worldfile);
     write (worldfile, 'exit back ');
     writeln (worldfile, parent);

     findfirst ('*.*', Directory, dir);
     while (doserror = 0) do
     begin
          if (dir.attr = Directory) and
             not (dir.name[1] = '.') then
          begin
               write (worldfile, 'exit ');
               write (worldfile, dir.name);
               write (worldfile, ' ');
               str (id + 1, idstr);
               writeln (worldfile, concat (startpath, '\', idstr, '.dir'));

               do_tree (dir.name, filename);
          end;
          findnext (dir);
     end;

     close (worldfile);
     getdir (0, idstr);

     i:= 1;
     while (idstr[i] = path[i]) do inc (i);

     if i <= ord (path[0]) then
     begin
          write ('-> stopping at ');
          write (idstr);
          write (', started at ');
          writeln (path);

          chdir (startpath);
          halt (0);
     end;

     chdir ('..');
     if (doserror <> 0) and (doserror <> 18) then
     begin
          write ('** could not cd .. from ');
          writeln (idstr);
          halt (0);
     end;

end;


begin
     id:= 0;
     getdir (0, startpath);
     writeln ('Virtual Drive World Builder 1.0  (c) 1994 Prinssoft Corp.  All rights reserved.');
     writeln;

     if ( ParamCount = 0 ) then
     begin
          writeln ('Ehm.. build which tree?');
          halt (0);
     end;

     chdir (ParamStr (1));
     if DosError <> 0 then
     begin
          write ('** wrong path ');
          writeln (ParamStr (1));
          halt (0);
     end;

     write ('writing to ');
     writeln (startpath);

     getdir (0, path);

     write ('analyzing  ');
     writeln (path);

     do_tree ( path , path );
end.
