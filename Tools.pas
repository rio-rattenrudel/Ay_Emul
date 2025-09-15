{
This is part of AY Emulator project
AY-3-8910/12 Emulator
Version 3.0 for Windows and Linux
Author Sergey Vladimirovich Bulba
(c)1999-2025 S.V.Bulba
}

unit Tools;

{$mode objfpc}{$H+}

interface

uses
 LCLIntf, {$IFDEF Windows}Windows, ShlObj, ComObj, ActiveX, {$ENDIF Windows}
 SysUtils, Classes, Graphics, Controls, Forms, Dialogs, StdCtrls, ComCtrls,
 ExtCtrls, Buttons, EditBtn, WinVersion, LConvEncoding, FileTypes;

const
 NOfIcons = 16;
 IconAuthors: array[0..NOfIcons] of string =
   ('Sergey Bulba', 'X-agon', 'X-agon', 'X-agon', 'X-agon', 'David Willis',
   'Graham Goring', 'Graham Goring', 'Graham Goring', 'Graham Goring',
   'bcass', 'bcass', 'Exocet', 'Exocet', 'Roman Morozov', 'Ivan Reshetnikov',
   'Ivan Reshetnikov');

type
 TSelIconProc = procedure(n: integer) of object;

 TIconSelector = class
   IcGrp: TGroupBox;
   IcImg: TImage;
   IconUpDown: TUpDown;
   TitLB, AuthLB, AuthName: TLabel;
   constructor Create(AOwner: TWinControl);
   destructor Destroy; override;
   procedure ShowIcon;
   procedure IconUpDownClick(Sender: TObject; Button: TUDBtnType);
   procedure UpdateTranslation(const Cap: string);
 public
   DoSelectIcon: TSelIconProc;
 end;

 { TFrmTools }

 TFrmTools = class(TForm)
   CBDefCP: TComboBox;
   CBDescCP: TComboBox;
   CBRegAllUsers: TCheckBox;
   CBSrchST1: TCheckBox;
   CBSrchSTF: TCheckBox;
   CBSrchST3: TCheckBox;
   CBForceLoop: TCheckBox;
   CBStrPrescan: TCheckBox;
   CBDoubleSz: TCheckBox;
   DESrchWrkFld: TDirectoryEdit;
   LangCB: TComboBox;
   EVisPeriod: TEdit;
   FontDialog1: TFontDialog;
   GBLang: TGroupBox;
   GBDefCP: TGroupBox;
   GBDescCP: TGroupBox;
   LVisPeriod: TLabel;
   PnSrchOptsR: TPanel;
   PnSrchOptsL: TPanel;
   PCTools: TPageControl;
   GenTools: TTabSheet;
   GBOther: TGroupBox;
   CheckBox40: TCheckBox;
   GBPrior: TGroupBox;
   RadioButton3: TRadioButton;
   RadioButton4: TRadioButton;
   RadioButton5: TRadioButton;
   GBMenu: TGroupBox;
   Button10: TButton;
   Button11: TButton;
   GBTray: TGroupBox;
   RadioButton8: TRadioButton;
   RadioButton9: TRadioButton;
   RadioButton10: TRadioButton;
   GBSkin: TGroupBox;
   ESkinFN: TEdit;
   ESkinAuth: TEdit;
   ESkinCom: TEdit;
   BChSkin: TButton;
   BStdSkin: TButton;
   GBMFolder: TGroupBox;
   EMFolder: TEdit;
   CBAutoSaveMFld: TCheckBox;
   BSaveMFld: TButton;
   FTypTools: TTabSheet;
   SearchTool: TTabSheet;
   LSrchFiles: TLabel;
   LSrchWrkFld: TLabel;
   LSrchRprt: TLabel;
   BSrchChFiles: TButton;
   GBSrchOpts: TGroupBox;
   CBSrchFLS: TCheckBox;
   CBSrchPSC: TCheckBox;
   CBSrchASC: TCheckBox;
   CBSrchASC0: TCheckBox;
   CBSrchSTP: TCheckBox;
   CBSrchSTC: TCheckBox;
   CBSrchPT1: TCheckBox;
   CBSrchPT2: TCheckBox;
   CBSrchPT3: TCheckBox;
   CBSrchFTC: TCheckBox;
   CBSrchSQT: TCheckBox;
   CBSrchGTR: TCheckBox;
   MReport: TMemo;
   PBSearching: TProgressBar;
   BSrchBegin: TButton;
   MSrchFiles: TMemo;
   BAppReg: TButton;
   BAppUnreg: TButton;
   FIDOTools: TTabSheet;
   Label2: TLabel;
   Label9: TLabel;
   Label10: TLabel;
   Label11: TLabel;
   EDeskFN: TEdit;
   EDeskPfx: TEdit;
   EDeskSfx: TEdit;
   EDeskNoth: TEdit;
   CBDescEn: TCheckBox;
   CBDescKExit: TCheckBox;
   CBDescKNoth: TCheckBox;
   Button16: TButton;
   BTlClose: TButton;
   BTlUninstall: TButton;
   CBSrchNotCheck: TCheckBox;
   GroupBox2: TGroupBox;
   Label1: TLabel;
   Label12: TLabel;
   Label13: TLabel;
   Label14: TLabel;
   Label15: TLabel;
   Label16: TLabel;
   Label17: TLabel;
   Label18: TLabel;
   Label19: TLabel;
   ColorDialog1: TColorDialog;
   LBTpMus: TListBox;
   LBTpBASS: TListBox;
   LBTpPL: TListBox;
   LBTpSkin: TListBox;
   BTpMus: TButton;
   BTpBASS: TButton;
   BTpPL: TButton;
   BTpSkin: TButton;
   GBEditor: TGroupBox;
   EditVTPath: TEdit;
   SpeedButton1: TSpeedButton;
   PListOpts: TTabSheet;
   procedure BSrchChFilesClick(Sender: TObject);
   procedure BSrchBeginClick(Sender: TObject);
   procedure AllEnable;
   procedure CBDefCPChange(Sender: TObject);
   procedure CBDoubleSzClick(Sender: TObject);
   procedure CBForceLoopClick(Sender: TObject);
   procedure CBSrchASC0Change(Sender: TObject);
   procedure CBSrchASCChange(Sender: TObject);
   procedure CBSrchFLSChange(Sender: TObject);
   procedure CBSrchFTCChange(Sender: TObject);
   procedure CBSrchGTRChange(Sender: TObject);
   procedure CBSrchNotCheckChange(Sender: TObject);
   procedure CBSrchPSCChange(Sender: TObject);
   procedure CBSrchPT1Change(Sender: TObject);
   procedure CBSrchPT2Change(Sender: TObject);
   procedure CBSrchPT3Change(Sender: TObject);
   procedure CBSrchSQTChange(Sender: TObject);
   procedure CBSrchST1Change(Sender: TObject);
   procedure CBSrchST3Change(Sender: TObject);
   procedure CBSrchSTCChange(Sender: TObject);
   procedure CBSrchSTFChange(Sender: TObject);
   procedure CBSrchSTPChange(Sender: TObject);
   procedure CBStrPrescanClick(Sender: TObject);
   function CloseQuery: boolean; override;
   procedure BTlCloseClick(Sender: TObject);
   procedure EMFolderEditingDone(Sender: TObject);
   procedure EVisPeriodEditingDone(Sender: TObject);
   procedure LangCBExit(Sender: TObject);
   procedure RadioButton3Click(Sender: TObject);
   procedure RadioButton4Click(Sender: TObject);
   procedure RadioButton5Click(Sender: TObject);
   procedure BTlUninstallClick(Sender: TObject);
   procedure BAppRegClick(Sender: TObject);
   procedure BAppUnregClick(Sender: TObject);
   procedure Button10Click(Sender: TObject);
   procedure Button11Click(Sender: TObject);
   procedure RadioButton8Click(Sender: TObject);
   procedure RadioButton9Click(Sender: TObject);
   procedure RadioButton10Click(Sender: TObject);
   procedure BChSkinClick(Sender: TObject);
   procedure BStdSkinClick(Sender: TObject);
   procedure CBAutoSaveMFldClick(Sender: TObject);
   procedure BSaveMFldClick(Sender: TObject);
   procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
   procedure CheckRegistration;
   procedure FormCreate(Sender: TObject);
   procedure CheckBox40Click(Sender: TObject);
   procedure Button16Click(Sender: TObject);
   procedure SelectMenuIcon(n: integer);
   procedure SelectMusIcon(n: integer);
   procedure SelectSkinIcon(n: integer);
   procedure SelectListIcon(n: integer);
   procedure SelectBASSIcon(n: integer);
   procedure Label1Click(Sender: TObject);
   procedure Label12Click(Sender: TObject);
   procedure Label13Click(Sender: TObject);
   procedure Label14Click(Sender: TObject);
   procedure Label15Click(Sender: TObject);
   procedure Label16Click(Sender: TObject);
   procedure Label18Click(Sender: TObject);
   procedure Label19Click(Sender: TObject);
   procedure Label17Click(Sender: TObject);
   function ChangePLColor(var WantedColor: TColor): boolean;
   procedure CreateIcSel(var IcSel: TIconSelector; AOwner: TWinControl;
     SelIconProc: TSelIconProc; x, y: integer; const IcName: string; IcNum: integer);
   procedure BTpMusClick(Sender: TObject);
   procedure EditVTPathChange(Sender: TObject);
   procedure UpdateTranslation;
   {$ifdef Windows}
   procedure RegisterGroup(t: TFTCategory; lb: TListBox);
   {$endif Windows}
   procedure SpeedButton1Click(Sender: TObject);
   procedure LoadLanguages;
 private
   { Private declarations }
 public
   { Public declarations }
   AppIcSel, TrayIcSel, StartIcSel, MusIcSel, SkinIcSel, ListIcSel,
   BASSIcSel: TIconSelector;
 end;

