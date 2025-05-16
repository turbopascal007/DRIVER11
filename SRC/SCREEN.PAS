unit screen;

interface

uses dos, crt;

procedure save_screen;
procedure restore_screen;
procedure cursor_off;
procedure cursor_on;

implementation

type
  screentype = array [1..4000] of byte;

var
  current_mono_screen: screentype absolute $B000:$0000;
  current_color_screen: screentype absolute $B800:$0000;
  saved_screen: screentype;
  posx, posy: byte;
  regs: registers;
  is_mono: boolean;

procedure save_screen;
begin
  if (is_mono) then
    saved_screen:= current_mono_screen
  else
    saved_screen:= current_color_screen;

  posx:= wherex;
  posy:= wherey;
end;

procedure restore_screen;
begin
  if (is_mono) then
    current_mono_screen:= saved_screen
  else
    current_color_screen:= saved_screen;

  gotoxy (posx, posy);
end;

procedure cursor_off;
begin
  regs.ax:= $0100;   (* Service $01 *)
  regs.cl:= $20;     (* Top scan line *)
  regs.ch:= $20;     (* Bottom scan line *)
  intr ($10, regs);   (* ROM BIOS video driver interrupt *)
end;

procedure cursor_on;
begin
  regs.ax:= $0100;
  if (is_mono) then
  begin
    regs.cl:= 13;
    regs.ch:= 12;
  end
  else
  begin
    regs.cl:= 7;
    regs.ch:= 6;
  end;
  intr ($10, regs);
end;

begin
  fillchar (regs, sizeof(regs), 0);
  regs.ah := $0F;
  intr ($10, regs);
  is_mono:= (regs.al = 7);
end.
