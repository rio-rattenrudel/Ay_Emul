{
This is part of AY Emulator project
AY-3-8910/12 Emulator
Version 3.0 for Windows and Linux
Author Sergey Vladimirovich Bulba
(c)1999-2025 S.V.Bulba
}

unit MainWin;

{$mode objfpc}{$H+}

interface

uses
 LCLIntf, LCLType,
 {$IFDEF Windows}
 Windows, MMSystem,
 {$ELSE Windows}
 LMessages,
 {$ENDIF Windows}
 {$IFDEF dbgmode}
 typinfo,
 {$ENDIF dbgmode}
 digsound, digsoundcode, mixerctl, SysUtils, LazFileUtils, Classes, Graphics,
 Controls, Forms, Dialogs, About, LH5, UniReader, AY, WinVersion, Languages,
 lazutf8, ExtCtrls, Menus, LConvEncoding;

const
 //User defined windows messages
 WM_PLAYNEXTITEM = WM_USER + 1;
 WM_PLAYERROR = WM_USER + 2;
 WM_FINALIZEWO = WM_USER + 5;
 WM_HIDEMINIMIZE = WM_USER + 6;
 WM_BASSMETADATA = WM_USER + 9;
 WM_VOLUMECHANGED = WM_USER + 10;

 //Metrics of some controls
 //Main window
 MWWidth = 358;
 MWHeight = 123;

 //Spectrum analizer
 spa_num = 91 - 26 - 2;
 spa_width = spa_num + 2;
 spa_height = 20;
 spa_x = 26;
 spa_y = 34;

 //Amplitude analizer
 amp_width = 17;
 amp_height = 15;
 amp_x = 50;
 amp_y = 18;

 max_width2 = spa_width;
 max_height2 = spa_height;

 //Scrolling title
 scr_lineheight = 24;
 scr_x = 108;
 scr_y = 48;
 scr_width = 197;
 scr_height = 24;

 //Time label
 time_x = 24;
 time_y = 65;
 time_width = 93 - 24;
 time_height = 20 + 4;
 time_fontheight = {$ifdef windows}21{$else}19{$endif};
 time_fontheightsmall = {$ifdef windows}15{$else}13{$endif};

 max_height = scr_height;

 //Offsets of background bitmaps for controls
 spa_src = 0;
 amp_src = spa_width;
 time_src = spa_width + amp_width;
 scr_src = spa_width + amp_width + time_width;
 max_src = scr_src + scr_width;

 //Skin 2.0 identificator
 SkinId: string = 'Ay_Emul 2.0 Skin File'#13#10#26;
 SkinIdLen = 24;

 VTPath: string = 'VT.exe';

 Zero: integer = 0; //:-)

type

 EMultiMediaError = class(Exception);

 //Spectrum analizer values
 TSpa = array[0..spa_num - 1] of integer;
 PSpa = ^TSpa;

 //Own sens object
 PSensZone = ^TSensZone;

 TSensZone = class(TObject)
   constructor Create(ps: PSensZone; x, y, w, h: integer; pr: TNotifyEvent);
   function Touche(x, y: integer): boolean;
 public
   Next: PSensZone;
   zx, zy, zw, zh: integer;
   Clicked: boolean;
   Action: TNotifyEvent;
 end;

 //Own button object
 PButtZone = ^TButtZone;

 TButtZone = class(TObject)
   constructor Create(ps: PButtZone; x, y, w, h: integer; Bmp: TBitmap;
     x1, y1, x2, y2: integer; pr: TNotifyEvent);
   procedure Free;
   function Touche(x, y: integer): boolean;
   procedure Push;
   procedure UnPush;
   procedure Switch_On;
   procedure Switch_Off;
   procedure Redraw(OnCanvas: boolean);
 public
   Next: PButtZone;
   zx, zy, zw, zh: integer;
   RgnHandle: HRGN;
   Clicked: integer;
   Is_On, Is_Pushed: boolean;
   Bmp1, Bmp2: TBitmap;
   Action: TNotifyEvent;
 end;

 //Own led object
 PLedZone = ^TLedZone;

 TLedZone = class(TObject)
   constructor Create(ps: PLedZone; x, y, w, h: integer; Bmp: TBitmap;
     x1, y1, x2, y2: integer);
   procedure Free;
   procedure Redraw(OnCanvas: boolean);
 public
   Next: PLedZone;
   zx, zy, zw, zh: integer;
   State: boolean;
   Bmp1, Bmp2: TBitmap;
 end;

 //Own mouse moving object
 PMoveZone = ^TMoveZone;

 TMoveZone = class(TObject)
   constructor Create(ps: PMoveZone; x, y, w, h, y1, h1: integer; pr: TNotifyEvent);
   procedure Free;
   function Touche(x, y: integer): boolean;
   function ToucheBut(x, y: integer): boolean;
   procedure AddBitmaps(Bmp: TBitmap; x1, y1, bw, bh: integer; m: boolean);
   procedure Redraw(OnCanvas: boolean);
   procedure HideBmp;
 public
   Next: PMoveZone;
   zx, zy, zw, zh, zy1, zh1, Delt, OldX, OldY, PosX, PosY, bm1h, bm1w: integer;
   RgnHandle: HRGN;
   Clicked, State, Bmps: boolean;
   Bmp1, Bmp2: TBitmap;
   Action: TNotifyEvent;
 end;

 FIDO_Status = (FIDO_Nothing, FIDO_Playing, FIDO_Exit);

 //Main window form

 { TFrmMain }

 TFrmMain = class(TForm)
   MIClose: TMenuItem;
   MIMinRes: TMenuItem;
   MIPlaylist: TMenuItem;
   MITools: TMenuItem;
   MIMixer: TMenuItem;
   MIOpenCD: TMenuItem;
   MIOpenFolder: TMenuItem;
   MIOpenFiles: TMenuItem;
   MIOpen: TMenuItem;
   MIRandom: TMenuItem;
   MINext: TMenuItem;
   MIPrevious: TMenuItem;
   MIStop: TMenuItem;
   MIRestart: TMenuItem;
   MIPlayPause: TMenuItem;
   OpenDialog1: TOpenDialog;
   PopupMenu1: TPopupMenu;
   SaveDialog1: TSaveDialog;
   Separator1: TMenuItem;
   Separator2: TMenuItem;
   Separator3: TMenuItem;
   Separator4: TMenuItem;
   TrayIcon1: TTrayIcon;
   procedure ButOpenClick(Sender: TObject);
   procedure DoMovingWindow(Sender: TObject);
   procedure DoMovingVol(Sender: TObject);
   procedure DoMovingProgr(Sender: TObject);
   procedure DoMovingScroll(Sender: TObject);
   procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
   procedure FormDeactivate(Sender: TObject);
   procedure FormDestroy(Sender: TObject);
   procedure FormDropFiles(Sender: TObject; const FileNames: array of string);
   procedure FormPaint(Sender: TObject);
   procedure MICloseClick(Sender: TObject);
   procedure MIMinResClick(Sender: TObject);
   procedure MIMixerClick(Sender: TObject);
   procedure MINextClick(Sender: TObject);
   procedure MIOpenCDClick(Sender: TObject);
   procedure MIOpenFilesClick(Sender: TObject);
   procedure MIOpenFolderClick(Sender: TObject);
   procedure MIPlaylistClick(Sender: TObject);
   procedure MIPlayPauseClick(Sender: TObject);
   procedure MIPreviousClick(Sender: TObject);
   procedure MIRandomClick(Sender: TObject);
   procedure MIRestartClick(Sender: TObject);
   procedure MIStopClick(Sender: TObject);
   procedure MIToolsClick(Sender: TObject);
   procedure PlayClick(Sender: TObject);
   procedure PopupMenu1Popup(Sender: TObject);
   procedure SetDefault;
   procedure ButPauseClick(Sender: TObject);
   procedure ButStopClick(Sender: TObject);
   procedure CommandLineInterpreter(CL: string; Start: boolean);
   procedure TrayIcon1DblClick(Sender: TObject);
   procedure TrayIcon1MouseDown(Sender: TObject; Button: TMouseButton;
     Shift: TShiftState; X, Y: integer);
   procedure TrayIcon1MouseUp(Sender: TObject; Button: TMouseButton;
     Shift: TShiftState; X, Y: integer);
   procedure WMPLAYNEXTITEM(var Msg: TMsg); message WM_PLAYNEXTITEM;
   procedure WMBASSMETADATA(var Msg: TMsg); message WM_BASSMETADATA;
   procedure WMPLAYERROR(var Msg: TMsg); message WM_PLAYERROR;
   procedure IPCMessage(Sender: TObject);
   procedure WMFINALIZEWO(var Msg: TMsg); message WM_FINALIZEWO;
   procedure HideMinimize(var Msg: TMsg); message WM_HIDEMINIMIZE;
   procedure WMVOLUMECHANGED(var Msg: TMsg); message WM_VOLUMECHANGED;
   procedure DoMinimize;
   procedure DoRestore;
   procedure DoVisualisation;
   procedure Set_Chip_Frq(Fr: integer);
   procedure Set_Player_Frq(Fr: integer);
   procedure ButMixerClick(Sender: TObject);
   procedure ButMinClick(Sender: TObject);
   procedure ButCloseClick(Sender: TObject);
   procedure ButAboutClick(Sender: TObject);
   procedure ButAmpClick(Sender: TObject);
   procedure ButTimeClick(Sender: TObject);
   procedure ButSpaClick(Sender: TObject);
   procedure ShowAllParams;
   procedure RestoreAllParams;
   procedure ButListClick(Sender: TObject);
   procedure ButNextClick(Sender: TObject);
   procedure ButPrevClick(Sender: TObject);
   procedure CalcModeCoefs(Mode: integer; ChType: ChTypes; TS, DMA: boolean;
     out Index_AL, Index_AR, Index_BL, Index_BR, Index_CL, Index_CR,
     BeeperMax, Atari_DMAMax: byte);
   procedure Set_Mode(Mode: integer);
   procedure Set_Mode_Manual(AL, AR, BL, BR, CL, CR: byte);
   procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
     Shift: TShiftState; X, Y: integer);
   procedure ButToolsClick(Sender: TObject);
   procedure ButLoopClick(Sender: TObject);
   procedure Set_Z80_Frq(NewF: integer);
   procedure Set_MC68K_Frq(NewF: integer);
   procedure Set_N_Tact(NewF: integer);
   procedure CommandLineAndRegCheck;
   procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: integer);
   procedure FormMouseUp(Sender: TObject; Button: TMouseButton;
     Shift: TShiftState; X, Y: integer);
   {$IFNDEF Windows}
   procedure CheckMin(Data: PtrInt);
   {$ENDIF Windows}
   procedure AppRestored(Sender: TObject);
   procedure AppMinimized(Sender: TObject);
   procedure AppModalBegin(Sender: TObject);
   procedure AppModalEnd(Sender: TObject);
   procedure AppEndSession(Sender: TObject);

   //create main form regions
   procedure PrepareRgn;

   //prepare regions and clue it to objects
   procedure RecreateRgn;

   procedure FormCreate(Sender: TObject);
   procedure FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
   procedure FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
   procedure RemoveTrayIcon;
   function AddTrayIcon:boolean;
   function LoadSkin(FName: string; First: boolean): boolean;
   procedure SetMainBmp(p: pointer; size: integer);
   procedure BmpFree;
   procedure CopyBmpSources;
   procedure Set_MFP_Frq(Md, Fr: integer);
   procedure ShowApp(Tray: boolean);
   procedure FIDO_SaveStatus(Status: FIDO_Status);
   procedure JumpToTime;
   procedure CallHelp;
   procedure VolUp;
   procedure VolDown;
   procedure FormMouseWheelDown(Sender: TObject; Shift: TShiftState;
     MousePos: TPoint; var Handled: boolean);
   procedure FormMouseWheelUp(Sender: TObject; Shift: TShiftState;
     MousePos: TPoint; var Handled: boolean);
   procedure SaveParams;
   procedure SetVisTimerPeriod(VTP: integer);
   procedure Set_Sample_Rate2(SR: integer);
   procedure Set_Sample_Bit2(SB: integer);
   procedure Set_Stereo2(St: integer);
   procedure SetBuffers(len, num: integer);
   procedure Set_WODevice2(WOD: integer; NM: string);
   {$IFDEF Windows}
   procedure Set_MIDIDevice2(MD: integer; NM: string);
   {$ENDIF Windows}
   procedure Set_BufLen_ms2(BL: integer);
   procedure Set_NumberOfBuffers2(NB: integer);
   procedure Set_Chip2(Ch: ChTypes);
   procedure Set_Z80_Frq2(NewF: integer);
   procedure Set_MC68K_Frq2(NewF: integer);
   procedure Set_Chip_Frq2(Fr: integer);
   procedure Set_Player_Frq2(Fr: integer);
   procedure Set_IntOffset2(InO: integer);
   procedure Set_N_Tact2(NT: integer);
   procedure Set_N_TactS(t: string);
   procedure Set_Language2(const aLang: string);
   function Get_Language: string;
   procedure Set_Loop2(Lp: boolean);
   procedure Set_ForceLoop2(Lp: boolean);
   procedure Set_StreamPrescan2(Prescan: boolean);
   procedure Set_TrayMode2(TM: integer);
   procedure Set_MFP_Frq2(Md, Fr: integer);
   procedure SetAutoSaveDefDir2(ASD: boolean);
   procedure SetAutoSaveWindowsPos2(ASW: boolean);
   procedure SetAutoSaveVolumePos2(ASV: boolean);
   procedure SetChan2(u, i: integer);
   procedure SetFilter(FQ: integer);
   procedure SetFilter2(FQ: integer);
   procedure CalcFiltKoefs;
   procedure SaveAllParams;
   procedure DoDestroyActions;
   procedure DoCloseActions;
   procedure SelectTrayIcon(n: integer);
   procedure SelectAppIcon(n: integer);
   {$IFDEF Windows}
   procedure SetPriority2(NP: DWORD);
   {$ENDIF Windows}
   procedure VisTimerEvent(Sender: TObject);
   procedure Ay_Emul_ShowExceptionA(Sender: TObject; E: Exception);
 private
   { Private declarations }
   //Set window region from application's queue
   procedure SetRgn(Data: PtrInt);
 public
   { Public declarations }
   SkinFileName, SkinAuthor, SkinComment: string;
   DefaultDirectory, SkinDirectory: string;
   LastTimeComLine: QWORD;
 end;

function DivMul(q1, q2, q3: int64): dword;

procedure PlayCurrent;
procedure StopAndFreeAll;
procedure StopPlaying;
procedure RestoreControls;

procedure AYVisualisation(smp: DWORD);

procedure RedrawVisChannels(ca, cb, cc, mh: integer);
procedure RedrawVisSpectrum(CP: PVisPoint; MaxVal: integer);

procedure ShowProgress(a1: integer);

procedure Set_Sample_Rate(SR: integer);
procedure Set_Sample_Bit(SB: integer);
procedure Set_Stereo(St: integer);

procedure Calculate_Level_Tables2;

procedure Rewind(newpos, maxpos: integer);

procedure SetScrollString(const scrstr: string);
procedure ReprepareScroll;

procedure GetSysVolume(Notified:boolean=False);
procedure SetSysVolume;
procedure RedrawVolume;

procedure Ay_Emul_ShowException(Msg: shortstring);

procedure SetCommandLine(clstr: string);

procedure AdjustFormOnDesktop(Frm: TForm);

procedure LongProcessPrepare(SetMainFocused: boolean = True);
procedure LongProcessDone;

var
 FrmMain: TFrmMain;

 MFPTimerFrq, MFPTimerMode: integer;

 VisTimer: TTimer;
 VisTimerPeriod: integer = 30;

 Spa_points: array[0..spa_num] of integer;
 Spa_piks, Spa_prev: TSpa;
 PSpa_Piks, PSpa_prev: PSpa;

 Scr_Left: boolean = False;
 ScrFlg: boolean = True;
 Scr_Pause: integer = 1;
 Scroll_Distination: integer = -1;
 Item_Displayed: integer = -1;
 HorScrl_Offset: integer = 0;
 Scroll_Offset: integer = scr_lineheight;
 ClearTimeInd: boolean;
 TimeMode: integer = 0;
 CurrTime_Rasch: integer;
 BaseSample: DWORD;

 BMP_Sources, BMP_Time, BMP_Vis: TBitmap;
 BMP_VScroll, BMP_Scroll: TBitmap;

 BMP_DBuffer: TBitmap;

 VProgrPos: integer;
 ProgrMax, ProgrPos: longword;
 ProgrWidth: word;

 OUTZXAYConv_TotalTime: integer;

 //0 - don't skip frames, >0 - number of frames to skip, <0 - end of music
 PSG_Skip: integer;

 May_Quit, May_Quit2: boolean;
 Do_Scroll: boolean = True;
 Time_ms: integer = 0;
 TimeShown: integer = -MaxInt;

 ButPlay, ButNext, ButPrev, ButOpen, ButStop, ButPause, ButAbout,
 ButLoop, ButMixer, ButTools, ButList, ButMinimize, ButClose: TButtZone;
 SensSpa, SensAmp, SensTime: TSensZone;
 MoveWin, MoveVol, MoveProgr, MoveScr: TMoveZone;
 Led_AY, Led_YM, Led_Stereo: TLedZone;
 MyFormRgn: HRGN = 0;
 RgnClose, RgnMin, RgnMixer, RgnTools, RgnPList, RgnLoop, RgnBack,
 RgnPlay, RgnNext, RgnStop, RgnPause, RgnOpen, RgnVol, RgnProgr: HRGN;

 Scale: integer = 1;

 IndicatorChecked: boolean = True;
 SpectrumChecked: boolean = True;
 AutoSaveDefDir: boolean = True;

 //Tray Icon Data
 TrayMode: integer = 0;
 TrayIconNumber: integer = 11;
 TrayIconClicked: boolean = False;

 AddFolderRecurseDirs: boolean = True;
 AddFolderDoDetect: boolean = False;

 //0 - добавлять, 1 - пропускать, 2 - добавлять только плейлисты
 AddFolderPlaylists: integer = 0;

 //преобразовывать полный путь в имя файла в групповых операциях
 PathBasedFileName: boolean = False;

 AppIsModal: boolean = False;

 MenuIconNumber: integer = 0;
 AppIconNumber: integer = 0;
 MusIconNumber: integer = 10;
 SkinIconNumber: integer = 3;
 ListIconNumber: integer = 2;
 BASSIconNumber: integer = 4;

 FIDO_Descriptor_Enabled: boolean = False;
 FIDO_Descriptor_Enc: string =
 {$IFDEF Windows}'Ansi'{$ELSE Windows}'UTF-8'{$ENDIF Windows};
 FIDO_Descriptor_KillOnNothing: boolean = False;
 FIDO_Descriptor_KillOnExit: boolean = True;
 FIDO_Descriptor_Prefix: string = '... Ay_Emul: ';
 FIDO_Descriptor_Suffix: string = '';
 FIDO_Descriptor_Nothing: string = Mes_NoSongPlaying;
 FIDO_Descriptor_Filename: string;
 FIDO_Descriptor_String: string = '';

 ToolsX: integer = MaxInt;
 ToolsY: integer;
 AutoSaveWindowsPos: boolean = True;
 AutoSaveVolumePos: boolean = False;
 SkipVolNotify: integer = 0;
 Uninstall: boolean = False;

const
 ButtZoneRoot: PButtZone = nil;
 SensZoneRoot: PSensZone = nil;
 MoveZoneRoot: PMoveZone = nil;
 LedZoneRoot: PLedZone = nil;
 CLFast = 800;
 InitialScan: boolean = False;

var
 AfterScan: array of string;

 IsPlaying: boolean = False;
 Paused: boolean;
 NOfTicks: DWORD;

implementation

uses Mixer, PlayList, Tools, Z80, JmpTime, Players, Options,
 basslight, basscode, basstags, ProgBox
 {$IFDEF Windows}
 , CDviaMCI, Midi
 {$ENDIF Windows}
 , Convs, FileTypes, settings, atari, SNDHTimeDB, LCLTranslator, LCLStrConsts;

 {$R *.lfm}

var
 CloseActionsDone: boolean = False;

 LCLBugWasTrayPopup: boolean = False; //todo remove when LCL fixes will be applyied to Lazarus release

 sw: integer = scr_width;
 sj, sw1, sj1, sw2, sj2, sh: integer;
 ss, ss1, ss2: string;

 {$IFDEF Windows}
 PrevWndProc: WNDPROC;
 PrevAWndProc: WNDPROC;
 {$ENDIF Windows}

function DivMul(q1, q2, q3: int64): dword;
begin
 Result := q1 * q2 div q3;
end;

procedure GetStringWnJ(const s: string; var w, j: integer);
begin
 w := BMP_VScroll.Canvas.TextWidth(s);
 j := 0;
 if scr_width > w then
   j := (scr_width - w) div 2;
end;

procedure RedrawScroll;
begin
 BMP_Scroll.Canvas.CopyMode := cmSrcCopy;
 BMP_Scroll.Canvas.CopyRect(Rect(0, 0, scr_width, scr_height), BMP_Sources.Canvas,
   Bounds(scr_src, 0, scr_width, scr_height));
 BMP_VScroll.Canvas.TextOut(-HorScrl_Offset + sj, scr_lineheight + sh, ss);
 BMP_Scroll.Canvas.CopyMode := cmSrcAnd;
 BMP_Scroll.Canvas.CopyRect(Rect(0, 0, scr_width, scr_height), BMP_VScroll.Canvas,
   Bounds(0, scr_height, scr_width, scr_height));
 FrmMain.Canvas.CopyMode := cmSrcCopy;
 FrmMain.Canvas.CopyRect(Bounds(scr_x * Scale, scr_y * Scale, scr_width *
   Scale, scr_height * Scale),
   BMP_Scroll.Canvas, Rect(0, 0, scr_width, scr_height));
end;

procedure RedrawTime;
var
 CurTimeJ, CurTimeH, TmS: integer;
 CurrTimeStr, sig: string;
begin
 if TimeMode = 1 then sig := '-'
 else
   sig := '';
 TmS := abs(TimeShown);
 CurrTimeStr := sig + TimeSToStr(TmS);
 if TmS < 60 * 60 then
   BMP_Time.Canvas.Font.Height := -time_fontheight
 else
   BMP_Time.Canvas.Font.Height := -time_fontheightsmall;
 CurTimeJ := time_width - BMP_Time.Canvas.TextWidth(CurrTimeStr);
 if CurTimeJ > 0 then CurTimeJ := CurTimeJ div 2;
 CurTimeH := (time_height - BMP_Time.Canvas.TextHeight(CurrTimeStr)) div 2
   {$ifdef windows}
   - 1
 {$else}
+1
 {$endif}
 ;
 BMP_Time.Canvas.CopyMode := cmSrcCopy;
 BMP_Time.Canvas.CopyRect(Rect(0, 0, time_width, time_height), BMP_Sources.Canvas,
   Bounds(time_src, 0, time_width, time_height));
 BMP_Time.Canvas.TextOut(CurTimeJ, CurTimeH, CurrTimeStr);
 FrmMain.Canvas.CopyMode := cmSrcCopy;
 FrmMain.Canvas.CopyRect(Bounds(time_x * Scale, time_y * Scale,
   time_width * Scale, time_height * Scale),
   BMP_Time.Canvas, Rect(0, 0, time_width, time_height));
end;

procedure CalculateSpectrumPoints;
var
 i: integer;
begin
 Spa_points[0] := $FFF;
 for i := 1 to spa_num do
   Spa_points[i] := round($FFF * exp(-ln(16 * 22050 * $FFF / AY_Freq) * i / spa_num));
end;

procedure TFrmMain.DoVisualisation;
var
 Y_Stp: integer;
 Points_To_Scroll: integer;
 Temp, Temp1: integer;
