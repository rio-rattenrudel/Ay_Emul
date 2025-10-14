{
AYMIDconsole.pas - AYMID console for displaying nerdy outputs
-------------------------------------------------------------

(c)2025 by rio rattenrudel

  The sound chip frequency of AY_Emul must match
  your hardware (1.77 / 2 MHz), which can be set
  on the 1st setup page at the top right. A MIDI 
  interface is capable of outputting data within 
  20ms (23ms), which corresponds to an interrupt 
  frequency of 50Hz.

  Keep in mind that this is close to the limit.
}

unit AYMIDconsole;

{$mode objfpc}{$H+}

interface

uses
 Windows, Classes, SysUtils, sometypes;

var
  hIn :     THandle;
  hOut:     THandle;
  sbInfo:   CONSOLE_SCREEN_BUFFER_INFO;
  colored:  Boolean = False;

function OpenConsole: Boolean;
procedure CloseConsole;
procedure DisableMenuButtons;
procedure OutputLogo(colored: Boolean = false);
procedure OutputAYRegister;
procedure OutputAYMID(mask,msb:uint16; data:PArray0OfByte; length:integer);

implementation

uses
 crt, AY;


procedure Color(code: byte);
begin
  if (hOut <> INVALID_HANDLE_VALUE) then begin
    SetConsoleTextAttribute( hOut, code);
    colored := True;
  end;
end;

procedure GreenColor(force: Boolean = False);
begin
  if (not colored or force) and (hOut <> INVALID_HANDLE_VALUE) then begin
    SetConsoleTextAttribute( hOut, FOREGROUND_GREEN or FOREGROUND_INTENSITY);
    colored := True;
  end;
end;

procedure WhiteColor(force: Boolean = False);
begin
  if (not colored or force) and (hOut <> INVALID_HANDLE_VALUE) then begin
    SetConsoleTextAttribute( hOut, FOREGROUND_INTENSITY or FOREGROUND_RED or FOREGROUND_GREEN or FOREGROUND_BLUE);
    colored := True;
  end;
end;

procedure RestoreColor();
begin
  if colored and (hOut <> INVALID_HANDLE_VALUE) then begin
    SetConsoleTextAttribute( hOut, sbInfo.wAttributes);
    colored := False;
  end;
end;

