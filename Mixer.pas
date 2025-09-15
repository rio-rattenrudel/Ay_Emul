{
This is part of AY Emulator project
AY-3-8910/12 Emulator
Version 3.0 for Windows and Linux
Author Sergey Vladimirovich Bulba
(c)1999-2025 S.V.Bulba
}

unit Mixer;

{$mode objfpc}{$H+}

interface

uses
 LCLIntf, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
 StdCtrls, ComCtrls, ExtCtrls, Buttons;

type

 { TFrmMixer }

 TFrmMixer = class(TForm)
   AtariMonoChk: TCheckBox;
   AtariYMMonoChk: TCheckBox;
   EMFPFrq1613: TEdit;
   GBSNDH: TGroupBox;
   PnChFrqL: TPanel;
   PnZ80FrqR: TPanel;
   PnZ80FrqL: TPanel;
   PnMFPFrqR: TPanel;
   PnMFPFrqL: TPanel;
   PnIntFrqR: TPanel;
   PnIntFrqL: TPanel;
   PnChFrqR: TPanel;
   RBChFrqCPC: TRadioButton;
   RBChFrqOther: TRadioButton;
   RBChFrqPnt: TRadioButton;
   RBChFrqST: TRadioButton;
   RBChFrqZX: TRadioButton;
   STRB: TRadioButton;
   STeRB: TRadioButton;
   SBHelper: TSpeedButton;
   LTSOvfl: TLabel;
   CBDCBias: TCheckBox;
   EAmpDMA: TEdit;
   EMCFrqST: TEdit;
   EMCFrqOther: TEdit;
   GBMCFrq: TGroupBox;
   LAmpDMA: TLabel;
   LAYOvfl: TLabel;
   CBProxy: TCheckBox;
   EProxy: TEdit;
   LProxy: TLabel;
   CBNetAgent: TComboBox;
   GBASSConn: TGroupBox;
   LBASSUA: TLabel;
   MixerTabSheet: TPageControl;
   AYEmuSheet: TTabSheet;
   GBChAmp: TGroupBox;
   BvAmpB: TBevel;
   BvAmpBR: TBevel;
   BvAmpBL: TBevel;
   BvAmpBV: TBevel;
   BvAmpAL: TBevel;
   BvAmpAR: TBevel;
   BvAmpA: TBevel;
   BvAmpAV: TBevel;
   BvAmpCR: TBevel;
   BvAmpC: TBevel;
   BvAmpCL: TBevel;
   BvAmpCV: TBevel;
   RBMCFrqST: TRadioButton;
   RBMCFrqOther: TRadioButton;
   TBAmpAL: TTrackBar;
   TBAmpDMA: TTrackBar;
   TBAmpAR: TTrackBar;
   TBAmpBL: TTrackBar;
   TBAmpBR: TTrackBar;
   TBAmpCL: TTrackBar;
   TBAmpCR: TTrackBar;
   EAmpAL: TEdit;
   EAmpAR: TEdit;
   EAmpCR: TEdit;
   EAmpCL: TEdit;
   EAmpBL: TEdit;
   EAmpBR: TEdit;
   CheckBox1: TCheckBox;
   EAmpALCur: TEdit;
   EAmpARCur: TEdit;
   EAmpBRCur: TEdit;
   EAmpCLCur: TEdit;
   EAmpCRCur: TEdit;
   EAmpBLCur: TEdit;
   TBAmpBpr: TTrackBar;
   GBChType: TGroupBox;
   RBChTypeAY: TRadioButton;
   RBChTypeYM: TRadioButton;
   CBChTypeLst: TCheckBox;
   CBChTypeAY: TCheckBox;
   CBCHTypeYM: TCheckBox;
   GBChFrq: TGroupBox;
   CBChFrqLst: TCheckBox;
   EChFrqZX: TEdit;
   EChFrqPnt: TEdit;
   EChFrqST: TEdit;
   EChFrqCPC: TEdit;
   EChFrqOther: TEdit;
   EChFrqCur: TEdit;
   EOUTStPerFrm: TEdit;
   GBOUTZXAY: TGroupBox;
   LOUTStPerFrm: TLabel;
   EAmpBpr: TEdit;
   GBIntFrq: TGroupBox;
   RBEIntFrqZX: TRadioButton;
   EIntFrqZX: TEdit;
   RBIntFrqOther: TRadioButton;
   EIntFrqOther: TEdit;
   CBIntFrqLst: TCheckBox;
   EIntFrqCur: TEdit;
   RBIntFrqPnt: TRadioButton;
   EIntFrqPnt: TEdit;
   GBMFPFrq: TGroupBox;
   RBMFPFrq1613: TRadioButton;
   RBMFPFrqST: TRadioButton;
   RBMFPFrqOther: TRadioButton;
   EMFPFrqOther: TEdit;
   EMFPFrqCur: TEdit;
   EMFPFrqST: TEdit;
   GBZ80Frq: TGroupBox;
   RBZ80FrqZX: TRadioButton;
   RBZ80FrqPnt: TRadioButton;
   RBZ80FrqOther: TRadioButton;
   EZ80FrqZX: TEdit;
   EZ80FrqPnt: TEdit;
   EZ80FrqOther: TEdit;
   LDMAOvfl: TLabel;
   WOSheet: TTabSheet;
   GBSRate: TGroupBox;
   RBSR48k: TRadioButton;
   RBSR44k: TRadioButton;
   RBSR22k: TRadioButton;
   RBSR11k: TRadioButton;
   GBChans: TGroupBox;
   RBChStereo: TRadioButton;
   RBChMono: TRadioButton;
   CheckBox6: TCheckBox;
   CheckBox7: TCheckBox;
   CBChLst: TCheckBox;
   GBBRate: TGroupBox;
   RBBt16: TRadioButton;
   RBBt8: TRadioButton;
   Button1: TButton;
   RBSR96k: TRadioButton;
   RBSROther: TRadioButton;
   ESROther: TEdit;
   SBSRAYby8: TSpeedButton;
   Button2: TButton;
   SBStop: TSpeedButton;
   GBBuffs: TGroupBox;
   LBufLen: TLabel;
   LNumBuf: TLabel;
   LTotLenCap: TLabel;
   LTotLen: TLabel;
   LBufLenCap: TLabel;
   LNumBufCap: TLabel;
   TBBufLen: TTrackBar;
   TBNumBuf: TTrackBar;
   GBDevice: TGroupBox;
   cbWODevice: TComboBox;
   BASSSheet: TTabSheet;
   GBBASSVis: TGroupBox;
   FFTTyp: TLabel;
   LNumFFTk: TLabel;
   TBNumFFTk: TTrackBar;
   TBLevMinMax: TTrackBar;
   LLevMinMax: TLabel;
   aminmax: TLabel;
   TBPreAmp: TTrackBar;
   EPreAmp: TEdit;
   VolumeSheet: TTabSheet;
   BVolCtrlSelect: TButton;
   BVolCtrlDetect: TButton;
   LVolCtrl: TLabel;
   EVolCtrl: TEdit;
   CBLnScale: TCheckBox;
   GBResamp: TGroupBox;
   Label13: TLabel;
   RBResamFIR: TRadioButton;
   RBResamAvg: TRadioButton;
   EIntOffs: TEdit;
   LOUTIntOffs: TLabel;
   CBSvVolPos: TCheckBox;
   LPreAmp: TLabel;
   LAmpBpr: TLabel;
   LAmpA: TLabel;
   LAmpB: TLabel;
   LAmpC: TLabel;
   LAmpAL: TLabel;
   LAmpAR: TLabel;
   LAmpBL: TLabel;
   LAmpBR: TLabel;
   LAmpCL: TLabel;
   LAmpCR: TLabel;
   MOSheet: TTabSheet;
   GBMidiDevice: TGroupBox;
   cbMODevice: TComboBox;
   CBHann: TCheckBox;
   CheckBox12: TCheckBox;
   RBSR192k: TRadioButton;
   Label22: TLabel;
   Label23: TLabel;
   Label24: TLabel;
   Label25: TLabel;
   Label26: TLabel;
   Label27: TLabel;
   procedure CBIntFrqLstChange(Sender: TObject);
   procedure EAmpDMAEditingDone(Sender: TObject);
   procedure EMCFrqOtherEditingDone(Sender: TObject);
   procedure FormShow(Sender: TObject);
   procedure GBChAmpResize(Sender: TObject);
   function OpenMixer(const Path1, Path2, Path3: string): boolean;
   procedure CBDCBiasChange(Sender: TObject);
   procedure EChFrqOtherEditingDone(Sender: TObject);
   procedure EOUTStPerFrmEditingDone(Sender: TObject);
   procedure EAmpALEditingDone(Sender: TObject);
   procedure EAmpBprEditingDone(Sender: TObject);
   procedure EIntFrqOtherEditingDone(Sender: TObject);
   procedure EMFPFrqOtherEditingDone(Sender: TObject);
   procedure EAmpAREditingDone(Sender: TObject);
   procedure EPreAmpEditingDone(Sender: TObject);
   procedure ESROtherEditingDone(Sender: TObject);
   procedure EZ80FrqOtherEditingDone(Sender: TObject);
   procedure EAmpBLEditingDone(Sender: TObject);
   procedure EAmpBREditingDone(Sender: TObject);
   procedure EAmpCLEditingDone(Sender: TObject);
   procedure EAmpCREditingDone(Sender: TObject);
   procedure EIntOffsEditingDone(Sender: TObject);
   procedure CBNetAgentChange(Sender: TObject);
   procedure CBProxyChange(Sender: TObject);
   procedure EProxyChange(Sender: TObject);
   procedure RBMCFrqSTClick(Sender: TObject);
   procedure RBMCFrqOtherClick(Sender: TObject);
   procedure SBHelperClick(Sender: TObject);
   procedure TBAmpDMAChange(Sender: TObject);
   procedure TBAmpALChange(Sender: TObject);
   procedure TBAmpARChange(Sender: TObject);
   procedure TBAmpBLChange(Sender: TObject);
   procedure TBAmpBRChange(Sender: TObject);
   procedure TBAmpCLChange(Sender: TObject);
   procedure TBAmpCRChange(Sender: TObject);
   procedure RBChTypeAYClick(Sender: TObject);
   procedure RBChTypeYMClick(Sender: TObject);
   procedure RBChFrqZXClick(Sender: TObject);
   procedure RBChFrqPntClick(Sender: TObject);
   procedure RBChFrqSTClick(Sender: TObject);
   procedure RBChFrqCPCClick(Sender: TObject);
   procedure RBChFrqOtherClick(Sender: TObject);
   procedure Set_Frqs;
   procedure Set_Z80Frqs;
   procedure Set_MC68KFrqs;
   procedure FormHide(Sender: TObject);
   procedure RBSR44kClick(Sender: TObject);
   procedure RBSR22kClick(Sender: TObject);
   procedure RBSR11kClick(Sender: TObject);
   procedure RBBt16Click(Sender: TObject);
   procedure RBBt8Click(Sender: TObject);
   procedure RBChStereoClick(Sender: TObject);
   procedure RBChMonoClick(Sender: TObject);
   procedure Change_Show(TB: TTrackBar; E1, E2: TEdit; NewVal: byte; var Ind: byte);
   procedure RBEIntFrqZXClick(Sender: TObject);
   procedure RBIntFrqOtherClick(Sender: TObject);
   procedure Set_Pl_Frqs;
   procedure Button1Click(Sender: TObject);
   procedure SetMixerParams;
   procedure FormCreate(Sender: TObject);
   procedure RBIntFrqPntClick(Sender: TObject);
   procedure RBMFPFrqOtherClick(Sender: TObject);
   procedure Set_MFPFrqs;
   procedure RBMFPFrq1613Click(Sender: TObject);
   procedure RBMFPFrqSTClick(Sender: TObject);
   procedure RBZ80FrqOtherClick(Sender: TObject);
   procedure RBZ80FrqPntClick(Sender: TObject);
   procedure RBZ80FrqZXClick(Sender: TObject);
   procedure Change_Show2(TB: TTrackBar; E1: TEdit; NewVal: byte; var Ind: byte);
   procedure TBAmpBprChange(Sender: TObject);
   procedure RBSR48kClick(Sender: TObject);
   procedure RBSR96kClick(Sender: TObject);
   procedure RBSR192kClick(Sender: TObject);
   procedure SetSRs;
   procedure RBSROtherClick(Sender: TObject);
   procedure SBSRAYby8Click(Sender: TObject);
   procedure Button2Click(Sender: TObject);
   procedure SBStopClick(Sender: TObject);
   procedure UpdateBuffLables;
   procedure TBBufLenChange(Sender: TObject);
   procedure TBNumBufChange(Sender: TObject);
   procedure cbWODeviceChange(Sender: TObject);
   procedure TBNumFFTkChange(Sender: TObject);
   procedure TBLevMinMaxChange(Sender: TObject);
   procedure TBPreAmpChange(Sender: TObject);
   procedure BVolCtrlSelectClick(Sender: TObject);
   procedure BVolCtrlDetectClick(Sender: TObject);
   procedure CBLnScaleClick(Sender: TObject);
   procedure RBResamAvgClick(Sender: TObject);
   procedure RBResamFIRClick(Sender: TObject);
   procedure CBSvVolPosClick(Sender: TObject);
   procedure cbMODeviceChange(Sender: TObject);
   procedure CBHannClick(Sender: TObject);
   procedure CheckBox12Click(Sender: TObject);
   procedure UpdateAmplFields;
 private
   { Private declarations }
 public
   { Public declarations }
   FrqAYTemp, FrqPlTemp, FrqMFPTemp: longword;
 end;

