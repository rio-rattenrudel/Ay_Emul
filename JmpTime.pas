{
This is part of AY Emulator project
AY-3-8910/12 Emulator
Version 3.0 for Windows and Linux
Author Sergey Vladimirovich Bulba
(c)1999-2025 S.V.Bulba
}

unit JmpTime;

{$mode objfpc}{$H+}

interface

uses
 LCLIntf, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
 StdCtrls;

type

 { TFrmJpTime }

 TFrmJpTime = class(TForm)
   Button1: TButton;
   Button2: TButton;
   Edit1: TEdit;
   Label1: TLabel;
   lbTrkLen: TLabel;
   procedure FormShow(Sender: TObject);
 private
   { Private declarations }
 public
   { Public declarations }
 end;

var
 FrmJpTime: TFrmJpTime;

implementation

{$R *.lfm}

procedure TFrmJpTime.FormShow(Sender: TObject);
begin
 Edit1.SelectAll;
 if Edit1.CanSetFocus then
   Edit1.SetFocus;
end;

end.