begin
 if LongProcess <= 0 then
   //no conversion, searching, etc
  begin
   PollGetTimeRequest;
   digsoundVisualisation;
   BASSVisualisation;
   {$IFDEF Windows}
   CDVisualisation;
   MIDIVisualisation;
   {$ENDIF Windows}
   if ClearTimeInd then
    begin
     BMP_Time.Canvas.CopyMode := cmSrcCopy;
     BMP_Time.Canvas.CopyRect(Rect(0, 0, time_width, time_height),
       BMP_Sources.Canvas, Bounds(time_src, 0, time_width, time_height));
     Canvas.CopyMode := cmSrcCopy;
     Canvas.CopyRect(Bounds(time_x * Scale, time_y * Scale, time_width *
       Scale, time_height * Scale),
       BMP_Time.Canvas, Rect(0, 0, time_width, time_height));
     TimeShown := -MaxInt;
     ClearTimeInd := False;
    end;
   if Time_ms <> 0 then
    begin
     case TimeMode of
       0: Temp := round(CurrTime_Rasch / 1000);
       1:
        begin
         Temp := Time_ms - CurrTime_Rasch;
         if Temp < 0 then Temp := 0;
         Temp := -round(Temp / 1000);
        end;
     else
      begin
       Temp := round(Time_ms / 1000);
       if Temp < 0 then Temp := 0;
      end;
      end;
     if Temp <> TimeShown then
      begin
       TimeShown := Temp;
       RedrawTime;
      end;
    end;
  end;

 Temp := Item_Displayed;
 Temp1 := Scroll_Distination;
 if Abs(Temp1 - Temp) > 16 then
  begin
   if Temp1 > Temp then
     Temp := Temp1 - 16
   else
     Temp := Temp1 + 16;
   Item_Displayed := Temp;
   ss := GetPlayListString(PlaylistItems[Temp]);
   GetStringWnJ(ss, sw, sj);
   BMP_VScroll.Canvas.TextOut(sj, scr_lineheight + sh, ss);
  end;
 Points_To_Scroll := scr_lineheight * (Temp1 - Temp + 1) - Scroll_Offset;
 if Points_To_Scroll <> 0 then
  begin
   ScrFlg := False;
   Y_Stp := (Abs(Points_To_Scroll) - 1) div scr_lineheight + 1;
   if Y_Stp >= scr_lineheight then Y_Stp := scr_lineheight - 1;
   if Points_To_Scroll > 0 then
    begin
     if (Scroll_Offset >= scr_lineheight) then
      begin
       BMP_VScroll.Canvas.FillRect(0, scr_lineheight * 2, scr_width, scr_lineheight * 3);
       if Temp + 1 < Length(PlaylistItems) then
        begin
         ss2 := GetPlayListString(PlaylistItems[Temp + 1]);
         GetStringWnJ(ss2, sw2, sj2);
         BMP_VScroll.Canvas.TextOut(sj2, scr_lineheight * 2 + sh, ss2);
        end;
      end;
     Inc(Scroll_Offset, Y_Stp);
     if Scroll_Offset >= 2 * scr_lineheight then
      begin
       HorScrl_Offset := 0;
       ss := ss2;
       sw := sw2;
       sj := sj2;
       BMP_VScroll.Canvas.CopyMode := cmSrcCopy;
       BMP_VScroll.Canvas.CopyRect(Rect(0, 0, scr_width, scr_lineheight * 2),
         BMP_VScroll.Canvas, Bounds(0, scr_lineheight, scr_width, scr_lineheight * 2));
       Dec(Scroll_Offset, scr_lineheight);
       Inc(Temp);
       Item_Displayed := Temp;
      end;
    end
   else
    begin
     if (Scroll_Offset <= scr_lineheight) then
      begin
       BMP_VScroll.Canvas.FillRect(0, 0, scr_width, scr_lineheight);
       if Temp - 1 >= 0 then
        begin
         ss1 := GetPlayListString(PlaylistItems[Temp - 1]);
         GetStringWnJ(ss1, sw1, sj1);
         BMP_VScroll.Canvas.TextOut(sj1, sh, ss1);
        end;
      end;
     Dec(Scroll_Offset, Y_Stp);
     if Scroll_Offset <= 0 then
      begin
       HorScrl_Offset := 0;
       ss := ss1;
       sw := sw1;
       sj := sj1;
       BMP_VScroll.Canvas.CopyMode := cmSrcCopy;
       BMP_VScroll.Canvas.CopyRect(Bounds(0, scr_lineheight, scr_width,
         scr_lineheight * 2),
         BMP_VScroll.Canvas, Rect(0, 0, scr_width, scr_lineheight * 2));
       Inc(Scroll_Offset, scr_lineheight);
       Dec(Temp);
       Item_Displayed := Temp;
      end;
    end;
   BMP_Scroll.Canvas.CopyMode := cmSrcCopy;
   BMP_Scroll.Canvas.CopyRect(Rect(0, 0, scr_width, scr_height),
     BMP_Sources.Canvas, Bounds(scr_src, 0, scr_width, scr_height));
   BMP_Scroll.Canvas.CopyMode := cmSrcAnd;
   BMP_Scroll.Canvas.CopyRect(Rect(0, 0, scr_width, scr_height),
     BMP_VScroll.Canvas, Bounds(0, Scroll_Offset, scr_width, scr_height));
   Canvas.CopyMode := cmSrcCopy;
   Canvas.CopyRect(Bounds(scr_x * Scale, scr_y * Scale, scr_width *
     Scale, scr_height * Scale),
     BMP_Scroll.Canvas,
     Rect(0, 0, scr_width, scr_height));
  end;
 if Do_Scroll and ScrFlg and (sw > scr_width) and not MoveScr.Clicked then
  begin
   Dec(Scr_Pause);
   if Scr_Pause = 0 then
    begin
     Inc(Scr_Pause);
     if Scr_Left then
      begin
       Dec(HorScrl_Offset);
       if HorScrl_Offset < 0 then
        begin
         Scr_Left := False;
         HorScrl_Offset := 0;
         Scr_Pause := 50;
        end
       else
         RedrawScroll;
      end
     else
      begin
       Inc(HorScrl_Offset);
       if HorScrl_Offset > sw - scr_width then
        begin
         Scr_Left := True;
         HorScrl_Offset := sw - scr_width;
         Scr_Pause := 50;
        end
       else
         RedrawScroll;
      end;
    end;
  end
 else
   ScrFlg := True;
end;

procedure TFrmMain.VisTimerEvent(Sender: TObject);
begin
 if WindowState <> wsMinimized then DoVisualisation;
end;

procedure RedrawVisChannels(ca, cb, cc, mh: integer);
begin
 if IndicatorChecked then
  begin
   BMP_Vis.Canvas.CopyMode := cmSrcCopy;
   BMP_Vis.Canvas.CopyRect(Rect(0, 0, amp_width, amp_height), BMP_Sources.Canvas,
     Bounds(amp_src, 0, amp_width, amp_height));
   if ca > 0 then
    begin
     BMP_Vis.Canvas.MoveTo(1, amp_height);
     BMP_Vis.Canvas.LineTo(1, amp_height + 1 - ca * amp_height div mh);
    end;
   if cb > 0 then
    begin
     BMP_Vis.Canvas.MoveTo(8, amp_height);
     BMP_Vis.Canvas.LineTo(8, amp_height + 1 - cb * amp_height div mh);
    end;
   if cc > 0 then
    begin
     BMP_Vis.Canvas.MoveTo(15, amp_height);
     BMP_Vis.Canvas.LineTo(15, amp_height + 1 - cc * amp_height div mh);
    end;
   FrmMain.Canvas.CopyMode := cmSrcCopy;
   FrmMain.Canvas.CopyRect(Bounds(amp_x * Scale, amp_y * Scale, amp_width *
     Scale, amp_height * Scale),
     BMP_Vis.Canvas, Rect(0, 0, amp_width, amp_height));
  end;
end;

procedure RedrawVisSpectrum(CP: PVisPoint; MaxVal: integer);
var
 p: pointer;
 i, j, n: integer;
begin
 if SpectrumChecked then
  begin
   p := PSpa_prev;
   PSpa_prev := PSpa_piks;
   PSpa_piks := p;
   if CP <> nil then
    begin
     FillChar(PSpa_piks^, SizeOf(TSpa), 0);
     for n := 0 to 1 do
      begin
       for i := 0 to spa_num - 1 do
        begin
         if (CP^.R[n].TnA > Spa_Points[i + 1]) and (CP^.R[n].TnA <= Spa_Points[i]) then
           if PSpa_piks^[i] < CP^.R[n].AmpA then
             PSpa_piks^[i] := CP^.R[n].AmpA;
         if (CP^.R[n].TnB > Spa_Points[i + 1]) and (CP^.R[n].TnB <= Spa_Points[i]) then
           if PSpa_piks^[i] < CP^.R[n].AmpB then
             PSpa_piks^[i] := CP^.R[n].AmpB;
         if (CP^.R[n].TnC > Spa_Points[i + 1]) and (CP^.R[n].TnC <= Spa_Points[i]) then
           if PSpa_piks^[i] < CP^.R[n].AmpC then
             PSpa_piks^[i] := CP^.R[n].AmpC;
        end;
       if not TSMode then break;
      end;
    end;
   BMP_Vis.Canvas.CopyMode := cmSrcCopy;
   BMP_Vis.Canvas.CopyRect(Rect(0, 0, spa_width, spa_height), BMP_Sources.Canvas,
     Bounds(spa_src, 0, spa_width, spa_height));
   for i := 0 to spa_num - 1 do
    begin
     if PSpa_Piks^[i] > 0 then
      begin
       BMP_Vis.Canvas.MoveTo(i + 1, spa_height);
       BMP_Vis.Canvas.LineTo(i + 1, (MaxVal - PSpa_Piks^[i]) * spa_height div MaxVal);
      end;
     if PSpa_Prev^[i] > PSpa_Piks^[i] then
      begin
       PSpa_Piks^[i] := PSpa_Prev^[i];
       if PSpa_Piks^[i] > 0 then
        begin
         j := (MaxVal - PSpa_Piks^[i]) * spa_height div MaxVal;
         BMP_Vis.Canvas.Pixels[i, j] := $0a0a0a;
         BMP_Vis.Canvas.Pixels[i + 1, j] := $0a0a0a;
         BMP_Vis.Canvas.Pixels[i + 2, j] := $0a0a0a;
        end;
       Dec(PSpa_Piks^[i], (MaxVal + 1) div 16);
      end;
    end;
   FrmMain.Canvas.CopyMode := cmSrcCopy;
   FrmMain.Canvas.CopyRect(Bounds(spa_x * Scale, spa_y * Scale, spa_width *
     Scale, spa_height * Scale),
     BMP_Vis.Canvas, Rect(0, 0, spa_width, spa_height));
  end;
end;

procedure ShowProgress(a1: integer);
var
 x: word;
begin
 if (ProgrMax = 0) or MoveProgr.Clicked then exit;
 if ProgrMax <> longword(-1) then
   ProgrPos := a1
 else
   ProgrPos := 0;
 if ProgrMax < ProgrPos then ProgrPos := ProgrMax;
 x := DivMul(ProgrWidth, ProgrPos, ProgrMax);
 if MoveProgr.PosX <> x then
  begin
   MoveProgr.HideBmp;
   OffsetRgn(MoveProgr.RgnHandle, (x - MoveProgr.PosX) * Scale, 0);
   MoveProgr.PosX := x;
   MoveProgr.Redraw(False);
  end;
end;

procedure TFrmMain.SetDefault;
var
 IsPl: boolean;
begin
 IsPl := digsoundthread_active;
 PreAmp := PreAmpDef;
 BeeperMax := BeeperMaxDef;
 Atari_DMAMax := Atari_DMAMaxDef;
 Set_Z80_Frq(FrqZ80Def);
 Set_Player_Frq(Interrupt_FreqDef);
 if not IsPl then Set_Sample_Rate(SampleRateDef);
 Atari_SetDefault;
 Set_Chip_Frq(AY_FreqDef);
 Set_MFP_Frq(MFPTimerModeDef, MFPTimerFrqDef);
 IntOffset := IntOffsetDef;
 Set_N_Tact(MaxTStatesDef);
 if not IsPl then
  begin
   Set_Sample_Bit(SampleBitDef);
   Set_Stereo(NumOfChanDef);
   SetBuffers(BufLen_msDef, NumberOfBuffersDef);
   digsoundDevice := digsoundDeviceDef;
  end;
 Set_Mode_Manual(Index_ALDef, Index_ARDef, Index_BLDef, Index_BRDef,
   Index_CLDef, Index_CRDef);
 ChType := YM_Chip;
 SetFilter(1);
 BASSFFTType := BASS_DATA_FFT8192;
 BASSFFTNoWin := 0;//BASS_DATA_FFT_NOWINDOW;
 BASSFFTRemDC := BASS_DATA_FFT_REMOVEDC;
 BASSAmpMin := 0.003;
 BASSNetAgent := '';
 BASSNetUseProxy := True;
 BASSNetProxy := '';
 Calculate_Level_Tables2;
 RedrawPlaylist(ShownFrom, False);
 CalculateTotalTime(False);
end;

procedure TFrmMain.ButOpenClick(Sender: TObject);
begin
 ButOpen.UnPush;
 if GetKeyState(VK_SHIFT) and 128 <> 0 then
   FrmPLst.Add_Directory_Dialog(False)
 {$IFDEF Windows}
 else if GetKeyState(VK_CONTROL) and 128 <> 0 then
   FrmPLst.Add_CD_Dialog(False)
 {$ENDIF Windows}
 else
   FrmPLst.Add_Item_Dialog(False);
end;

procedure TFrmMain.PlayClick(Sender: TObject);
begin
 if IsPlaying then
   Exit;
 if not FileAvailable then
  begin
   ButPlay.UnPush;
   Exit;
  end;
 PlayCurrent;
end;

procedure TFrmMain.PopupMenu1Popup(Sender: TObject);
begin
 LCLBugWasTrayPopup := True;
end;

procedure TFrmMain.ButPauseClick(Sender: TObject);
begin
 if not IsPlaying then
  begin
   ButPause.UnPush;
   exit;
  end;
 if IsStreamOrModuleFileType(CurFileType) then
   // {$IFDEF UseBassForEmu}or MinAYChipFile..MaxAYChipFile{$ENDIF UseBassForEmu}
  begin
   Paused := True;
   SwitchPause;
   Paused := BASSPaused;
  end
 {$IFDEF Windows}
 else if IsCDFileType(CurFileType) then
  begin
   CDSwitchPause(CurCDNum, Handle);
   Paused := CDPlayingPaused;
  end
 else if IsMIDIFileType(CurFileType) then
  begin
   MIDIParams^.paused := not MIDIParams^.paused;
   Paused := MIDIParams^.paused;
  end
 {$ENDIF Windows}
 else
   digsound_pauseswitch;
 if not Paused then
  begin
   FIDO_SaveStatus(FIDO_Playing);
   ButPause.Switch_Off;
  end
 else
  begin
   FIDO_SaveStatus(FIDO_Nothing);
   ButPause.Switch_On;
  end;
end;

procedure TFrmMain.ButStopClick(Sender: TObject);
begin
  try
   StopAndFreeAll;
  finally
   ButStop.UnPush;
  end;
end;

procedure RestoreControls;
begin
 FrmMain.FIDO_SaveStatus(FIDO_Nothing);
 ButPlay.Switch_Off;

 FrmMixer.GBSRate.Enabled := True;

 FrmMixer.GBBRate.Enabled := True;
 FrmMixer.GBBuffs.Enabled := True;
 FrmMixer.GBDevice.Enabled := True;
 FrmMixer.GBMidiDevice.Enabled := True;
 FrmMixer.RBChStereo.Enabled := True;
 FrmMixer.RBChMono.Enabled := True;

 ButStop.UnPush;
 ButPause.Switch_Off;
 FrmMixer.EAmpALCur.Clear;
 FrmMixer.EAmpARCur.Clear;
 FrmMixer.EAmpBLCur.Clear;
 FrmMixer.EAmpBRCur.Clear;
 FrmMixer.EAmpCLCur.Clear;
 FrmMixer.EAmpCRCur.Clear;
 FrmMixer.EChFrqCur.Clear;
 FrmMixer.EIntFrqCur.Clear;
 FrmMixer.EMFPFrqCur.Clear;
 FrmMixer.CBChTypeAY.Checked := False;
 FrmMixer.CBCHTypeYM.Checked := False;
 FrmMixer.CheckBox6.Checked := False;
 FrmMixer.CheckBox7.Checked := False;
end;

procedure PlayCurrent;
begin
 case ChType of
   AY_Chip:
    begin
     Led_AY.State := False;
     Led_YM.State := True;
    end;
   YM_Chip:
    begin
     Led_AY.State := True;
     Led_YM.State := False;
    end
  end;
 Led_Stereo.State := NumberOfChannels = 1;
 Led_AY.Redraw(False);
 Led_YM.Redraw(False);
 Led_Stereo.Redraw(False);

 ButPlay.Switch_On;
 FrmMain.ShowAllParams;
 ButPause.Switch_Off;
 ButStop.UnPush;

 FrmMixer.GBSRate.Enabled := False;

 FrmMixer.GBBRate.Enabled := False;
 FrmMixer.GBBuffs.Enabled := False;
 FrmMixer.GBDevice.Enabled := False;
 FrmMixer.GBMidiDevice.Enabled := False;
 FrmMixer.RBChStereo.Enabled := False;
 FrmMixer.RBChMono.Enabled := False;

 FrmMain.FIDO_SaveStatus(FIDO_Playing);

  try
   InitForAllTypes(True);
   if IsStreamOrModuleFileType(CurFileType) then
     StartBASS
   {$IFDEF Windows}
   else if IsCDFileType(CurFileType) then
     StartCD(CurCDNum, CurCDTrk)
   else if IsMIDIFileType(CurFileType) then
     midithread_start
   {$ENDIF Windows}
   else
     digsoundthread_start;
  except
   RestoreControls;
   ShowException(ExceptObject, ExceptAddr);
  end;
end;

procedure SetCommandLine(clstr: string);
begin
 if InitialScan then
   FrmMain.CommandLineInterpreter(clstr, False)
 else
  begin
   SetLength(AfterScan, Length(AfterScan) + 1);
   AfterScan[Length(AfterScan) - 1] := clstr;
  end;
end;

procedure TFrmMain.IPCMessage(Sender: TObject);
begin
 SetCommandLine(IPCServer.StringMessage);
end;