var
 FrmMixer: TFrmMixer;

implementation

uses
 MainWin, Tools, AY, Z80, basslight, basscode, digsound, digsoundcode, PlayList,
 mixerctl, SelVolCtrl{$IFDEF Windows}, Midi{$ENDIF Windows}, settings, atari,
 mxhelper, Languages;

 {$R *.lfm}

function TFrmMixer.OpenMixer(const Path1, Path2, Path3: string): boolean;
var
 s: string;
begin
 Result := mixerctl_open(Path1, Path2, Path3, FrmMain.Handle, WM_VOLUMECHANGED) = 0;
 if not Result then exit;
 GetSysVolume;
 mixerctl_title(s);
 EVolCtrl.Text := s;
end;

procedure TFrmMixer.EAmpDMAEditingDone(Sender: TObject);
var
 A, Cde: integer;
begin
 Val(EAmpDMA.Text, A, Cde);
 if (Cde = 0) and (A in [0..255]) then
   Change_Show2(TBAmpDMA, EAmpDMA, A, Atari_DMAMax)
 else
   EAmpDMA.Text := IntToStr(TBAmpDMA.Position);
end;

procedure TFrmMixer.CBIntFrqLstChange(Sender: TObject);
begin
 RedrawPlaylist(ShownFrom, False);
 CalculateTotalTime(False);
