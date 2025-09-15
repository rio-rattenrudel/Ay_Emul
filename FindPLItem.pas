{
This is part of AY Emulator project
AY-3-8910/12 Emulator
Version 3.0 for Windows and Linux
Author Sergey Vladimirovich Bulba
(c)1999-2025 S.V.Bulba
}

unit FindPLItem;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, LCLType, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, lazutf8;

type

  { TFrmFndPLItm }

  TFrmFndPLItm = class(TForm)
    GroupBox1: TGroupBox;
    Edit1: TEdit;
    RadioGroup1: TRadioGroup;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FrmFndPLItm: TFrmFndPLItm;

implementation

uses
  PlayList, Languages;

{$R *.lfm}

function FindItem2(Item,FMode:integer;const FString:string):boolean;
begin
Result := True;
with PlayListItems[Item]^ do
  begin
   if (FMode in [0,1]) and (Pos(FString,UTF8LowerCase(Author)) > 0) then exit;
   if (FMode in [0,2]) and (Pos(FString,UTF8LowerCase(Title)) > 0) then exit;
   Result := (FMode in [0,3]) and (Pos(FString,UTF8LowerCase(ExtractFileName(FileName))) > 0);
   if Result or (FMode <> 0) then exit;
   Result := True;
   if Pos(FString,UTF8LowerCase(Programm)) > 0 then exit;
   if Pos(FString,UTF8LowerCase(Tracker)) > 0 then exit;
   if Pos(FString,UTF8LowerCase(Computer)) > 0 then exit;
   if Pos(FString,UTF8LowerCase(Date)) > 0 then exit;
   if Pos(FString,UTF8LowerCase(Comment)) > 0 then exit
  end;
Result := False;
end;

function FindItem(FFrom,FTo,FMode:integer;const FString:string):integer;
var
 i:integer;
begin
Result := -1;
for i := FFrom to FTo do
 if FindItem2(i,FMode,FString) then
  begin
   Result := i;
   exit;
  end;
end;

procedure TFrmFndPLItm.Button1Click(Sender: TObject);
var
 Found:integer;
 FStr:string;
begin
FStr := UTF8LowerCase(Edit1.Text);
Found := FindItem(LastSelected + 1,Length(PlayListItems) - 1,RadioGroup1.ItemIndex,FStr);
if (Found < 0) and (LastSelected >= 0) then
 Found := FindItem(0,LastSelected,RadioGroup1.ItemIndex,FStr);
if Found < 0 then
 Application.MessageBox(PChar(Mes_SearchStringNotFound),PChar(Caption),MB_OK)
else
 begin
  ClearSelection;
  LastSelected := Found;
  PlayListItems[Found]^.Selected := True;
  MakeVisible(Found,True);
 end;
end;

procedure TFrmFndPLItm.Button2Click(Sender: TObject);
var
 i,m,Cnt:integer;
 FStr:string;
begin
ClearSelection;
FStr := UTF8LowerCase(Edit1.Text);
Cnt := 0; m := RadioGroup1.ItemIndex;
for i := 0 to Length(PlayListItems) - 1 do
 if FindItem2(i,m,FStr) then
  begin
   Inc(Cnt);
   PlayListItems[i]^.Selected := True;
  end;
if Cnt = 0 then
 Application.MessageBox(PChar(Mes_SearchStringNotFound),PChar(Caption),MB_OK)
else
 RedrawPlaylist(ShownFrom,True);
end;

resourcestring
 FrmFndPLItmAnywhere = 'Anywhere';
 FrmFndPLItmAuthorName = 'Author name';
 FrmFndPLItmMusicTitle = 'Music title';
 FrmFndPLItmFileName = 'File name';

procedure TFrmFndPLItm.FormCreate(Sender: TObject);
begin
RadioGroup1.Items.Append(FrmFndPLItmAnywhere);
RadioGroup1.Items.Append(FrmFndPLItmAuthorName);
RadioGroup1.Items.Append(FrmFndPLItmMusicTitle);
RadioGroup1.Items.Append(FrmFndPLItmFileName);
RadioGroup1.ItemIndex:=0;
end;

end.