procedure TFrmMain.CommandLineInterpreter(CL: string; Start: boolean);
var
 CLPos, CLLen, fileadp: integer;
 Param: string;
 fileex, quote, Fast, fileadd: boolean;
 ParamFiles: TStringList;

 procedure CommandLineParameter(CLP: string);

   procedure CLFile;
   begin
     if not IsSkinFileType(GetFileTypeFromFNExt(ExtractFileExt(CLP))) then
       fileex := True;
     ParamFiles.Add(ExpandFileName(CLP));
   end;

 var
   {$IFDEF Windows}
   Ch: char;
   {$ENDIF Windows}
   ErrPos, NewFrq, i, j: integer;
   usils: array[0..5] of byte;
   TempStr: string;
   EmChip: ChTypes;
   d1, d2: byte;
 begin
   if CLP = '' then exit;
   if (CLP[1] = '-')
     {$IFDEF Windows}
     or (CLP[1] = '/')
   {$ENDIF Windows}
   then
    begin
     if Length(CLP) < 2 then
       CLFile
     else
       case char(byte(CLP[2]) or $20) of
         's':
          begin
           Val(Copy(CLP, 3, Length(CLP) - 2), NewFrq, ErrPos);
           if ErrPos = 0 then
             Set_Sample_Rate2(NewFrq);
          end;
         'b':
          begin
           Val(Copy(CLP, 3, Length(CLP) - 2), NewFrq, ErrPos);
           if ErrPos = 0 then
             Set_Sample_Bit2(NewFrq);
          end;
         'z':
          begin
           Val(Copy(CLP, 3, Length(CLP) - 2), NewFrq, ErrPos);
           if ErrPos = 0 then Set_Z80_Frq2(NewFrq);
          end;
         'y':
          begin
           CLP := LowerCase(Copy(CLP, 3, Length(CLP) - 2));
           Val(CLP, NewFrq, ErrPos);
           if ErrPos = 0 then Set_Chip_Frq2(NewFrq)
           else if CLP = 'list' then FrmMixer.CBChFrqLst.Checked := True
           else if CLP = 'mixer' then FrmMixer.CBChFrqLst.Checked := False;
          end;
         'q':
          begin
           CLP := Trim(Copy(CLP, 3, Length(CLP) - 2));
           if CLP = '' then
             Set_MFP_Frq2(0, 0)
           else
            begin
             Val(CLP, NewFrq, ErrPos);
             if ErrPos = 0 then
               Set_MFP_Frq2(1, NewFrq);
            end;
          end;
         't':
          begin
           Val(Copy(CLP, 3, Length(CLP) - 2), NewFrq, ErrPos);
           if ErrPos = 0 then Set_IntOffset2(Newfrq);
          end;
         'a':
          begin
           CLP := LowerCase(Copy(CLP, 3, Length(CLP) - 2));
           if CLP = 'on' then
             IndicatorChecked := True
           else if CLP = 'off' then
             IndicatorChecked := False
           else if CLP = 'dd' then
            begin
             fileadd := True;
             fileadp := -1;
            end
           else if CLP = 'dp' then
             fileadd := True;
          end;
         'f':
          begin
           TempStr := LowerCase(Copy(CLP, 3, Length(CLP) - 2));
           if TempStr = 'on' then
             SpectrumChecked := True
           else if TempStr = 'off' then
             SpectrumChecked := False
           else if (Length(TempStr) > 2) and (TempStr[1] = 'd') then
            begin
             CLP := Copy(CLP, 5, Length(CLP) - 4);
             case TempStr[2] of
               'f': FIDO_Descriptor_FileName := CLP;
               'n': FIDO_Descriptor_Nothing := CLP;
               's': FIDO_Descriptor_Suffix := CLP;
               'p': FIDO_Descriptor_Prefix := CLP;
               'e': FIDO_Descriptor_Enabled := CLP <> '0';
               'k': FIDO_Descriptor_KillOnNothing := CLP <> '0';
               'x': FIDO_Descriptor_KillOnExit := CLP <> '0';
               'c': FIDO_Descriptor_Enc := CLP;
              end;
            end;
          end;
         'i':
           Set_N_TactS(Copy(CLP, 3, Length(CLP) - 2));
         'l':
           if Length(CLP) >= 3 then
             Set_Language2(Copy(CLP, 3, Length(CLP) - 2));
         'n':
          begin
           CLP := LowerCase(Copy(CLP, 3, Length(CLP) - 2));
           Val(CLP, NewFrq, ErrPos);
           if ErrPos = 0 then
             Set_Player_Frq2(NewFrq)
           else if CLP = 'list' then
             FrmMixer.CBIntFrqLst.Checked := True
           else if CLP = 'mixer' then
             FrmMixer.CBIntFrqLst.Checked := False;
          end;
         'c':
          begin
           CLP := LowerCase(Copy(CLP, 3, Length(CLP) - 2));
           if CLP = 'on' then
             Set_Loop2(True)
           else if CLP = 'off' then
             Set_Loop2(False);
          end;
         {$IFDEF Windows}
         'r':
           if Length(CLP) = 3 then
            begin
             Ch := char(byte(CLP[3]) or $20);
             if Ch in ['i', 'n', 'h'] then
              begin
               case Ch of
                 'i': SetPriority2(IDLE_PRIORITY_CLASS);
                 'n': SetPriority2(NORMAL_PRIORITY_CLASS)
               else
                 SetPriority2(HIGH_PRIORITY_CLASS)
                end;
              end;
            end;
         {$ENDIF Windows}
         'h':
          begin
           CLP := UpperCase(Copy(CLP, 3, Length(CLP) - 2));
           if CLP = 'MONO' then NewFrq := 0
           else if CLP = 'AYABC' then NewFrq := 1
           else if CLP = 'AYACB' then NewFrq := 2
           else if CLP = 'AYBAC' then NewFrq := 3
           else if CLP = 'AYBCA' then NewFrq := 4
           else if CLP = 'AYCAB' then NewFrq := 5
           else if CLP = 'AYCBA' then NewFrq := 6
           else if CLP = 'YMABC' then NewFrq := 7
           else if CLP = 'YMACB' then NewFrq := 8
           else if CLP = 'YMBAC' then NewFrq := 9
           else if CLP = 'YMBCA' then NewFrq := 10
           else if CLP = 'YMCAB' then NewFrq := 11
           else if CLP = 'YMCBA' then NewFrq := 12
           else if CLP = 'LIST' then
            begin
             FrmMixer.CheckBox1.Checked := True;
             NewFrq := -1;
            end
           else if CLP = 'MIXER' then
            begin
             FrmMixer.CheckBox1.Checked := False;
             NewFrq := -1;
            end
           else
            begin
             i := 1;
             CLP := CLP + ',';
             for j := 0 to 5 do
              begin
               TempStr := '';
               while (i <= Length(CLP)) and (CLP[i] <> ',') do
                begin
                 TempStr := TempStr + CLP[i];
                 Inc(i);
                end;
               Inc(i);
               if i - 1 > Length(CLP) then break;
               Val(TempStr, usils[j], ErrPos);
               if ErrPos <> 0 then break;
              end;
             if (i - 1 <= Length(CLP)) and (ErrPos = 0) then
               with FrmMixer do
                 for j := 0 to 5 do
                   SetChan2(usils[j], j);
             NewFrq := -1;
            end;
           if NewFrq >= 0 then
            begin
             if NewFrq > 6 then
              begin
               Dec(NewFrq, 6);
               EmChip := YM_Chip;
              end
             else
               EmChip := AY_Chip;
             FrmMain.CalcModeCoefs(NewFrq, EmChip, True, True,
               Index_AL, Index_AR, Index_BL, Index_BR, Index_CL, Index_CR,
               d1, d2);
             FrmMixer.UpdateAmplFields;
            end;
          end;
         'd':
          begin
           CLP := UpperCase(Copy(CLP, 3, Length(CLP) - 2));
           if CLP = 'MONO' then Set_Stereo2(1)
           else if CLP = 'STEREO' then Set_Stereo2(2)
           else if CLP = 'LIST' then FrmMixer.CBChLst.Checked := True
           else if CLP = 'MIXER' then FrmMixer.CBChLst.Checked := False;
          end;
         'e':
          begin
           CLP := UpperCase(Copy(CLP, 3, Length(CLP) - 2));
           if CLP = 'AY' then Set_Chip2(AY_Chip)
           else if CLP = 'YM' then Set_Chip2(YM_Chip)
           else if CLP = 'LIST' then FrmMixer.CBChTypeLst.Checked := True
           else if CLP = 'MIXER' then FrmMixer.CBChTypeLst.Checked := False;
          end;
         'g':
          begin
           CLP := Copy(CLP, 3, Length(CLP) - 2);
           if CLP = '0' then
             Set_TrayMode2(0)
           else if CLP = '1' then
             Set_TrayMode2(1)
           else if CLP = '2' then
             Set_TrayMode2(2);
          end;
         'j':
          begin
           CLP := Copy(CLP, 3, Length(CLP) - 2);
           if CLP = '0' then
             TimeMode := 0
           else if CLP = '1' then
             TimeMode := 1
           else if CLP = '2' then
             TimeMode := 2;
           TimeShown := -MaxInt;
          end;
         'k':
          begin
           CLP := LowerCase(Copy(CLP, 3, Length(CLP) - 2));
           if CLP = 'on' then Do_Scroll := True
           else if CLP = 'off' then Do_Scroll := False;
          end;
         'p':
           LoadSkin(ExpandFileName(Copy(CLP, 3, Length(CLP) - 2)), False);
         'w':
          begin
           CLP := LowerCase(Copy(CLP, 3, Length(CLP) - 2));
           if CLP = 'on' then
             SetAutoSaveDefDir2(True)
           else if CLP = 'off' then
             SetAutoSaveDefDir2(False)
           else if (Length(CLP) > 2) and (CLP[1] = 'o') then
            begin
             Val(Copy(CLP, 3, Length(CLP) - 2), NewFrq, ErrPos);
             if ErrPos = 0 then
               case CLP[2] of
                 'n': Set_NumberOfBuffers2(NewFrq);
                 'l': Set_BufLen_ms2(NewFrq);
                 'd': Set_WODevice2(NewFrq, '')
                end;
            end;
          end;
         'u':
          begin
           Val(Copy(CLP, 3, Length(CLP) - 2), NewFrq, ErrPos);
           if ErrPos = 0 then SetChan2(NewFrq, 6);
          end;
         'v':
          begin
           CLP := LowerCase(Copy(CLP, 3, Length(CLP) - 2));
           if CLP = 'hide' then
             PostMessage(Handle, WM_HIDEMINIMIZE, 0, 0)
           else if CLP = 'show' then
             ShowApp(False);
          end;
         'x':
          begin
           CLP := LowerCase(Copy(CLP, 3, Length(CLP) - 2));
           if CLP = 'on' then
             SetAutoSaveWindowsPos2(True)
           else if CLP = 'off' then
             SetAutoSaveWindowsPos2(False);
          end;
         '!':
          begin
           CLP := LowerCase(Copy(CLP, 3, Length(CLP) - 2));
           if CLP = 'on' then
             SetAutoSaveVolumePos2(True)
           else if CLP = 'off' then
             SetAutoSaveVolumePos2(False);
          end;
       else
         CLFile;
        end;
    end
   else
     CLFile;
 end;

var
 First: integer;
 PlayWay: TPlayWay;
 dir: string;
begin
 if AppIsModal or not IsWindowEnabled(Handle) then
   //ignore command line scan for closing modal window to finish playlist operations
   Exit;

 Fast := GetTickCount64 - LastTimeComLine < CLFast;
 dir := GetCurrentDir;
 ParamFiles := TStringList.Create;
 fileex := False;
 fileadd := False;
 fileadp := Length(PlayListItems);
 CLPos := 1;
 CLLen := Length(CL);
 First := 0;
 while CLPos <= CLLen do
  begin
   quote := False;
   Param := '';
   while (CLPos <= CLLen) and (quote or (CL[CLPos] > ' ')) do
    begin
     if CL[CLPos] = '"' then
       quote := not quote
     else
       Param := Param + CL[CLPos];
     Inc(CLPos);
    end;
   case First of
     0:
      begin
       First := 1;
       SetCurrentDir(Param);
      end;
     1:
       First := 2;
   else
     CommandLineParameter(Param);
    end;
   Inc(CLPos);
  end;
 SetCurrentDir(dir);
 if ParamFiles.Count <> 0 then
  begin
    try
     if FileEx then
       if not fileadd and not Start and not Fast then
        begin
         StopPlaying;
         ClearPlayList;
        end
       else if fileadd and (fileadp >= 0) and not Fast then
         StopPlaying;
     FrmPLst.Add_Files(ParamFiles);
     if FileEx then
       CalculateTotalTime(False);
    finally
     ParamFiles.Free;
     if FileEx then
      begin
       CreatePlayOrder;
       if (fileadp >= 0) and (fileadp < Length(PlayListItems)) then
         RedrawPlaylist(fileadp, True)
       else
         RedrawPlaylist(0, True);
      end;
    end;
   if FileEx then
    begin
     if Start then
       PlayWay := pwNo
     else
       PlayWay := pwPlay;
     if not fileadd then
      begin
       if not Fast then PlayItem(0, PlayWay);
      end
     else if (fileadp >= 0) and (fileadp < Length(PlayListItems)) and not Fast then
       PlayItem(PlayListItems[fileadp]^.Tag, PlayWay);
    end;
  end;
 LastTimeComLine := GetTickCount64;
end;

procedure TFrmMain.Set_Chip_Frq2(Fr: integer);
begin
 if Fr <> AY_Freq then
  begin
   Set_Chip_Frq(Fr);
   FrmMixer.FrqAYTemp := AY_Freq;
   FrmMixer.Set_Frqs;
  end;
end;

procedure TFrmMain.Set_Chip_Frq(Fr: integer);
begin
 if (Fr >= 1000000) and (Fr <= 3546800) then
  begin
   digsoundloop_catch;
    try
     AY_Freq := Fr;
     CalculateSpectrumPoints;
     if MFPTimerMode = 0 then
       Set_MFP_Frq(0, 0);
     Delay_In_Tiks := round(8192 / SampleRate * AY_Freq);
     FrqAyByFrqZ80 := round(AY_Freq / FrqZ80 / 8 * 4294967296);
     Tik.Re := Delay_In_Tiks;
     AY_Tiks_In_Interrupt := round(AY_Freq / (Interrupt_Freq / 1000 * 8));
     YM6TiksOnInt := AY_Freq / (Interrupt_Freq / 1000 * 8);
     SetFilter(FilterQuality);
     if IsPlaying then
      begin
       FrmMixer.EChFrqCur.Text := IntToStr(AY_Freq);
       FrmMixer.EMFPFrqCur.Text := IntToStr(MFPTimerFrq);
      end;
     AyFreq := AY_Freq;
     FrqAyByFrqMC68000 := round(AyFreq / MC68000Freq / 8 * 4294967296);
    finally
     digsoundloop_release;
    end;
  end;
end;

procedure TFrmMain.Set_MFP_Frq(Md, Fr: integer);
begin
 digsoundloop_catch;
  try
   if Md = 0 then
    begin
     MFPTimerMode := 0;
     MFPTimerFrq := Trunc(AY_Freq * 16 / 13 + 0.5);
    end
   else
   if (Fr >= 1000000) and (Fr <= 4365292) then
    begin
     MFPTimerMode := 1;
     MFPTimerFrq := Fr;
    end;
   if IsPlaying then
     FrmMixer.EMFPFrqCur.Text := IntToStr(MFPTimerFrq);
   MFPFreq := MFPTimerFrq;
   MCbyMFP := MC68000Freq / MFPFreq;
  finally
   digsoundloop_release;
  end;
end;

procedure TFrmMain.ButMixerClick(Sender: TObject);
begin
 if ButMixer.Is_On then
   ButMixer.Switch_Off
 else
   ButMixer.Is_On := True;
 FrmMixer.Visible := ButMixer.Is_On;
 {$IFNDEF Windows}
 if FrmMixer.WindowState = wsMinimized then
  //mask GTK error (minimize button is always visible (do bug report?)
  FrmMixer.WindowState := wsNormal;
 {$ENDIF Windows}
end;

procedure TFrmMain.Set_Z80_Frq(NewF: integer);
var
 i: integer;
begin
 if (NewF >= 1000000) and (NewF <= 8000000) then
  begin
   digsoundloop_catch;
    try
     if FrqZ80 <> NewF then
      begin
       for i := 0 to Length(PlayListItems) - 1 do
         with PlayListItems[i]^ do
           if (FileType = FT.OUT) or (FileType = FT.ZXAY) or (FileType = FT.EPSG) then
             //force rescan
             Time := 0;
       if FileAvailable and ((CurFileType = FT.OUT) or
         (CurFileType = FT.ZXAY) or (CurFileType = FT.AY) or
         (CurFileType = FT.AYM) or (CurFileType = FT.EPSG)) then
         //Z80 frequency duration depended file was opened
        begin
         Time_ms := trunc(Time_ms / NewF * FrqZ80 + 0.5);
         ProgrMax := trunc(Time_ms / 1000 * SampleRate + 0.5);
         VProgrPos := trunc(VProgrPos / NewF * FrqZ80 + 0.5);
        end;
       FrqZ80 := NewF;
      end;
     FrqAyByFrqZ80 := trunc(AY_Freq / FrqZ80 / 8 * 4294967296 + 0.5);
    finally
     digsoundloop_release;
    end;
   RedrawPlaylist(ShownFrom, False);
   CalculateTotalTime(False);
  end;
end;

procedure TFrmMain.Set_MC68K_Frq(NewF: integer);
begin
 if (NewF >= 2000000) and (NewF <= 16000000) then
  begin
   digsoundloop_catch;
    try
     MC68000Freq := NewF;
     VBLPeriod := round(MC68000Freq / VBLFreq);
     FrqAyByFrqMC68000 := round(AyFreq / MC68000Freq / 8 * 4294967296);
     MCbyMFP := MC68000Freq / MFPFreq;
    finally
     digsoundloop_release;
    end;
  end;
end;

procedure TFrmMain.Set_Z80_Frq2(NewF: integer);
begin
 if NewF <> FrqZ80 then
  begin
   Set_Z80_Frq(NewF);
   FrmMixer.Set_Z80Frqs;
  end;
end;

procedure TFrmMain.Set_MC68K_Frq2(NewF: integer);
begin
 if NewF <> MC68000Freq then
  begin
   Set_MC68K_Frq(NewF);
   FrmMixer.Set_MC68KFrqs;
  end;
end;

procedure TFrmMain.Set_N_Tact(NewF: integer);
begin
 if (NewF > 9999) and (NewF <= 200000) then
  begin
   digsoundloop_catch;
    try
     if (MaxTStates <> NewF) and FileAvailable and
       IsZ80EmuFileType(CurFileType) then
      begin
       Time_ms := trunc(Time_ms / MaxTStates * NewF + 0.5);
       ProgrMax := trunc(Time_ms / 1000 * SampleRate + 0.5);
       VProgrPos := trunc(VProgrPos / MaxTStates * NewF + 0.5);
      end;
     MaxTStates := NewF;
     if IntOffset >= MaxTStates then
      begin
       IntOffset := MaxTStates - 1;
       FrmMixer.EIntOffs.Text := IntToStr(IntOffset);
      end;
    finally
     digsoundloop_release;
    end;
   RedrawPlaylist(ShownFrom, False);
   CalculateTotalTime(False);
  end;
end;

procedure TFrmMain.Set_N_Tact2(NT: integer);
begin
 if NT <> MaxTStates then
  begin
   Set_N_Tact(NT);
   FrmMixer.EOUTStPerFrm.Text := IntToStr(MaxTStates);
  end;
end;

procedure TFrmMain.Set_N_TactS(t: string);
var
 V, ErrPos: integer;
begin
 Val(t, V, ErrPos);
 if ErrPos = 0 then Set_N_Tact2(V);
end;

procedure TFrmMain.SetVisTimerPeriod(VTP: integer);
begin
 if (VTP > 9) and (VTP < 101) then
  begin
   VisTimerPeriod := VTP;
   VisTimer.Interval := VTP;
  end;
end;

procedure TFrmMain.Set_Sample_Rate2(SR: integer);
begin
 if (SR <> SampleRate) and not IsPlaying then
  begin
   Set_Sample_Rate(SR);
   FrmMixer.SetSRs;
  end;
end;

procedure Set_Sample_Rate(SR: integer);
begin
 if IsPlaying then exit;
 if not ((SR >= 8000) and (SR < 300000)) then exit;
 SampleRate := SR;
 VisStep := round(SampleRate / 100);
 BufferLength := round(BufLen_ms * SampleRate / 1000);
 VisPosMax := round(BufferLength * NumberOfBuffers / VisStep) + 1;
 VisTickMax := VisStep * VisPosMax;
 SetLength(VisPoints, VisPosMax);
 Delay_In_Tiks := round(8192 / SampleRate * AY_Freq);
 FrmMain.SetFilter(FilterQuality);
end;

procedure SetSynthesizer;
begin
 if NumberOfChannels = 2 then
  begin
   if SampleBit = 8 then
     Synthesizer := @Synthesizer_Stereo8
   else
     Synthesizer := @Synthesizer_Stereo16;
  end
 else if SampleBit = 8 then
   Synthesizer := @Synthesizer_Mono8
 else
   Synthesizer := @Synthesizer_Mono16;
 Calculate_Level_Tables2;
end;

procedure TFrmMain.Set_Sample_Bit2(SB: integer);
begin
 if (SampleBit <> SB) and ((SB = 16) or (SB = 8)) and not IsPlaying then
  begin
   Set_Sample_Bit(SB);
   case SB of
     16: FrmMixer.RBBt16.Checked := True;
     8: FrmMixer.RBBt8.Checked := True;
    end;
  end;
end;

procedure Set_Sample_Bit(SB: integer);
begin
 if IsPlaying then exit;
 SampleBit := SB;
 SetSynthesizer;
end;

procedure TFrmMain.Set_Stereo2(St: integer);
begin
 if (St <> NumberOfChannels) and (St in [1, 2]) and not IsPlaying then
  begin
   Set_Stereo(St);
   case St of
     1: FrmMixer.RBChMono.Checked := True;
     2: FrmMixer.RBChStereo.Checked := True;
    end;
  end;
end;

procedure Set_Stereo(St: integer);
begin
 if IsPlaying then exit;
 NumberOfChannels := St;
 SetSynthesizer;
end;

procedure Calculate_Level_Tables2;
var
 Max, MaxL: integer;
begin
 Calculate_Level_Tables;
 Get_Max_of_Level_Tables(Max);
 if SampleBit = 8 then
   MaxL := 127
 else
   MaxL := 32767;
 FrmMixer.LAYOvfl.Visible := Max > MaxL;
 FrmMixer.LTSOvfl.Visible := Max * 2 > MaxL;
 Inc(Max, Atari_DMALevel);
 if NumberOfChannels = 1 then
   Inc(Max, Atari_DMALevel);
 FrmMixer.LDMAOvfl.Visible := (Atari_DMALevel <> 0) and (Max > MaxL);
end;

procedure TFrmMain.ShowAllParams;
begin
 FrmMixer.EAmpALCur.Text := IntToStr(Index_AL);
 FrmMixer.EAmpARCur.Text := IntToStr(Index_AR);
 FrmMixer.EAmpBLCur.Text := IntToStr(Index_BL);
 FrmMixer.EAmpBRCur.Text := IntToStr(Index_BR);
 FrmMixer.EAmpCLCur.Text := IntToStr(Index_CL);
 FrmMixer.EAmpCRCur.Text := IntToStr(Index_CR);
 FrmMixer.EChFrqCur.Text := IntToStr(AY_Freq);
 FrmMixer.EIntFrqCur.Text := FloatToStrF(Interrupt_Freq / 1000, ffFixed, 7, 3);
 FrmMixer.EMFPFrqCur.Text := IntToStr(MFPTimerFrq);
 if ChType = AY_Chip then
   FrmMixer.CBChTypeAY.Checked := True
 else
   FrmMixer.CBCHTypeYM.Checked := True;
 if NumberOfChannels = 2 then
   FrmMixer.CheckBox7.Checked := True
 else
   FrmMixer.CheckBox6.Checked := True;
end;

procedure TFrmMain.RestoreAllParams;
begin
 with FrmMixer do
  begin
   if RBChTypeYM.Checked then
     ChType := YM_Chip
   else
     ChType := AY_Chip;
   SetChan2(TBAmpAL.Position, 0);
   SetChan2(TBAmpAR.Position, 1);
   SetChan2(TBAmpBL.Position, 2);
   SetChan2(TBAmpBR.Position, 3);
   SetChan2(TBAmpCL.Position, 4);
   SetChan2(TBAmpCR.Position, 5);
   Set_Chip_Frq(FrqAYTemp);
   Set_Player_Frq(FrqPlTemp);
   if RBChStereo.Checked then
     Set_Stereo(2)
   else
     Set_Stereo(1);
  end;
end;

procedure TFrmMain.ButListClick(Sender: TObject);
begin
 if ButList.Is_On then
   ButList.Switch_Off
 else
   ButList.Is_On := True;
 FrmPLst.Visible := ButList.Is_On;
 {$IFNDEF Windows}
 if FrmPLst.WindowState = wsMinimized then
  //mask GTK error (minimize button is always visible (do bug report?)
  FrmPLst.WindowState := wsNormal;
 {$ENDIF Windows}
end;

procedure TFrmMain.ButNextClick(Sender: TObject);
begin
 ButNext.UnPush;
 FrmPLst.PlayNextItem;
end;

procedure TFrmMain.ButPrevClick(Sender: TObject);
begin
 ButPrev.UnPush;
 FrmPLst.PlayPreviousItem;
end;

procedure TFrmMain.WMPLAYNEXTITEM(var Msg: TMsg);
var
 Flg: boolean;
begin
 {$IFDEF Windows}
 if not IsCDFileType(CurFileType) then
   StopPlaying
 else
  begin
   IsPlaying := False;
   Paused := False;
   RestoreControls;
  end;
 {$ELSE Windows}
StopPlaying;
 {$ENDIF Windows}
 Flg := (Direction = 3) and (not ListLooped);
 if not Flg then
  begin
   if Direction <> 3 then
    begin
     FrmPLst.PlayNextItem;
     Flg := PlayingItem >= Length(PlayListItems) - 1;
    end
   else
     PlayCurrent;
  end;
 if not IsPlaying and Flg then
  begin
   FreeAndUnloadBASS;
   {$IFDEF Windows}
   CloseCDDevice(CurCDNum);
   {$ENDIF Windows}
  end;
end;

procedure TFrmMain.WMBASSMETADATA(var Msg: TMsg);
var
 Tags: TTags;
 s: string;
begin
 if (MusicHandle <> 0) and MusicIsStream and TAGS_Read_Meta(MusicHandle, Tags) then
  begin
   ForceScrollForDisplay;
   s := FormatScrollString(Tags.Artist, Tags.Title, '', -1);
   if s = '' then ReprepareScroll
   else
     SetScrollString(s);
   CurItem.PLStr := ss;
   if not Paused then FIDO_SaveStatus(FIDO_Playing);
   TrayIcon1.Hint := ss;
  end;
end;

procedure TFrmMain.Set_Mode_Manual(AL, AR, BL, BR, CL, CR: byte);
begin
 Index_AL := AL;
 Index_AR := AR;
 Index_BL := BL;
 Index_BR := BR;
 Index_CL := CL;
 Index_CR := CR;
 Calculate_Level_Tables2;
end;

procedure TFrmMain.CalcModeCoefs(Mode: integer; ChType: ChTypes;
 TS, DMA: boolean; out Index_AL, Index_AR, Index_BL, Index_BR, Index_CL,
 Index_CR, BeeperMax, Atari_DMAMax: byte);
var
 Echo: integer;
begin
 if not DMA then
   Atari_DMAMax := 0;
 if Mode > 0 then
  begin
   if ChType = AY_Chip then Echo := 85
   else
     Echo := 13;
   BeeperMax := (255 + 170 + Echo) div 3;
   if DMA then
     Atari_DMAMax := BeeperMax;
   case Mode of
     1: begin
       Index_AL := 255;
       Index_AR := Echo;
       Index_BL := 170;
       Index_BR := 170;
       Index_CL := Echo;
       Index_CR := 255;
      end;
     2: begin
       Index_AL := 255;
       Index_AR := Echo;
       Index_BL := Echo;
       Index_BR := 255;
       Index_CL := 170;
       Index_CR := 170;
      end;
     3: begin
       Index_AL := 170;
       Index_AR := 170;
       Index_BL := 255;
       Index_BR := Echo;
       Index_CL := Echo;
       Index_CR := 255;
      end;
     4: begin
       Index_AL := Echo;
       Index_AR := 255;
       Index_BL := 255;
       Index_BR := Echo;
       Index_CL := 170;
       Index_CR := 170;
      end;
     5: begin
       Index_AL := 170;
       Index_AR := 170;
       Index_BL := Echo;
       Index_BR := 255;
       Index_CL := 255;
       Index_CR := Echo;
      end;
     6: begin
       Index_AL := Echo;
       Index_AR := 255;
       Index_BL := 170;
       Index_BR := 170;
       Index_CL := 255;
       Index_CR := Echo;
      end;
    end;
  end
 else
  begin
   BeeperMax := 255;
   if DMA then
     Atari_DMAMax := BeeperMax;
   Index_AL := 255;
   Index_AR := 255;
   Index_BL := 255;
   Index_BR := 255;
   Index_CL := 255;
   Index_CR := 255;
  end;
