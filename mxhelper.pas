{
This is part of AY Emulator project
AY-3-8910/12 Emulator
Version 3.0 for Windows and Linux
Author Sergey Vladimirovich Bulba
(c)1999-2025 S.V.Bulba
}

unit mxhelper;

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
 StdCtrls;

type

 { TFrmMxHlp }

 TFrmMxHlp = class(TForm)
  Button1: TButton;
  Button2: TButton;
  TSDMAChG: TCheckGroup;
  ChansRG: TRadioGroup;
 private
  { private declarations }
 public
  { public declarations }
 end;

var
 FrmMxHlp: TFrmMxHlp;

implementation

{$R *.lfm}

end.