end;

procedure TFrmMixer.EMCFrqOtherEditingDone(Sender: TObject);
var
 Err, Fr: integer;
begin
 Val(EMCFrqOther.Text, Fr, Err);
 if Err = 0 then
   FrmMain.Set_MC68K_Frq(Fr);
 Set_MC68KFrqs;
end;

procedure TFrmMixer.FormShow(Sender: TObject);
begin
 FrmMain.MIMixer.Checked:=True;
end;

procedure TFrmMixer.GBChAmpResize(Sender: TObject);
var
 Border, MinOfs, NeedOfs, NewConst: integer;
begin
 //fix LCL AutoSize error (need todo bugreport)
 Border := GBChAmp.Width - GBChAmp.ClientWidth;
 MinOfs := LAmpC.Left;
 if MinOfs > LAmpBpr.Left then
   MinOfs := LAmpBpr.Left;
 if MinOfs > LPreAmp.Left then
   MinOfs := LPreAmp.Left;
 NeedOfs := DivMul(4, Monitor.PixelsPerInch, DesignTimePPI);
 if MinOfs > NeedOfs then
  begin
   NewConst := GBChAmp.Width - MinOfs + NeedOfs + Border;
   if NewConst < GBChAmp.Constraints.MinWidth then
     NewConst := GBChAmp.Constraints.MinWidth;
   GBChAmp.Constraints.MaxWidth := NewConst;
  end;
end;

procedure TFrmMixer.TBAmpALChange(Sender: TObject);
begin
 FrmMain.SetChan2(TBAmpAL.Position, 0);
end;

procedure TFrmMixer.EAmpALEditingDone(Sender: TObject);
var
 A, Cde: integer;
begin
 Val(EAmpAL.Text, A, Cde);
 if (Cde = 0) and (A in [0..255]) then
   FrmMain.SetChan2(A, 0)
 else
   EAmpAL.Text := IntToStr(TBAmpAL.Position);
end;

procedure TFrmMixer.EOUTStPerFrmEditingDone(Sender: TObject);
begin
 FrmMain.Set_N_TactS(EOUTStPerFrm.Text);
end;

procedure TFrmMixer.EChFrqOtherEditingDone(Sender: TObject);
var
 Err, Fr: integer;
begin
 Val(EChFrqOther.Text, Fr, Err);
 if Err = 0 then
  begin
   FrmMain.Set_Chip_Frq(Fr);
   FrqAYTemp := AY_Freq;
  end;
 Set_Frqs;
end;

procedure TFrmMixer.EAmpBprEditingDone(Sender: TObject);
var
 A, Cde: integer;