end;

procedure TFrmMain.Set_Mode(Mode: integer);
var
 d1, d2: byte;
begin
 CalcModeCoefs(Mode, ChType, True, True, Index_AL, Index_AR, Index_BL, Index_BR,
   Index_CL, Index_CR, d1, d2);
 Calculate_Level_Tables2;
end;

procedure TFrmMain.Set_Player_Frq2(Fr: integer);
begin
 if Fr <> Interrupt_Freq then
  begin
   Set_Player_Frq(Fr);
   FrmMixer.FrqPlTemp := Interrupt_Freq;
   FrmMixer.Set_Pl_Frqs;
   RedrawPlaylist(ShownFrom, False);
   CalculateTotalTime(False);
  end;
end;

procedure TFrmMain.Set_Player_Frq(Fr: integer);
begin
 if (Fr >= 1000) and (Fr <= 2000000) and (Interrupt_Freq <> Fr) then
  begin
   digsoundloop_catch;
    try
     if FileAvailable and IsVBLFileType(CurFileType) then
      begin
       Time_ms := trunc(Time_ms / Fr * Interrupt_Freq + 0.5);
       ProgrMax := trunc(Time_ms / 1000 * SampleRate + 0.5);
       VProgrPos := trunc(VProgrPos / Fr * Interrupt_Freq + 0.5);
      end;
     Interrupt_Freq := Fr;
     if IsPlaying then
       FrmMixer.EIntFrqCur.Text := FloatToStrF(Interrupt_Freq / 1000, ffFixed, 70, 3);
     AY_Tiks_In_Interrupt := trunc(AY_Freq / (Interrupt_Freq / 1000 * 8) + 0.5);
     YM6TiksOnInt := AY_Freq / (Interrupt_Freq / 1000 * 8);
     VBLFreq := Interrupt_Freq / 1000;
     VBLPeriod := round(MC68000Freq / VBLFreq);
    finally
     digsoundloop_release;
    end;
  end;
end;

procedure TFrmMain.FormMouseDown(Sender: TObject; Button: TMouseButton;
 Shift: TShiftState; X, Y: integer);
var
 p: PSensZone;
 p1: PMoveZone;
 p2: PButtZone;
 OfsR: integer;
begin

 if DoBreakLongProccess then
   //any clicks to stop conversion, searching, etc
   Exit;

 if ssDouble in Shift then
   if (X >= scr_x * Scale) and (X < (scr_x + scr_width) * Scale) and
     (Y >= scr_y * Scale) and (Y < (scr_y + scr_height) * Scale) then
    begin
     Do_Scroll := not Do_Scroll;
     Exit;
    end;

 if Button = mbLeft then
  begin
   if MoveWin.Touche(X, Y) then
    begin
     {$IFNDEF Windows}
     BeginDrag(False);
     {$ENDIF Windows}
    end;
   p := SensZoneRoot;
   while p <> nil do
    begin
     if p^.Touche(X, Y) then
       p^.Clicked := True;
     p := p^.Next;
    end;
   p2 := ButtZoneRoot;
   while p2 <> nil do
    begin
     if (p2^.Clicked = 0) and p2^.Touche(X, Y) then
      begin
       p2^.Clicked := 1;
       p2^.Push;
      end;
     p2 := p2^.Next;
    end;
   p1 := MoveZoneRoot;
   while p1 <> nil do
    begin
     if p1^.Bmps then
      begin
       if p1^.ToucheBut(X, Y) then
        begin
         p1^.OldX := X div Scale;
         p1^.Delt := X div Scale - p1^.posX;
         p1^.Clicked := True;
        end
       else if p1^.Touche(X, Y) then
        begin
         p1^.Clicked := True;
         OfsR := X div Scale - p1^.zx - p1^.bm1w div 2;
         if OfsR > p1^.zw - p1^.bm1w then
           OfsR := p1^.zw - p1^.bm1w
         else if OfsR < 0 then
           OfsR := 0;
         if OfsR <> p1^.PosX then
          begin
           p1^.HideBmp;
           OffsetRgn(p1^.RgnHandle, (OfsR - p1^.PosX) * Scale, 0);
           p1^.PosX := OfsR;
           p1^.Redraw(False);
           p1^.Action(Self);
          end;
         p1^.OldX := X div Scale;
         p1^.Delt := X div Scale - p1^.posX;
        end;
      end
     else if p1^.Touche(X, Y) then
      begin
       p1^.OldX := X div Scale;
       p1^.OldY := Y div Scale;
       p1^.Clicked := True;
      end;
     p1 := p1^.Next;
    end;
  end;
end;

procedure TFrmMain.ButToolsClick(Sender: TObject);
begin
 if not ButTools.Is_On then
  begin
   ButTools.Is_On := True;
   FinderWorksNow := False;
   FrmTools := TFrmTools.Create(Self);
  end
 else if not FinderWorksNow then
   FrmTools.Close;
end;

procedure MainWinRepaint;
var
 p: PButtZone;
 p1: PMoveZone;
 p2: PLedZone;
begin
 if LedZoneRoot <> nil then
  begin
   p2 := LedZoneRoot;
   repeat
     p2^.Redraw(True);
     p2 := p2^.Next;
   until p2 = nil;
  end;
 if ButtZoneRoot <> nil then
  begin
   p := ButtZoneRoot;
   repeat
     p^.Redraw(True);
     p := p^.Next;
   until p = nil;
  end;
 if MoveZoneRoot <> nil then
  begin
   p1 := MoveZoneRoot;
   repeat
     p1^.Redraw(True);
     p1 := p1^.Next;
   until p1 = nil;
  end;

 BMP_DBuffer.Canvas.CopyMode := cmSrcCopy;
 BMP_DBuffer.Canvas.CopyRect(Bounds(scr_x, scr_y, scr_width, scr_height),
   BMP_Scroll.Canvas, Rect(0, 0, scr_width, scr_height));
 BMP_DBuffer.Canvas.CopyRect(Bounds(time_x, time_y, time_width, time_height),
   BMP_Time.Canvas, Rect(0, 0, time_width, time_height));
 FrmMain.Canvas.CopyMode := cmSrcCopy;
 FrmMain.Canvas.CopyRect(Rect(0, 0, MWWidth * Scale, MWHeight * Scale),
   BMP_DBuffer.Canvas,
   Rect(0, 0, MWWidth, MWHeight));
end;

procedure TFrmMain.ButLoopClick(Sender: TObject);
begin
 if ButLoop.Is_On then
   ButLoop.Switch_Off
 else
   ButLoop.Is_On := True;
 Do_Loop := ButLoop.Is_On;
 BASS_SetLoop;
 {$IFDEF Windows}
 MIDI_SetLoop;
 {$ENDIF Windows}
end;

constructor TSensZone.Create(ps: PSensZone; x, y, w, h: integer; pr: TNotifyEvent);
var
 p: PSensZone;
begin
 inherited Create;
 zx := x;
 zy := y;
 zw := w;
 zh := h;
 if SensZoneRoot = nil then
   SensZoneRoot := ps
 else
  begin
   p := SensZoneRoot;
   while p^.Next <> nil do p := p^.Next;
   p^.Next := ps;
  end;
 Next := nil;
 Clicked := False;
 Action := pr;
end;

function TSensZone.Touche(x, y: integer): boolean;
begin
 Result := (x >= zx * Scale) and (x < (zx + zw) * Scale) and
   (y >= zy * Scale) and (y < (zy + zh) * Scale);
end;

procedure TFrmMain.FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: integer);
var
 p: PButtZone;
 p1: PMoveZone;
 p2: PSensZone;
 OfsR: integer;
 Over: boolean;
begin
 if ssShift in Shift then
   Shift := Shift - [ssShift];
 if [ssLeft] = Shift then
  begin
   p := ButtZoneRoot;
   while p <> nil do
    begin
     if (p^.Clicked = 1) and not p^.Is_On then
       if p^.Touche(X, Y) then
         p^.Push
       else
         p^.UnPush;
     p := p^.Next;
    end;
   p1 := MoveZoneRoot;
   while p1 <> nil do
    begin
     if p1^.Clicked then
      begin
       if p1^.Bmps then
        begin
         OfsR := p1^.posX + X div Scale - p1^.OldX;
         p1^.OldX := X div Scale;
         if OfsR < 0 then
          begin
           p1^.OldX := p1^.Delt;
           OfsR := 0;
          end
         else if OfsR > p1^.zw - p1^.bm1w then
          begin
           OfsR := p1^.zw - p1^.bm1w;
           p1^.OldX := OfsR + p1^.Delt;
          end;
         if OfsR <> p1^.PosX then
          begin
           p1^.HideBmp;
           OffsetRgn(p1^.RgnHandle, (OfsR - p1^.PosX) * Scale, 0);
           p1^.PosX := OfsR;
           p1^.Redraw(False);
           p1^.Action(Self);
          end;
        end
       else
        begin
         p1^.PosX := X div Scale - p1^.OldX;
         p1^.PosY := Y div Scale - p1^.OldY;
         p1^.Action(Self);
        end;
      end;
     p1 := p1^.Next;
    end;
  end
 else if (Cursor = crDefault) or (Cursor = crHandPoint) then
  begin
   Over := MoveScr.Touche(X, Y);
   if not Over then
    begin
     p2 := SensZoneRoot;
     while p2 <> nil do
      begin
       if p2^.Touche(X, Y) then
        begin
         Over := True;
         Break;
        end;
       p2 := p2^.Next;
      end;
    end;
   if Over then
     Cursor := crHandPoint
   else
     Cursor := crDefault;
  end;
end;

procedure TFrmMain.FormMouseUp(Sender: TObject; Button: TMouseButton;
 Shift: TShiftState; X, Y: integer);
var
 p: PSensZone;
 p1: PMoveZone;
 p2: PButtZone;
begin
 if Button = mbLeft then
  begin
   p := SensZoneRoot;
   while p <> nil do
    begin
     if p^.Clicked then
      begin
       if p^.Touche(X, Y) then
         p^.Action(Self);
       p^.Clicked := False;
      end;
     p := p^.Next;
    end;
   p2 := ButtZoneRoot;
   while p2 <> nil do
    begin
     if p2^.Clicked = 1 then
      begin
       if p2^.Touche(X, Y) then
         p2^.Action(Self);
       p2^.Clicked := 0;
      end;
     p2 := p2^.Next;
    end;
   p1 := MoveZoneRoot;
   while p1 <> nil do
    begin
     if p1^.Clicked then
      begin
       p1^.Clicked := False;
       p1^.Action(Self);
      end;
     p1 := p1^.Next;
    end;
  end;
end;

constructor TButtZone.Create(ps: PButtZone; x, y, w, h: integer;
 Bmp: TBitmap; x1, y1, x2, y2: integer; pr: TNotifyEvent);
var
 p: PButtZone;
begin
 inherited Create;
 zx := x;
 zy := y;
 zw := w;
 zh := h;
 RgnHandle := 0;
 if ButtZoneRoot = nil then
   ButtZoneRoot := ps
 else
  begin
   p := ButtZoneRoot;
   while p^.Next <> nil do p := p^.Next;
   p^.Next := ps;
  end;
 Next := nil;
 Is_On := False;
 Is_Pushed := False;
 Clicked := 0;
 Action := pr;
 Bmp1 := TBitmap.Create;
 Bmp1.Width := zw;
 Bmp1.Height := zh;
 Bmp1.Canvas.CopyMode := cmSrcCopy;
 Bmp1.Canvas.CopyRect(Rect(0, 0, zw, zh), Bmp.Canvas, Bounds(x1, y1, zw, zh));
 Bmp2 := TBitmap.Create;
 Bmp2.Width := zw;
 Bmp2.Height := zh;
 Bmp2.Canvas.CopyMode := cmSrcCopy;
 Bmp2.Canvas.CopyRect(Rect(0, 0, zw, zh), Bmp.Canvas, Bounds(x2, y2, zw, zh));
end;

function TButtZone.Touche(x, y: integer): boolean;
begin
 if RgnHandle <> 0 then
   Result := PtInRegion(RgnHandle, x, y)
 else
   Result := (x >= zx * Scale) and (x < (zx + zw) * Scale) and
     (y >= zy * Scale) and (y < (zy + zh) * Scale);
end;

procedure TButtZone.Free;
begin
 Bmp1.Free;
 Bmp2.Free;
 inherited;
end;

procedure TButtZone.Redraw(OnCanvas: boolean);
begin
 if OnCanvas then
  begin
   BMP_DBuffer.Canvas.CopyMode := cmSrcCopy;
   if not Is_Pushed then
     BMP_DBuffer.Canvas.CopyRect(Bounds(zx, zy, zw, zh), Bmp1.Canvas, Rect(0, 0, zw, zh))
   else
     BMP_DBuffer.Canvas.CopyRect(Bounds(zx, zy, zw, zh), Bmp2.Canvas,
       Rect(0, 0, zw, zh));
  end
 else
  begin
   FrmMain.Canvas.CopyMode := cmSrcCopy;
   if not Is_Pushed then
     FrmMain.Canvas.CopyRect(Bounds(zx * Scale, zy * Scale, zw * Scale, zh * Scale),
       Bmp1.Canvas, Rect(0, 0, zw, zh))
   else
     FrmMain.Canvas.CopyRect(Bounds(zx * Scale, zy * Scale, zw * Scale, zh * Scale),
       Bmp2.Canvas, Rect(0, 0, zw, zh));
  end;
end;

procedure TButtZone.Push;
begin
 if not Is_Pushed then
  begin
   Is_Pushed := True;
   Redraw(False);
  end;
end;

procedure TButtZone.UnPush;
begin
 if Is_Pushed then
  begin
   Is_Pushed := False;
   Redraw(False);
  end;
end;

procedure TButtZone.Switch_On;
begin
 if not Is_On then
   Is_On := True;
 Push;
end;

procedure TButtZone.Switch_Off;
begin
 if Is_On then
   Is_On := False;
 UnPush;
end;

constructor TLedZone.Create(ps: PLedZone; x, y, w, h: integer;
 Bmp: TBitmap; x1, y1, x2, y2: integer);
var
 p: PLedZone;
begin
 inherited Create;
 zx := x;
 zy := y;
 zw := w;
 zh := h;
 if LedZoneRoot = nil then
   LedZoneRoot := ps
 else
  begin
   p := LedZoneRoot;
   while p^.Next <> nil do p := p^.Next;
   p^.Next := ps;
  end;
 Next := nil;
 State := False;
 Bmp1 := TBitmap.Create;
 Bmp1.Width := zw;
 Bmp1.Height := zh;
 Bmp1.Canvas.CopyMode := cmSrcCopy;
 Bmp1.Canvas.CopyRect(Rect(0, 0, zw, zh), Bmp.Canvas, Bounds(x1, y1, zw, zh));
 Bmp2 := TBitmap.Create;
 Bmp2.Width := zw;
 Bmp2.Height := zh;
 Bmp2.Canvas.CopyMode := cmSrcCopy;
 Bmp2.Canvas.CopyRect(Rect(0, 0, zw, zh), Bmp.Canvas, Bounds(x2, y2, zw, zh));
end;

procedure TLedZone.Redraw(OnCanvas: boolean);
begin
 if OnCanvas then
  begin
   BMP_DBuffer.Canvas.CopyMode := cmSrcCopy;
   if not State then
     BMP_DBuffer.Canvas.CopyRect(Bounds(zx, zy, zw, zh), Bmp1.Canvas, Rect(0, 0, zw, zh))
   else
     BMP_DBuffer.Canvas.CopyRect(Bounds(zx, zy, zw, zh), Bmp2.Canvas,
       Rect(0, 0, zw, zh));
  end
 else
  begin
   FrmMain.Canvas.CopyMode := cmSrcCopy;
   if not State then
     FrmMain.Canvas.CopyRect(Bounds(zx * Scale, zy * Scale, zw * Scale, zh * Scale),
       Bmp1.Canvas, Rect(0, 0, zw, zh))
   else
     FrmMain.Canvas.CopyRect(Bounds(zx * Scale, zy * Scale, zw * Scale, zh * Scale),
       Bmp2.Canvas, Rect(0, 0, zw, zh));
  end;
end;

procedure TLedZone.Free;
begin
 Bmp1.Free;
 Bmp2.Free;
 inherited;
end;

procedure TFrmMain.ButCloseClick(Sender: TObject);
begin
 Close;
end;

procedure TFrmMain.ButAboutClick(Sender: TObject);
begin
 with TAboutBox.Create(Self) do
  try
   AbDBuffer.Canvas.Brush.Style := bsClear;
   {$ifdef beta}
   AbDBuffer.Canvas.Font.Height:={$IFDEF Windows}16{$ELSE}10{$ENDIF};
   AbDBuffer.Canvas.TextOut(122-AbDBuffer.Canvas.TextWidth(BetaNumber) div 2,
                            248-AbDBuffer.Canvas.TextHeight(BetaNumber),
                            BetaNumber);
   {$endif beta}
   AbDBuffer.Canvas.Font.Height:={$IFDEF Windows}46{$ELSE}34{$ENDIF};
   AbDBuffer.Canvas.TextOut(122-AbDBuffer.Canvas.TextWidth(VersionString) div 2,
                            260-AbDBuffer.Canvas.TextHeight(VersionString) div 2,
                            VersionString);
   ShowModal;
  finally
   Free;
   ButAbout.UnPush;
  end;
end;

procedure TFrmMain.ButSpaClick(Sender: TObject);
begin
 SpectrumChecked := not SpectrumChecked;
end;

procedure TFrmMain.ButAmpClick(Sender: TObject);
begin
 IndicatorChecked := not IndicatorChecked;
end;

procedure TFrmMain.ButTimeClick(Sender: TObject);
begin
 Inc(TimeMode);
 if TimeMode > 2 then TimeMode := 0;
 TimeShown := -MaxInt;
end;

constructor TMoveZone.Create(ps: PMoveZone; x, y, w, h, y1, h1: integer;
 pr: TNotifyEvent);
var
 p: PMoveZone;
begin
 inherited Create;
 zx := x;
 zy := y;
 zw := w;
 zh := h;
 zy1 := y1;
 zh1 := h1;
 RgnHandle := 0;
 PosX := 0;
 if MoveZoneRoot = nil then
   MoveZoneRoot := ps
 else
  begin
   p := MoveZoneRoot;
   while p^.Next <> nil do p := p^.Next;
   p^.Next := ps;
  end;
 Next := nil;
 Bmps := False;
 State := False;
 Clicked := False;
 Action := pr;
end;

function TMoveZone.ToucheBut(x, y: integer): boolean;
begin
 Result := PtInRegion(RgnHandle, x, y);
end;

function TMoveZone.Touche(x, y: integer): boolean;
begin
 Result := ((x >= zx * Scale) and (x < (zx + zw) * Scale) and
   (y >= (zy + zy1) * Scale) and (y < (zy + zy1 + zh1) * Scale));
end;

procedure TFrmMain.DoMovingWindow(Sender: TObject);
begin
(*{$IFNDEF Windows}
Left := Left + MoveWin.PosX;
Top := Top + MoveWin.PosY;
{$ENDIF Windows}*)
end;

procedure TFrmMain.DoMovingScroll(Sender: TObject);
begin
 Inc(MoveScr.OldX, MoveScr.PosX);
 if sw <= scr_width then
   Exit;
 if Scroll_Distination <> Item_Displayed then
   Exit;
 Dec(HorScrl_Offset, MoveScr.PosX);
 if HorScrl_Offset < 0 then
   HorScrl_Offset := 0
 else if HorScrl_Offset > sw - scr_width then
   HorScrl_Offset := sw - scr_width;
 RedrawScroll;
end;

procedure TMoveZone.AddBitmaps(Bmp: TBitmap; x1, y1, bw, bh: integer; m: boolean);
begin
 Bmps := True;
 Bmp1 := TBitmap.Create;
 Bmp1.Width := bw;
 Bmp1.Height := bh;
 Bm1w := bw;
 Bm1h := bh;
 Bmp1.Canvas.CopyMode := cmSrcCopy;
 Bmp1.Canvas.CopyRect(Rect(0, 0, bw, bh), Bmp.Canvas, Bounds(x1, y1, bw, bh));
 if m then
  begin
   Bmp1.TransparentColor := Bmp1.Canvas.Pixels[0, 0];
   Bmp1.Transparent := True;
   Bmp1.TransparentMode := tmFixed;
  end;
 Bmp2 := TBitmap.Create;
 Bmp2.Width := zw;
 Bmp2.Height := zh;
 Bmp2.Canvas.CopyMode := cmSrcCopy;
 Bmp2.Canvas.CopyRect(Rect(0, 0, zw, zh), Bmp.Canvas, Bounds(zx, zy, zw, zh));
end;

procedure TMoveZone.Free;
begin
 if Bmps then
  begin
   Bmp1.Free;
   Bmp2.Free;
  end;
 inherited;
end;

procedure TMoveZone.Redraw(OnCanvas: boolean);
begin
 if Bmps then
  begin
   BMP_DBuffer.Canvas.Draw(zx + PosX, zy, Bmp1);
   if not OnCanvas then
    begin
     FrmMain.Canvas.CopyMode := cmSrcCopy;
     FrmMain.Canvas.CopyRect(Bounds(zx * Scale, zy * Scale, zw * Scale, zh * Scale),
       BMP_DBuffer.Canvas, Bounds(zx, zy, zw, zh));
    end;
  end;
end;

procedure TMoveZone.HideBmp;
begin
 if Bmps then
  begin
   BMP_DBuffer.Canvas.CopyMode := cmSrcCopy;
   BMP_DBuffer.Canvas.CopyRect(Bounds(zx + PosX, zy, Bm1w, Bm1h), Bmp2.Canvas,
     Bounds(PosX, 0, Bm1w, Bm1h));
  end;
end;

procedure TFrmMain.DoMovingVol(Sender: TObject);
begin
 VolumeCtrl := MoveVol.PosX;
 SetSysVolume;
end;

procedure Rewind(newpos, maxpos: integer);
var
 i, d: longword;
 {$IFDEF Windows}
 MSF: packed record
   case boolean of
     True: (MSF: DWORD);
     False: (M, S, F: byte);
    end;
 {$ENDIF Windows}