{$IFDEF Windows}
procedure SetPriority(Pr: DWORD);
{$ENDIF Windows}

var
 FrmTools: TFrmTools;
 {$IFDEF Windows}
 Priority: dword = NORMAL_PRIORITY_CLASS;
 {$ENDIF Windows}

implementation

uses
 MainWin, Players, PlayList, Options, Languages
 {$IFDEF Windows}, assoc{$ENDIF Windows}, settings;

 {$R *.lfm}

{$IFDEF Windows}
procedure SetPriority(Pr: DWORD);
var
 HMyProcess: HANDLE;
begin
 HMyProcess := GetCurrentProcess;
 SetPriorityClass(HMyProcess, Pr);
 CloseHandle(HMyProcess);
 Priority := Pr;
end;
{$ENDIF Windows}

procedure TFrmTools.BSrchChFilesClick(Sender: TObject);
begin
 FrmMain.OpenDialog1.Filter := T_AllFiles + '|*';
 FrmMain.OpenDialog1.Filter := FrmMain.OpenDialog1.Filter +
   '|SNA|*.sna|TRD, TD0, FDI, SCL|*.trd;*.scl;*.fdi;*.td0|BIN|*.bin|TAP, TZX|' +
   '*.tap;*.tzx';
 if FrmMain.OpenDialog1.Execute then
  begin
   MSrchFiles.Lines := FrmMain.OpenDialog1.Files;
   FrmMain.OpenDialog1.FileName := '';
  end;
end;