begin
 Val(EAmpBpr.Text, A, Cde);
 if (Cde = 0) and (A in [0..255]) then
   Change_Show2(TBAmpBpr, EAmpBpr, A, BeeperMax)
 else
   EAmpBpr.Text := IntToStr(TBAmpBpr.Position);
end;

procedure TFrmMixer.EIntFrqOtherEditingDone(Sender: TObject);
var
 Fr: Double;
begin
 if TryStrToFloat(EIntFrqOther.Text,Fr) then
  FrmMain.Set_Player_Frq2(Trunc(Fr * 1000 + 0.5));
 Set_Pl_Frqs;
end;

procedure TFrmMixer.EMFPFrqOtherEditingDone(Sender: TObject);
var
 Err, Fr: integer;
begin
 Val(EMFPFrqOther.Text, Fr, Err);
 if Err = 0 then
  begin
   FrmMain.Set_MFP_Frq(1, Fr);
   FrqMFPTemp := MFPTimerFrq;
  end;
 Set_MFPFrqs;
end;

procedure TFrmMixer.EAmpAREditingDone(Sender: TObject);
var
 A, Cde: integer;
begin
 Val(EAmpAR.Text, A, Cde);
 if (Cde = 0) and (A in [0..255]) then
   FrmMain.SetChan2(A, 1)
 else
   EAmpAR.Text := IntToStr(TBAmpAR.Position);
end;

procedure TFrmMixer.EPreAmpEditingDone(Sender: TObject);
var
 A, Cde: integer;
begin
 Val(EPreAmp.Text, A, Cde);
 if (Cde = 0) and (A in [0..255]) then
   Change_Show2(TBPreAmp, EPreAmp, A, PreAmp)
 else
   EPreAmp.Text := IntToStr(TBPreAmp.Position);
end;

procedure TFrmMixer.ESROtherEditingDone(Sender: TObject);
var
 Err, Fr: integer;
begin
 Val(ESROther.Text, Fr, Err);
 if Err = 0 then FrmMain.Set_Sample_Rate2(Fr);
end;

procedure TFrmMixer.EZ80FrqOtherEditingDone(Sender: TObject);
var
 Err, Fr: integer;
begin
 Val(EZ80FrqOther.Text, Fr, Err);
 if Err = 0 then
   FrmMain.Set_Z80_Frq(Fr);
 Set_Z80Frqs;
end;

procedure TFrmMixer.EAmpBLEditingDone(Sender: TObject);
var
 A, Cde: integer;
begin
 Val(EAmpBL.Text, A, Cde);
 if (Cde = 0) and (A in [0..255]) then
   FrmMain.SetChan2(A, 2)
 else
   EAmpBL.Text := IntToStr(TBAmpBL.Position);
end;

procedure TFrmMixer.EAmpBREditingDone(Sender: TObject);
var
 A, Cde: integer;
begin
 Val(EAmpBR.Text, A, Cde);
 if (Cde = 0) and (A in [0..255]) then
   FrmMain.SetChan2(A, 3)
 else
   EAmpBR.Text := IntToStr(TBAmpBR.Position);
end;

procedure TFrmMixer.EAmpCLEditingDone(Sender: TObject);
var
 A, Cde: integer;
begin
 Val(EAmpCL.Text, A, Cde);
 if (Cde = 0) and (A in [0..255]) then
   FrmMain.SetChan2(A, 4)
 else
   EAmpCL.Text := IntToStr(TBAmpCL.Position);
end;

procedure TFrmMixer.EAmpCREditingDone(Sender: TObject);
var
 A, Cde: integer;
begin
 Val(EAmpCR.Text, A, Cde);
 if (Cde = 0) and (A in [0..255]) then
   FrmMain.SetChan2(A, 5)
 else
   EAmpCR.Text := IntToStr(TBAmpCR.Position);
end;

procedure TFrmMixer.EIntOffsEditingDone(Sender: TObject);
var
 Temp1, Temp2: integer;
begin
 Val(EIntOffs.Text, Temp1, Temp2);
 if (Temp2 = 0) and (Temp1 >= 0) and (Temp1 < integer(MaxTStates)) then
   IntOffset := Temp1;
 EIntOffs.Text := IntToStr(IntOffset);
end;

procedure TFrmMixer.CBNetAgentChange(Sender: TObject);
begin
 BASSNetAgent := CBNetAgent.Text;
end;

procedure TFrmMixer.CBProxyChange(Sender: TObject);
begin
 BASSNetUseProxy := CBProxy.Checked;
 FrmMixer.EProxy.Enabled := BASSNetUseProxy;
end;

procedure TFrmMixer.EProxyChange(Sender: TObject);
begin
 BASSNetProxy := EProxy.Text;
end;

procedure TFrmMixer.RBMCFrqSTClick(Sender: TObject);
begin
 if not RBMCFrqST.Checked then exit;
 FrmMain.Set_MC68K_Frq(8000000);
end;

procedure TFrmMixer.RBMCFrqOtherClick(Sender: TObject);
var
 Err, Fr: integer;
begin
 if not RBMCFrqOther.Checked then exit;
 Val(EMCFrqOther.Text, Fr, Err);
 if Err = 0 then
  begin
   FrmMain.Set_MC68K_Frq(Fr);
   Set_MC68KFrqs;
  end;
 if EMCFrqOther.CanSetFocus then
   EMCFrqOther.SetFocus;
end;

procedure TFrmMixer.SBHelperClick(Sender: TObject);
var
 APoint: TPoint;
 EmChip: ChTypes;
 i: integer;
