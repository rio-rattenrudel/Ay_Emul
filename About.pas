{
This is part of AY Emulator project
AY-3-8910/12 Emulator
Version 3.0 for Windows and Linux
Author Sergey Vladimirovich Bulba
(c)1999-2025 S.V.Bulba
}

unit About;

{$mode objfpc}{$H+}

interface

uses
 LCLIntf, LCLType, {$IFDEF Windows}Windows,{$ENDIF Windows}
 SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
 ExtCtrls, LH5;

type

 { TAboutBox }

 TAboutBox = class(TForm)
   procedure FormDeactivate(Sender: TObject);
   procedure FormDestroy(Sender: TObject);
   procedure FormPaint(Sender: TObject);
   procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
     Shift: TShiftState; X, Y: integer);
   procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: integer);
   procedure FormMouseUp(Sender: TObject; Button: TMouseButton;
     Shift: TShiftState; X, Y: integer);
   procedure FormShow(Sender: TObject);
   procedure Push(Bt: integer; DoPush: boolean);
   procedure FormCreate(Sender: TObject);
   procedure FormKeyPress(Sender: TObject; var Key: char);
 private
   { Private declarations }
 public
   { Public declarations }
   AbFormRgn: HRGN;
   AbDBuffer: TBitmap;
   OKClicked, HlpClicked: boolean;
   But: array[0..1] of record
     Pushed: boolean;
     PushedBmp, UnPushedBmp: TBitmap;
     x1, y1, x2, y2: integer;
     end;
 end;

implementation

uses
 MainWin, UniReader;

 {$R *.lfm}

var
 {$IFDEF Windows}
 PrevWndProc: WNDPROC;
 {$ENDIF Windows}
 AbOkRgn, AbHlpRgn: HRGN;

const
 {$i rgn2.inc}

{$IFDEF Windows}
function WndCallback(Ahwnd: HWND; uMsg: UINT; wParam: WParam;
 lParam: LParam): LRESULT; stdcall;
var
 r: _RECT;
begin
 case uMsg of
   WM_NCHITTEST:
    begin
     if GetWindowRect(Ahwnd, r) and not PtInRegion(AbOkRgn,
       GET_X_LPARAM(lParam) - r.Left, GET_Y_LPARAM(lParam) - r.Top) and not
       PtInRegion(AbHlpRgn, smallint(LOWORD(lParam)) - r.Left,
       smallint(HIWORD(lParam)) - r.Top) then
       Result := HTCAPTION
     else
       Result := DefWindowProc(Ahwnd, uMsg, wParam, lParam);
     Exit;
    end;
  end;
 Result := CallWindowProc(PrevWndProc, Ahwnd, uMsg, WParam, LParam);
end;
{$ENDIF Windows}

procedure TAboutBox.FormCreate(Sender: TObject);

 procedure AddRectRgn(a, b, c, d, op: integer);
 var
   r: HRGN;
 begin
   r := CreateRectRgn(a, b, c, d);
   CombineRgn(AbFormRgn, AbFormRgn, r, op);
   DeleteObject(r);
 end;

 procedure AddRoundRectRgnH(a, b, c, d, e, f, op: integer);
 var
   r: HRGN;
 begin
   r := CreateRoundRectRgn(a, b, c, d, e, f);
   CombineRgn(AbHlpRgn, AbHlpRgn, r, op);
   DeleteObject(r);
 end;

 procedure AddRectRgnH(a, b, c, d, op: integer);
 var
   r: HRGN;
 begin
   r := CreateRectRgn(a, b, c, d);
   CombineRgn(AbHlpRgn, AbHlpRgn, r, op);
   DeleteObject(r);
 end;

var
 Bitmap: TBitmap;
 URHandle, i: integer;
 Stream: TStream;
 pic: pointer;
 rs: TResourceStream;