procedure TFrmTools.BSrchBeginClick(Sender: TObject);
begin
 if FinderWorksNow then
  begin
   May_Quit := True;
   AllEnable;
  end
 else
  begin
   BSrchBegin.Caption := Mes_Stop;
   MSrchFiles.ReadOnly := True;
   DESrchWrkFld.ReadOnly := True;
   BSrchChFiles.Enabled := False;
   BTlClose.Enabled := False;
   GBOther.Enabled := False;
   GBSrchOpts.Enabled := False;
   GBPrior.Enabled := False;
   GBLang.Enabled := False;
   GBMenu.Enabled := False;
   MReport.Clear;
   FindModules;
  end;
end;

procedure TFrmTools.AllEnable;
begin
 FinderWorksNow := False;
 BSrchBegin.Caption := Mes_Begin;
 MSrchFiles.ReadOnly := False;
 DESrchWrkFld.ReadOnly := False;
 BSrchChFiles.Enabled := True;
 BTlClose.Enabled := True;
 GBOther.Enabled := True;
 GBSrchOpts.Enabled := True;
 GBPrior.Enabled := True;
 GBLang.Enabled := True;
 GBMenu.Enabled := True;
end;

procedure TFrmTools.CBDefCPChange(Sender: TObject);
begin
 CodePageDef := CBDefCP.Text;
end;

procedure TFrmTools.CBDoubleSzClick(Sender: TObject);
var
 NewS: integer;
begin
 NewS := Ord(CBDoubleSz.Checked) + 1;
 if NewS <> Scale then
  begin
   Scale := NewS;
   FrmMain.RecreateRgn;
  end;
end;

procedure TFrmTools.CBForceLoopClick(Sender: TObject);
begin
 Force_Loop := CBForceLoop.Checked;
end;

procedure TFrmTools.CBSrchASC0Change(Sender: TObject);
begin
F_ASM0 := CBSrchASC0.Checked;
end;

procedure TFrmTools.CBSrchASCChange(Sender: TObject);
begin
F_ASM1 := CBSrchASC.Checked;
end;

procedure TFrmTools.CBSrchFLSChange(Sender: TObject);
begin
F_FLS := CBSrchFLS.Checked;
end;

procedure TFrmTools.CBSrchFTCChange(Sender: TObject);
begin
F_FTC := CBSrchFTC.Checked;
end;

procedure TFrmTools.CBSrchGTRChange(Sender: TObject);
begin
F_GTR := CBSrchGTR.Checked;
end;

procedure TFrmTools.CBSrchNotCheckChange(Sender: TObject);
begin
IntegrityCheck := not CBSrchNotCheck.Checked;
end;

procedure TFrmTools.CBSrchPSCChange(Sender: TObject);
begin
F_PSC := CBSrchPSC.Checked;
end;

procedure TFrmTools.CBSrchPT1Change(Sender: TObject);
begin
F_PT1 := CBSrchPT1.Checked;
end;

procedure TFrmTools.CBSrchPT2Change(Sender: TObject);
begin
F_PT2 := CBSrchPT2.Checked;
end;

procedure TFrmTools.CBSrchPT3Change(Sender: TObject);
begin
F_PT3 := CBSrchPT3.Checked;
end;

procedure TFrmTools.CBSrchSQTChange(Sender: TObject);
begin
F_SQT := CBSrchSQT.Checked;
end;

procedure TFrmTools.CBSrchST1Change(Sender: TObject);
begin
F_ST1 := CBSrchST1.Checked;
end;

procedure TFrmTools.CBSrchST3Change(Sender: TObject);
begin
F_ST3 := CBSrchST3.Checked;
end;

procedure TFrmTools.CBSrchSTCChange(Sender: TObject);
begin
F_STC := CBSrchSTC.Checked;
end;

procedure TFrmTools.CBSrchSTFChange(Sender: TObject);
begin
F_STF := CBSrchSTF.Checked;
end;

procedure TFrmTools.CBSrchSTPChange(Sender: TObject);
begin
F_STP := CBSrchSTP.Checked;
end;

procedure TFrmTools.CBStrPrescanClick(Sender: TObject);
begin
 StreamPrescan := CBStrPrescan.Checked;
end;

procedure TFrmTools.BTlCloseClick(Sender: TObject);
begin
Close;
end;

procedure TFrmTools.EMFolderEditingDone(Sender: TObject);
var
 s: string;
begin
 s := Trim(EMFolder.Text);
 if DirectoryExists(s) then
   FrmMain.DefaultDirectory := s;
end;

procedure TFrmTools.EVisPeriodEditingDone(Sender: TObject);
var
 i: integer;
begin
  try
    try
     i := StrToInt(Trim(EVisPeriod.Text));
    except
     exit;
    end;
   FrmMain.SetVisTimerPeriod(i);
  finally
   EVisPeriod.Text := IntToStr(VisTimerPeriod);
  end;

end;

procedure TFrmTools.LangCBExit(Sender: TObject);
begin
 if LangCB.Text = LangCB.Items[0] then
   FrmMain.Set_Language2('')
 else
   FrmMain.Set_Language2(LangCB.Text);
end;

function TFrmTools.CloseQuery: boolean;
begin
 Result := not FinderWorksNow;
 if Result then
  begin
   if ButTools.Is_On then ButTools.Switch_Off;
   ToolsY := Top;
   ToolsX := Left;
  end;
end;

procedure TFrmTools.RadioButton3Click(Sender: TObject);
begin
 if not RadioButton3.Checked then exit;
 {$IFDEF Windows}
 SetPriority(IDLE_PRIORITY_CLASS);
 {$ELSE Windows}
 NonWin;
 {$ENDIF Windows}
end;

procedure TFrmTools.RadioButton4Click(Sender: TObject);
begin
 if not RadioButton4.Checked then exit;
 {$IFDEF Windows}
 SetPriority(NORMAL_PRIORITY_CLASS);
 {$ELSE Windows}
 NonWin;
 {$ENDIF Windows}