begin
 APoint.x := SBHelper.Width;
 APoint.y := SBHelper.Height;
 APoint := SBHelper.ClientToScreen(APoint);
 FrmMxHlp.Left := APoint.x;
 FrmMxHlp.Top := APoint.y;
 if FrmMxHlp.ShowModal = mrOk then
  begin
   i := FrmMxHlp.ChansRG.ItemIndex + 1;
   if i > 6 then
    begin
     Dec(i, 6);
     if i = 7 then
       i := 0;
     EmChip := YM_Chip;
    end
   else
     EmChip := AY_Chip;
   FrmMain.CalcModeCoefs(i, EmChip, FrmMxHlp.TSDMAChG.Checked[0],
     FrmMxHlp.TSDMAChG.Checked[1],
     Index_AL, Index_AR, Index_BL, Index_BR, Index_CL, Index_CR,
     BeeperMax, Atari_DMAMax);
   PreAmp := 0; //byte!
   repeat //нет смысла заранее просчитывать, проще перебирать все варианты, пока не найдем подходящий
     Dec(PreAmp);
     Calculate_Level_Tables2;
     if not (LAYOvfl.Visible or (FrmMxHlp.TSDMAChG.Checked[1] and
       LDMAOvfl.Visible) or (FrmMxHlp.TSDMAChG.Checked[0] and LTSOvfl.Visible)) then
       Break;
   until Preamp = 0;
   UpdateAmplFields;
  end;
end;

procedure TFrmMixer.TBAmpDMAChange(Sender: TObject);
begin
 Change_Show2(TBAmpDMA, EAmpDMA, TBAmpDMA.Position, Atari_DMAMax);
end;

procedure TFrmMixer.TBAmpARChange(Sender: TObject);
begin
 FrmMain.SetChan2(TBAmpAR.Position, 1);
end;

procedure TFrmMixer.TBAmpBLChange(Sender: TObject);
begin
 FrmMain.SetChan2(TBAmpBL.Position, 2);
end;

procedure TFrmMixer.TBAmpBRChange(Sender: TObject);
begin
 FrmMain.SetChan2(TBAmpBR.Position, 3);
end;

procedure TFrmMixer.TBAmpCLChange(Sender: TObject);
begin
 FrmMain.SetChan2(TBAmpCL.Position, 4);
end;

procedure TFrmMixer.TBAmpCRChange(Sender: TObject);
begin
 FrmMain.SetChan2(TBAmpCR.Position, 5);
end;

procedure TFrmMixer.RBChTypeAYClick(Sender: TObject);
begin
 if not RBChTypeAY.Checked then exit;
 FrmMain.Set_Chip2(AY_Chip);
end;

procedure TFrmMixer.RBChTypeYMClick(Sender: TObject);
begin
 if not RBChTypeYM.Checked then exit;
 FrmMain.Set_Chip2(YM_Chip);
end;

procedure TFrmMixer.RBChFrqZXClick(Sender: TObject);
begin
 if not RBChFrqZX.Checked then exit;
 FrmMain.Set_Chip_Frq(1773400);
 FrqAYTemp := 1773400;
end;

procedure TFrmMixer.RBChFrqPntClick(Sender: TObject);
begin
 if not RBChFrqPnt.Checked then exit;
 FrmMain.Set_Chip_Frq(1750000);
 FrqAYTemp := 1750000;
end;

procedure TFrmMixer.RBChFrqSTClick(Sender: TObject);
begin
 if not RBChFrqST.Checked then exit;
 FrmMain.Set_Chip_Frq(2000000);
 FrqAYTemp := 2000000;
end;

procedure TFrmMixer.RBChFrqCPCClick(Sender: TObject);
begin
 if not RBChFrqCPC.Checked then exit;
 FrmMain.Set_Chip_Frq(1000000);
 FrqAYTemp := 1000000;
end;

procedure TFrmMixer.RBChFrqOtherClick(Sender: TObject);
var
 Err, Fr: integer;
begin
 if not RBChFrqOther.Checked then
  Exit;
 Val(EChFrqOther.Text, Fr, Err);
 if Err = 0 then
  begin
   FrmMain.Set_Chip_Frq(Fr);
   FrqAYTemp := AY_Freq;
   Set_Frqs;
  end;
 if EChFrqOther.CanSetFocus then
   EChFrqOther.SetFocus;
end;

procedure TFrmMixer.Set_MFPFrqs;
begin
 if MFPTimerMode = 0 then
   RBMFPFrq1613.Checked := True
 else
   case FrqMFPTemp of
     2457600: RBMFPFrqST.Checked := True;
   else
    begin
     EMFPFrqOther.Text := IntToStr(FrqMFPTemp);
     RBMFPFrqOther.Checked := True;
    end;
    end;
end;

procedure TFrmMixer.Set_Z80Frqs;
begin
 case FrqZ80 of
   3494400: RBZ80FrqZX.Checked := True;
   3500000: RBZ80FrqPnt.Checked := True;
 else
  begin
   EZ80FrqOther.Text := IntToStr(FrqZ80);
   RBZ80FrqOther.Checked := True;
  end;
  end;
end;

procedure TFrmMixer.Set_MC68KFrqs;
begin
 if MC68000Freq = 8000000 then
   RBMCFrqST.Checked := True
 else
  begin
   EMCFrqOther.Text := FloatToStr(MC68000Freq);
   RBMCFrqOther.Checked := True;
  end;
end;

procedure TFrmMixer.Set_Frqs;
begin
 case FrqAYTemp of
   1773400: RBChFrqZX.Checked := True;
   1750000: RBChFrqPnt.Checked := True;
   2000000: RBChFrqST.Checked := True;
   1000000: RBChFrqCPC.Checked := True;
 else
  begin
   EChFrqOther.Text := IntToStr(FrqAYTemp);
   RBChFrqOther.Checked := True;
  end;
  end;
end;

procedure TFrmMixer.Set_Pl_Frqs;
begin
 case FrqPlTemp of
   50000: RBEIntFrqZX.Checked := True;
   48828: RBIntFrqPnt.Checked := True;
 else
  begin
   EIntFrqOther.Text := FloatToStrF(FrqPlTemp / 1000, ffFixed, 7, 3);
   RBIntFrqOther.Checked := True;
  end;
  end;