begin
 AbHlpRgn := CreateRoundRectRgn(243, 0, 343, 70, 344 - 244, 70 - 0);
 AddRectRgnH(243, 43, 343, 71, RGN_DIFF);
 AddRoundRectRgnH(243, 3, 343, 66, 343 - 243, 66 - 3, RGN_OR);
 AddRoundRectRgnH(280, 27, 297, 45, 17, 17, RGN_DIFF);
 AddRoundRectRgnH(277, 38, 292, 54, 15, 16, RGN_DIFF);
 AddRoundRectRgnH(270, 50, 286, 66, 15, 16, RGN_DIFF);
 AddRoundRectRgnH(280, 54, 308, 82, 28, 28, RGN_OR);
 AddRectRgnH(306, 62, 314, 70, RGN_OR);
 AddRoundRectRgnH(309, 64, 319, 73, 314 - 306, 74 - 65, RGN_DIFF);
 AddRectRgnH(262, 150, 291, 307, RGN_OR);
 AddRoundRectRgnH(269, 95, 316, 143, 317 - 270, 143 - 95, RGN_OR);
 AbOkRgn := CreateRoundRectRgn(176, 250, 259, 332, 260 - 177, 334 - 252);

 with rgn2[0] do
   AbFormRgn := CreateRectRgn(x, y, x + w, y + h);
 for i := 1 to nrects2 do
   with rgn2[i] do
     AddRectRgn(x, y, x + w, y + h, RGN_OR);

 //mask bug in GTK2 (form randomly not repainted with more complex RGN}
 //{$ifdef linux}AddRectRgn(0,0,Width,Height div 5,RGN_OR);{$endif linux}

 Bitmap := TBitmap.Create;
 rs := TResourceStream.Create(HInstance, 'ABOUTSCREEN', RT_RCDATA);
 UniReadInit(URHandle, URMemory, '', rs.Memory, rs.Size);
 Compressed_Size := rs.Size - 4;
 pic := nil;
  try
    try
     UniRead(URHandle, @Original_Size, 4);
     UniAddDepacker(URHandle, UDLZH);
     GetMem(pic, Original_Size);
     UniRead(URHandle, pic, Original_Size)
    finally
     UniReadClose(URHandle);
    end;
   Stream := TMemoryStream.Create;
   Stream.Write(pic^, Original_Size);
   Stream.Position := 0;
   Bitmap.LoadFromStream(Stream);
   Stream.Free;
   AbDBuffer := TBitmap.Create;
   AbDBuffer.Width := 343;
   AbDBuffer.Height := 346;
   AbDBuffer.Canvas.CopyRect(Rect(0, 0, 343, 346), Bitmap.Canvas, Rect(1, 2, 344, 348));
   AbDBuffer.Canvas.Font := Font;
   But[0].UnPushedBmp := TBitmap.Create;
   But[0].UnPushedBmp.Width := 83;
   But[0].UnPushedBmp.Height := 82;
   But[0].UnPushedBmp.Canvas.
     CopyRect(Rect(0, 0, 83, 82), Bitmap.Canvas, Rect(177, 252, 260, 334));
   But[0].PushedBmp := TBitmap.Create;
   But[0].PushedBmp.Width := 83;
   But[0].PushedBmp.Height := 82;
   But[0].PushedBmp.Canvas.
     CopyRect(Rect(0, 0, 83, 82), Bitmap.Canvas, Rect(323, 252, 406, 334));
   But[0].x1 := 176;
   But[0].y1 := 250;
   But[0].x2 := 259;
   But[0].y2 := 332;
   But[1].UnPushedBmp := TBitmap.Create;
   But[1].UnPushedBmp.Width := 100;
   But[1].UnPushedBmp.Height := 142;
   But[1].UnPushedBmp.Canvas.
     CopyRect(Rect(0, 0, 100, 142), Bitmap.Canvas, Rect(244, 2, 344, 144));
   But[1].PushedBmp := TBitmap.Create;
   But[1].PushedBmp.Width := 100;
   But[1].PushedBmp.Height := 142;
   But[1].PushedBmp.Canvas.
     CopyRect(Rect(0, 0, 100, 142), Bitmap.Canvas, Rect(345, 2, 445, 144));
   But[1].x1 := 243;
   But[1].y1 := 0;
   But[1].x2 := 343;
   But[1].y2 := 142;
   Bitmap.Free;
   But[0].Pushed := False;
   But[1].Pushed := False;
   OKClicked := False;
   HlpClicked := False;
  finally
   if pic <> nil then FreeMem(pic);
   rs.Free;
  end;