end;

procedure TFrmTools.RadioButton5Click(Sender: TObject);
begin
 if not RadioButton5.Checked then exit;
 {$IFDEF Windows}
 SetPriority(HIGH_PRIORITY_CLASS);
 {$ELSE Windows}
 NonWin;
 {$ENDIF Windows}
end;

procedure TFrmTools.BTlUninstallClick(Sender: TObject);
var
 s: string;
begin
 Uninstall := True;
 DeleteOptions;
 DeleteDefaultPL; //todo: remove config folder
 s := '';
  try
   UnregisterApp(not CBRegAllUsers.Checked);
  except
   s := ' ' + Mes_ExcRegAdm;
  end;
 ShowMessage(Mes_AyEmulRemoved + s + '. ' + Mes_CloseBye);
end;

{$IFDEF Windows}
procedure StartMenuLink(ChangeIcon: boolean);
//todo: посмотреть, есть ли что-то кроссплатформенное
var
 AnObj: IUnknown;
 ShLink: IShellLinkW;
 PFile: IPersistFile;
 StartMenuDir, MyProgramPath, ShCutPath: WideString;
 Pidl: PItemIDList;
begin
 SetLength(StartMenuDir, MAX_PATH + 1);
 if (SHGetSpecialFolderLocation(FrmMain.Handle, CSIDL_PROGRAMS, Pidl) = NOERROR) and
   SHGetPathFromIDListW(Pidl, pwidechar(StartMenuDir)) then
  begin
   StartMenuDir := pwidechar(StartMenuDir);
   ShCutPath := StartMenuDir + '\AY Emulator.lnk';
   if not FileExists(ShCutPath) then
    begin
     if ChangeIcon then exit;
    end
   else
     DeleteFile(ShCutPath);
   MyProgramPath := UTF8Decode(GetProcessFileName);
   AnObj := CreateComObject(CLSID_ShellLink);
   ShLink := AnObj as IShellLinkW;
   PFile := AnObj as IPersistFile;
   ShLink.SetPath(pwidechar(MyProgramPath));
   ShLink.SetWorkingDirectory(pwidechar(ExtractFileDir(MyProgramPath)));
   ShLink.SetIconLocation(pwidechar(MyProgramPath), MenuIconNumber);
   PFile.Save(pwidechar(ShCutPath), False);
  end;
end;
{$ENDIF Windows}

procedure TFrmTools.SelectMenuIcon(n: integer);
begin
 if MenuIconNumber = n then exit;
 MenuIconNumber := n;
 {$IFDEF Windows}
 StartMenuLink(True);
 {$ENDIF Windows}
end;

procedure TFrmTools.Button10Click(Sender: TObject);
begin
 {$IFDEF Windows}
 StartMenuLink(False);
 {$ELSE Windows}
 NonWin;
 {$ENDIF Windows}
end;

procedure TFrmTools.Button11Click(Sender: TObject);
{$IFDEF Windows}
var
 Pidl: PItemIDList;
 StartMenuDir: WideString;
begin
 SetLength(StartMenuDir, MAX_PATH + 1);
 if (SHGetSpecialFolderLocation(FrmMain.Handle, CSIDL_PROGRAMS, Pidl) = NOERROR) and
   SHGetPathFromIDListW(Pidl, pwidechar(StartMenuDir)) then
  begin
   StartMenuDir := pwidechar(StartMenuDir) + '\AY Emulator.lnk';
   if FileExists(StartMenuDir) then
     DeleteFile(StartMenuDir);
  end;
 {$ELSE Windows}
begin
 NonWin;
 {$ENDIF Windows}
end;

procedure TFrmTools.RadioButton8Click(Sender: TObject);
begin
 if not RadioButton8.Checked then
  Exit;
 FrmMain.Set_TrayMode2(0);
end;

procedure TFrmTools.RadioButton9Click(Sender: TObject);
begin
 if not RadioButton9.Checked then
  Exit;
 FrmMain.Set_TrayMode2(1);
end;

procedure TFrmTools.RadioButton10Click(Sender: TObject);
begin
 if not RadioButton10.Checked then
  Exit;
 FrmMain.Set_TrayMode2(2);
end;

procedure TFrmTools.BChSkinClick(Sender: TObject);
var
 tmp: integer;
 s, s1, s2: string;
begin
 s := FrmMain.OpenDialog1.FileName;
 s1 := FrmMain.OpenDialog1.InitialDir;
 FrmMain.OpenDialog1.FileName := '';
 tmp := FrmMain.OpenDialog1.FilterIndex;
 FrmMain.OpenDialog1.FilterIndex := 1;
 FrmMain.OpenDialog1.Options := [OfHideReadOnly, OfEnableSizing];
 FrmMain.OpenDialog1.Filter := GetFilterString(GetFileType('AYS'));
 if FrmMain.SkinDirectory <> '' then
   FrmMain.OpenDialog1.InitialDir := FrmMain.SkinDirectory;
 if FrmMain.OpenDialog1.Execute then
  begin
   s2 := FrmMain.OpenDialog1.FileName;
   if FrmMain.LoadSkin(s2, False) then
     FrmMain.SkinDirectory := ExtractFileDir(s2);
  end;
 FrmMain.OpenDialog1.InitialDir := s1;
 FrmMain.OpenDialog1.FilterIndex := tmp;
 FrmMain.OpenDialog1.FileName := s;
 FrmMain.OpenDialog1.Options := [OfHideReadOnly, OfEnableSizing, OfAllowMultiSelect];
end;

procedure TFrmTools.BStdSkinClick(Sender: TObject);
begin
 if FrmMain.SkinFileName <> '' then
   FrmMain.LoadSkin('', False);
end;