end;

procedure TFrmMixer.FormHide(Sender: TObject);
begin
 if ButtZoneRoot <> nil then
   if ButMixer.Is_On then
     ButMixer.Switch_Off;
 FrmMain.MIMixer.Checked:=False;
end;

procedure TFrmMixer.RBSR192kClick(Sender: TObject);
begin
 if not RBSR192k.Checked then exit;
 Set_Sample_Rate(192000);
end;

procedure TFrmMixer.RBSR96kClick(Sender: TObject);
begin
 if not RBSR96k.Checked then exit;
 Set_Sample_Rate(96000);
end;

procedure TFrmMixer.RBSR48kClick(Sender: TObject);
begin
 if not RBSR48k.Checked then exit;
 Set_Sample_Rate(48000);
end;

procedure TFrmMixer.RBSR44kClick(Sender: TObject);
begin
 if not RBSR44k.Checked then exit;
 Set_Sample_Rate(44100);
end;

procedure TFrmMixer.RBSR22kClick(Sender: TObject);
begin
 if not RBSR22k.Checked then exit;
 Set_Sample_Rate(22050);
end;

procedure TFrmMixer.RBSR11kClick(Sender: TObject);
begin
 if not RBSR11k.Checked then exit;
 Set_Sample_Rate(11025);
end;

procedure TFrmMixer.RBBt16Click(Sender: TObject);
begin
 if not RBBt16.Checked then exit;
 Set_Sample_Bit(16);
end;

procedure TFrmMixer.RBBt8Click(Sender: TObject);
begin
 if not RBBt8.Checked then exit;
 Set_Sample_Bit(8);
end;

procedure TFrmMixer.RBChStereoClick(Sender: TObject);
begin
 if not RBChStereo.Checked then exit;
 Set_Stereo(2);
end;

procedure TFrmMixer.RBChMonoClick(Sender: TObject);
begin
 if not RBChMono.Checked then exit;
 Set_Stereo(1);
end;

procedure TFrmMixer.UpdateAmplFields;
begin
 FrmMain.SetChan2(PreAmp, -1);
 FrmMain.SetChan2(Index_AL, 0);
 FrmMain.SetChan2(Index_AR, 1);
 FrmMain.SetChan2(Index_BL, 2);
 FrmMain.SetChan2(Index_BR, 3);
 FrmMain.SetChan2(Index_CL, 4);
 FrmMain.SetChan2(Index_CR, 5);
 FrmMain.SetChan2(BeeperMax, 6);
 FrmMain.SetChan2(Atari_DMAMax, 7);
end;

procedure TFrmMixer.Change_Show(TB: TTrackBar; E1, E2: TEdit; NewVal: byte; var Ind: byte);
begin
 TB.Position := NewVal;
 E1.Text := IntToStr(NewVal);
 if IsPlaying then E2.Text := E1.Text;
 Ind := NewVal;
 Calculate_Level_Tables2;
end;

procedure TFrmMixer.RBEIntFrqZXClick(Sender: TObject);
begin
 if not RBEIntFrqZX.Checked then
   Exit;
 FrmMain.Set_Player_Frq2(50000);
end;

procedure TFrmMixer.RBIntFrqOtherClick(Sender: TObject);
var
 Fr: Double;
begin
 if not RBIntFrqOther.Checked then
  Exit;
 if TryStrToFloat(EIntFrqOther.Text,Fr) then
  begin
   FrmMain.Set_Player_Frq2(Trunc(Fr * 1000 + 0.5));
   Set_Pl_Frqs;
  end;
 if EIntFrqOther.CanSetFocus then
   EIntFrqOther.SetFocus;
end;

procedure TFrmMixer.Button1Click(Sender: TObject);
begin
 FrmMain.SetDefault;
 CheckBox1.Checked := True;
 CBChTypeLst.Checked := True;
 CBChFrqLst.Checked := True;
 CBIntFrqLst.Checked := True;
 CBChLst.Checked := True;
 SetMixerParams;
end;

procedure TFrmMixer.SetSRs;
begin
 case SampleRate of
   192000:
     RBSR192k.Checked := True;
   96000:
     RBSR96k.Checked := True;
   48000:
     RBSR48k.Checked := True;
   44100:
     RBSR44k.Checked := True;
   22050:
     RBSR22k.Checked := True;
   11025:
     RBSR11k.Checked := True;
 else
  begin
   RBSROther.Checked := True;
   ESROther.Text := IntToStr(SampleRate);
  end;
  end;
end;