procedure OutputLogo(colored: Boolean = false);
begin
  if colored then begin
    WriteLn('');
    Color($C);Write('   _____');Color($D);Write(' _____.___.');Color($B);Write('  _____  ');Color($A);Write('.___');Color($E);Write('________');RestoreColor;Write('             _____ _____.___.________  '+#13#10);
    Color($C);Write('  /  _  \');Color($D);Write('\__  |   |');Color($B);Write(' /     \ ');Color($A);Write('|   \');Color($E);Write('______ \');RestoreColor;Write('           /  _  \\__  |   |\_____  \ '+#13#10);
    Color($C);Write(' /  /_\  \');Color($D);Write('/   |   |');Color($B);Write('/  \ /  \');Color($A);Write('|   |');Color($E);Write('|    |  \');RestoreColor;Write('   ____  /  /_\  \/   |   |  _(__  < '+#13#10);
    Color($C);Write('/    |    \');Color($D);Write('____   ');Color($B);Write('/    Y    \');Color($A);Write('   |');Color($E);Write('|    `   \');RestoreColor;Write(' /___/ /    |    \____   | /       \'+#13#10);
    Color($C);Write('\____|__  /');Color($D);Write(' ______');Color($B);Write('\____|__  /');Color($A);Write('___/');Color($E);Write('_______  /');RestoreColor;Write('       \____|__  / ______|/______  /'+#13#10);
    Color($C);Write('        \/');Color($D);Write('\/       ');Color($B);Write('       \/');Color($A);Write('    ');Color($E);Write('        \/');RestoreColor;Write('                \/\/              \/ '+#13#10);
    WriteLn('');
  end else begin
    WriteLn('');
    WriteLn('   _____ _____.___.  _____  .___________             _____ _____.___.________  ');
    WriteLn('  /  _  \\__  |   | /     \ |   \______ \           /  _  \\__  |   |\_____  \ ');
    WriteLn(' /  /_\  \/   |   |/  \ /  \|   ||    |  \   ____  /  /_\  \/   |   |  _(__  < ');
    WriteLn('/    |    \____   /    Y    \   ||    `   \ /___/ /    |    \____   | /       \');
    WriteLn('\____|__  / ______\____|__  /___/_______  /       \____|__  / ______|/______  /');
    WriteLn('        \/\/              \/            \/                \/\/              \/ ');
    WriteLn('');
  end;

  if colored then RestoreColor;
end;

procedure OutputInstruction;
begin
  WriteLn('  Please choose your right midi equip and port!');
  WriteLn('');
  WriteLn('  The sound chip frequency of AY_Emul must match your hardware (1.77 / 2Mhz).');
  WriteLn('  While sample rate and buffer length are set automatically,');
  WriteLn('  the number of buffers can be adjusted as needed (recommended: 8).');
  WriteLn('');
  WriteLn('  AYMID is based on the ASID sysex data protocol from Elektron.');
  WriteLn('  Two masks, two MSBs and 14 registers are enuff!');
  WriteLn('');
  WriteLn('  ~~ rio rattenrudel ~~                                        V0.1  10/2023  ');
  WriteLn('                                                               V0.2  04/2024  ');
  WriteLn('                                                               V0.3  09/2025  ');
  WriteLn('                                                               V1.0  10/2025  ');
end;

function OpenConsole: Boolean;
var
  prevMode: DWORD;
  Rect: TSmallRect;
  Size: COORD;

begin
  Result := AllocConsole;
  if not Result then Exit;

  StdInputHandle := 0;
  StdOutputHandle := 0;
  StdErrorHandle := 0;

  IsConsole := True;
  SysInitStdIO;
  IsConsole := False;

  hOut := GetStdHandle( STD_OUTPUT_HANDLE );
  if hOut <> INVALID_HANDLE_VALUE then begin

    // set mode
    SetConsoleMode( hOut, ENABLE_PROCESSED_OUTPUT or ENABLE_WRAP_AT_EOL_OUTPUT);

    // resize console
    Rect.Left := 0;
    Rect.Top := 0;
    Rect.Right := 80 - 1;
    Rect.Bottom := 35 - 1;
    SetConsoleWindowInfo(hOut, True, &Rect);

    // save current buffer info
    GetConsoleScreenBufferInfo( hOut, &sbInfo );

    // set new buffer size (avoid scrollbars)
    Size.X := sbInfo.srWindow.Right - sbInfo.srWindow.Left + 1; // Columns
    Size.Y := sbInfo.srWindow.Bottom - sbInfo.srWindow.Top + 1; // Rows
    SetConsoleScreenBufferSize( hOut, Size );
  end;

  hIn := GetStdHandle( STD_INPUT_HANDLE );
  if hIn <> INVALID_HANDLE_VALUE then begin

    // set mode (ignore selections by mouse or keys)
    GetConsoleMode(hIn, &prevMode); 
    SetConsoleMode(hIn, ENABLE_EXTENDED_FLAGS or (prevMode and not (ENABLE_QUICK_EDIT_MODE or ENABLE_PROCESSED_INPUT)));
  end;

  SetConsoleTitle('AYMID Console V1.0');

  DisableMenuButtons;

  OutputLogo(true);
  OutputInstruction;
end;

procedure CloseConsole;
begin
  SysFlushStdIO;
  FreeConsole;
  SysInitStdIO;
end;

procedure DisableMenuButtons;
var
  Wnd:  HWND;
  Menu: HMENU;

begin
  Wnd := GetConsoleWindow;
  if Wnd = 0 then Exit;

  // remove maximize button
  SetWindowLong(Wnd, GWL_STYLE, GetWindowLong(Wnd, GWL_STYLE) and not WS_MAXIMIZEBOX);

  // remove close button
  Menu := GetSystemMenu(Wnd, False);        // get menu
  DeleteMenu(Menu, SC_CLOSE, MF_BYCOMMAND); // delete close
  DrawMenuBar(Wnd);                         // redraw
end;

procedure OutputAYRegister;
begin
 // 16 Reg Debugger
 WriteLn(IntToHex(SoundChip[0].RegisterAY.Index[0]) + ' ' + 
        IntToHex(SoundChip[0].RegisterAY.Index[1]) + ' ' +
        IntToHex(SoundChip[0].RegisterAY.Index[2]) + ' ' +
        IntToHex(SoundChip[0].RegisterAY.Index[3]) + ' ' +
        IntToHex(SoundChip[0].RegisterAY.Index[4]) + ' ' +
        IntToHex(SoundChip[0].RegisterAY.Index[5]) + ' ' +
        IntToHex(SoundChip[0].RegisterAY.Index[6]) + ' ' +
        IntToHex(SoundChip[0].RegisterAY.Index[7]) + ' ' +
        IntToHex(SoundChip[0].RegisterAY.Index[8]) + ' ' +
        IntToHex(SoundChip[0].RegisterAY.Index[9]) + ' ' +
        IntToHex(SoundChip[0].RegisterAY.Index[10]) + ' ' +
        IntToHex(SoundChip[0].RegisterAY.Index[11]) + ' ' +
        IntToHex(SoundChip[0].RegisterAY.Index[12]) + ' ' +
        IntToHex(SoundChip[0].RegisterAY.Index[13]) + ' ' +
        IntToHex(SoundChip[0].RegisterAY.Index[14]) + ' ' +
        IntToHex(SoundChip[0].RegisterAY.Index[15]));
end;

procedure OutputAYMID(mask,msb:uint16; data:PArray0OfByte; length:integer);
begin
    // RAW OUTPUT:
    {Write('  ' +
    IntToStr(mask and $01) +
    IntToStr((mask and $02) shr 1) +
    IntToStr((mask and $04) shr 2) +
    IntToStr((mask and $08) shr 3) +
    IntToStr((mask and $10) shr 4) +
    IntToStr((mask and $20) shr 5) +
    IntToStr((mask and $40) shr 6) + ' ' +
    IntToStr((mask and $80) shr 7) +
    IntToStr((mask and $100) shr 8) +
    IntToStr((mask and $200) shr 9) +
    IntToStr((mask and $400) shr 10) +
    IntToStr((mask and $800) shr 11) +
    IntToStr((mask and $1000) shr 12) +
    IntToStr((mask and $2000) shr 13) + ' ' +
    IntToStr(msb and $01) +
    IntToStr((msb and $02) shr 1) +
    IntToStr((msb and $04) shr 2) +
    IntToStr((msb and $08) shr 3) +
    IntToStr((msb and $10) shr 4) +
    IntToStr((msb and $20) shr 5) +
    IntToStr((msb and $40) shr 6) + ' ' +
    IntToStr((msb and $80) shr 7) +
    IntToStr((msb and $100) shr 8) +
    IntToStr((msb and $200) shr 9) +
    IntToStr((msb and $400) shr 10) +
    IntToStr((msb and $800) shr 11) +
    IntToStr((msb and $1000) shr 12) +
    IntToStr((msb and $2000) shr 13) + '   ');}

    Write('  ');

    if (msb and $01) <> 0 then WhiteColor;
    Write(IntToStr(mask and $01));
    RestoreColor;

    if (msb and $02) <> 0 then WhiteColor;
    Write(IntToStr((mask and $02) shr 1));
    RestoreColor;

    if (msb and $04) <> 0 then WhiteColor;
    Write(IntToStr((mask and $04) shr 2));
    RestoreColor;

    if (msb and $08) <> 0 then WhiteColor;
    Write(IntToStr((mask and $08) shr 3));
    RestoreColor;

    if (msb and $10) <> 0 then WhiteColor;
    Write(IntToStr((mask and $10) shr 4));
    RestoreColor;

    if (msb and $20) <> 0 then WhiteColor;
    Write(IntToStr((mask and $20) shr 5));
    RestoreColor;

    if (msb and $40) <> 0 then WhiteColor;
    Write(IntToStr((mask and $40) shr 6));
    RestoreColor;

    Write('  ');

    if (msb and $80) <> 0 then WhiteColor;
    Write(IntToStr((mask and $80) shr 7));
    RestoreColor;

    if (msb and $100) <> 0 then WhiteColor;
    Write(IntToStr((mask and $100) shr 8));
    RestoreColor;

    if (msb and $200) <> 0 then WhiteColor;
    Write(IntToStr((mask and $200) shr 9));
    RestoreColor;

    if (msb and $400) <> 0 then WhiteColor;
    Write(IntToStr((mask and $400) shr 10));
    RestoreColor;

    if (msb and $800) <> 0 then WhiteColor;
    Write(IntToStr((mask and $800) shr 11));
    RestoreColor;

    if (msb and $1000) <> 0 then WhiteColor;
    Write(IntToStr((mask and $1000) shr 12));
    RestoreColor;

    if (msb and $2000) <> 0 then WhiteColor;
    Write(IntToStr((mask and $2000) shr 13));
    RestoreColor;

    Write('        ');

    GreenColor;

    if length > 0 then Write(IntToHex(data[6]) + ' ');
    if length > 1 then Write(IntToHex(data[7]) + ' ');
    if length > 2 then Write(IntToHex(data[8]) + ' ');
    if length > 3 then Write(IntToHex(data[9]) + ' ');
    if length > 4 then Write(IntToHex(data[10]) + ' ');
    if length > 5 then Write(IntToHex(data[11]) + ' ');
    if length > 6 then Write(IntToHex(data[12]) + ' ');
    if length > 7 then Write(IntToHex(data[13]) + ' ');
    if length > 8 then Write(IntToHex(data[14]) + ' ');
    if length > 9 then Write(IntToHex(data[15]) + ' ');
    if length > 10 then Write(IntToHex(data[16]) + ' ');
    if length > 11 then Write(IntToHex(data[17]) + ' ');
    if length > 12 then Write(IntToHex(data[18]) + ' ');
    if length > 13 then Write(IntToHex(data[19]));

    RestoreColor;

    Write(#13#10);

end;

end.