procedure TFrmTools.CBAutoSaveMFldClick(Sender: TObject);
begin
 AutoSaveDefDir := CBAutoSaveMFld.Checked;
end;

procedure TFrmTools.BSaveMFldClick(Sender: TObject);
begin
 SaveDefaultDir3;
end;

procedure TFrmTools.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
 CloseAction := caFree;
 AppIcSel.Free;
 TrayIcSel.Free;
 StartIcSel.Free;
 MusIcSel.Free;
 SkinIcSel.Free;
 ListIcSel.Free;
 BASSIcSel.Free;
 FrmMain.MITools.Checked:=False;
end;

procedure TFrmTools.CreateIcSel(var IcSel: TIconSelector; AOwner: TWinControl;
 SelIconProc: TSelIconProc; x, y: integer; const IcName: string; IcNum: integer);
begin
 IcSel := TIconSelector.Create(AOwner);
 with IcSel do
  begin
   DoSelectIcon := SelIconProc;
   IcGrp.Top := y;
   IcGrp.Left := x;
   UpdateTranslation(IcName);
   IconUpDown.Position := IcNum;
   ShowIcon;
  end;
end;

procedure TFrmTools.CheckRegistration;
var
 AppRegistered: boolean;
 ProgIdRegistered: array[TFTCategory] of boolean;

 function IsFileExtAndProgID(const s: string; t: TFTCategory): boolean;
 begin
   Result := False;
   if not AppRegistered then exit;
   if not ProgIdRegistered[t] then exit;
   Result := IsFileExtAssoc(s, t);
 end;

 procedure Chk(t: TFTCategory; lb: TListBox);
 var
   i: integer;
 begin
   for i := 0 to lb.Count - 1 do
     lb.Selected[i] := IsFileExtAndProgID(lb.Items[i], t);
 end;

var
 fti: TFTCategory;
begin
 {$IFDEF Windows}
 AppRegistered := IsRegApp(GetProcessFileName);
 {$ELSE Windows}
 AppRegistered := False; //todo
 {$ENDIF Windows}
 if AppRegistered then
   for fti := Low(TFTCategory) to High(TFTCategory) do
     ProgIdRegistered[fti] := IsFileTypeReg(fti);
 Chk(TFTCAudio, LBTpMus);
 Chk(TFTCBASS, LBTpBASS);
 Chk(TFTCPlaylist, LBTpPL);
 Chk(TFTCSkin, LBTpSkin);
end;