begin
 if not IsPlaying or Paused or MoveProgr.Clicked
   {$IFDEF Windows}
   or (IsMIDIFileType(CurFileType) and MIDIParams^.seeking)
 {$ENDIF Windows}
 then
   Exit;
 if ProgrMax = longword(-1) then
   Exit;
 if newpos < 0 then
   newpos := 0
 else if newpos > maxpos then
   newpos := maxpos;
 i := Trunc(newpos / maxpos * ProgrMax + 0.5);
 ShowProgress(i);
 if IsStreamOrModuleFileType(CurFileType) then
  begin
   if IsStreamFileType(CurFileType) and (StreamPlayFrom > 0) then
     d := StreamPlayFrom
   else
     d := 0;
   if not Do_Loop and (i >= ProgrMax - 50) then
     //no need to seek to the end area if not looped
     PostMessage(FrmMain.Handle, WM_PLAYNEXTITEM, 0, 0)
   else if Do_Loop and (i >= ProgrMax - 50) and IsStreamFileType(CurFileType) then
     //seek to begin of strem instead of end area if looped
    begin
     if not BASS_ChannelSetPosition(MusicHandle, BASS_ChannelSeconds2Bytes(
       MusicHandle, d / 1000), BASS_POS_BYTE) then
       //show cause of fail and raise
       RaiseLastBASSError;
     CurrTime_Rasch := 0;
    end
   else if BASS_ChannelSetPosition(MusicHandle, BASS_ChannelSeconds2Bytes(
     MusicHandle, (i + d) / 1000), BASS_POS_BYTE) then
     CurrTime_Rasch := i
   else if not Do_Loop then
     //seeking after end or any other error, hide error and play next
     PostMessage(FrmMain.Handle, WM_PLAYNEXTITEM, 0, 0)
   else if (i > 1) and //last chance for looped music before raising - seek to 1 ms before
     BASS_ChannelSetPosition(MusicHandle, BASS_ChannelSeconds2Bytes(
     MusicHandle, (i - 1 + d) / 1000), BASS_POS_BYTE) then
     CurrTime_Rasch := i - 1
   else
     //don't hide error in loop mode, show and raise
     RaiseLastBASSError;
  end
 {$IFDEF Windows}
 else if IsCDFileType(CurFileType) then
  begin
   CurrTime_Rasch := round(i / 75 * 1000);
   MSF.F := i mod 75;
   i := i div 75;
   MSF.S := i mod 60;
   MSF.M := i div 60;
   CDSetPosition(CurCDNum, CurCDTrk, MSF.MSF, FrmMain.Handle);
  end
 else if IsMIDIFileType(CurFileType) then
  begin
   MIDIParams^.seek_to := i;
   CurrTime_Rasch := i;
   MIDIParams^.seeking := True;
  end
 {$ENDIF Windows}
 else
  begin
   {$IFNDEF UseBassForEmu}
   digsoundloop_catch;
   {$ELSE UseBassForEmu}
   BASS_ChannelStop(MusicHandle);
   {$ENDIF UseBassForEmu}
    try
     RerollMusic(newpos, maxpos);
    finally
     {$IFNDEF UseBassForEmu}
     digsound_reset;
     MkVisPos := 0;
     VisPoint := 0;
     NOfTicks := 0;
     digsoundloop_release;
     {$ELSE UseBassForEmu}
     BASS_ChannelPlay(MusicHandle,True);
     {$ENDIF UseBassForEmu}
    end;
  end;
end;

procedure TFrmMain.DoMovingProgr(Sender: TObject);
begin
 Rewind(MoveProgr.PosX, ProgrWidth);
end;

{$IFDEF dbgmode}
//to catch GTK2 issues in variouos Linuxes
procedure LogWState(const Capt:string);
begin
  Log(Capt + ' WindowState:'#10+
    #9'FrmMain='+GetEnumName(TypeInfo(TWindowState), Ord(FrmMain.WindowState))+
    #9'FrmPLst='+GetEnumName(TypeInfo(TWindowState), Ord(FrmPLst.WindowState))+
    #9'FrmMixer='+GetEnumName(TypeInfo(TWindowState), Ord(FrmMixer.WindowState)));
end;
{$ENDIF dbgmode}

procedure TFrmMain.DoMinimize;
begin
 {$IFDEF dbgmode}
 LogWState('Before Application.Minimize');
 {$ENDIF dbgmode}

 {$IFNDEF Windows}
 //GTK widgetset.Minimize skips all windows with bsNone (even main form)
 WindowState := wsMinimized;
 //OnMinimize is not raised if ws set in code
 AppMinimized(Self);
 {$ENDIF Windows}

 Application.Minimize;

 {$IFDEF dbgmode}
 LogWState('After Application.Minimize');
 {$ENDIF dbgmode}
end;

procedure TFrmMain.ButMinClick(Sender: TObject);
begin
 ButMinimize.UnPush;
 DoMinimize;
end;

procedure TFrmMain.AppModalBegin(Sender: TObject);
begin
 AppIsModal := True;
end;

procedure TFrmMain.AppModalEnd(Sender: TObject);
begin
 AppIsModal := False;
end;

procedure TFrmMain.AppMinimized(Sender: TObject);
begin
 {$IFDEF dbgmode}
 LogWState('Enter AppMinimized');
 {$ENDIF dbgmode}
 case TrayMode of
   {$IFDEF Windows}
   1:
     //LCL cannot minimize tool window app
     ShowWindow(GetParent(FrmMain.Handle), SW_HIDE);
   {$ENDIF Windows}
   2:
    begin
     if AddTrayIcon then
      RemoveTaskbarButton;
    end;
  end;
 {$IFDEF dbgmode}
 LogWState('Exit AppMinimized');
 {$ENDIF dbgmode}
end;

{$IFNDEF Windows}
procedure TFrmMain.CheckMin(Data: PtrInt);
var
 i:integer;
 aForm:TCustomForm;
begin
if not Assigned(Screen) then
 Exit;
for i := 0 to Screen.CustomFormZOrderCount-1 do
 begin
   aForm := Screen.CustomFormsZOrdered[i];
   if Assigned(aForm) then
    begin
     if aForm.WindowState = wsMinimized then
      //in Linux Mint forms except MainForm are not restored, do it manually
      begin
       aForm.WindowState := wsNormal;
       if aForm.Visible then
        begin
         aForm.Hide;
         aForm.Show;
        end;
      end;
    end;
 end;
BringToFront;
end;
{$ENDIF Windows}

procedure TFrmMain.AppRestored(Sender: TObject);
begin
 {$IFDEF dbgmode}
 LogWState('Enter AppRestored');
 {$ENDIF dbgmode}
 if TrayMode = 2 then
  begin
   RemoveTrayIcon;
   AddTaskbarButton;
  end;

 {$IFNDEF Windows}
 Application.QueueAsyncCall(@CheckMin,0);
 {$ENDIF Windows}

 {$IFDEF dbgmode}
 LogWState('Exit AppRestored');
 {$ENDIF dbgmode}
end;

procedure TFrmMain.DoRestore;
begin
 {$IFDEF dbgmode}
 LogWState('Before Application.Restore');
 {$ENDIF dbgmode}

 {$IFNDEF Windows}
 //GTK widgetset.Minimize skips all windows with bsNone (even main form)
 WindowState := wsNormal;
 //OnMinimize is not raised if ws set in code
 AppRestored(Self);
 {$ENDIF Windows}

 Application.Restore;

 {$IFDEF dbgmode}
 LogWState('After Application.Restore');
 {$ENDIF dbgmode}
end;

procedure TFrmMain.ShowApp(Tray: boolean);
begin
 if WindowState = wsMinimized then
   DoRestore
 {$IFDEF Windows}
 else if not Tray then
  begin //real bring to front instead of taskbar button flashing
   if TrayMode = 2 then TrayMode := -1;
   DoMinimize;
   DoRestore;
   if TrayMode = -1 then TrayMode := 2;
  end
 {$ENDIF Windows}
 else
   Application.BringToFront; //todo в GTK не работает
end;

{$IFDEF Windows}
function IsWindowStayOnTop(h: THandle): boolean;
begin
 Result := GetWindowLong(h, GWL_EXSTYLE) and WS_EX_TOPMOST <> 0;
end;

function IsApplicationForm(h: THandle): boolean;
var
 i: integer;
begin
 for i := 0 to Screen.CustomFormCount - 1 do
   if Screen.CustomForms[i].Handle = h then
     Exit(True);
 Result := False;
end;

function Overlapped: boolean;
var
 R1, R2: TRect;
 h: THandle;
begin
 Result := False;
 h := FrmMain.Handle;
 if not GetWindowRect(h, R1) then Exit;
 repeat
   h := GetNextWindow(h, GW_HWNDPREV);
   if h = 0 then Exit;
   if not IsWindowVisible(h) then continue;
   if IsWindowStayOnTop(h) then continue;
   if not GetWindowRect(h, R2) then continue;
   if R2.Left = R2.Right then continue;
   if R2.Top = R2.Bottom then continue;
   if R1.Left > R2.Right then continue;
   if R1.Right < R2.Left then continue;
   if R1.Top > R2.Bottom then continue;
   if R1.Bottom < R2.Top then continue;
   if IsApplicationForm(h) then continue;
   Exit(True);
 until False;
end;
{$ENDIF Windows}

procedure TFrmMain.TrayIcon1DblClick(Sender: TObject);
begin
 TrayIconClicked := True;
end;

procedure TFrmMain.TrayIcon1MouseDown(Sender: TObject; Button: TMouseButton;
 Shift: TShiftState; X, Y: integer);
begin
 if Button = mbLeft then
   TrayIconClicked := True;
end;

procedure TFrmMain.TrayIcon1MouseUp(Sender: TObject; Button: TMouseButton;
 Shift: TShiftState; X, Y: integer);
begin
 if Button <> mbLeft then
   Exit;
 if TrayIconClicked then
  begin
   TrayIconClicked := False;
   if (WindowState = wsMinimized)
     {$IFDEF Windows}
     or Overlapped
   {$ENDIF Windows}
   then
     ShowApp(True)
   else
     DoMinimize;
  end;
end;

{$IFDEF Windows}
function WndCallback(Ahwnd: HWND; uMsg: UINT; wParam: WParam;
 lParam: LParam): LRESULT; stdcall;
var
 r: _RECT;
begin
 case uMsg of
   WM_NCHITTEST:
    begin
     if GetWindowRect(Ahwnd, r) and MoveWin.Touche(GET_X_LPARAM(lParam) -
       r.Left, GET_Y_LPARAM(lParam) - r.Top) then
       Result := HTCAPTION
     else
       Result := DefWindowProc(Ahwnd, uMsg, wParam, lParam);
     Exit;
    end;
   MM_MCINOTIFY:
    begin
     if CheckCDNum(CurCDNum) then
       if LParam = integer(CDIDs[CurCDNum]) then
         if WParam = MCI_NOTIFY_SUCCESSFUL then
          begin
           PostMessage(Ahwnd, WM_PLAYNEXTITEM, 0, 0);
           Exit(0);
          end;
    end;
  end;
 Result := CallWindowProc(PrevWndProc, Ahwnd, uMsg, WParam, LParam);
end;

function AWndCallback(Ahwnd: HWND; uMsg: UINT; wParam: WParam;
 lParam: LParam): LRESULT; stdcall;
var
 NeedShowTrayIcon: boolean;
begin
 NeedShowTrayIcon := False;
 case uMsg of
   WM_SYSCOMMAND:
     case (WParam and $FFF0) of
       SC_MINIMIZE:
         //LCL cannot minimize app tool window
         if TrayMode = 1 then ShowWindow(GetParent(FrmMain.Handle), SW_HIDE);
       SC_RESTORE:
        begin
         //LCL cannot restore hidden app tool window
         if TrayMode = 1 then ShowWindow(GetParent(FrmMain.Handle), SW_SHOWNA);

         //mask LCL error (helper ttrayicon window become visible after
         //show popup menu and calling application.restore)
         if LCLBugWasTrayPopup and FrmMain.TrayIcon1.Visible then
          begin
           FrmMain.TrayIcon1.Hide;
           NeedShowTrayIcon := (TrayMode = 1);
          end;
        end;
      end;
  end;
 Result := CallWindowProc(PrevAWndProc, Ahwnd, uMsg, WParam, LParam);
 if NeedShowTrayIcon then
  begin
   FrmMain.TrayIcon1.Show;
   LCLBugWasTrayPopup := False;
  end;
end;
{$ENDIF Windows}

procedure DestroyRgn;
begin
 DeleteObject(RgnProgr);
 DeleteObject(RgnVol);
 DeleteObject(RgnClose);
 DeleteObject(RgnMin);
 DeleteObject(RgnTools);
 DeleteObject(RgnPList);
 DeleteObject(RgnMixer);
 DeleteObject(RgnOpen);
 DeleteObject(RgnNext);
 DeleteObject(RgnStop);
 DeleteObject(RgnPause);
 DeleteObject(RgnPlay);
 DeleteObject(RgnBack);
 DeleteObject(RgnLoop);
 DeleteObject(MyFormRgn);
 MyFormRgn := 0;
end;

//set buttzone's and movezone's regions with created in PrepareRgn
procedure ClueRgn;
begin
 MoveVol.RgnHandle := RgnVol;
 MoveProgr.RgnHandle := RgnProgr;
 ButPlay.RgnHandle := RgnPlay;
 ButPrev.RgnHandle := RgnBack;
 ButNext.RgnHandle := RgnNext;
 ButOpen.RgnHandle := RgnOpen;
 ButStop.RgnHandle := RgnStop;
 ButPause.RgnHandle := RgnPause;
 ButLoop.RgnHandle := RgnLoop;
 ButMixer.RgnHandle := RgnMixer;
 ButList.RgnHandle := RgnPList;
 ButTools.RgnHandle := RgnTools;
 ButMinimize.RgnHandle := RgnMin;
 ButClose.RgnHandle := RgnClose;
end;

procedure TFrmMain.PrepareRgn;

{ $define CreateRgn}

{$ifdef CreateRgn}
 function AddRoundRectRgnR(a,b,c,d,e,f:integer):HRGN;
 begin
  Result := CreateRoundRectRgn(a,b,c,d,e,f);
  CombineRgn(MyFormRgn,MyFormRgn,Result,RGN_OR);
 end;

 procedure AddRoundRectRgn(a,b,c,d,e,f:integer);
 begin
  DeleteObject(AddRoundRectRgnR(a,b,c,d,e,f));
 end;
{$endif CreateRgn}
const
 VolPointsN = 2;
 ProgrPointsN = 11;
 MaxN = ProgrPointsN;
var
 {$ifndef CreateRgn}
 hr: HRGN;
 {$endif CreateRgn}
 i: integer;
 PolyRgnScaled: array[0..MaxN] of TPoint;
const
 RegionVolPoints: array[0..VolPointsN] of TPoint =
   ((x: 237 + 70 - 18; y: 21 + 11 + 1), (x: 237 + 70; y: 21 + 11 + 1), (x: 237 + 70;
   y: 21 + 1));
 RegionProgrPoints: array[0..ProgrPointsN] of TPoint =
   ((x: 96; y: 84), (x: 100; y: 84), (x: 100; y: 83), (x: 112; y: 83), (x: 112; y: 84),
   (x: 116; y: 84), (x: 116; y: 92), (x: 112; y: 92), (x: 112; y: 93), (x: 100; y: 93),
   (x: 100; y: 92), (x: 96; y: 92));

 {$ifndef CreateRgn}
 {$i rgn.inc}
 {$endif CreateRgn}
begin
 if MyFormRgn <> 0 then
   DestroyRgn;

 {$ifdef CreateRgn}
MyFormRgn := CreateRectRgn(51,1,311,114);
AddRoundRectRgn(0,0,115,115,115,115);
AddRoundRectRgn(358-115,0,358,115,115,115);
 {$endif CreateRgn}
 RgnLoop :=
   {$ifdef CreateRgn}
  AddRoundRectRgnR
   {$else CreateRgn}
   CreateRoundRectRgn
   {$endif CreateRgn}
   ((62 - 10) * Scale, (110 - 10) * Scale, (62 + 11) * Scale,
   (110 + 11) * Scale, 21 * Scale, 21 * Scale);
 RgnBack :=
   {$ifdef CreateRgn}
  AddRoundRectRgnR
   {$else CreateRgn}
   CreateRoundRectRgn
   {$endif CreateRgn}
   (80 * Scale, 96 * Scale, (80 + 35) * Scale, 123 * Scale, 14 * Scale, 14 * Scale);
 RgnPlay :=
   {$ifdef CreateRgn}
  AddRoundRectRgnR
   {$else CreateRgn}
   CreateRoundRectRgn
   {$endif CreateRgn}
   (119 * Scale, 96 * Scale, (119 + 35) * Scale, 123 * Scale, 14 * Scale, 14 * Scale);
 RgnPause :=
   {$ifdef CreateRgn}
  AddRoundRectRgnR
   {$else CreateRgn}
   CreateRoundRectRgn
   {$endif CreateRgn}
   (158 * Scale, 96 * Scale, (158 + 35) * Scale, 123 * Scale, 14 * Scale, 14 * Scale);
 RgnStop :=
   {$ifdef CreateRgn}
  AddRoundRectRgnR
   {$else CreateRgn}
   CreateRoundRectRgn
   {$endif CreateRgn}
   (197 * Scale, 96 * Scale, (197 + 35) * Scale, 123 * Scale, 14 * Scale, 14 * Scale);
 RgnNext :=
   {$ifdef CreateRgn}
  AddRoundRectRgnR
   {$else CreateRgn}
   CreateRoundRectRgn
   {$endif CreateRgn}
   (235 * Scale, 96 * Scale, (235 + 35) * Scale, 123 * Scale, 14 * Scale, 14 * Scale);
 RgnOpen :=
   {$ifdef CreateRgn}
  AddRoundRectRgnR
   {$else CreateRgn}
   CreateRoundRectRgn
   {$endif CreateRgn}
   (275 * Scale, 96 * Scale, (275 + 35) * Scale, 123 * Scale, 14 * Scale, 14 * Scale);
 RgnMixer := CreateRoundRectRgn(318 * Scale, 21 * Scale, (318 + 26) *
   Scale, (21 + 26) * Scale, 26 * Scale, 26 * Scale);
 RgnPList := CreateRoundRectRgn(310 * Scale, 77 * Scale, (310 + 26) *
   Scale, (77 + 26) * Scale, 26 * Scale, 26 * Scale);
 RgnTools := CreateRoundRectRgn(322 * Scale, 50 * Scale, (322 + 26) *
   Scale, (50 + 26) * Scale, 26 * Scale, 26 * Scale);
 RgnMin := CreateRoundRectRgn(282 * Scale, 6 * Scale, (282 + 16) *
   Scale, (6 + 16) * Scale, 16 * Scale, 16 * Scale);
 RgnClose := CreateRoundRectRgn(304 * Scale, 6 * Scale, (304 + 16) *
   Scale, (6 + 16) * Scale, 16 * Scale, 16 * Scale);

 for i := 0 to VolPointsN do
  begin
   PolyRgnScaled[i].X := RegionVolPoints[i].X * Scale;
   PolyRgnScaled[i].Y := RegionVolPoints[i].Y * Scale;
  end;

 RgnVol := CreatePolygonRgn(PolyRgnScaled, VolPointsN + 1, ALTERNATE);

 for i := 0 to ProgrPointsN do
  begin
   PolyRgnScaled[i].X := RegionProgrPoints[i].X * Scale;
   PolyRgnScaled[i].Y := RegionProgrPoints[i].Y * Scale;
  end;

 RgnProgr := CreatePolygonRgn(PolyRgnScaled, ProgrPointsN + 1, ALTERNATE);

 {$ifndef CreateRgn}
 with rgn[0] do
   MyFormRgn := CreateRectRgn(x * Scale, y * Scale, (x + w) * Scale, (y + h) * Scale);
 for i := 1 to nrects do
   with rgn[i] do
    begin
     hr := CreateRectRgn(x * Scale, y * Scale, (x + w) * Scale, (y + h) * Scale);
     CombineRgn(MyFormRgn, MyFormRgn, hr, RGN_OR);
     DeleteObject(hr);
    end;
 {$endif CreateRgn}

 Width := MWWidth * Scale;
 Height := MWHeight * Scale;

 Application.QueueAsyncCall(@SetRgn, 0);
end;

procedure TFrmMain.SetRgn(Data: PtrInt);
begin
 SetWindowRgn(Handle, MyFormRgn, True);
end;

procedure TFrmMain.RecreateRgn;
begin
 PrepareRgn;
 ClueRgn;
end;

procedure TFrmMain.FormCreate(Sender: TObject);
var
 i: integer;
begin
 Randomize;

 PrepareRgn;

 SensSpa := TSensZone.Create(@SensSpa, spa_x, spa_y, spa_width, spa_height,
   @ButSpaClick);
 SensAmp := TSensZone.Create(@SensAmp, amp_x, amp_y, amp_width, amp_height,
   @ButAmpClick);
 SensTime := TSensZone.Create(@SensTime, time_x, time_y, time_width,
   time_height, @ButTimeClick);
 MoveWin := TMoveZone.Create(@MoveWin, 84, 5, 279 - 84, 22 - 5, 0,
   22 - 5, @DoMovingWindow);
 MoveVol := TMoveZone.Create(@MoveVol, 237, 21 + 1, 70, 12, 4, 8, @DoMovingVol);
 MoveProgr := TMoveZone.Create(@MoveProgr, 96, 83, 255 - 96, 10, 2, 5, @DoMovingProgr);
 MoveScr := TMoveZone.Create(@MoveScr, scr_x, scr_y, scr_width, scr_height,
   0, scr_height, @DoMovingScroll);

 BMP_DBuffer := TBitmap.Create;
 BMP_DBuffer.Width := MWWidth;
 BMP_DBuffer.Height := MWHeight;

 LoadSkin('', True);

 VolumeCtrl := MoveVol.zw - MoveVol.Bm1w;
 VolumeCtrlMax := VolumeCtrl;
 MoveVol.PosX := VolumeCtrl;

 ProgrWidth := MoveProgr.zw - MoveProgr.Bm1w;

 Led_AY.State := True;

 PSpa_prev := @Spa_prev;
 PSpa_piks := @Spa_piks;
 Synthesizer := @Synthesizer_Stereo16;
 Application.OnRestore := @AppRestored;
 Application.OnMinimize := @AppMinimized;
 Application.OnModalBegin := @AppModalBegin;
 Application.OnModalEnd := @AppModalEnd;
 Application.OnEndSession := @AppEndSession;
 Application.TaskBarBehavior := tbSingleButton;

 Application.Title := 'Ay_Emul'; //avoid undesired behavior of GetAppConfigDirUTF8
 FIDO_Descriptor_Filename := GetAppConfigDirUTF8(False) + 'aystatus.txt';

 for i := 0 to spa_num - 1 do Spa_piks[i] := 0;

 BMP_Sources := TBitmap.Create;
 BMP_Sources.Width := max_src;
 BMP_Sources.Height := max_height;

 BMP_Time := TBitmap.Create;
 BMP_Time.Width := time_width;
 BMP_Time.Height := time_height;
 BMP_Time.Canvas.Font.Bold := True;
 BMP_Time.Canvas.Font.Color := $464646;
 BMP_Time.Canvas.Brush.Style := bsClear;

 BMP_Vis := TBitmap.Create;
 BMP_Vis.Width := max_width2;
 BMP_Vis.Height := max_height2;
 BMP_Vis.Canvas.Pen.Color := $464646;
 BMP_Vis.Canvas.Pen.Width := 3;

 BMP_VScroll := TBitmap.Create;
 BMP_VScroll.Width := scr_width;
 BMP_VScroll.Height := scr_lineheight * 3;
 BMP_VScroll.Canvas.Font.Bold := True;
 BMP_VScroll.Canvas.Font.Height := -scr_lineheight;
 BMP_VScroll.Canvas.Font.Color := $606060;
 //отступ для центровки
 sh:=scr_lineheight-BMP_VScroll.Canvas.TextHeight('0'){$ifdef linux}+1{$endif};

 BMP_Scroll := TBitmap.Create;
 BMP_Scroll.Width := scr_width;
 BMP_Scroll.Height := scr_lineheight;

 BMP_VScroll.Canvas.Brush.Color := clWhite;
 BMP_VScroll.Canvas.FillRect(0, 0, scr_width, scr_lineheight * 3);
 CopyBmpSources;

 GetTimeQueue := TFPIntList.Create;

 VisTimer := TTimer.Create(Self);
 VisTimer.Interval := VisTimerPeriod;
 VisTimer.OnTimer := @VisTimerEvent;
 VisTimer.Enabled := True;

 {$IFDEF Windows}
 PrevWndProc :={%H-}Windows.WNDPROC(SetWindowLongPtr(
   Handle, GWL_WNDPROC,{%H-}PtrInt(@WndCallback)));
 PrevAWndProc :={%H-}Windows.WNDPROC(SetWindowLongPtr(
   GetParent(Handle), GWL_WNDPROC,{%H-}PtrInt(@AWndCallback)));
 {$ENDIF Windows}

 IPCServer.OnMessage := @IPCMessage;

 SNDHTimeDBInit;
end;

procedure SetScrollString(const scrstr: string);
begin
 ss := scrstr;
 GetStringWnJ(ss, sw, sj);
 if scr_lineheight * (Scroll_Distination - Item_Displayed + 1) - Scroll_Offset = 0 then
  begin
   if scr_width < sw then
    begin
     if HorScrl_Offset > sw - scr_width then
       HorScrl_Offset := sw - scr_width - 1;
    end
   else
    begin
     HorScrl_Offset := 0;
     BMP_VScroll.Canvas.FillRect(Rect(0, scr_lineheight, scr_width, scr_lineheight * 2));
    end;
   RedrawScroll;
  end;
end;

procedure ReprepareScroll;
begin
 if Item_Displayed > 0 then
  begin
   ss1 := GetPlayListString(PlaylistItems[Item_Displayed - 1]);
   GetStringWnJ(ss1, sw1, sj1);
  end;
 if Item_Displayed < Length(PlaylistItems) - 1 then
  begin
   ss2 := GetPlayListString(PlaylistItems[Item_Displayed + 1]);
   GetStringWnJ(ss2, sw2, sj2);
  end;
 if (Item_Displayed >= 0) and (Item_Displayed < Length(PlaylistItems)) then
   SetScrollString(GetPlayListString(PlaylistItems[Item_Displayed]));
end;

procedure TFrmMain.FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);

 procedure TryClick(Bt: TButtZone);
 begin
   if Bt.Clicked = 2 then
    begin
     Bt.Clicked := 0;
     Bt.Action(Sender);
    end;
 end;

