{
This is part of AY Emulator project
AY-3-8910/12 Emulator
Version 3.0 for Windows and Linux
Author Sergey Vladimirovich Bulba
(c)1999-2025 S.V.Bulba
}

unit HeadEdit;

{$mode objfpc}{$H+}

interface

uses
 LCLIntf, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
 StdCtrls;

type
 THeaderEditor = class(TForm)
   FrqBox: TGroupBox;
   SpeccyF: TRadioButton;
   AtariF: TRadioButton;
   AmstradF: TRadioButton;
   rbFrqOther: TRadioButton;
   Edit1: TEdit;
   Label1: TLabel;
   Label2: TLabel;
   Label3: TLabel;
   Label4: TLabel;
   Edit2: TEdit;
   Edit3: TEdit;
   Edit4: TEdit;
   VBLFrqBox: TGroupBox;
   RadioButton1: TRadioButton;
   Edit5: TEdit;
   Label5: TLabel;
   rbPlFrqOther: TRadioButton;
   Edit6: TEdit;
   Label6: TLabel;
   VBLLoopBox: TGroupBox;
   Edit7: TEdit;
   SongInfoBox: TGroupBox;
   lbTitle: TLabel;
   Edit8: TEdit;
   lbAuthor: TLabel;
   Edit9: TEdit;
   ChTypeBox: TGroupBox;
   rbAY: TRadioButton;
   rbYM: TRadioButton;
   OtherBox: TGroupBox;
   lbTotVBLs: TLabel;
   Edit10: TEdit;
   btRestore: TButton;
   btApply: TButton;
   ChanAllocBox: TGroupBox;
   lbProgram: TLabel;
   lbTracker: TLabel;
   Edit11: TEdit;
   Edit12: TEdit;
   lbYear: TLabel;
   Edit13: TEdit;
   cbChanAlloc: TComboBox;
   procedure btRestoreClick(Sender: TObject);
   procedure SetParams;
   procedure GetParams;
 private
   { Private declarations }
 public
   { Public declarations }
   FrqAYChk: array[0..3] of boolean;
   FrqIntChk: array[0..1] of boolean;
   ChipChk: array[0..1] of boolean;
   LoopPos: dword;
   NumOfPos: dword;
   SongName, SongAuthor, SongProgram, SongTracker: string;
   FrAy: dword;
   FrInt: word;
   ChanMode: byte;
   Year: word;
 end;

var
 HeaderEditor: THeaderEditor;

implementation

{$R *.lfm}

procedure THeaderEditor.SetParams;
var
 i: integer;
 s: string;
begin
 for i := 0 to 3 do FrqAyChk[i] := False;
 case FrAy of
   1773400: FrqAyChk[0] := True;
   2000000: FrqAyChk[1] := True;
   1000000: FrqAyChk[2] := True;
 else
   FrqAyChk[3] := True
  end;
 for i := 0 to 1 do FrqIntChk[i] := False;
 if FrInt = 50 then FrqIntChk[0] := True
 else
   FrqIntChk[1] := True;
 SpeccyF.Checked := FrqAYChk[0];
 AtariF.Checked := FrqAYChk[1];
 AmstradF.Checked := FrqAYChk[2];
 rbFrqOther.Checked := FrqAYChk[3];
 if FrqAYChk[3] then Str(FrAy, s)
 else
   s := '';
 Edit1.Text := s;
 RadioButton1.Checked := FrqIntChk[0];
 rbPlFrqOther.Checked := FrqIntChk[1];
 if FrqIntChk[1] then Str(FrInt, s)
 else
   s := '';
 Edit6.Text := s;
 rbAY.Checked := ChipChk[0];
 rbYM.Checked := ChipChk[1];
 Str(LoopPos, s);
 Edit7.Text := s;
 Str(NumOfPos, s);
 Edit10.Text := s;
 Edit8.Text := SongName;
 Edit9.Text := SongAuthor;
 Edit11.Text := SongProgram;
 Edit12.Text := SongTracker;
 if Year <> 0 then Str(Year, s)
 else
   s := '';
 Edit13.Text := s;
 cbChanAlloc.ItemIndex := ChanMode;
end;

procedure THeaderEditor.btRestoreClick(Sender: TObject);
begin
 SetParams;
end;

procedure THeaderEditor.GetParams;
var
 i, j: integer;
begin
 if SpeccyF.Checked then fray := 1773400
 else
 if AtariF.Checked then fray := 2000000
 else
 if AmstradF.Checked then fray := 1000000
 else
 if rbFrqOther.Checked then
  begin
   Val(Edit1.Text, j, i);
   if i = 0 then
    begin
     if j < 1000000 then j := 1000000
     else
     if j > 3000000 then j := 3000000;
     fray := j;
    end;
  end;
 if RadioButton1.Checked then FrInt := 50
 else
  begin
   Val(Edit6.Text, j, i);
   if i = 0 then
    begin
     if j < 1 then j := 1
     else
     if j > 255 then j := 255;
     frInt := j;
    end;
  end;
 ChipChk[0] := rbAY.Checked;
 ChipChk[1] := rbYM.Checked;
 Val(Edit7.Text, j, i);
 if i = 0 then
  begin
   if j < 0 then j := 0
   else
   if longword(j) >= NumOfPos then j := NumOfPos - 1;
   LoopPos := j;
  end;
 Val(Edit13.Text, j, i);
 if (i = 0) and (j >= 0) and (j < 65536) then
   Year := j
 else
   Year := 0;
 SongName := Edit8.Text;
 SongAuthor := Edit9.Text;
 SongProgram := Edit11.Text;
 SongTracker := Edit12.Text;
 ChanMode := cbChanAlloc.ItemIndex;
end;

end.