procedure TFrmTools.FormCreate(Sender: TObject);
begin
 if ToolsX <> MaxInt then
  begin
   Top := ToolsY;
   Left := ToolsX;
   AdjustFormOnDesktop(Self);
  end
 else
   Position := poScreenCenter;

 CreateIcSel(StartIcSel, GenTools, @SelectMenuIcon, 9, 247, Tit_StartMenuIcon, MenuIconNumber);
 StartIcSel.IcGrp.AnchorSideLeft.Control := GBMenu;
 StartIcSel.IcGrp.AnchorSideLeft.Side := asrLeft;
 StartIcSel.IcGrp.AnchorSideTop.Control := GBMenu;
 StartIcSel.IcGrp.AnchorSideTop.Side := asrBottom;
 StartIcSel.IcGrp.BorderSpacing.Top := 2;
 StartIcSel.IcGrp.BorderSpacing.Bottom := 4;

 CreateIcSel(TrayIcSel, GenTools, @FrmMain.SelectTrayIcon, 111, 247,
   Tit_TrayIcon, TrayIconNumber);
 TrayIcSel.IcGrp.AnchorSideLeft.Control := StartIcSel.IcGrp;
 TrayIcSel.IcGrp.AnchorSideLeft.Side := asrRight;
 TrayIcSel.IcGrp.BorderSpacing.Left := 8;
 TrayIcSel.IcGrp.AnchorSideTop.Control := StartIcSel.IcGrp;
 TrayIcSel.IcGrp.AnchorSideTop.Side := asrTop;
 TrayIcSel.IcGrp.BorderSpacing.Bottom := 4;

 CreateIcSel(AppIcSel, GenTools, @FrmMain.SelectAppIcon, 213, 247, Tit_AppIcon, AppIconNumber);
 AppIcSel.IcGrp.AnchorSideLeft.Control := TrayIcSel.IcGrp;
 AppIcSel.IcGrp.AnchorSideLeft.Side := asrRight;
 AppIcSel.IcGrp.BorderSpacing.Left := 8;
 AppIcSel.IcGrp.AnchorSideTop.Control := TrayIcSel.IcGrp;
 AppIcSel.IcGrp.AnchorSideTop.Side := asrTop;
 AppIcSel.IcGrp.BorderSpacing.Bottom := 4;


 CreateIcSel(MusIcSel, FTypTools, @SelectMusIcon, LBTpMus.Left - 104, LBTpMus.Top,
   Tit_MusicIcon, MusIconNumber);
 MusIcSel.IcGrp.AnchorSideLeft.Control := BTpMus;
 MusIcSel.IcGrp.AnchorSideLeft.Side := asrCenter;
 MusIcSel.IcGrp.AnchorSideTop.Control := LBTpMus;
 MusIcSel.IcGrp.AnchorSideTop.Side := asrTop;
 MusIcSel.IcGrp.BorderSpacing.Bottom := 2;
 MusIcSel.IcGrp.BorderSpacing.Left := 4;

 CreateIcSel(SkinIcSel, FTypTools, @SelectSkinIcon, LBTpSkin.Left - 104,
   LBTpSkin.Top, Tit_SkinIcon, SkinIconNumber);
 SkinIcSel.IcGrp.AnchorSideLeft.Control := BTpSkin;
 SkinIcSel.IcGrp.AnchorSideLeft.Side := asrCenter;
 SkinIcSel.IcGrp.AnchorSideTop.Control := LBTpSkin;
 SkinIcSel.IcGrp.AnchorSideTop.Side := asrTop;
 SkinIcSel.IcGrp.BorderSpacing.Bottom := 2;

 CreateIcSel(ListIcSel, FTypTools, @SelectListIcon, LBTpPL.Left - 104,
   LBTpPL.Top, Tit_PlaylistIcon, ListIconNumber);
 ListIcSel.IcGrp.AnchorSideLeft.Control := BTpPL;
 ListIcSel.IcGrp.AnchorSideLeft.Side := asrCenter;
 ListIcSel.IcGrp.AnchorSideTop.Control := LBTpPL;
 ListIcSel.IcGrp.AnchorSideTop.Side := asrTop;
 ListIcSel.IcGrp.BorderSpacing.Bottom := 2;

 CreateIcSel(BASSIcSel, FTypTools, @SelectBASSIcon, LBTpBASS.Left - 104,
   LBTpBASS.Top, Tit_BASSIcon, BASSIconNumber);
 BASSIcSel.IcGrp.AnchorSideLeft.Control := BTpBASS;
 BASSIcSel.IcGrp.AnchorSideLeft.Side := asrCenter;
 BASSIcSel.IcGrp.AnchorSideTop.Control := LBTpBASS;
 BASSIcSel.IcGrp.AnchorSideTop.Side := asrTop;
 BASSIcSel.IcGrp.BorderSpacing.Top := 2;

 LBTpMus.ControlStyle := LBTpMus.ControlStyle - [csDoubleClicks];
 LBTpBASS.ControlStyle := LBTpBASS.ControlStyle - [csDoubleClicks];
 LBTpPL.ControlStyle := LBTpPL.ControlStyle - [csDoubleClicks];
 LBTpSkin.ControlStyle := LBTpSkin.ControlStyle - [csDoubleClicks];

 GetFNExtsCat(LBTpMus.Items, LBTpBASS.Items, LBTpPL.Items, LBTpSkin.Items);

  try
   CheckRegistration;
  except
  end;

 EditVTPath.Text := VTPath;
 ESkinAuth.Text := FrmMain.SkinAuthor;
 ESkinCom.Text := FrmMain.SkinComment;
 ESkinFN.Text := FrmMain.SkinFileName;
 EMFolder.Text := FrmMain.DefaultDirectory;
 CBAutoSaveMFld.Checked := AutoSaveDefDir;
 CheckBox40.Checked := AutoSaveWindowsPos;
 CBForceLoop.Checked := Force_Loop;
 CBStrPrescan.Checked := StreamPrescan;
 CBDoubleSz.Checked := Scale <> 1;
 DESrchWrkFld.Directory := IncludeTrailingPathDelimiter(FrmMain.OpenDialog1.InitialDir) +
   'AYFinderTmp';
 {$IFDEF Windows}
 case Priority of
   IDLE_PRIORITY_CLASS: RadioButton3.Checked := True;
   NORMAL_PRIORITY_CLASS: RadioButton4.Checked := True;
   HIGH_PRIORITY_CLASS: RadioButton5.Checked := True;
  end;
 {$ENDIF Windows}
 case TrayMode of
   0: RadioButton8.Checked := True;
   1: RadioButton9.Checked := True;
   2: RadioButton10.Checked := True;
  end;
 CBDescEn.Checked := FIDO_Descriptor_Enabled;
 CBDescKNoth.Checked := FIDO_Descriptor_KillOnNothing;
 CBDescKExit.Checked := FIDO_Descriptor_KillOnExit;
 EDeskPfx.Text := FIDO_Descriptor_Prefix;
 EDeskSfx.Text := FIDO_Descriptor_Suffix;
 EDeskNoth.Text := FIDO_Descriptor_Nothing;
 EDeskFN.Text := FIDO_Descriptor_Filename;
 Label1.Color := PLColorBk;
 Label1.Font.Color := PLColor;
 Label12.Color := PLColorBk;
 Label12.Font.Color := PLColor;
 Label13.Color := PLColorBkSel;
 Label13.Font.Color := PLColorSel;
 Label14.Color := PLColorBkSel;
 Label14.Font.Color := PLColorSel;
 Label15.Color := PLColorBkPl;
 Label15.Font.Color := PLColorPl;
 Label16.Color := PLColorBkPl;
 Label16.Font.Color := PLColorPl;
 Label17.Color := PLColorBkSel;
 Label17.Font.Color := PLColorPlSel;
 Label18.Color := PLColorBk;
 Label18.Font.Color := PLColorErr;
 Label19.Color := PLColorBkSel;
 Label19.Font.Color := PLColorErrSel;

 EVisPeriod.Text := IntToStr(VisTimerPeriod);

 GetSupportedEncodings(CBDefCP.Items);
 CBDefCP.Text := CodePageDef;

 GetSupportedEncodings(CBDescCP.Items);
 CBDescCP.Text := FIDO_Descriptor_Enc;

 CBSrchSTF.Checked := F_STF;
 CBSrchST1.Checked := F_ST1;
 CBSrchSTC.Checked := F_STC;
 CBSrchST3.Checked := F_ST3;
 CBSrchASC0.Checked := F_ASM0;
 CBSrchASC.Checked := F_ASM1;
 CBSrchSTP.Checked := F_STP;
 CBSrchPSC.Checked := F_PSC;
 CBSrchFLS.Checked := F_FLS;
 CBSrchSQT.Checked := F_SQT;
 CBSrchPT1.Checked := F_PT1;
 CBSrchPT2.Checked := F_PT2;
 CBSrchPT3.Checked := F_PT3;
 CBSrchFTC.Checked := F_FTC;
 CBSrchGTR.Checked := F_GTR;
 CBSrchNotCheck.Checked := not IntegrityCheck;

 LoadLanguages;

 FrmMain.MITools.Checked:=True;