begin
 case Key of
   byte('T'):
     ButTimeClick(Sender);
   byte('1'):
     ButAmpClick(Sender);
   byte('2'):
     ButSpaClick(Sender);
   byte('P'):
     TryClick(ButTools);
   byte('E'):
     TryClick(ButList);
   byte('G'):
     TryClick(ButMixer);
   byte('R'):
     TryClick(ButLoop);
   byte('X'):
     TryClick(ButPlay);
   VK_NUMPAD5:
     if not IsPlaying then
       TryClick(ButPlay)
     else
       TryClick(ButPause);
   byte('V'):
     TryClick(ButStop);
   byte('C'):
     TryClick(ButPause);
   byte('B'), VK_NUMPAD6:
     TryClick(ButNext);
   byte('Z'), VK_NUMPAD4:
     TryClick(ButPrev);
   byte('L'), VK_NUMPAD0:
     TryClick(ButOpen);
   else
     Exit;
  end;
 Key := 0;
end;

procedure TFrmMain.FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);

 procedure UnClickAllButButt(Butt: TButtZone);
 var
   p: PButtZone;
 begin
   p := ButtZoneRoot;
   while p <> nil do
    begin
     if p <> @Butt then
       if p^.Clicked <> 0 then
        begin
         p^.Clicked := 0;
         if not p^.Is_On then p^.UnPush;
        end;
     p := p^.Next;
    end;
 end;

 procedure Push(Bt: TButtZone);
 begin
   if Bt.Clicked = 0 then
    begin
     UnClickAllButButt(Bt);
     Bt.Clicked := 2;
     Bt.Push;
    end;
 end;

begin
 if LongProcess > 0 then
   //conversion, searching, etc is in progress
  begin
   DoCheckQuitKey(Key);
   Key := 0;
   Exit;
  end;

 case Key of
   byte('P'):
     Push(ButTools);
   byte('J'):
    begin
     UnClickAllButButt(nil);
     JumpToTime;
    end;
   byte('E'):
     Push(ButList);
   byte('G'):
     Push(ButMixer);
   byte('R'):
     Push(ButLoop);
   byte('X'):
     Push(ButPlay);
   VK_NUMPAD5:
     if not IsPlaying then
       Push(ButPlay)
     else
       Push(ButPause);
   byte('V'):
     Push(ButStop);
   byte('C'):
     Push(ButPause);
   byte('B'), VK_NUMPAD6:
     Push(ButNext);
   byte('Z'), VK_NUMPAD4:
     Push(ButPrev);
   byte('L'), VK_NUMPAD0:
     Push(ButOpen);
   VK_UP, VK_NUMPAD8:
     VolUp;
   VK_DOWN, VK_NUMPAD2:
     VolDown;
   VK_LEFT:
    begin
     UnClickAllButButt(nil);
     if Time_ms > 0 then
       Rewind(CurrTime_Rasch - 5000, Time_ms);
    end;
   VK_RIGHT:
    begin
     UnClickAllButButt(nil);
     if Time_ms > 0 then
       Rewind(CurrTime_Rasch + 5000, Time_ms);
    end;
   VK_F1:
    begin
     UnClickAllButButt(nil);
     CallHelp;
    end;
   VK_ESCAPE:
     DoMinimize;
   else
     Exit;
  end;
 Key := 0;
end;

procedure TFrmMain.VolUp;
begin
 if MoveVol.PosX < MoveVol.zw - MoveVol.Bm1w then
  begin
   MoveVol.Clicked := False;
   MoveVol.HideBmp;
   Inc(MoveVol.PosX);
   OffsetRgn(MoveVol.RgnHandle, 1 * Scale, 0);
   MoveVol.Redraw(False);
   MoveVol.Action(Self);
  end;
end;

procedure TFrmMain.VolDown;
begin
 if MoveVol.posX > 0 then
  begin
   MoveVol.Clicked := False;
   MoveVol.HideBmp;
   Dec(MoveVol.PosX);
   OffsetRgn(MoveVol.RgnHandle, -1 * Scale, 0);
   MoveVol.Redraw(False);
   MoveVol.Action(Self);
  end;
end;

function TFrmMain.AddTrayIcon:boolean;
begin
  TrayIcon1.Icon.LoadFromResourceName(hInstance, Format('ICON%.2u', [TrayIconNumber]));
  if not FileAvailable then
    TrayIcon1.Hint := 'AY Emulator';
  try
    Result := TrayIcon1.Show;
    LCLBugWasTrayPopup := False;
  except
    //https://forum.lazarus.freepascal.org/index.php?topic=65348.0
    ShowMessage(Mes_CantCreateTrayIcon);
    TrayMode:=0;
    Result:=False;
  end;
end;

procedure TFrmMain.RemoveTrayIcon;
begin
 TrayIcon1.Hide;
end;

function TFrmMain.LoadSkin(FName: string; First: boolean): boolean;
var
 Buffer: array of byte;
 Author, Comment: string;
 rs: TResourceStream;
 s: string;
 i: integer;
 tl, mx, pl, ls, pa, l1, l2, l3, lp: boolean;
 URHandle: integer;
begin
 Result := False;
  try
   if FName = '' then
    begin
     rs := TResourceStream.Create(HInstance, 'DEFAULTSKIN', RT_RCDATA);
     UniReadInit(URHandle, URMemory, '', rs.Memory, rs.Size);
     Compressed_Size := rs.Size - SkinIdLen - 4;
    end
   else
    begin
      try
       UniReadInit(URHandle, URFile, FName, nil, -1);
      except
       ShowException(ExceptObject, ExceptAddr);
       exit;
      end;
     Compressed_Size := UniReadersData[URHandle]^.UniFileSize - SkinIdLen - 4;
    end;
    try
     SetLength(s, SkinIdLen);
     UniRead(URHandle, @s[1], SkinIdLen);
     if s <> SkinId then
      begin
       ShowMessage(Mes_File + ' ' + FName + ' ' + Mes_notAy_Emul20Skin);
       Exit;
      end;
     UniRead(URHandle, @Original_Size, 4);
     UniAddDepacker(URHandle, UDLZH);
     SetLength(Buffer, Original_Size);
     UniRead(URHandle, @Buffer[0], Original_Size)
    finally
     UniReadClose(URHandle);
     if FName = '' then rs.Free;
    end;

   Author := '';
   i := 0;
   while (i < Original_Size) and (Buffer[i] <> 0) do
    begin
     Author := Author + char(Buffer[i]);
     Inc(i);
    end;
   Author := CPToUTF8(Author); //todo - skins only utf8 encoding
   Comment := '';
   Inc(i);
   while (i < Original_Size) and (Buffer[i] <> 0) do
    begin
     Comment := Comment + char(Buffer[i]);
     Inc(i);
    end;
   Comment := CPToUTF8(Comment);
   Inc(i);

   if not First then
    begin
     tl := ButTools.Is_On;
     mx := ButMixer.Is_On;
     ls := ButList.Is_On;
     pa := ButPause.Is_Pushed;
     pl := ButPlay.Is_Pushed;
     lp := ButLoop.Is_Pushed;
     l1 := Led_AY.State;
     l2 := Led_YM.State;
     l3 := Led_Stereo.State;
     BmpFree;
     MoveVol.Bmp1.Free;
     MoveVol.Bmp2.Free;
     MoveVol.Bmps := False;
     MoveProgr.Bmp1.Free;
     MoveProgr.Bmp2.Free;
     MoveProgr.Bmps := False;
     SetMainBmp(@Buffer[i], Original_Size - i);
     CopyBmpSources;
     ButTools.Is_On := tl;
     ButTools.Is_Pushed := tl;
     ButMixer.Is_On := mx;
     ButMixer.Is_Pushed := mx;
     ButList.Is_On := ls;
     ButList.Is_Pushed := ls;
     ButPause.Is_Pushed := pa;
     ButPlay.Is_Pushed := pl;
     ButLoop.Is_Pushed := lp;
     ButLoop.Is_On := lp;
     Led_AY.State := l1;
     Led_YM.State := l2;
     Led_Stereo.State := l3;
     if ButTools.Is_On then
      begin
       FrmTools.ESkinAuth.Text := Author;
       FrmTools.ESkinCom.Text := Comment;
       FrmTools.ESkinFN.Text := FName;
      end;
    end
   else
     SetMainBmp(@Buffer[i], Original_Size - i);
   ClueRgn;
  except
   ShowException(ExceptObject, ExceptAddr);
   Exit;
  end;
 SkinAuthor := Author;
 SkinComment := Comment;
 SkinFileName := FName;
 Result := True;
 if FileAvailable then
  begin
   RedrawTime;
   RedrawScroll;
  end;
 Refresh;
end;

procedure TFrmMain.SetMainBmp(p: pointer; size: integer);
var
 Stream: TStream;
 Bitmap: TBitmap;
begin
 Stream := TMemoryStream.Create;
 Stream.Write(p^, size);
 Stream.Position := 0;
 Bitmap := TBitmap.Create;
 Bitmap.LoadFromStream(Stream);
 Stream.Free;
 BMP_DBuffer.Canvas.CopyMode := cmSrcCopy;
 BMP_DBuffer.Canvas.CopyRect(Rect(0, 0, MWWidth, MWHeight), Bitmap.Canvas,
   Rect(0, 0, MWWidth, MWHeight));
 ButPlay := TButtZone.Create(@ButPlay, 119, 96, 35, 27, Bitmap, 119,
   96, 119, 122, @PlayClick);
 ButPrev := TButtZone.Create(@ButPrev, 80, 96, 35, 27, Bitmap, 80,
   96, 80, 122, @ButPrevClick);
 ButNext := TButtZone.Create(@ButNext, 235, 96, 35, 27, Bitmap, 235,
   96, 235, 122, @ButNextClick);
 ButOpen := TButtZone.Create(@ButOpen, 275, 96, 35, 27, Bitmap, 275,
   96, 275, 122, @ButOpenClick);
 ButStop := TButtZone.Create(@ButStop, 197, 96, 35, 27, Bitmap, 197,
   96, 197, 122, @ButStopClick);
 ButPause := TButtZone.Create(@ButPause, 158, 96, 35, 27, Bitmap,
   158, 96, 158, 122, @ButPauseClick);
 ButLoop := TButtZone.Create(@ButLoop, 62 - 10, 110 - 10, 21, 21,
   Bitmap, 62 - 10, 110 - 10, 358 - 21, 110 - 7, @ButLoopClick);
 ButMixer := TButtZone.Create(@ButMixer, 318, 21, 26, 26, Bitmap,
   318, 21, 26 * 2, 124, @ButMixerClick);
 ButList := TButtZone.Create(@ButList, 310, 77, 26, 26, Bitmap, 310,
   77, 26, 124, @ButListClick);
 ButTools := TButtZone.Create(@ButTools, 322, 50, 26, 26, Bitmap,
   322, 50, 0, 124, @ButToolsClick);
 ButMinimize := TButtZone.Create(@ButMinimize, 282, 6, 16, 16, Bitmap,
   282, 6, 0, 0, @ButMinClick);
 ButClose := TButtZone.Create(@ButClose, 304, 6, 16, 16, Bitmap,
   304, 6, 358 - 16, 0, @ButCloseClick);
 ButAbout := TButtZone.Create(@ButAbout, 258, 84, 307 - 258, 92 - 84,
   Bitmap, 258, 84, 0, 123 - (92 - 84), @ButAboutClick);
 MoveVol.AddBitmaps(Bitmap, 358 - 41, 113, 18, 11, True);
 MoveProgr.AddBitmaps(Bitmap, 0, 103, 20, 10, True);
 Led_AY := TLedZone.Create(@Led_AY, 99, 26, 144 - 99, 33 - 26, Bitmap,
   99, 26, 358 - (144 - 99) - 1, 150 - (33 - 26) - 1);
 Led_YM := TLedZone.Create(@Led_YM, 144, 26, 190 - 144, 33 - 26,
   Bitmap, 144, 26, 358 - (190 - 144) - 1, 150 - (33 - 26) * 2 - 2);
 Led_Stereo := TLedZone.Create(@Led_Stereo, 190, 26, 234 - 190, 33 -
   26, Bitmap, 190, 26, 358 - (234 - 190) - 1, 150 - (33 - 26) * 3 - 3);
 Bitmap.Free;
end;

procedure TFrmMain.BmpFree;
var
 pppp, pppp1: PButtZone;
 ppp, ppp1: PLedZone;
begin
 if ButtZoneRoot <> nil then
  begin
   pppp := ButtZoneRoot;
   ButtZoneRoot := nil;
   repeat
     pppp1 := pppp^.Next;
     pppp^.Free;
     pppp := pppp1;
   until pppp = nil;
  end;
 if LedZoneRoot <> nil then
  begin
   ppp := LedZoneRoot;
   LedZoneRoot := nil;
   repeat
     ppp1 := ppp^.Next;
     ppp^.Free;
     ppp := ppp1;
   until ppp = nil;
  end;
end;

procedure TFrmMain.CopyBmpSources;
begin
 BMP_Sources.Canvas.CopyMode := cmSrcCopy;
 BMP_Sources.Canvas.CopyRect(Bounds(spa_src, 0, spa_width, spa_height),
   BMP_DBuffer.Canvas, Bounds(spa_x, spa_y, spa_width, spa_height));
 BMP_Sources.Canvas.CopyRect(Bounds(amp_src, 0, amp_width, amp_height),
   BMP_DBuffer.Canvas, Bounds(amp_x, amp_y, amp_width, amp_height));
 BMP_Sources.Canvas.CopyRect(Bounds(time_src, 0, time_width, time_height),
   BMP_DBuffer.Canvas, Bounds(time_x, time_y, time_width, time_height));
 BMP_Sources.Canvas.CopyRect(Bounds(scr_src, 0, scr_width, scr_height),
   BMP_DBuffer.Canvas, Bounds(scr_x, scr_y, scr_width, scr_height));
 BMP_Time.Canvas.CopyMode := cmSrcCopy;
 BMP_Time.Canvas.CopyRect(Rect(0, 0, time_width, time_height), BMP_Sources.Canvas,
   Bounds(time_src, 0, time_width, time_height));
 BMP_Scroll.Canvas.CopyMode := cmSrcCopy;
 BMP_Scroll.Canvas.CopyRect(Rect(0, 0, scr_width, scr_height), BMP_Sources.Canvas,
   Bounds(scr_src, 0, scr_width, scr_height));
end;

procedure TFrmMain.FormDropFiles(Sender: TObject; const FileNames: array of string);
var
 nFiles, i: integer;
 Skin: boolean;
begin

 if LongProcess > 0 then
   //conversion, searching, etc is in progress
   Exit;

 LongProcessPrepare;
 Skin := True;
 for i := 0 to Length(FileNames) - 1 do
   if not IsSkinFileType(GetFileTypeFromFNExt(ExtractFileExt(FileNames[i]))) then
    begin
     Skin := False;
     Break;
    end;
 if not Skin then
  begin
   StopAndFreeAll;
   ClearPlayList;
  end;
 May_Quit2 := False;
  try
   nFiles := Length(FileNames);
   for i := 0 to nFiles - 1 do
    begin
     if not DirectoryExists(FileNames[i]) then
       FrmPLst.Add_File(FileNames[i], True, 0)
     else
       FrmPLst.SearchFilesInFolder(FileNames[i], True, True, 0);
     Application.ProcessMessages;
     if May_Quit then
       Break;
    end;
  finally
   if not Skin then
    begin
     CalculateTotalTime(False);
     CreatePlayOrder;
    end;
   LongProcessDone;
  end;
 if not Skin then
   PlayItem(0, pwPlay);
end;

procedure TFrmMain.FIDO_SaveStatus(Status: FIDO_Status);
var
 f: TextFile;
 s: string;

 procedure KillFile;
 begin
    try
     if FileExists(FIDO_Descriptor_FileName) then
       DeleteFile(FIDO_Descriptor_FileName);
    except
    end;
 end;

begin
 if not FIDO_Descriptor_Enabled or Uninstall then exit;
 case Status of
   FIDO_Nothing:
    begin
     if FIDO_Descriptor_KillOnNothing then
      begin
       KillFile;
       exit;
      end;
     s := FIDO_Descriptor_Prefix + FIDO_Descriptor_Nothing;
    end;
   FIDO_Exit:
    begin
     if FIDO_Descriptor_KillOnExit then
      begin
       KillFile;
       exit;
      end;
     s := FIDO_Descriptor_Prefix + FIDO_Descriptor_Nothing;
    end;
 else
   s := FIDO_Descriptor_Prefix + CurItem.PLStr + FIDO_Descriptor_Suffix;
  end;
 if s <> FIDO_Descriptor_String then
  begin
   FIDO_Descriptor_String := s;
   s := ConvertEncoding(s, 'UTF8', FIDO_Descriptor_Enc);

   //FIDO вроде уже не актуально, обходить его ограничения больше нет смысла
(*  for i := 1 to Length(s) do //меняем русские 'Н' 'р' (т.е. только для CP1251 и CP866)
   case s[i] of
    #205: s[i] := 'H';
    #240: s[i] := 'p'
   end;
   if not FIDO_Descriptor_WinEnc then
    AnsiToOemBuff(@s[1], @s[1], Length(s));
*)

    try
     AssignFile(f, FIDO_Descriptor_FileName);
     Rewrite(f);
      try
       Write(f, s);
      finally
       CloseFile(f);
      end;
    except;
    end;
  end;
end;

procedure TFrmMain.JumpToTime;

 function TimeValid(stime: string; var time: integer): boolean;
 var
   temp, t1: integer;
 begin
   Result := True;
   Val(stime, time, temp);
   if temp = 0 then exit;
   if (temp > 1) and (temp < Length(stime)) and (stime[temp] = ':') then
    begin
     Val(Copy(stime, temp + 1, Length(stime) - temp), time, t1);
     if t1 = 0 then
      begin
       Val(Copy(stime, 1, temp - 1), t1, temp);
       if temp = 0 then
        begin
         Inc(time, t1 * 60);
         Exit;
        end;
      end;
    end;
   Result := False;
 end;

var
 time: integer;
begin
 if not IsPlaying then exit;
 if Paused then exit;
 with TFrmJpTime.Create(Self) do
  try
   Edit1.Text := TimeSToStr(round(CurrTime_Rasch / 1000));
   lbTrkLen.Caption := Mes_TrackLength + ' ' + TimeSToStr(round(Time_ms / 1000));
   if ShowModal = mrOk then
     if TimeValid(Edit1.Text, time) then
       Rewind(time * 1000, Time_ms);
  finally
   Free;
  end;
end;

procedure TFrmMain.CallHelp;
var
 f, h: string;
begin
 f := ExtractFilePath(GetProcessFileName) + 'Ay_Emul.';
 h := f + Get_Language + '.chm';
 if not FileExists(h) then
   h := f + 'chm';
 if not OpenDocument(h) then
   ShowMessage(Mes_CantOpen + ' ' + h);
end;

procedure TFrmMain.FormMouseWheelDown(Sender: TObject; Shift: TShiftState;
 MousePos: TPoint; var Handled: boolean);
begin
 VolDown;
end;

procedure TFrmMain.FormMouseWheelUp(Sender: TObject; Shift: TShiftState;
 MousePos: TPoint; var Handled: boolean);
begin
 VolUp;
end;

procedure TFrmMain.WMFINALIZEWO(var Msg: TMsg);
begin
 if not IsPlaying then exit;
 digsoundthread_free;
 RestoreControls;
 PostMessage(FrmMain.Handle, WM_PLAYNEXTITEM, 0, 0);
end;

procedure TFrmMain.FormDeactivate(Sender: TObject);
var
 p: PSensZone;
 p1: PMoveZone;
 p2: PButtZone;
begin
 p := SensZoneRoot;
 while p <> nil do
  begin
   p^.Clicked := False;
   p := p^.Next;
  end;
 p2 := ButtZoneRoot;
 while p2 <> nil do
  begin
   if (p2^.Clicked = 1) and not p2^.Is_On then
     p2^.UnPush;
   p2^.Clicked := 0;
   p2 := p2^.Next;
  end;
 p1 := MoveZoneRoot;
 while p1 <> nil do
  begin
   p1^.Clicked := False;
   p1 := p1^.Next;
  end;
end;

procedure TFrmMain.FormPaint(Sender: TObject);
begin
 MainWinRepaint;
end;

procedure TFrmMain.MICloseClick(Sender: TObject);
begin
 Close;
end;

procedure TFrmMain.MIMinResClick(Sender: TObject);
begin
 if WindowState = wsMinimized then
   DoRestore
 else
   DoMinimize;
end;

procedure TFrmMain.MIMixerClick(Sender: TObject);
begin
 ButMixerClick(Sender);
end;

procedure TFrmMain.MINextClick(Sender: TObject);
begin
 ButNextClick(Sender);
end;

procedure TFrmMain.MIOpenCDClick(Sender: TObject);
begin
 {$IFDEF Windows}
 FrmPLst.Add_CD_Dialog(False);
 {$ELSE Windows}
 NonWin;
 {$ENDIF Windows}
end;

procedure TFrmMain.MIOpenFilesClick(Sender: TObject);
begin
 FrmPLst.Add_Item_Dialog(False);
end;

procedure TFrmMain.MIOpenFolderClick(Sender: TObject);
begin
 FrmPLst.Add_Directory_Dialog(False);
end;

procedure TFrmMain.MIPlaylistClick(Sender: TObject);
begin
 ButListClick(Sender);
end;

procedure TFrmMain.MIPlayPauseClick(Sender: TObject);
begin
 if not IsPlaying then
   PlayClick(Sender)
 else
   ButPauseClick(Sender);
end;

procedure TFrmMain.MIPreviousClick(Sender: TObject);
begin
 ButPrevClick(Sender);
end;

procedure TFrmMain.MIRandomClick(Sender: TObject);
var
 L: integer;
begin
 L := Length(PlayListItems);
 if L <= 0 then
   Exit;
 PlayItem(Random(L), pwPlay);
end;

procedure TFrmMain.MIRestartClick(Sender: TObject);
begin
 if IsPlaying then
   ButStopClick(Sender);
 PlayClick(Sender);
end;

procedure TFrmMain.MIStopClick(Sender: TObject);
begin
 if IsPlaying then
   ButStopClick(Sender);
end;

