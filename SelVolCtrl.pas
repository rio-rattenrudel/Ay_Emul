{
This is part of AY Emulator project
AY-3-8910/12 Emulator
Version 3.0 for Windows and Linux
Author Sergey Vladimirovich Bulba
(c)1999-2025 S.V.Bulba
}

unit SelVolCtrl;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls;

type
  TFrmSelVolCtrl = class(TForm)
    ListBox1: TListBox;
    Button1: TButton;
    Button2: TButton;
    procedure FormShow(Sender: TObject);
    procedure ListBox1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.lfm}

procedure TFrmSelVolCtrl.FormShow(Sender: TObject);
begin
ListBox1.ItemIndex := 0;
end;

procedure TFrmSelVolCtrl.ListBox1Click(Sender: TObject);
begin
Button1.Enabled := ListBox1.ItemIndex <> -1;
end;

end.