end;

procedure TFrmTools.CheckBox40Click(Sender: TObject);
begin
 AutoSaveWindowsPos := CheckBox40.Checked;
end;

procedure TFrmTools.Button16Click(Sender: TObject);
begin
 with FrmMain do
  begin
   FIDO_Descriptor_Enabled := CBDescEn.Checked;
   FIDO_Descriptor_KillOnNothing := CBDescKNoth.Checked;
   FIDO_Descriptor_KillOnExit := CBDescKExit.Checked;
   FIDO_Descriptor_Enc := CBDescCP.Text;
   FIDO_Descriptor_Prefix := EDeskPfx.Text;
   FIDO_Descriptor_Suffix := EDeskSfx.Text;
   FIDO_Descriptor_Nothing := EDeskNoth.Text;
   FIDO_Descriptor_Filename := EDeskFN.Text;
   FIDO_Descriptor_String := '';
   if IsPlaying and not Paused then
     FIDO_SaveStatus(FIDO_Playing)
   else
     FIDO_SaveStatus(FIDO_Nothing);
  end;
end;

procedure TIconSelector.ShowIcon;
var
 icon: TIcon;
begin
 icon := TIcon.Create;
 icon.LoadFromResourceName(hInstance, Format('ICON%.2u', [IconUpDown.Position]));

 IcImg.Canvas.FillRect(IcImg.ClientRect);
 IcImg.Canvas.Draw(0, 0, icon);

 AuthName.Caption := IconAuthors[IconUpDown.Position];

 icon.Free;
end;

procedure TIconSelector.IconUpDownClick(Sender: TObject; Button: TUDBtnType);
begin
 ShowIcon;
 DoSelectIcon(IconUpDown.Position);
end;

procedure TIconSelector.UpdateTranslation(const Cap: string);
begin
 IcGrp.Caption := Tit_Icon;
 AuthLB.Caption := Tit_Author;
 TitLB.Caption := Cap;
end;

constructor TIconSelector.Create(AOwner: TWinControl);
begin
 inherited Create;
 IcGrp := TGroupBox.Create(AOwner);
 IcGrp.Width := 97;
 IcGrp.Height := 81 + 16 + 2;
 IcImg := TImage.Create(IcGrp);
 IcImg.Parent := IcGrp;
 IcImg.Width := 32;
 IcImg.Height := 32;
 IcImg.Top := 1 + 16;
 IcImg.Left := 24;
 IconUpDown := TUpDown.Create(IcGrp);
 IconUpDown.Parent := IcGrp;
 IconUpDown.Height := 32;
 IconUpDown.Top := 1 + 16;
 IconUpDown.Left := 56;
 IconUpDown.Max := NOfIcons;
 IconUpDown.OnClick := @IconUpDownClick;
 TitLB := TLabel.Create(IcGrp);
 TitLB.Parent := IcGrp;
 TitLB.AutoSize := False;
 TitLB.Alignment := taCenter;
 TitLB.Left := 1;
 TitLB.Top := 1;
 TitLB.Width := IcGrp.Width - 5;
 AuthLB := TLabel.Create(IcGrp);
 AuthLB.Parent := IcGrp;
 AuthLB.AutoSize := False;
 AuthLB.Alignment := taCenter;
 AuthLB.Left := 1;
 AuthLB.Top := 33 + 16;
 AuthLB.Width := IcGrp.Width - 5;
 AuthName := TLabel.Create(IcGrp);
 AuthName.Parent := IcGrp;
 AuthName.Alignment := taCenter;
 AuthName.AutoSize := False;
 AuthName.Left := 1;
 AuthName.Top := 49 + 16;
 AuthName.Width := IcGrp.Width - 5;
 IcGrp.Parent := AOwner;
end;

destructor TIconSelector.Destroy;
begin
  try
   TitLB.Free;
   AuthName.Free;
   AuthLB.Free;
   IconUpDown.Free;
   IcImg.Free;
   IcGrp.Free;
  finally
   inherited;
  end;
end;

procedure TFrmTools.UpdateTranslation;
begin
 AppIcSel.UpdateTranslation(Tit_AppIcon);
 TrayIcSel.UpdateTranslation(Tit_TrayIcon);
 StartIcSel.UpdateTranslation(Tit_StartMenuIcon);
 MusIcSel.UpdateTranslation(Tit_MusicIcon);
 SkinIcSel.UpdateTranslation(Tit_SkinIcon);
 ListIcSel.UpdateTranslation(Tit_PlaylistIcon);
 BASSIcSel.UpdateTranslation(Tit_BASSIcon);
end;

{$ifdef Windows}
procedure TFrmTools.RegisterGroup(t: TFTCategory; lb: TListBox);
var
 i: integer;
begin
 FileTypeReg(not CBRegAllUsers.Checked, t);
 for i := 0 to lb.Count - 1 do
   FileExtAssoc(not CBRegAllUsers.Checked, lb.Items[i], t, lb.Selected[i]);
end;
{$endif Windows}

procedure TFrmTools.BAppRegClick(Sender: TObject);
begin
 Screen.Cursor := crHourGlass;
  try
   {$ifndef Windows}
   WriteIconsAsPNG(not CBRegAllUsers.Checked);
   MimeTypesReg(not CBRegAllUsers.Checked);
   {$endif Windows}
   AppReg(not CBRegAllUsers.Checked);
   {$ifdef Windows}
   RegisterGroup(TFTCAudio, LBTpMus);
   RegisterGroup(TFTCBASS, LBTpBASS);
   RegisterGroup(TFTCPlaylist, LBTpPL);
   RegisterGroup(TFTCSkin, LBTpSkin);
   AssocChanged;
   {$endif Windows}
  finally
   Screen.Cursor := crDefault;
  end;
 CheckRegistration;