procedure TFrmMain.MIToolsClick(Sender: TObject);
begin
 ButToolsClick(Sender);
end;

procedure StopPlaying;
begin
  try
   if IsStreamOrModuleFileType(CurFileType) then
     // {$IFDEF UseBassForEmu}or MinAYChipFile..MaxAYChipFile{$ENDIF UseBassForEmu}
     PlayFreeBASS
   {$IFDEF Windows}
   else if IsCDFileType(CurFileType) then
     StopCDDevice(CurCDNum)
   else if IsMIDIFileType(CurFileType) then
     midithread_stop
   {$ENDIF Windows}
   else
    begin
     digsoundthread_stop;
     if CurFileType = FT.SNDH then
       Atari_StopEmu;
    end;
  finally
   IsPlaying := False;
   Paused := False;
   RestoreControls;
  end;
end;

procedure GetSysVolume(Notified:boolean=False);
var
 v: single;
begin
 //Updating balance only if shure that volume changed not by Ay_Emul
 if (mixerctl_getvolume(v,not Notified or (SkipVolNotify = 0)) <> 0) or (v < 0) then
  Exit;

 if v > 1 then
  //in Linux volume can be > 100%
  v := 1;

 if VolLinear then
   VolumeCtrl := Trunc(v * VolumeCtrlMax + 0.5)
 else
   VolumeCtrl := Trunc(ln(v
     //                         + 1) / ln(2)  //closer to linear version
     * (exp(1) - 1) + 1) * VolumeCtrlMax + 0.5);
 if Notified and (MoveVol.Clicked or (SkipVolNotify <> 0)) then
  //don't redraw slider if user move it during getting volume changed message
  begin
   if SkipVolNotify > 0 then
    //volume was set by SetSysVolume before, so just decrease skip counter
    Dec(SkipVolNotify);
   Exit;
  end;
 RedrawVolume;
end;

procedure SetSysVolume;
var
 v: single;
begin
 if VolLinear then
   v := VolumeCtrl / VolumeCtrlMax
 else
   //(exp(VolumeCtrl / VolumeCtrlMax * ln(2)) - 1) //closer to linear version
   v := (exp((VolumeCtrl / VolumeCtrlMax)) - 1) / (exp(1) - 1);

 //skip several notices from system mixer to prevent pos back after rounding or
 //to ignore feedback random vol changing (met in only Linuxes) to keep balance
 SkipVolNotify := mixerctl_setvolume(v);
 RedrawVolume;
end;

procedure RedrawVolume;
begin
 if VolumeCtrl = MoveVol.PosX then
   Exit;
 MoveVol.HideBmp;
 OffsetRgn(MoveVol.RgnHandle, (VolumeCtrl - MoveVol.PosX) * Scale, 0);
 MoveVol.PosX := VolumeCtrl;
 MoveVol.Redraw(False);
end;

procedure TFrmMain.WMPLAYERROR(var Msg: TMsg);
begin
 ButStopClick(Self);
end;

procedure StopAndFreeAll;
begin
  try
   StopPlaying;
  finally
   FreeAndUnloadBASS;
   {$IFDEF Windows}
    try
     FreeAllCD;
    except
    end;
   {$ENDIF Windows}
  end;
end;

procedure TFrmMain.SaveParams;

 procedure SaveDW(Nm: PChar; const Vl: integer);
 begin
   OptionsWrite(Nm, IntToStr(Vl));
 end;

 procedure SaveStr(Nm: PChar; const Vl: string);
 begin
   OptionsWrite(Nm, Vl);
 end;

begin
 if Uninstall then exit;

 if OptionsInit(True) then
  try
   SaveDW('SampleRate', SampleRate);
   SaveDW('SampleBit', SampleBit);
   SaveDW('OutChansMono', Ord(FrmMixer.RBChMono.Checked));
   SaveDW('OutChansList', Ord(FrmMixer.CBChLst.Checked));
   SaveDW('BufLen_ms', BufLen_ms);
   SaveDW('NumberOfBuffers', NumberOfBuffers);
   SaveDW('Chip', Ord(not FrmMixer.RBChTypeAY.Checked) + 1);
   SaveDW('ChipList', Ord(FrmMixer.CBChTypeLst.Checked));
   SaveDW('FrqZ80', FrqZ80);
   SaveDW('FrqMC68K', trunc(MC68000Freq));
   SaveDW('FrqAY', FrmMixer.FrqAYTemp);
   SaveDW('FrqAYList', Ord(FrmMixer.CBChFrqLst.Checked));
   SaveDW('FrqPl', FrmMixer.FrqPlTemp);
   SaveDW('FrqPlList', Ord(FrmMixer.CBIntFrqLst.Checked));
   SaveDW('IntOffset', IntOffset);
   SaveDW('AtariSTe', Ord(FrmMixer.STeRB.Checked));
   SaveDW('AtariYMMono', Ord(FrmMixer.AtariYMMonoChk.Checked));
   SaveDW('AtariMono', Ord(FrmMixer.AtariMonoChk.Checked));
   SaveDW('MaxTStates', MaxTStates);
   SaveDW('VisAmpls', Ord(IndicatorChecked));
   SaveDW('VisSpectrum', Ord(SpectrumChecked));
   SaveDW('VisScroll', Ord(Do_Scroll));
   SaveDW('VisPeriod', VisTimerPeriod);
   SaveStr('Lang', Lang);
   SaveDW('Loop', Ord(Do_Loop));
   SaveDW('ForceLoop', Ord(Force_Loop));
   SaveDW('StreamPrescan', Ord(StreamPrescan));
   SaveDW('TrayMode', TrayMode);
   SaveDW('TimeMode', TimeMode);
   SaveStr('Skin', SkinFileName);
   SaveDW('MFPTimerMode', MFPTimerMode);
   SaveDW('MFPTimerFrq', MFPTimerFrq);
   SaveDW('AutoSaveDefDir', Ord(AutoSaveDefDir));
   SaveDW('AutoSaveWindowsPos', Ord(AutoSaveWindowsPos));
   SaveDW('AutoSaveVolumePos', Ord(AutoSaveVolumePos));
   SaveDW('BeeperMax', BeeperMax);
   SaveDW('DMAMax', Atari_DMAMax);
   SaveDW('ChanAL', FrmMixer.TBAmpAL.Position);
   SaveDW('ChanAR', FrmMixer.TBAmpAR.Position);
   SaveDW('ChanBL', FrmMixer.TBAmpBL.Position);
   SaveDW('ChanBR', FrmMixer.TBAmpBR.Position);
   SaveDW('ChanCL', FrmMixer.TBAmpCL.Position);
   SaveDW('ChanCR', FrmMixer.TBAmpCR.Position);
   SaveDW('ChansList', Ord(FrmMixer.CheckBox1.Checked));
   SaveStr('EditorPath', VTPath);
   SaveDW('FIDO_Descriptor_Enabled', Ord(FIDO_Descriptor_Enabled));
   SaveDW('FIDO_Descriptor_KillOnExit', Ord(FIDO_Descriptor_KillOnExit));
   SaveDW('FIDO_Descriptor_KillOnNothing', Ord(FIDO_Descriptor_KillOnNothing));
   SaveStr('FIDO_Descriptor_Enc', FIDO_Descriptor_Enc);
   SaveStr('FIDO_Descriptor_FileName', FIDO_Descriptor_FileName);
   SaveStr('FIDO_Descriptor_Nothing', FIDO_Descriptor_Nothing);
   SaveStr('FIDO_Descriptor_Suffix', FIDO_Descriptor_Suffix);
   SaveStr('FIDO_Descriptor_Prefix', FIDO_Descriptor_Prefix);
   SaveStr('DefaultCodePage', CodePageDef);
   SaveDW('FilterQuality', FilterQuality);
   SaveDW('PreAmp', PreAmp);
   SaveDW('VolLinear', Ord(VolLinear));
   if AutoSaveVolumePos then
     SaveDW('Volume', VolumeCtrl);
   if AutoSaveWindowsPos then
    begin
     SaveDW('MainX', FrmMain.Left);
     SaveDW('MainY', FrmMain.Top);
     SaveDW('ListX', FrmPLst.Left);
     SaveDW('ListY', FrmPLst.Top);
     SaveDW('ListW', FrmPLst.Width);
     SaveDW('ListH', FrmPLst.Height);
     SaveDW('ListP', FrmPLst.PixelsPerInch);
     SaveDW('ListVis', Ord(FrmPLst.Visible));
     SaveDW('MixerX', FrmMixer.Left);
     SaveDW('MixerY', FrmMixer.Top);
     if ButTools.Is_On then
      begin
       ToolsY := FrmTools.Top;
       ToolsX := FrmTools.Left;
      end;
     SaveDW('ToolsX', ToolsX);
     SaveDW('ToolsY', ToolsY);
    end;
   SaveDW('DoubleSize', Ord(Scale <> 1));
   SaveDW('ListItem', PlayingItem);
   SaveDW('AppIcon', AppIconNumber);
   SaveDW('TrayIcon', TrayIconNumber);
   SaveDW('MenuIcon', MenuIconNumber);
   SaveDW('MusIcon', MusIconNumber);
   SaveDW('SkinIcon', SkinIconNumber);
   SaveDW('ListIcon', ListIconNumber);
   SaveDW('BASSIcon', BASSIconNumber);
   SaveStr('SkinDirectory', SkinDirectory);
   SaveDW('PlayListDirection', Direction);
   SaveDW('PlayListLoop', Ord(ListLooped));
   SaveDW('PLColorBkSel', PLColorBkSel);
   SaveDW('PLColorBkPl', PLColorBkPl);
   SaveDW('PLColorBk', PLColorBk);
   SaveDW('PLColorPlSel', PLColorPlSel);
   SaveDW('PLColorPl', PLColorPl);
   SaveDW('PLColorSel', PLColorSel);
   SaveDW('PLColor', PLColor);
   SaveDW('PLColorErrSel', PLColorErrSel);
   SaveDW('PLColorErr', PLColorErr);
   SaveStr('PLFontName', PLArea.Font.Name);
   SaveDW('PLFontSize', PLArea.Font.Size);
   SaveDW('PLFontBold', Ord(PLArea.Font.Bold));
   SaveDW('PLFontItalic', Ord(PLArea.Font.Italic));
   SaveDW('digsoundDevice', digsoundDevice);
   SaveStr('digsoundDeviceName', FrmMixer.cbWODevice.Items[digsoundDevice]);
   {$IFDEF Windows}
   SaveDW('MIDIDevice', MIDIDevice);
   SaveStr('MIDIDeviceName', FrmMixer.cbMODevice.Items[integer(MIDIDevice) + 1]);
   SaveDW('MIDISeekToFirstNote', Ord(MIDISeekToFirstNote));
   SaveDW('Priority', Priority);
   {$ENDIF Windows}
   SaveDW('BASSFFTType', BASSFFTType);
   SaveDW('BASSFFTNoWin', BASSFFTNoWin);
   SaveDW('BASSFFTRemDC', BASSFFTRemDC);
   SaveDW('BASSAmpMin', round(BASSAmpMin * 10000));
   SaveStr('BASSNetAgent', BASSNetAgent);
   SaveDW('BASSNetUseProxy', Ord(BASSNetUseProxy));
   SaveStr('BASSNetProxy', BASSNetProxy);
   SaveStr('mixerctlPath1', mixerctl_Path1);
   SaveStr('mixerctlPath2', mixerctl_Path2);
   SaveStr('mixerctlPath3', mixerctl_Path3);

   SaveDW('FindSTF', Ord(F_STF));
   SaveDW('FindST1', Ord(F_ST1));
   SaveDW('FindSTC', Ord(F_STC));
   SaveDW('FindST3', Ord(F_ST3));
   SaveDW('FindAS0', Ord(F_ASM0));
   SaveDW('FindASC', Ord(F_ASM1));
   SaveDW('FindSTP', Ord(F_STP));
   SaveDW('FindPSC', Ord(F_PSC));
   SaveDW('FindFLS', Ord(F_FLS));
   SaveDW('FindSQT', Ord(F_SQT));
   SaveDW('FindPT1', Ord(F_PT1));
   SaveDW('FindPT2', Ord(F_PT2));
   SaveDW('FindPT3', Ord(F_PT3));
   SaveDW('FindFTC', Ord(F_FTC));
   SaveDW('FindGTR', Ord(F_GTR));
   SaveDW('FindIntegrity', Ord(IntegrityCheck));

   if AutoSaveDefDir then SaveDefaultDir2;
  finally
   OptionsDone;
  end;
end;

procedure AdjustFormOnDesktop(Frm: TForm);
var
 i: integer;
begin
 //Frm.MakeFullyVisible; не годится, работает с каким-либо монитором, а не со всем рабочим столом
 //подумать еще
 if Frm.Left >= Screen.DesktopLeft + Screen.DesktopWidth - Frm.Width then
  begin
   i := Screen.DesktopLeft + Screen.DesktopWidth - Frm.Width;
   if i < Screen.DesktopLeft then i := Screen.DesktopLeft;
   Frm.Left := i;
  end
 else if Frm.Left < Screen.DesktopLeft then
   Frm.Left := Screen.DesktopLeft;
 if Frm.Top >= Screen.DesktopTop + Screen.DesktopHeight - Frm.Height then
  begin
   i := Screen.DesktopTop + Screen.DesktopHeight - Frm.Height;
   if i < Screen.DesktopTop then i := Screen.DesktopTop;
   Frm.Top := i;
  end
 else if Frm.Top < Screen.DesktopTop then
   Frm.Top := Screen.DesktopTop;
end;

procedure LongProcessPrepare(SetMainFocused: boolean = True);
begin
 FrmMain.Cursor :=
   {$IFDEF Windows}
   crAppStart{ignored in GTK2...}
   {$ELSE}
   crHourGlass
   {$ENDIF}
   ;

 if SetMainFocused then
   //only main form used for user input
  begin
   FrmPLst.Enabled := False;
   FrmMixer.Enabled := False;
   if ButTools.Is_On then
     FrmTools.Enabled := False;
   if FrmMain.CanSetFocus then
     FrmMain.SetFocus;
  end;
 FrmMain.ShowHint := True;

 May_Quit := False;
 Inc(LongProcess);
end;

procedure LongProcessDone;
begin
 Dec(LongProcess);
 if LongProcess <= 0 then
  begin
   LongProcess := 0;
   FrmMain.Cursor := crDefault;
   FrmMain.ShowHint := False;
   FrmPLst.Enabled := True;
   FrmMixer.Enabled := True;
   if ButTools.Is_On then
     FrmTools.Enabled := True;
   if May_Quit then
     ShowMessage(Mes_GroupOpStopped);
  end;
end;

procedure TFrmMain.CommandLineAndRegCheck;

 function GetDW(Nm: PChar; out Vl: integer): boolean;
 var
   s: string;
 begin
   Result := OptionsRead(Nm, s) and TryStrToInt(s, Vl);
 end;

 function GetStr(Nm: PChar; var Vl: string): boolean;
 begin
   Result := OptionsRead(Nm, Vl);
 end;

var
 i, v, v1: integer;
 dir, s1, s2, s3: string;
 CanReadOptions, LangSet: boolean;
begin
 ClearParams;
 CanReadOptions := OptionsInit(False);
 SetDefault;
 FrmMixer.UpdateBuffLables;
 //todo упростить установку параметров
 AppIconNumber := -1;
 SelectAppIcon(0);
 LangSet := False;

  try
    try
     if CanReadOptions then
      begin
       if GetDW('SampleRate', v) then Set_Sample_Rate2(v);
       if GetDW('SampleBit', v) then Set_Sample_Bit2(v);
       if GetDW('OutChansMono', v) then Set_Stereo2(v);
       if GetDW('OutChansList', v) then FrmMixer.CBChLst.Checked := v <> 0;
       if GetDW('BufLen_ms', v) then Set_BufLen_ms2(v);
       if GetDW('NumberOfBuffers', v) then Set_NumberOfBuffers2(v);
       if GetDW('Chip', v) then Set_Chip2(ChTypes(v));
       if GetDW('ChipList', v) then FrmMixer.CBChTypeLst.Checked := v <> 0;
       if GetDW('FrqZ80', v) then Set_Z80_Frq2(v);
       if GetDW('FrqMC68K', v) then Set_MC68K_Frq2(v);
       if GetDW('FrqAY', v) then Set_Chip_Frq2(v);
       if GetDW('FrqAYList', v) then FrmMixer.CBChFrqLst.Checked := v <> 0;
       if GetDW('FrqPl', v) then Set_Player_Frq2(v);
       if GetDW('FrqPlList', v) then FrmMixer.CBIntFrqLst.Checked := v <> 0;
       if GetDW('MaxTStates', v) then Set_N_Tact2(v);
       if GetDW('IntOffset', v) then Set_IntOffset2(v);
       if GetDW('AtariSTe', v) then
        begin
         FrmMixer.STRB.Checked := v = 0;
         FrmMixer.STeRB.Checked := v <> 0;
        end;
       if GetDW('AtariYMMono', v) then FrmMixer.AtariYMMonoChk.Checked := v <> 0;
       if GetDW('AtariMono', v) then FrmMixer.AtariMonoChk.Checked := v <> 0;
       if GetDW('VisAmpls', v) then IndicatorChecked := v <> 0;
       if GetDW('VisSpectrum', v) then SpectrumChecked := v <> 0;
       if GetDW('VisScroll', v) then Do_Scroll := v <> 0;
       if GetDW('VisPeriod', v) then SetVisTimerPeriod(v);
       if GetDW('FilterQuality', v) then SetFilter2(v);
       if GetStr('Lang', dir) then
        begin
         LangSet := True;
         Set_Language2(dir);
        end;
       if GetDW('Loop', v) then Set_Loop2(v <> 0);
       if GetDW('ForceLoop', v) then Set_ForceLoop2(v <> 0);
       if GetDW('StreamPrescan', v) then Set_StreamPrescan2(v <> 0);
       if GetDW('TimeMode', v) then if v in [0..2] then TimeMode := v;
       SkinDirectory := '';
       if GetStr('Skin', dir) then if dir <> '' then
           if LoadSkin(dir, False) then SkinDirectory := ExtractFileDir(dir);
       if GetStr('SkinDirectory', dir) then if dir <> '' then
           SkinDirectory := dir;
       v1 := MFPTimerMode;
       if GetDW('MFPTimerMode', v) then v1 := v;
       if v1 = 0 then
         Set_MFP_Frq2(0, 0)
       else
        begin
         v1 := MFPTimerFrq;
         if GetDW('MFPTimerFrq', v) then v1 := v;
         Set_MFP_Frq2(1, v1);
        end;
       if GetDW('AutoSaveDefDir', v) then SetAutoSaveDefDir2(v <> 0);
       if GetDW('AutoSaveWindowsPos', v) then SetAutoSaveWindowsPos2(v <> 0);
       if GetDW('AutoSaveVolumePos', v) then SetAutoSaveVolumePos2(v <> 0);
       if GetDW('ChanAL', v) then SetChan2(v, 0);
       if GetDW('ChanAR', v) then SetChan2(v, 1);
       if GetDW('ChanBL', v) then SetChan2(v, 2);
       if GetDW('ChanBR', v) then SetChan2(v, 3);
       if GetDW('ChanCL', v) then SetChan2(v, 4);
       if GetDW('ChanCR', v) then SetChan2(v, 5);
       if GetDW('BeeperMax', v) then SetChan2(v, 6);
       if GetDW('DMAMax', v) then SetChan2(v, 7);
       if GetDW('PreAmp', v) then SetChan2(v, -1);
       if GetDW('ChansList', v) then FrmMixer.CheckBox1.Checked := v <> 0;
       if GetStr('EditorPath', dir) then VTPath := dir;
       if GetDW('FIDO_Descriptor_Enabled', v) then FIDO_Descriptor_Enabled := v <> 0;
       if GetDW('FIDO_Descriptor_KillOnExit', v) then
         FIDO_Descriptor_KillOnExit := v <> 0;
       if GetDW('FIDO_Descriptor_KillOnNothing', v) then
         FIDO_Descriptor_KillOnNothing := v <> 0;
       if GetStr('FIDO_Descriptor_Enc', dir) then FIDO_Descriptor_Enc := dir;
       if GetStr('FIDO_Descriptor_FileName', dir) then FIDO_Descriptor_FileName := dir;
       if GetStr('FIDO_Descriptor_Nothing', dir) then FIDO_Descriptor_Nothing := dir;
       if GetStr('FIDO_Descriptor_Suffix', dir) then FIDO_Descriptor_Suffix := dir;
       if GetStr('FIDO_Descriptor_Prefix', dir) then FIDO_Descriptor_Prefix := dir;
       if GetStr('DefaultCodePage', dir) then CodePageDef := dir;
       if GetDW('PlayListDirection', v) then if v in [0..3] then FrmPLst.SetDirection(v);
       if GetDW('PlayListLoop', v) then
        begin
         ListLooped := v <> 0;
         FrmPLst.SBLoop.Down := ListLooped;
        end;
       if GetDW('PLColorBkSel', v) then PLColorBkSel := v;
       if GetDW('PLColorBkPl', v) then PLColorBkPl := v;
       if GetDW('PLColorBk', v) then PLColorBk := v;
       if GetDW('PLColorPlSel', v) then PLColorPlSel := v;
       if GetDW('PLColorPl', v) then PLColorPl := v;
       if GetDW('PLColorSel', v) then PLColorSel := v;
       if GetDW('PLColor', v) then PLColor := v;
       if GetDW('PLColorErrSel', v) then PLColorErrSel := v;
       if GetDW('PLColorErr', v) then PLColorErr := v;
       if GetStr('PLFontName', dir) then PLArea.Font.Name := dir;
       if GetDW('PLFontSize', v) then PLArea.Font.Size := v;
       if GetDW('PLFontBold', v) then PLArea.Font.Bold := v <> 0;
       if GetDW('PLFontItalic', v) then PLArea.Font.Italic := v <> 0;

       if not GetStr('digsoundDeviceName', dir) then dir := '';
       if GetDW('digsoundDevice', v) then Set_WODevice2(v, dir);
       {$IFDEF Windows}
       if not GetStr('MIDIDeviceName', dir) then dir := '';
       if GetDW('MIDIDevice', v) then Set_MIDIDevice2(v, dir);
       if GetDW('MIDISeekToFirstNote', v) then
         MIDISeekToFirstNote := v <> 0;
       {$ENDIF Windows}
       if GetDW('BASSFFTType', v) then
         if (DWORD(v) >= BASS_DATA_FFT256) and (DWORD(v) <= BASS_DATA_FFT32768) then
           BASSFFTType := v;
       if GetDW('BASSFFTNoWin', v) then
         if v in [0, BASS_DATA_FFT_NOWINDOW] then
           BASSFFTNoWin := v;
       if GetDW('BASSFFTRemDC', v) then
         if v in [0, BASS_DATA_FFT_REMOVEDC] then
           BASSFFTRemDC := v;
       if GetDW('BASSAmpMin', v) then
         if (v >= 1) and (v <= 200) then
           BASSAmpMin := v / 10000;
       if GetStr('BASSNetAgent', dir) then BASSNetAgent := dir;
       if GetDW('BASSNetUseProxy', v) then
         BASSNetUseProxy := v <> 0;
       if GetStr('BASSNetProxy', dir) then BASSNetProxy := dir;

       if GetDW('VolLinear', v) then VolLinear := v <> 0;
       if not GetStr('mixerctlPath1', s1) then s1 := '';
       if not GetStr('mixerctlPath2', s2) then s2 := '';
       if not GetStr('mixerctlPath3', s3) then s3 := '';
       FrmMixer.OpenMixer(s1, s2, s3);
       if AutoSaveVolumePos then
        begin
         if GetDW('Volume', v) then
           if (v >= 0) and (v <= VolumeCtrlMax) then
            begin
             VolumeCtrl := v;
             SetSysVolume;
            end;
        end;

       if GetDW('FindSTF', v) then F_STF := v <> 0;
       if GetDW('FindST1', v) then F_ST1 := v <> 0;
       if GetDW('FindSTC', v) then F_STC := v <> 0;
       if GetDW('FindST3', v) then F_ST3 := v <> 0;
       if GetDW('FindAS0', v) then F_ASM0 := v <> 0;
       if GetDW('FindASC', v) then F_ASM1 := v <> 0;
       if GetDW('FindSTP', v) then F_STP := v <> 0;
       if GetDW('FindPSC', v) then F_PSC := v <> 0;
       if GetDW('FindFLS', v) then F_FLS := v <> 0;
       if GetDW('FindSQT', v) then F_SQT := v <> 0;
       if GetDW('FindPT1', v) then F_PT1 := v <> 0;
       if GetDW('FindPT2', v) then F_PT2 := v <> 0;
       if GetDW('FindPT3', v) then F_PT3 := v <> 0;
       if GetDW('FindFTC', v) then F_FTC := v <> 0;
       if GetDW('FindGTR', v) then F_GTR := v <> 0;
       if GetDW('FindIntegrity', v) then IntegrityCheck := v <> 0;

       {$IFDEF Windows}
       if GetDW('Priority', v) then SetPriority2(v);
       {$ENDIF Windows}
       DefaultDirectory := '';
       if GetStr('DefaultDirectory', dir) then DefaultDirectory := dir;
      end
     else
       FrmMixer.OpenMixer('', '', '');
    finally
     FrmMixer.SetMixerParams;
     if not LangSet then
       Set_Language2('');
    end;
   LastTimeComLine := GetTickCount64 - CLFast;
    try
     if ParamCount <> 0 then
       CommandLineInterpreter('"' + GetCurrentDir + '" ' + GetCommandLine, True);
     for i := 0 to Length(AfterScan) - 1 do
       CommandLineInterpreter(AfterScan[i], True);
    except
     ShowException(ExceptObject, ExceptAddr);
    end;
   AfterScan := nil;
   if LocateAndTryLoadDefaultPL then
     if CanReadOptions then
       if GetDW('ListItem', v) then
         if (v >= 0) and (v < Length(PlayListItems)) then
           PlayingItem := v;
   CreatePlayOrder;
   CalculateTotalTime(False);
   dir := ExtractFileDir(GetProcessFileName);
   if DefaultDirectory = '' then DefaultDirectory := dir;
   if SetCurrentDir(DefaultDirectory) then FrmMain.OpenDialog1.InitialDir :=
       DefaultDirectory;
   if CanReadOptions then
    begin
     if GetDW('DoubleSize', v) then
      begin
       if v <> 0 then
         v := 2
       else
         v := 1;
       if Scale <> v then
        begin
         Scale := v;
         RecreateRgn;
        end;
      end;

     if AutoSaveWindowsPos then
      begin
       Position := poDesigned;
       if GetDW('MainX', v) then Left := v;
       if GetDW('MainY', v) then Top := v;
       AdjustFormOnDesktop(FrmMain);

       FrmPLst.Position := poDesigned;
       if GetDW('ListX', v) then FrmPLst.Left := v;
       if GetDW('ListY', v) then FrmPLst.Top := v;

       if not GetDW('ListP', v1) or (v1 <= 0) then
         v1 := FrmPLst.Monitor.PixelsPerInch;

       if GetDW('ListW', v) then
         //if form is not scaled yet, convert from saved/monitor DPI
         FrmPLst.Width := MulDiv(v, FrmPLst.PixelsPerInch, v1);
       if GetDW('ListH', v) then
         //same with height
         FrmPLst.Height := MulDiv(v, FrmPLst.PixelsPerInch, v1);

       AdjustFormOnDesktop(FrmPLst);
       if FrmPLst.PixelsPerInch <> FrmPLst.Monitor.PixelsPerInch then
         //After moving programmatically no WM_DPICHANGED is sent
         FrmPLst.AutoScale;

       if GetDW('ListVis', v) then if v <> 0 then
          begin
           ButList.Switch_On;
           FrmPLst.Visible := True;
          end;

       FrmMixer.Position := poDesigned;
       if GetDW('MixerX', v) then FrmMixer.Left := v;
       if GetDW('MixerY', v) then FrmMixer.Top := v;
       AdjustFormOnDesktop(FrmMixer);
       if FrmMixer.PixelsPerInch <> FrmMixer.Monitor.PixelsPerInch then
         FrmMixer.AutoScale;

       if GetDW('ToolsX', v) then ToolsX := v;
       if GetDW('ToolsY', v) then ToolsY := v;
      end;
     if GetDW('AppIcon', v) then SelectAppIcon(v);
     if GetDW('TrayIcon', v) then SelectTrayIcon(v);
     if GetDW('MenuIcon', v) then MenuIconNumber := v;
     if GetDW('MusIcon', v) then MusIconNumber := v;
     if GetDW('SkinIcon', v) then SkinIconNumber := v;
     if GetDW('ListIcon', v) then ListIconNumber := v;
     if GetDW('BASSIcon', v) then BASSIconNumber := v;
     if GetDW('TrayMode', v) then Set_TrayMode2(v);
    end;
  finally
   if CanReadOptions then OptionsDone;
  end;
 FIDO_SaveStatus(FIDO_Nothing);
 if FileAvailable then
   PlayCurrent
 else
   PlayItem(PlayingOrderItem, pwNo);
 InitialScan := True;