procedure TFrmMixer.SetMixerParams;
begin
 FrqAYTemp := AY_Freq;
 FrqPlTemp := Interrupt_Freq;
 FrqMFPTemp := MFPTimerFrq;
 TBAmpAL.Position := Index_AL;
 TBAmpAR.Position := Index_AR;
 TBAmpBL.Position := Index_BL;
 TBAmpBR.Position := Index_BR;
 TBAmpCL.Position := Index_CL;
 TBAmpCR.Position := Index_CR;
 TBAmpBpr.Position := BeeperMax;
 TBAmpDMA.Position := Atari_DMAMax;
 TBPreAmp.Position := PreAmp;
 EAmpAL.Text := IntToStr(Index_AL);
 EAmpAR.Text := IntToStr(Index_AR);
 EAmpBL.Text := IntToStr(Index_BL);
 EAmpBR.Text := IntToStr(Index_BR);
 EAmpCL.Text := IntToStr(Index_CL);
 EAmpCR.Text := IntToStr(Index_CR);
 EAmpBpr.Text := IntToStr(BeeperMax);
 EPreAmp.Text := IntToStr(PreAmp);
 EOUTStPerFrm.Text := IntToStr(MaxTStates);
 if ChType = AY_Chip then
   RBChTypeAY.Checked := True
 else
   RBChTypeYM.Checked := True;
 Set_Z80Frqs;
 Set_Frqs;
 Set_Pl_Frqs;
 Set_MFPFrqs;
 SetSRs;
 case SampleBit of
   16:
     RBBt16.Checked := True;
   8:
     RBBt8.Checked := True;
  end;
 if NumberOfChannels = 2 then
   RBChStereo.Checked := True
 else
   RBChMono.Checked := True;
 UpdateBuffLables;
 cbWODevice.ItemIndex := digsoundDevice;
 {$IFDEF Windows}
 cbMODevice.ItemIndex := integer(MIDIDevice) + 1;
 {$ENDIF Windows}

 if FilterQuality = 0 then
   RBResamAvg.Checked := True
 else
   RBResamFIR.Checked := True;

 EIntOffs.Text := IntToStr(IntOffset);
 TBNumFFTk.Position := BASSFFTType - BASS_DATA_FFT256;
 TBLevMinMax.Position := round(BASSAmpMin * 10000);
 CBHann.Checked := BASSFFTNoWin = 0;
 {$IFDEF Windows}
 CheckBox12.Checked := MIDISeekToFirstNote;
 {$ENDIF Windows}
 CBDCBias.Checked := BASSFFTRemDC = BASS_DATA_FFT_REMOVEDC;
 CBNetAgent.Text := BASSNetAgent;
 CBProxy.Checked := BASSNetUseProxy;
 EProxy.Text := BASSNetProxy;
 CBLnScale.Checked := VolLinear;
 CBSvVolPos.Checked := AutoSaveVolumePos;
 if IsPlaying then
   FrmMain.ShowAllParams;
end;

procedure TFrmMixer.FormCreate(Sender: TObject);
begin
 EIntFrqZX.Text := FloatToStrF(50, ffFixed, 7, 3);
 EIntFrqPnt.Text := FloatToStrF(48.828, ffFixed, 7, 3);
 digsound_getdevices(cbWODevice.Items);
 {$IFDEF Windows}
 MIDIEnumDevices(cbMODevice);
 {$ENDIF Windows}
 CBLnScale.Checked := VolLinear;
end;

procedure TFrmMixer.RBIntFrqPntClick(Sender: TObject);
begin
 if not RBIntFrqPnt.Checked then
   Exit;
 FrmMain.Set_Player_Frq2(48828);
end;

procedure TFrmMixer.RBMFPFrqOtherClick(Sender: TObject);
var
 Err, Fr: integer;
begin
 if not RBMFPFrqOther.Checked then
   Exit;
 Val(EMFPFrqOther.Text, Fr, Err);
 if Err = 0 then
  begin
   FrmMain.Set_MFP_Frq(1, Fr);
   FrqMFPTemp := MFPTimerFrq;
   Set_MFPFrqs;
  end;
 if EMFPFrqOther.CanSetFocus then
   EMFPFrqOther.SetFocus;
end;

procedure TFrmMixer.RBMFPFrq1613Click(Sender: TObject);
begin
 if not RBMFPFrq1613.Checked then
  Exit;
 FrmMain.Set_MFP_Frq(0, 0);
 FrqMFPTemp := MFPTimerFrq;
end;

procedure TFrmMixer.RBMFPFrqSTClick(Sender: TObject);
begin
 if not RBMFPFrqST.Checked then
  Exit;
 FrmMain.Set_MFP_Frq(1, 2457600);
 FrqMFPTemp := 2457600;
end;

procedure TFrmMixer.RBZ80FrqOtherClick(Sender: TObject);
var
 Err, Fr: integer;
begin
 if not RBZ80FrqOther.Checked then
  Exit;
 Val(EZ80FrqOther.Text, Fr, Err);
 if Err = 0 then
  begin
   FrmMain.Set_Z80_Frq(Fr);
   Set_Z80Frqs;
  end;
 if EZ80FrqOther.CanSetFocus then
   EZ80FrqOther.SetFocus;
end;

procedure TFrmMixer.RBZ80FrqPntClick(Sender: TObject);
begin
 if not RBZ80FrqPnt.Checked then
  Exit;
 FrmMain.Set_Z80_Frq(3500000);
end;

procedure TFrmMixer.RBZ80FrqZXClick(Sender: TObject);
begin
 if not RBZ80FrqZX.Checked then
  Exit;
 FrmMain.Set_Z80_Frq(3494400);
end;

procedure TFrmMixer.Change_Show2(TB: TTrackBar; E1: TEdit; NewVal: byte; var Ind: byte);
begin
 TB.Position := NewVal;
 E1.Text := IntToStr(NewVal);
 Ind := NewVal;
 Calculate_Level_Tables2;
end;

procedure TFrmMixer.TBAmpBprChange(Sender: TObject);
begin
 Change_Show2(TBAmpBpr, EAmpBpr, TBAmpBpr.Position, BeeperMax);
end;

procedure TFrmMixer.RBSROtherClick(Sender: TObject);
var
 Err, Fr: integer;
begin
 if not RBSROther.Checked then exit;
 Val(ESROther.Text, Fr, Err);
 if Err = 0 then
  begin
   Set_Sample_Rate(Fr);
   SetSRs;
  end;
 if ESROther.CanSetFocus then
   ESROther.SetFocus;
end;

procedure TFrmMixer.SBSRAYby8Click(Sender: TObject);
begin
 Set_Sample_Rate(round(FrqAYTemp / 8));
 SetSRs;
end;

procedure TFrmMixer.Button2Click(Sender: TObject);
begin
 Visible := False;
end;

procedure TFrmMixer.SBStopClick(Sender: TObject);
begin
 StopAndFreeAll;
end;

procedure TFrmMixer.UpdateBuffLables;
begin
 FrmMixer.TBBufLen.Position := BufLen_ms;
 FrmMixer.TBNumBuf.Position := NumberOfBuffers;
 LNumBuf.Caption := IntToStr(NumberOfBuffers);
 LBufLen.Caption := IntToStr(BufLen_ms) + ' ' + Mes_MiliSec;
 LTotLen.Caption := IntToStr(BufLen_ms * NumberOfBuffers) + ' ' + Mes_MiliSec;