end;

procedure TFrmTools.BAppUnregClick(Sender: TObject);
begin
 Screen.Cursor := crHourGlass;
  try
   UnregisterApp(not CBRegAllUsers.Checked);
   {$ifndef Windows}
   DeleteMimeTypes(not CBRegAllUsers.Checked);
   DeleteIcons(not CBRegAllUsers.Checked);
   {$endif Windows}
  finally
   Screen.Cursor := crDefault;
  end;
 CheckRegistration;
end;

procedure TFrmTools.SelectMusIcon(n: integer);
begin
 if MusIconNumber <> n then
   MusIconNumber := n;
end;

procedure TFrmTools.SelectSkinIcon(n: integer);
begin
 if SkinIconNumber <> n then
   SkinIconNumber := n;
end;

procedure TFrmTools.SelectListIcon(n: integer);
begin
 if ListIconNumber <> n then
   ListIconNumber := n;
end;

procedure TFrmTools.SelectBASSIcon(n: integer);
begin
 if BASSIconNumber <> n then
   BASSIconNumber := n;
end;

function TFrmTools.ChangePLColor(var WantedColor: TColor): boolean;
begin
 ColorDialog1.Color := WantedColor;
 Result := ColorDialog1.Execute;
 if Result then
  begin
   WantedColor := ColorDialog1.Color;
   RedrawPlaylist(ShownFrom, False);
  end;
end;

procedure TFrmTools.Label1Click(Sender: TObject);
begin
 if ChangePLColor(PLColor) then
  begin
   Label1.Font.Color := PLColor;
   Label12.Font.Color := PLColor;
  end;
end;

procedure TFrmTools.Label12Click(Sender: TObject);
begin
 if ChangePLColor(PLColorBk) then
  begin
   Label1.Color := PLColorBk;
   Label12.Color := PLColorBk;
   Label18.Color := PLColorBk;
  end;
end;

procedure TFrmTools.Label13Click(Sender: TObject);
begin
 if ChangePLColor(PLColorSel) then
  begin
   Label13.Font.Color := PLColorSel;
   Label14.Font.Color := PLColorSel;
  end;
end;

procedure TFrmTools.Label14Click(Sender: TObject);
begin
 if ChangePLColor(PLColorBkSel) then
  begin
   Label13.Color := PLColorBkSel;
   Label14.Color := PLColorBkSel;
   Label17.Color := PLColorBkSel;
   Label19.Color := PLColorBkSel;
  end;
end;

procedure TFrmTools.Label15Click(Sender: TObject);
begin
 if ChangePLColor(PLColorPl) then
  begin
   Label15.Font.Color := PLColorPl;
   Label16.Font.Color := PLColorPl;
  end;
end;

procedure TFrmTools.Label16Click(Sender: TObject);
begin
 if ChangePLColor(PLColorBkPl) then
  begin
   Label15.Color := PLColorBkPl;
   Label16.Color := PLColorBkPl;
  end;
end;

procedure TFrmTools.Label17Click(Sender: TObject);
begin
 if ChangePLColor(PLColorPlSel) then Label17.Font.Color := PLColorPlSel;
end;

procedure TFrmTools.Label18Click(Sender: TObject);
begin
 if ChangePLColor(PLColorErr) then Label18.Font.Color := PLColorErr;
end;

procedure TFrmTools.Label19Click(Sender: TObject);
begin
 if ChangePLColor(PLColorErrSel) then Label19.Font.Color := PLColorErrSel;
end;

procedure TFrmTools.BTpMusClick(Sender: TObject);
var
 lb: TListBox;
 i: integer;
begin
 case (Sender as TButton).Tag of
   0: lb := LBTpMus;
   1: lb := LBTpBASS;
   2: lb := LBTpPL;
   3: lb := LBTpSkin;
 else
   exit;
  end;
 if lb.SelCount < lb.Count then
   lb.SelectAll
 else
   for i := 0 to lb.Count - 1 do
     lb.Selected[i] := False;
end;

procedure TFrmTools.EditVTPathChange(Sender: TObject);
begin
 VTPath := EditVTPath.Text;
end;

procedure TFrmTools.SpeedButton1Click(Sender: TObject);
begin
 FontDialog1.Font := PLArea.Font;
 if FontDialog1.Execute then
  PLArea.Font := FontDialog1.Font;
end;

procedure TFrmTools.LoadLanguages;
var
 SearchRec: TSearchRec;
 i, j: integer;
 Dir, s: string;
 unique: boolean;
begin
 LangCB.Clear;
 LangCB.Items.Append('auto/en');
 LangCB.Items.Append('en');
 Dir := IncludeTrailingBackslash(ExtractFilePath(GetProcessFileName)) +
   'languages' + DirectorySeparator;
 if not DirectoryExists(Dir, False{todo: fpc bug: FP can't expand relative links}) then
   Exit;
 i := FindFirst(Dir + '*.po', faAnyFile, SearchRec);
 while i = 0 do
  begin
   if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
     if SearchRec.Attr and faDirectory = 0 then
       if SearchRec.Size > 0 then
        begin
         i := Length(SearchRec.Name) - 3;
         s := Copy(SearchRec.Name, 1, i);
         while (i > 0) and (s[i] <> '.') do
           Dec(i);
         if i > 0 then
          begin
           s := Copy(s, i + 1, Length(s));
           unique := True;
           for j := 1 to LangCB.Items.Count - 1 do
             if LangCB.Items[j] = s then
              begin
               unique := False;
               break;
              end;
           if unique then
             LangCB.Items.Append(s);
          end;
        end;
   i := FindNext(SearchRec);
  end;
 FindClose(SearchRec);
 if Lang = '' then
   LangCB.ItemIndex := 0
 else
   LangCB.Text := Lang;
end;

end.