end;

procedure TFrmMain.SetBuffers(len, num: integer);
begin
 if digsoundthread_active then exit;
 if (num < 2) or (num > 10) then exit;
 if (len < 5) or (len > 2000) then exit;
 BufLen_ms := len;
 NumberOfBuffers := num;
 BufferLength := round(BufLen_ms * SampleRate / 1000);
 VisPosMax := round(BufferLength * NumberOfBuffers / VisStep) + 1;
 VisTickMax := VisStep * VisPosMax;
 SetLength(VisPoints, VisPosMax);
end;

procedure TFrmMain.Set_WODevice2(WOD: integer; NM: string);
var
 l, j: integer;
begin
 if digsoundthread_active or (WOD < 0) then exit;
 l := FrmMixer.cbWODevice.Items.Count;
 if WOD >= l then exit;
 if (NM <> '') and (FrmMixer.cbWODevice.Items[WOD] <> NM) then
  begin
   j := 1;
   while (j < l) and (FrmMixer.cbWODevice.Items[j] <> NM) do Inc(j);
   if j < l then
     WOD := j
   else
     WOD := 0;
  end;
 if digsoundDevice <> WOD then
  begin
   digsoundDevice := WOD;
   FrmMixer.cbWODevice.ItemIndex := WOD;
  end;
end;

{$IFDEF Windows}
procedure TFrmMain.Set_MIDIDevice2(MD: integer; NM: string);
var
 l, j: integer;
begin
 if midithread_active or (MD < -1) then exit;
 l := FrmMixer.cbMODevice.Items.Count;
 if MD >= l - 1 then exit;
 if (NM <> '') and (FrmMixer.cbMODevice.Items[MD + 1] <> NM) then
  begin
   j := 0;
   while (j < l) and (FrmMixer.cbMODevice.Items[j] <> NM) do Inc(j);
   if j < l then
     MD := j - 1
   else
     MD := -1;
  end;
 if MIDIDevice <> DWORD(MD) then
  begin
   MIDIDevice := MD;
   FrmMixer.cbMODevice.ItemIndex := MD + 1;
  end;
end;
{$ENDIF Windows}

procedure TFrmMain.Set_BufLen_ms2(BL: integer);
begin
 if BL <> BufLen_ms then
  begin
   SetBuffers(BL, NumberOfBuffers);
   FrmMixer.UpdateBuffLables;
  end;
end;

procedure TFrmMain.Set_NumberOfBuffers2(NB: integer);
begin
 if NB <> NumberOfBuffers then
  begin
   SetBuffers(BufLen_ms, NB);
   FrmMixer.UpdateBuffLables;
  end;
end;

procedure TFrmMain.Set_Chip2(Ch: ChTypes);
begin
 if (Ch <> ChType) and (Ch in [AY_Chip, YM_Chip]) then
  begin
   ChType := Ch;
   Calculate_Level_Tables2;
   FrmMixer.CBChTypeAY.Checked := False;
   FrmMixer.CBCHTypeYM.Checked := False;
   case Ch of
     AY_Chip:
      begin
       FrmMixer.RBChTypeAY.Checked := True;
       Led_AY.State := False;
       Led_YM.State := True;
       Led_AY.Redraw(False);
       Led_YM.Redraw(False);
       if IsPlaying then
         FrmMixer.CBChTypeAY.Checked := True;
      end;
     YM_Chip:
      begin
       FrmMixer.RBChTypeYM.Checked := True;
       Led_AY.State := True;
       Led_YM.State := False;
       Led_AY.Redraw(False);
       Led_YM.Redraw(False);
       if IsPlaying then
         FrmMixer.CBCHTypeYM.Checked := True;
      end;
    end;
  end;
end;

procedure TFrmMain.Set_IntOffset2(InO: integer);
begin
 if (InO <> IntOffset) and (InO >= 0) and (InO < MaxTStates) then
  begin
   IntOffset := InO;
   FrmMixer.EIntOffs.Text := IntToStr(InO);
  end;
end;

function TFrmMain.Get_Language: string;
begin
 if Lang = '' then
   Result := DefaultLang
 else
   Result := Lang;
end;

procedure TFrmMain.Set_Language2(const aLang: string);
begin
 if Lang = aLang then
   Exit;
 Lang := aLang;
 DefaultLang := SetDefaultLang(aLang);

 //lcl bug/feature: system dialog titles are translated once on create
 OpenDialog1.Title := rsfdopenfile;
 SaveDialog1.Title := rsfdfilesaveas;

 if ButTools.Is_On then
  begin
   if aLang = '' then
     FrmTools.LangCB.ItemIndex := 0
   else
     FrmTools.LangCB.Text := aLang;
   FrmTools.UpdateTranslation;
  end;
end;

procedure TFrmMain.Set_Loop2(Lp: boolean);
begin
 if Do_Loop = Lp then
   Exit;
 Do_Loop := Lp;
 case Lp of
   True: ButLoop.Switch_On;
 else
   ButLoop.Switch_Off;
  end;
end;

procedure TFrmMain.Set_ForceLoop2(Lp: boolean);
begin
 if Force_Loop = Lp then
   Exit;
 Force_Loop := Lp;
 if ButTools.Is_On then FrmTools.CBForceLoop.Checked := Lp;
end;

procedure TFrmMain.Set_StreamPrescan2(Prescan: boolean);
begin
 if StreamPrescan = Prescan then
   Exit;
 StreamPrescan := Prescan;
 if ButTools.Is_On then FrmTools.CBStrPrescan.Checked := Prescan;
end;

procedure TFrmMain.Set_TrayMode2(TM: integer);
begin
 if (TrayMode = TM) or (DWORD(TM) > 2) then
   Exit;
 TrayMode := TM;
 if TM = 2 then
   if WindowState <> wsMinimized then TM := 0
   else
     TM := 1;
 case TM of
   0:
    begin
     RemoveTrayIcon;
     AddTaskbarButton;
    end;
   1:
    begin
     if AddTrayIcon then
      RemoveTaskbarButton;
    end;
  end;
 if ButTools.Is_On then
   case TrayMode of
     0: FrmTools.RadioButton8.Checked := True;
     1: FrmTools.RadioButton9.Checked := True;
     2: FrmTools.RadioButton10.Checked := True;
    end;
end;

procedure TFrmMain.Set_MFP_Frq2(Md, Fr: integer);
begin
 if (Md = MFPTimerMode) and (Fr = MFPTimerFrq) then exit;
 Set_MFP_Frq(Md, Fr);
 FrmMixer.FrqMFPTemp := MFPTimerFrq;
 FrmMixer.Set_MFPFrqs;
end;

procedure TFrmMain.SetAutoSaveDefDir2(ASD: boolean);
begin
 AutoSaveDefDir := ASD;
 if ButTools.Is_On then FrmTools.CBAutoSaveMFld.Checked := ASD;
end;

procedure TFrmMain.SetAutoSaveWindowsPos2(ASW: boolean);
begin
 AutoSaveWindowsPos := ASW;
 if ButTools.Is_On then FrmTools.CheckBox40.Checked := ASW;
end;

procedure TFrmMain.SetAutoSaveVolumePos2(ASV: boolean);
begin
 AutoSaveVolumePos := ASV;
 FrmMixer.CBSvVolPos.Checked := ASV;
end;

{$IFDEF Windows}
procedure TFrmMain.SetPriority2(NP: DWORD);
begin
 if not (NP in [IDLE_PRIORITY_CLASS, NORMAL_PRIORITY_CLASS, HIGH_PRIORITY_CLASS]) then
   exit;
 SetPriority(NP);
 if ButTools.Is_On then
   case Priority of
     IDLE_PRIORITY_CLASS: FrmTools.RadioButton3.Checked := True;
     NORMAL_PRIORITY_CLASS: FrmTools.RadioButton4.Checked := True;
     HIGH_PRIORITY_CLASS: FrmTools.RadioButton5.Checked := True;
    end;
end;
{$ENDIF Windows}

procedure TFrmMain.SetChan2(u, i: integer);
begin
 if DWORD(u) > 255 then
   Exit;
 with FrmMixer do
   case i of
     0: Change_Show(TBAmpAL, EAmpAL, EAmpALCur, u, Index_AL);
     1: Change_Show(TBAmpAR, EAmpAR, EAmpARCur, u, Index_AR);
     2: Change_Show(TBAmpBL, EAmpBL, EAmpBLCur, u, Index_BL);
     3: Change_Show(TBAmpBR, EAmpBR, EAmpBRCur, u, Index_BR);
     4: Change_Show(TBAmpCL, EAmpCL, EAmpCLCur, u, Index_CL);
     5: Change_Show(TBAmpCR, EAmpCR, EAmpCRCur, u, Index_CR);
     6: Change_Show2(TBAmpBpr, EAmpBpr, u, BeeperMax);
     7: Change_Show2(TBAmpDMA, EAmpDMA, u, Atari_DMAMax);
     -1: Change_Show2(TBPreAmp, EPreAmp, u, PreAmp);
    end;
end;

procedure TFrmMain.CalcFiltKoefs;
const
 MaxF = 9200;
var
 i: integer;
 K, F, C, i2, Filt_M2: double;
 FKt: array of double;
 s: string;
begin
 //Work range [0..MaxF)
 //Range [MaxF..SampleRate / 2) is easy cut-off from 0 to -53 dB
 //Cut-off range is [SampleRate / 2.. AY_Freq div 8 / 2] (-53 dB)
 //for Ay_Freq = 1773400 Hz:
(*
Полезная область - 0..11083,75 Гц (10)
221675->44100 - 67 (коэффициентов)
221675->48000 - 57
221675->96000 - 20
221675->110000 - 17

Полезная область - 0..10076,14 (11)
221675->22050 - 771

Полезная область - 0..9236,46 (12)
221675->22050 - 409

Полезная область - 0..8525,96 (13)
221675->22050 - 293
*)
 IsFilt := 0;
 C := 22050;
 if SampleRate >= 44100 then
  begin
   C := SampleRate / 2;
   Inc(IsFilt);
  end;
 Filt_M := round(3.3 / (C - MaxF) * (AY_Freq div 8));
 if AY_Freq * Filt_M > 3500000 * 50 then //90% of usage for my Celeron 850 MHz
  begin
   Filt_M := round(3500000 * 50 / AY_Freq);
   IsFilt := 0;
  end;
 C := Pi * (MaxF + C) / (AY_Freq div 8);
 SetLength(FKt, Filt_M);
 Filt_M2 := (Filt_M - 1) / 2;
 K := 0;
 for i := 0 to Filt_M - 1 do
  begin
   i2 := i - Filt_M2;
   if i2 = 0 then
     F := C
   else
     F := sin(C * i2) / i2 * (0.54 + 0.46 * cos(2 * Pi / Filt_M * i2));
   FKt[i] := F;
   K := K + F;
  end;
 SetLength(Filt_K, Filt_M);
 for i := 0 to Filt_M - 1 do
   Filt_K[i] := round(FKt[i] / K * $1000000);
 s := Mes_FIR + ' (' + IntToStr(Filt_M) + ' ' + Mes_PTS + ')';
 if IsFilt = 0 then s := s + ' + ' + LowerCase(Mes_Averager);
 FrmMixer.Label13.Caption := s;
 Dec(Filt_M);
end;

procedure TFrmMain.SetFilter(FQ: integer);
begin
 digsoundloop_catch;
  try
   FilterQuality := FQ;
   if (FQ = 0) or (SampleRate >= AY_Freq div 8) then
    begin
     IsFilt := -1;
     Filt_K := nil;
     Filt_XL := nil;
     Filt_XR := nil;
     FrmMixer.Label13.Caption := Mes_Averager;
     exit;
    end;
   CalcFiltKoefs;
   SetLength(Filt_XL, Filt_M + 1);
   SetLength(Filt_XR, Filt_M + 1);
   FillChar(Filt_XL[0], (Filt_M + 1) * 4, 0);
   FillChar(Filt_XR[0], (Filt_M + 1) * 4, 0);
   Filt_I := 0;
  finally
   digsoundloop_release;
  end;
end;

procedure TFrmMain.SetFilter2(FQ: integer);
begin
 if (FilterQuality = FQ) or (FQ > 6) then
   Exit;
 SetFilter(FQ);
end;

procedure TFrmMain.SaveAllParams;
var
 Tmp: boolean;
begin
  try
   Tmp := FIDO_Descriptor_Enabled;
   FIDO_Descriptor_Enabled := False;
   StopAndFreeAll;
   FIDO_Descriptor_Enabled := Tmp;
   FIDO_SaveStatus(FIDO_Exit);
   FreePlayingResourses;
   SaveParams;
  except
   ShowException(ExceptObject, ExceptAddr);
  end;
end;

procedure TFrmMain.DoDestroyActions;
var
 p, p1: PSensZone;
 pp, pp1: PMoveZone;
begin
 BmpFree;

 if SensZoneRoot <> nil then
  begin
   p := SensZoneRoot;
   SensZoneRoot := nil;
   repeat
     p1 := p^.Next;
     p^.Free;
     p := p1;
   until p = nil;
  end;
 if MoveZoneRoot <> nil then
  begin
   pp := MoveZoneRoot;
   MoveZoneRoot := nil;
   repeat
     pp1 := pp^.Next;
     pp^.Free;
     pp := pp1;
   until pp = nil;
  end;

 DestroyRgn;

 VisTimer.Free;

 GetTimeQueue.Free;

 BMP_Scroll.Free;
 BMP_VScroll.Free;
 BMP_Vis.Free;
 BMP_Time.Free;
 BMP_Sources.Free;
 BMP_DBuffer.Free;
end;

procedure TFrmMain.DoCloseActions;
begin
 if CloseActionsDone then
   Exit;
 IPCServer.OnMessage := nil;
 VisTimer.Enabled := False;
 SaveAllParams;
 TrySaveDefaultPL;
 mixerctl_close;
 RemoveTrayIcon;
 {$IFDEF Windows}
 SetPriority(NORMAL_PRIORITY_CLASS);
 {$ENDIF Windows}
 CloseActionsDone := True;
end;

procedure TFrmMain.HideMinimize(var Msg: TMsg);
begin
 DoMinimize;
end;

procedure TFrmMain.SelectAppIcon(n: integer);
begin
 if AppIconNumber = n then
   Exit;
 AppIconNumber := n;
 Application.Icon.LoadFromResourceName(hInstance, Format('ICON%.2u', [n]));
end;

procedure TFrmMain.SelectTrayIcon(n: integer);
begin
 if TrayIconNumber = n then
   Exit;
 TrayIconNumber := n;
 TrayIcon1.Icon.LoadFromResourceName(hInstance, Format('ICON%.2u', [n]));
end;

procedure Ay_Emul_ShowException(Msg: shortstring);
begin
 ShowMessage(
   {$IFDEF Windows}
   IfAnsiToUTF8(
   {$ENDIF}
   Msg
   {$IFDEF Windows}
   )
   {$ENDIF}
   );
end;

procedure TFrmMain.Ay_Emul_ShowExceptionA(Sender: TObject; E: Exception);
begin
 ShowMessage(
   {$IFDEF Windows}
   IfAnsiToUTF8(
   {$ENDIF}
   E.Message
   {$IFDEF Windows}
   )
   {$ENDIF}
   );
end;

procedure TFrmMain.FormDestroy(Sender: TObject);
begin
 DoDestroyActions;
end;

procedure TFrmMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
 DoCloseActions;
end;

procedure TFrmMain.AppEndSession(Sender: TObject);
begin
 DoCloseActions;
 DoDestroyActions;
end;

procedure AYVisualisation(smp: DWORD);
var
 CurVisPos: DWORD;
 T, E, A, i: integer;
 TE: boolean;
begin
 VProgrPos := BaseSample + smp;
 CurrTime_Rasch := trunc(VProgrPos / SampleRate * 1000);
 CurVisPos := smp mod VisTickMax div VisStep;

 if SpectrumChecked or IndicatorChecked then
   with VisPoints[CurVisPos] do
    begin
     if Calc = 0 then
      begin
       Calc := 1;
       for i := 0 to 1 do
         with VisPoints[CurVisPos].R[i] do
          begin
           case EnvT of
             8, 12: E := 28;
             10, 14: E := 26;
           else
            begin
             E := AmpE - 1;
             if E < 0 then E := 0;
            end
            end;
           T := TnA;
           if AmpA and 16 = 0 then
             AmpA := AmpA * 2
           else if not (EnvT in [8, 10, 12, 14]) then
             AmpA := E
           else
            begin
             A := E;
             TE := Mix and 1 = 0;
             if (T <= 3) and TE then
               Dec(A, 6)
             else if TE then
               A := 30;
             AmpA := A;
             if (T <= 3) or not TE then
               if EnvT in [8, 12] then
                 T := EnvP * 16
               else
                 T := EnvP * 32;
            end;
           TnA := T;
           T := TnB;
           if AmpB and 16 = 0 then
             AmpB := AmpB * 2
           else if not (EnvT in [8, 10, 12, 14]) then
             AmpB := E
           else
            begin
             A := E;
             TE := Mix and 2 = 0;
             if (T <= 3) and TE then
               Dec(A, 6)
             else if TE then
               A := 30;
             AmpB := A;
             if (T <= 3) or not TE then
               if EnvT in [8, 12] then
                 T := EnvP * 16
               else
                 T := EnvP * 32;
            end;
           TnB := T;
           T := TnC;
           if AmpC and 16 = 0 then
             AmpC := AmpC * 2
           else if not (EnvT in [8, 10, 12, 14]) then
             AmpC := E
           else
            begin
             A := E;
             TE := Mix and 4 = 0;
             if (T <= 3) and TE then
               Dec(A, 6)
             else if TE then
               A := 30;
             AmpC := A;
             if (T <= 3) or not TE then
               if EnvT in [8, 12] then
                 T := EnvP * 16
               else
                 T := EnvP * 32;
            end;
           TnC := T;
           if not TSMode then break;
          end;
      end;
     T := R[0].AmpA;
     E := R[0].AmpB;
     A := R[0].AmpC;
     if TSMode then
      begin
       if R[1].AmpA > T then T := R[1].AmpA;
       if R[1].AmpB > E then E := R[1].AmpB;
       if R[1].AmpC > A then A := R[1].AmpC;
      end;
     RedrawVisChannels(T, E, A, 30);
     RedrawVisSpectrum(@VisPoints[CurVisPos], 31);
    end;
 ShowProgress(VProgrPos);
end;

procedure TFrmMain.WMVOLUMECHANGED(var Msg: TMsg);
begin
 GetSysVolume(True);
end;

end.