end;

procedure TFrmMixer.TBBufLenChange(Sender: TObject);
begin
 FrmMain.SetBuffers(TBBufLen.Position, NumberOfBuffers);
 UpdateBuffLables;
end;

procedure TFrmMixer.TBNumBufChange(Sender: TObject);
begin
 FrmMain.SetBuffers(BufLen_ms, TBNumBuf.Position);
 UpdateBuffLables;
end;

procedure TFrmMixer.TBNumFFTkChange(Sender: TObject);
begin
 case TBNumFFTk.Position of
   0:
    begin
     FFTTyp.Caption := '128';
     BASSFFTType := BASS_DATA_FFT256;
    end;
   1:
    begin
     FFTTyp.Caption := '256';
     BASSFFTType := BASS_DATA_FFT512;
    end;
   2:
    begin
     FFTTyp.Caption := '512';
     BASSFFTType := BASS_DATA_FFT1024;
    end;
   3:
    begin
     FFTTyp.Caption := '1024';
     BASSFFTType := BASS_DATA_FFT2048;
    end;
   4:
    begin
     FFTTyp.Caption := '2048';
     BASSFFTType := BASS_DATA_FFT4096;
    end;
   5:
    begin
     FFTTyp.Caption := '4096';
     BASSFFTType := BASS_DATA_FFT8192;
    end;
   6:
    begin
     FFTTyp.Caption := '8192';
     BASSFFTType := BASS_DATA_FFT16384;
    end;
   7:
    begin
     FFTTyp.Caption := '16384';
     BASSFFTType := BASS_DATA_FFT32768;
    end;
  end;
end;

procedure TFrmMixer.TBLevMinMaxChange(Sender: TObject);
begin
 BASSAmpMin := TBLevMinMax.Position / 10000;
 aminmax.Caption := FloatToStr(BASSAmpMin);
end;

procedure TFrmMixer.TBPreAmpChange(Sender: TObject);
begin
 Change_Show2(TBPreAmp, EPreAmp, TBPreAmp.Position, PreAmp);
end;

procedure TFrmMixer.BVolCtrlSelectClick(Sender: TObject);
var
 Lst: Tmixerctl_list;
 i, j, k: integer;
begin
 if mixerctl_enumerate(Lst) <> 0 then
  Exit; //todo errors
 with TFrmSelVolCtrl.Create(Self) do
  try
   Caption := Mes_SelectMixerDivice;
   for i := 0 to Length(Lst) - 1 do
     ListBox1.Items.Add(Lst[i].Name);
   if ShowModal <> mrOk then exit;
   i := ListBox1.ItemIndex;
   if Length(Lst[i].SubDevice) = 0 then
    begin
     ShowMessage(Mes_NoValidDestForMixer);
     exit;
    end;
   ListBox1.Clear;
   Caption := Mes_SelectDestination;
   for j := 0 to Length(Lst[i].SubDevice) - 1 do
     ListBox1.Items.Add(Lst[i].SubDevice[j].Name);
   if ShowModal <> mrOk then exit;
   j := ListBox1.ItemIndex;
   if Length(Lst[i].SubDevice[j].SubDevice) = 0 then
    begin
     ShowMessage(Mes_NoVolumeControlsFound);
     exit;
    end;
   ListBox1.Clear;
   Caption := Mes_SelectControl;
   for k := 0 to Length(Lst[i].SubDevice[j].SubDevice) - 1 do
     ListBox1.Items.Add(Lst[i].SubDevice[j].SubDevice[k]);
   if ShowModal <> mrOk then exit;
   OpenMixer(Lst[i].Name, Lst[i].SubDevice[j].Name,
     Lst[i].SubDevice[j].SubDevice[ListBox1.ItemIndex]);
  finally
   Free;
  end;
end;

procedure TFrmMixer.BVolCtrlDetectClick(Sender: TObject);
begin
 if not OpenMixer('', '', '') then
   ShowMessage(Mes_SystemVolCtrlsNotDetected);
end;

procedure TFrmMixer.CBLnScaleClick(Sender: TObject);
begin
 VolLinear := CBLnScale.Checked;
 GetSysVolume;
end;

procedure TFrmMixer.RBResamAvgClick(Sender: TObject);
begin
 if not RBResamAvg.Checked then exit;
 FrmMain.SetFilter(0);
end;

procedure TFrmMixer.RBResamFIRClick(Sender: TObject);
begin
 if not RBResamFIR.Checked then exit;
 FrmMain.SetFilter(1);
end;

procedure TFrmMixer.CBSvVolPosClick(Sender: TObject);
begin
 AutoSaveVolumePos := CBSvVolPos.Checked;
end;

procedure TFrmMixer.cbWODeviceChange(Sender: TObject);
begin
 digsoundDevice := cbWODevice.ItemIndex;
end;

procedure TFrmMixer.cbMODeviceChange(Sender: TObject);
begin
 {$IFDEF Windows}
 MIDIDevice := cbMODevice.ItemIndex - 1;
 {$ENDIF Windows}
end;

procedure TFrmMixer.CBHannClick(Sender: TObject);
begin
 if CBHann.Checked then
   BASSFFTNoWin := 0
 else
   BASSFFTNoWin := BASS_DATA_FFT_NOWINDOW;
end;

procedure TFrmMixer.CheckBox12Click(Sender: TObject);
begin
 {$IFDEF Windows}
 MIDISeekToFirstNote := CheckBox12.Checked;
 {$ENDIF Windows}
end;

procedure TFrmMixer.CBDCBiasChange(Sender: TObject);
begin
 if not CBDCBias.Checked then
   BASSFFTRemDC := 0
 else
   BASSFFTRemDC := BASS_DATA_FFT_REMOVEDC;
end;

end.
