{
This is part of AY Emulator project
AY-3-8910/12 Emulator
Version 3.0 for Windows and Linux
Author Sergey Vladimirovich Bulba
(c)1999-2025 S.V.Bulba
}

unit ProgBox;

{$mode objfpc}{$H+}

interface

uses
 LCLIntf, LCLType, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
 StdCtrls, ComCtrls;

type

 { TFrmPrBox }

 TFrmPrBox = class(TForm)
   Button2: TButton;
   Label1: TLabel;
   ProgressBar1: TProgressBar;
   Button1: TButton;
   procedure Button1Click(Sender: TObject);
   procedure Button2Click(Sender: TObject);
 private
   { Private declarations }
 public
   { Public declarations }
 end;

procedure DoCheckQuitKey(var Key: word);
function DoBreakLongProccess: boolean;

var
 FrmPrBox: TFrmPrBox;

 //is started conversion or searching or some other long task
 LongProcess: integer = 0;

 //is visible progress box with two buttons controlling May_Quit and May_Quit2 flags
 PrgBox: boolean = False;

implementation

uses
 MainWin;

 {$R *.lfm}

procedure TFrmPrBox.Button1Click(Sender: TObject);
begin
 May_Quit := True;
end;

procedure TFrmPrBox.Button2Click(Sender: TObject);
begin
 May_Quit := True;
 May_Quit2 := True;
end;

procedure DoCheckQuitKey(var Key: word);
begin
 if Key = VK_ESCAPE then
  begin
   May_Quit := True;
   Key := 0;
  end;
end;

function DoBreakLongProccess: boolean;
begin
 if LongProcess > 0 then
  begin
   May_Quit := True;
   Exit(True);
  end;
 Result := False;
end;

end.