end;

procedure TAboutBox.FormDestroy(Sender: TObject);
begin
 DeleteObject(AbFormRgn);
 DeleteObject(AbOkRgn);
 DeleteObject(AbHlpRgn);
 But[0].PushedBmp.Free;
 But[0].UnPushedBmp.Free;
 But[1].PushedBmp.Free;
 But[1].UnPushedBmp.Free;
 AbDBuffer.Free;
end;

procedure TAboutBox.FormPaint(Sender: TObject);
begin
 Canvas.CopyMode := cmSrcCopy;
 Canvas.CopyRect(Rect(0, 0, AbDBuffer.Width, AbDBuffer.Height), AbDBuffer.Canvas,
   Rect(0, 0, AbDBuffer.Width, AbDBuffer.Height));
end;

procedure TAboutBox.FormMouseDown(Sender: TObject; Button: TMouseButton;
 Shift: TShiftState; X, Y: integer);
begin
 if Shift <> [ssLeft] then exit;
 if PtInRegion(AbOkRgn, X, Y) then
  begin
   Push(0, True);
   OKClicked := True;
   HlpClicked := False;
  end
 else if PtInRegion(AbHlpRgn, X, Y) then
  begin
   Push(1, True);
   OKClicked := False;
   HlpClicked := True;
  end
 else
  begin
   {$IFNDEF Windows}
   BeginDrag(False);
   {$ENDIF Windows}
   OKClicked := False;
   HlpClicked := False;
  end;
end;

procedure TAboutBox.Push(Bt: integer; DoPush: boolean);
begin
 with But[Bt] do
  begin
   if DoPush = Pushed then exit;
   if DoPush then
     AbDBuffer.Canvas.CopyRect(Rect(x1, y1, x2, y2), PushedBmp.Canvas,
       Rect(0, 0, x2 - x1, y2 - y1))
   else
     AbDBuffer.Canvas.CopyRect(Rect(x1, y1, x2, y2), UnPushedBmp.Canvas,
       Rect(0, 0, x2 - x1, y2 - y1));
   Pushed := DoPush;
   Canvas.CopyRect(Rect(x1, y1, x2, y2), AbDBuffer.Canvas, Rect(x1, y1, x2, y2));
  end;
end;

procedure TAboutBox.FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: integer);
begin
 if Shift <> [ssLeft] then exit;
 if OKClicked then
  begin
   if PtInRegion(AbOkRgn, X, Y) then
     Push(0, True)
   else
     Push(0, False);
  end
 else if HlpClicked then
  begin
   if PtInRegion(AbHlpRgn, X, Y) then
     Push(1, True)
   else
     Push(1, False);
  end;
end;

procedure TAboutBox.FormMouseUp(Sender: TObject; Button: TMouseButton;
 Shift: TShiftState; X, Y: integer);
begin
 if OKClicked and PtInRegion(AbOkRgn, X, Y) then
   Close
 else if HlpClicked and PtInRegion(AbHlpRgn, X, Y) then
  begin
   Push(1, False);
   FrmMain.CallHelp;
  end;
 OKClicked := False;
 HlpClicked := False;
end;

procedure TAboutBox.FormShow(Sender: TObject);
begin
 //starting Lazarus 1.6.1 Handle is recreated on ShowModal (after FormCreate) :(
 SetWindowRgn(Handle, AbFormRgn, False);
 {$IFDEF Windows}
 PrevWndProc :={%H-}Windows.WNDPROC(SetWindowLongPtr(
   Handle, GWL_WNDPROC,{%H-}PtrInt(@WndCallback)));
 {$ENDIF Windows}
end;

procedure TAboutBox.FormDeactivate(Sender: TObject);
begin
 Push(0, False);
 Push(1, False);
 OKClicked := False;
 HlpClicked := False;
end;

procedure TAboutBox.FormKeyPress(Sender: TObject; var Key: char);
begin
 if Key = #27 then
  begin
   Close;
   Key := #0;
  end;
end;

end.
