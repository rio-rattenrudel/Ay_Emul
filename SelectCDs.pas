{
This is part of CD Player
-------------------------
(c)2003 S.V.Bulba
http://bulba.untergrund.net/
svbulba@gmail.com
}

unit SelectCDs;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, StdCtrls;

type
  TCDList = class(TForm)
    ListBox1: TListBox;
    Panel1: TPanel;
    Button1: TButton;
    Button2: TButton;
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  CDList: TCDList;

implementation

uses
  CDviaMCI;

{$R *.lfm}

procedure TCDList.FormShow(Sender: TObject);
var
 i:integer;
 Flg:boolean;
begin
if ListBox1.CanSetFocus then
 ListBox1.SetFocus;
Flg := False;
for i := 0 to Length(CDDrives) - 1 do
 if ListBox1.Selected[i] then
  begin
   Flg := True;
   break;
  end;
if (Length(CDDrives) > 0) and not Flg then
 ListBox1.Selected[0] := True;
end;

procedure TCDList.FormCreate(Sender: TObject);
var
 i:integer;
begin
for i := 0 to Length(CDDrives) - 1 do
 ListBox1.Items.Add(CDDrives[i] + ':');
end;

end.
