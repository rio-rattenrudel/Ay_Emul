{
This is part of AY Emulator project
AY-3-8910/12 Emulator
Version 3.0 for Windows and Linux
Author Sergey Vladimirovich Bulba
(c)1999-2025 S.V.Bulba
}

unit ItemEdit;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, AY;

type

  { TFrmPLIEdit }

  TFrmPLIEdit = class(TForm)
   EChFrMixer: TEdit;
   EPlrFrMixer: TEdit;
    GBInfo: TGroupBox;
    LAuthor: TLabel;
    EAuthor: TEdit;
    LTitle: TLabel;
    ETitle: TEdit;
    LProgram: TLabel;
    EProgram: TEdit;
    LTracker: TLabel;
    ETracker: TEdit;
    LComputer: TLabel;
    EComputer: TEdit;
    LDate: TLabel;
    EDate: TEdit;
    LComment: TLabel;
    MComment: TMemo;
    GBPlay: TGroupBox;
    GBChip: TGroupBox;
    PnPlrFrqR: TPanel;
    PnPlrFrqL: TPanel;
    PnChipFrqR: TPanel;
    PnChipFrqL: TPanel;
    RBChAY: TRadioButton;
    RBChYM: TRadioButton;
    GBChipFrq: TGroupBox;
    RBChFrZX: TRadioButton;
    RBChFrPnt: TRadioButton;
    RBChFrST: TRadioButton;
    RBChFrCPC: TRadioButton;
    RBChFrOther: TRadioButton;
    EChFrZX: TEdit;
    EChFrPnt: TEdit;
    EChFrST: TEdit;
    EChFrCPC: TEdit;
    EChFrOther: TEdit;
    GBPlrFrq: TGroupBox;
    RBPlrFrZX: TRadioButton;
    RBPlrFrOther: TRadioButton;
    EPlrFrZX: TEdit;
    GBNChans: TGroupBox;
    RBNStereo: TRadioButton;
    RBNMono: TRadioButton;
    GBChAmp: TGroupBox;
    RBAmpOther: TRadioButton;
    EAmpAL: TEdit;
    EAmpAR: TEdit;
    EAmpBR: TEdit;
    EAmpBL: TEdit;
    EAmpCR: TEdit;
    EAmpCL: TEdit;
    RBAmpStd: TRadioButton;
    CBAmpStd: TComboBox;
    LAmpA: TLabel;
    LAmpB: TLabel;
    LAmpC: TLabel;
    GBDef: TGroupBox;
    BDefLoad: TButton;
    BDefSave: TButton;
    BOk: TButton;
    BCancel: TButton;
    RBChDef: TRadioButton;
    RBNDef: TRadioButton;
    RBChFrDef: TRadioButton;
    RBPlrFrDef: TRadioButton;
    RBAmpDef: TRadioButton;
    GBFile: TGroupBox;
    LFType: TLabel;
    LFOffs: TLabel;
    LFAddr: TLabel;
    LFTime: TLabel;
    LFLen: TLabel;
    EFName: TEdit;
    CBFType: TComboBox;
    EFOffs: TEdit;
    EFLen: TEdit;
    EFAddr: TEdit;
    EFTime: TEdit;
    EFLoop: TEdit;
    LFLoop: TLabel;
    EPlrFrPnt: TEdit;
    RBPlrFrPnt: TRadioButton;
    EPlrFrOther: TEdit;
    LFSpec: TLabel;
    EFSpec: TEdit;
    procedure SetPlayItems(Chip_Type:ChTypes;Number_Of_Channels,SoundChip_Frq,
                     Player_Frq,Channel_Mode:integer;AL,AR,BL,BR,CL,CR:byte);
    procedure GetPlayItems(var Chip_Type:ChTypes;var Number_Of_Channels,SoundChip_Frq,
                     Player_Frq,Channel_Mode:integer;var AL,AR,BL,BR,CL,CR:byte);
    procedure BDefLoadClick(Sender: TObject);
    procedure BDefSaveClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure CBAmpStdSelect(Sender: TObject);
    procedure EChFrOtherChange(Sender: TObject);
    procedure EPlrFrOtherChange(Sender: TObject);
    procedure CustomChAllocSet(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FrmPLIEdit: TFrmPLIEdit;

implementation

uses
  PlayList, FileTypes;

{$R *.lfm}

procedure TFrmPLIEdit.SetPlayItems(Chip_Type:ChTypes;Number_Of_Channels,SoundChip_Frq,
                     Player_Frq,Channel_Mode:integer;AL,AR,BL,BR,CL,CR:byte);
begin
case Chip_Type of
AY_Chip:RBChAY.Checked:=True;
YM_Chip:RBChYM.Checked:=True;
No_Chip:RBChDef.Checked:=True;
end;
case Number_Of_Channels of
2:RBNStereo.Checked:=True;
1:RBNMono.Checked:=True;
0:RBNDef.Checked:=True;
end;
EChFrOther.Text:='';
case SoundChip_Frq of
1773400:RBChFrZX.Checked:=True;
1750000:RBChFrPnt.Checked:=True;
2000000:RBChFrST.Checked:=True;
1000000:RBChFrCPC.Checked:=True;
-2,-1  :RBChFrDef.Checked:=True;
else
 begin
  RBChFrOther.Checked:=True;
  EChFrOther.Text:=IntToStr(SoundChip_Frq);
 end;
end;
EPlrFrOther.Text:='';
case Player_Frq of
50000:RBPlrFrZX.Checked:=True;
48828:RBPlrFrPnt.Checked:=True;
-1,-2:RBPlrFrDef.Checked:=True;
else
 begin
  RBPlrFrOther.Checked:=True;
  EPlrFrOther.Text:=IntToStr(Player_Frq);
 end;
end;
EAmpAL.Text:=''; EAmpAR.Text:='';
EAmpBR.Text:=''; EAmpBL.Text:='';
EAmpCR.Text:=''; EAmpCL.Text:='';
CBAmpStd.ItemIndex:=-1;
case Channel_Mode of
0..6:
 begin
  CBAmpStd.ItemIndex:=Channel_Mode;
  RBAmpStd.Checked:=True;
 end;
-2:
 begin
  RBAmpOther.Checked:=True;
  EAmpAL.Text:=IntToStr(AL);
  EAmpAR.Text:=IntToStr(AR);
  EAmpBL.Text:=IntToStr(BL);
  EAmpBR.Text:=IntToStr(BR);
  EAmpCL.Text:=IntToStr(CL);
  EAmpCR.Text:=IntToStr(CR);
 end;
-1:
 RBAmpDef.Checked:=True;
end;
end;

procedure TFrmPLIEdit.BDefLoadClick(Sender: TObject);
begin
with FrmPLst do
 SetPlayItems(PLDef_Chip_Type,PLDef_Number_Of_Channels,PLDef_SoundChip_Frq,
                     PLDef_Player_Frq,PLDef_Channel_Mode,
                     PLDef_AL,PLDef_AR,PLDef_BL,PLDef_BR,PLDef_CL,PLDef_CR);
end;

procedure TFrmPLIEdit.BDefSaveClick(Sender: TObject);
begin
with FrmPLst do
 GetPlayItems(PLDef_Chip_Type,PLDef_Number_Of_Channels,PLDef_SoundChip_Frq,
                     PLDef_Player_Frq,PLDef_Channel_Mode,
                     PLDef_AL,PLDef_AR,PLDef_BL,PLDef_BR,PLDef_CL,PLDef_CR);
BDefLoadClick(Sender);
end;

procedure TFrmPLIEdit.GetPlayItems(var Chip_Type:ChTypes;var Number_Of_Channels,SoundChip_Frq,
                     Player_Frq,Channel_Mode:integer;var AL,AR,BL,BR,CL,CR:byte);
var
 Temp:integer;
begin
if RBChAY.Checked then Chip_Type:=AY_Chip else
if RBChYM.Checked then Chip_Type:=YM_Chip else
if RBChDef.Checked then Chip_Type:=No_Chip;

if RBNStereo.Checked then Number_Of_Channels:=2 else
if RBNMono.Checked then Number_Of_Channels:=1 else
if RBNDef.Checked then Number_Of_Channels:=0;

if RBChFrZX.Checked then SoundChip_Frq:=1773400 else
if RBChFrPnt.Checked then SoundChip_Frq:=1750000 else
if RBChFrST.Checked then SoundChip_Frq:=2000000 else
if RBChFrCPC.Checked then SoundChip_Frq:=1000000 else
if RBChFrDef.Checked then SoundChip_Frq:=-1 else
if RBChFrOther.Checked then
 begin
  Val(EChFrOther.Text,SoundChip_Frq,Temp);
  if Temp<>0 then SoundChip_Frq:=-1;
 end;

if RBPlrFrZX.Checked then Player_Frq:=50000 else
if RBPlrFrPnt.Checked then Player_Frq:=48828 else
if RBPlrFrDef.Checked then Player_Frq:=-1 else
if RBPlrFrOther.Checked then
 begin
  Val(EPlrFrOther.Text,Player_Frq,Temp);
  if Temp<>0 then Player_Frq:=-1;
 end;

if RBAmpStd.Checked then Channel_Mode:=CBAmpStd.ItemIndex else
if RBAmpDef.Checked then Channel_Mode:=-1 else
if RBAmpOther.Checked then
 begin
  Channel_Mode:=-1;
  Val(EAmpAL.Text,AL,Temp);
  if Temp=0 then
   begin
    Val(EAmpAR.Text,AR,Temp);
    if Temp=0 then
     begin
      Val(EAmpBL.Text,BL,Temp);
      if Temp=0 then
       begin
        Val(EAmpBR.Text,BR,Temp);
        if Temp=0 then
         begin
          Val(EAmpCL.Text,CL,Temp);
          if Temp=0 then
           begin
            Val(EAmpCR.Text,CR,Temp);
            if Temp=0 then Channel_Mode:=-2;
           end;
         end;
       end;
     end;
   end;
 end;
end;

procedure TFrmPLIEdit.FormCreate(Sender: TObject);
begin
GetFileTypes(CBFType.Items);
end;

procedure TFrmPLIEdit.CBAmpStdSelect(Sender: TObject);
begin
RBAmpStd.Checked := True;
end;

procedure TFrmPLIEdit.EChFrOtherChange(Sender: TObject);
begin
RBChFrOther.Checked := True;
end;

procedure TFrmPLIEdit.EPlrFrOtherChange(Sender: TObject);
begin
RBPlrFrOther.Checked := True;
end;

procedure TFrmPLIEdit.CustomChAllocSet(Sender: TObject);
begin
RBAmpOther.Checked := True;
end;

end.
