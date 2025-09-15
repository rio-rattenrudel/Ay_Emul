{
This is part of AY Emulator project
AY-3-8910/12 Emulator
Version 3.0 for Windows and Linux
Author Sergey Vladimirovich Bulba
(c)1999-2025 S.V.Bulba
}

unit PlayList;

{$mode objfpc}{$H+}

interface

uses
 LCLIntf, LCLType, SysUtils, LazFileUtils, Classes, Graphics,
 Controls, Forms, Dialogs, StdCtrls, ExtCtrls, Menus, Buttons, lazutf8,
 LConvEncoding, MainWin, AY, Players, UniReader, FileTypes;

const
 Version_String = 'ZX Spectrum Sound Chip Emulator Play List File v1.';
 Add_File_Errors: string = '';

type
 TPlayList = class(TPanel)
   procedure PlayListPaint(Sender: TObject);
 public
   constructor Create(AOwner: TComponent); override;
   procedure PLAreaMouseDown(Sender: TObject; Button: TMouseButton;
     Shift: TShiftState; X, Y: integer);
   procedure PLAreaMouseUp(Sender: TObject; Button: TMouseButton;
     Shift: TShiftState; X, Y: integer);
   procedure PLAreaMouseMove(Sender: TObject; Shift: TShiftState; X, Y: integer);
   procedure PLAreaMouseWheelDown(Sender: TObject; Shift: TShiftState;
     MousePos: TPoint; var Handled: boolean);
   procedure PLAreaMouseWheelUp(Sender: TObject; Shift: TShiftState;
     MousePos: TPoint; var Handled: boolean);
   procedure PLAreaDblClick(Sender: TObject);
   procedure PLAreaKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
   procedure PLAreaKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
   procedure MTimerPrc(Sender: TObject);
 end;

 TDirType = (dtSource, dtCurrent, dtTemp, dtCustom);
 TPlayWay = (pwSave, pwPlay, pwConvWAV, pwConvVTX, pwConvYM6, pwConvPSG, pwConvZXAY,
   pwConvMP3, pwConvOGG, pwConvFLAC, pwConvOPUS);

const
 pwNo = pwSave; //neither play, nor convert

type

 { TFrmPLst }

 TFrmPLst = class(TForm)
   Deduplicate1: TMenuItem;
   MenuConvertAll: TMenuItem;
   MenuFLAC: TMenuItem;
   MIAllToOPUS: TMenuItem;
   MIAllToFLAC: TMenuItem;
   MIAllToOGG: TMenuItem;
   MIAllToMP3: TMenuItem;
   MenuOPUS: TMenuItem;
   MenuOGG: TMenuItem;
   MenuMP3: TMenuItem;
   MIAllToWAV: TMenuItem;
   MIAllToZXAY: TMenuItem;
   MIAllToVTX: TMenuItem;
   MenuItem5: TMenuItem;
   MIAllToPSG: TMenuItem;
   SaveToFolder1: TMenuItem;
   Panel1: TPanel;
   PopupMenu1: TPopupMenu;
   MenuItemAdjusting: TMenuItem;
   MenuWAV: TMenuItem;
   MenuVTX: TMenuItem;
   MenuYM6: TMenuItem;
   MenuPSG: TMenuItem;
   N4: TMenuItem;
   MenuZXAY: TMenuItem;
   MenuSaveAs: TMenuItem;
   ScBPLItems: TScrollBar;
   Separator1: TMenuItem;
   Separator2: TMenuItem;
   Separator3: TMenuItem;
   Separator4: TMenuItem;
   Separator5: TMenuItem;
   SBAdd: TSpeedButton;
   SBClear: TSpeedButton;
   SBSave: TSpeedButton;
   SBTools: TSpeedButton;
   LTotTime: TLabel;
   SBDirection: TSpeedButton;
   SBLoop: TSpeedButton;
   ImageList1: TImageList;
   PopupMenu2: TPopupMenu;
   RandomSort: TMenuItem;
   ByauthorSort: TMenuItem;
   BytitleSort: TMenuItem;
   ByfilenameSort: TMenuItem;
   Byfiletype1: TMenuItem;
   N3: TMenuItem;
   Finditem1: TMenuItem;
   LQtyCurTotal: TLabel;
   MenuOpenInEditor: TMenuItem;
   MenuConvert: TMenuItem;
   procedure Add_Item_Dialog(Add: boolean);
   {$IFDEF Windows}
   procedure Add_CD_Dialog(Add: boolean);
   {$ENDIF Windows}
   procedure Deduplicate1Click(Sender: TObject);
   procedure ConvToWAV1Click(Sender: TObject);
   procedure FormConstrainedResize(Sender: TObject;
     var MinWidth, MinHeight, MaxWidth, MaxHeight: TConstraintSize);
   procedure FormShow(Sender: TObject);
   function GetNumberOfSelectedItems: integer;
   procedure MenuFLACClick(Sender: TObject);
   procedure MenuMP3Click(Sender: TObject);
   procedure MenuOGGClick(Sender: TObject);
   procedure MenuOPUSClick(Sender: TObject);
   procedure MIAllToFLACClick(Sender: TObject);
   procedure MIAllToMP3Click(Sender: TObject);
   procedure MIAllToOGGClick(Sender: TObject);
   procedure MIAllToOPUSClick(Sender: TObject);
   procedure MIAllToZXAYClick(Sender: TObject);
   procedure MIAllToVTXClick(Sender: TObject);
   procedure MenuItem5Click(Sender: TObject);
   procedure MIAllToPSGClick(Sender: TObject);

   //save playlist items (all or selected)
   procedure SaveToFolder(Way: TPlayWay; All: boolean);

   procedure SaveToFolder1Click(Sender: TObject);
   procedure Add_Directory_Dialog(Add: boolean);
   procedure FormDropFiles(Sender: TObject; const FileNames: array of string);
   procedure PlayNextItem;
   procedure PlayPreviousItem;
   procedure FormHide(Sender: TObject);
   procedure MenuWAVClick(Sender: TObject);
   procedure MenuVTXClick(Sender: TObject);
   procedure MenuYM6Click(Sender: TObject);
   procedure MenuPSGClick(Sender: TObject);
   procedure MenuZXAYClick(Sender: TObject);
   procedure MenuItemAdjustingClick(Sender: TObject);
   procedure Add_Files(SF: TStrings);
   procedure MenuSaveAsClick(Sender: TObject);
   procedure ScBPLItemsScroll(Sender: TObject; ScrollCode: TScrollCode;
     var ScrollPos: integer);
   procedure UpdateTray(Index: integer);
   procedure Add_File(FN: string; Detect: boolean; Playlist: integer);
   procedure FormActivate(Sender: TObject);
   procedure FormCreate(Sender: TObject);
   procedure SBAddClick(Sender: TObject);
   procedure SBClearClick(Sender: TObject);
   procedure SBSaveClick(Sender: TObject);
   procedure LTotTimeMouseDown(Sender: TObject; Button: TMouseButton;
     Shift: TShiftState; X, Y: integer);
   procedure PopupMenu1Popup(Sender: TObject);
   procedure SetDirection(Dir: integer);
   procedure SBLoopClick(Sender: TObject);
   procedure SBDirectionClick(Sender: TObject);
   procedure RandomSortClick(Sender: TObject);
   procedure SBToolsClick(Sender: TObject);
   procedure ByauthorSortClick(Sender: TObject);
   procedure BytitleSortClick(Sender: TObject);
   procedure ByfilenameSortClick(Sender: TObject);
   procedure SearchFilesInFolder(Dir: string; Recurse, Detect: boolean;
     Playlists: integer);
   procedure Byfiletype1Click(Sender: TObject);
   procedure FormDestroy(Sender: TObject);
   procedure Finditem1Click(Sender: TObject);
   procedure RedrawItemsLabel;
   procedure MenuOpenInEditorClick(Sender: TObject);

   //if Silent then DestDir='' for auto, DestDir<>'' for custom
   function GetDirForSave(out DirType: TDirType; n: integer; Silent: boolean;
     const DestDir: string = ''): string;

   //Exten mast be lower cased without dot
   function GetFileNameForSave(const Dir: string; DirType: TDirType;
     n: integer; Silent: boolean; const Exten: string; TwoForTS: boolean): string;

   //calls GetDirForSave/GetFileNameForSave, set Exten by FType, prepare save dialog
   function GetVarsForSave(PLItem, FType: integer; Silent: boolean;
     const DestDir: string; out Dir: string; out DirType: TDirType;
     out FN: string; out Exten: string; TwoForTS: boolean = False): boolean;


   //n:PLItem number, Silent for no save file dialog, DestDir to point path
   //Result=False if user press Cancel or error occured
   function SaveFile(n: integer; Silent: boolean; out FN: string;
     const DestDir: string = ''): boolean;
   procedure ConvertSelected(pw: TPlayWay);
 private
   { Private declarations }
 public
   { Public declarations }
 end;

type
 //PlayListItem parameters
 PPlayListItem = ^TPlayListItem;

 TPlayListItem = record
   FileName, Author, Title, Programm, Tracker, Computer, Date, Comment: string;
   FileType: Available_Types;
   Time, Loop, Address, AY_Freq, Int_Freq,
   Channel_Mode, Number_Of_Channels, FormatSpec, Tag: integer;
   Offset, Length, UnpackedSize: int64;
   Chip_Type: ChTypes;
   AL, AR, BL, BR, CL, CR: byte;
   Selected: boolean;
   Error: ErrorCodes;
   Next: PPlayListItem;
 end;

procedure ClearParams;
procedure ClearPlayList;
procedure ClearSelection;
procedure FillDefPlayListItem(var PLItem: TPlayListItem);
function AddPlayListItem(var PLItem: PPlayListItem): integer;

//if Play<>pwPlay then Result is False if user aborted process or error occured
//Index - PlayList item number, Silent=True = don't ask file name
//DestDir - target foolder
function PlayItem(Index: integer; Play: TPlayWay = pwPlay; Silent: boolean = False;
 const DestDir: string = ''): boolean;

procedure RedrawItem(n: integer);
procedure RedrawPlaylist(From: integer; OnlyItems: boolean);
function FormatScrollString(const Author, Title, FileNameFull: string;
 FileType: Available_Types): string;
function GetPlayListString(PLItem: PPLayListItem): string;
procedure DeleteDefaultPL;
procedure TrySaveDefaultPL;
function LocateAndTryLoadDefaultPL: boolean;
procedure LoadAYL(AYLName: string);
procedure SaveAYL(const AYLName: string);
function LoadCUE(CUEName, FilterName: string): boolean;
procedure CalculatePlaylistScrollBar;
function CalculateTotalTime(Force: boolean): boolean;
function TimeSToStr(ms: integer): string;
procedure CreatePlayOrder;
function AllErrored: boolean;
procedure MakeVisible(Index: integer; RedrawAll: boolean);
function RemoveAnyExt(const FileName: string): string;
function RemoveStdExt(Ext: Available_Types; Force: boolean;
 const FileName: string): string;
procedure TryGetTime(n: integer);

//add to queue
procedure NeedGetTime(n: integer);

//check queue and TryGetTime first
procedure PollGetTimeRequest;

procedure ForceScrollForDisplay;

//add .N index before extension
function GetTSFileName(const fn: string; N: integer): string;

//dynamic since DPI aware app
function ListLineHeight: integer;

type
 TFPIntList = TFPList;//specialize TFPGList<Integer>;

var
 FrmPLst: TFrmPLst;
 GetTimeQueue: TFPIntList;
 IsClicked: boolean;
 MTimer: TTimer;
 MTimerY: integer;
 MTimerOn: boolean = False;
 Direction: integer = -1;
 ListLooped: boolean = False;
 PLArea: TPlayList = nil;
 PlayingOrderItem: integer = -1;
 PlayingItem: integer = -1;
 PlayListItems: array of PPlayListItem;
 PlayingOrder: array of integer;
 LastSelected: integer = -1;
 ShownFrom: integer;
 PLDef_Number_Of_Channels: integer;
 PLDef_Channel_Mode: integer;
 PLDef_SoundChip_Frq: integer;
 PLDef_Chip_Type: ChTypes;
 PLDef_Player_Frq: integer;
 PLDef_AL, PLDef_AR, PLDef_BL, PLDef_BR, PLDef_CL, PLDef_CR: byte;
 DisablePLRedraw: boolean = False;
 PLColorBkSel, PLColorBkPl, PLColorBk, PLColorPlSel, PLColorPl, PLColorSel,
 PLColor, PLColorErrSel, PLColorErr: TColor;

implementation

uses
 ItemEdit, Mixer, Z80, Convs, basscode, basslight, ProgBox,
 {$IFDEF Windows}
 CDviaMCI, SelectCDs,
 {$ENDIF Windows}
 FindPLItem, WinVersion, seldir, settings, sometypes, atari, Languages;

 {$R *.lfm}

type
 TMyCompare = function(Index1, Index2: integer): integer;

const
 DefaultPL = 'Ay_Emul.ayl';

var
 PLPath: string = '';

{$IFNDEF Windows}
procedure CheckPath(var path:string);
begin
 if FileExists(path) then
  Exit;
 path := StringReplace(path,'\','/',[rfReplaceAll]);
end;
 {$ENDIF Windows}

procedure MovePLItem(i, n: integer);
var
 PLI: pointer;
 j: integer;
begin
 if i = n then exit;
 if i > n then
   for j := i - 1 downto n do
    begin
     PLI := PlaylistItems[j + 1];
     PlaylistItems[j + 1] := PlaylistItems[j];
     PlaylistItems[j] := PLI;
    end
 else
   for j := i + 1 to n do
    begin
     PLI := PlaylistItems[j - 1];
     PlaylistItems[j - 1] := PlaylistItems[j];
     PlaylistItems[j] := PLI;
    end;
 CreatePlayOrder;
end;

procedure MovePLItem2(i, n: integer);
begin
 if Item_Displayed = i then
   Item_Displayed := n
 else if (i < Item_Displayed) and (n >= Item_Displayed) then
   Dec(Item_Displayed)
 else if (i > Item_Displayed) and (n <= Item_Displayed) then
   Inc(Item_Displayed);
 if Scroll_Distination = i then
   Scroll_Distination := n
 else if (i < Scroll_Distination) and (n >= Scroll_Distination) then
   Dec(Scroll_Distination)
 else if (i > Scroll_Distination) and (n <= Scroll_Distination) then
   Inc(Scroll_Distination);
 if PlayingItem = i then
  begin
   PlayingItem := n;
   FrmPLst.RedrawItemsLabel;
  end
 else if (i < PlayingItem) and (n >= PlayingItem) then
  begin
   Dec(PlayingItem);
   FrmPLst.RedrawItemsLabel;
  end
 else if (i > PlayingItem) and (n <= PlayingItem) then
  begin
   Inc(PlayingItem);
   FrmPLst.RedrawItemsLabel;
  end;
 MovePLItem(i, n);
end;

procedure MakeVisible(Index: integer; RedrawAll: boolean);
var
 n: integer;
begin
 if Index <= ShownFrom then
   RedrawPlayList(Index, True)
 else
  begin
   n := PLArea.ClientHeight div ListLineHeight;
   if Index - ShownFrom >= n then
     RedrawPlayList(Index - n + 1, True)
   else if RedrawAll then
     RedrawPlayList(ShownFrom, True)
   else
     RedrawItem(Index);
  end;
end;

procedure DoMove(Y: integer);
var
 Index: integer;
begin
 Index := (Y + ShownFrom * ListLineHeight) div ListLineHeight;
 if Index < 0 then
   Index := 0
 else if Index >= Length(PlaylistItems) then
   Index := Length(PlaylistItems) - 1;
 if LastSelected <> Index then
  begin
   MovePLItem2(LastSelected, Index);
   MakeVisible(Index, True);
   ReprepareScroll;
   LastSelected := Index;
  end;
end;

procedure TPlaylist.MTimerPrc(Sender: TObject);
begin
 DoMove(MTimerY);
end;

function ListLineHeight: integer;
const
 DefaultLineHeight = 18; //failsafe
begin
 if PLArea = nil then
   Result := DefaultLineHeight
 else
  begin
   Result := PLArea.Canvas.TextHeight('0');
   if Result = 0 then
     Result := DefaultLineHeight;
  end;
end;

procedure StartTimer(Y: integer);
begin
 MTimerY := Y;
 DoMove(MTimerY);
 if Y < 0 then
   Y := -Y
 else
   Y := Y - PLArea.Height + 1;
 Y := 300 - Y * 10;
 if Y <= 0 then Y := 1;
 if MTimerOn then
  begin
   MTimer.Interval := Y;
   Exit;
  end;
 MTimer := TTimer.Create(PLArea);
 MTimerOn := True;
 MTimer.Interval := Y;
 MTimer.OnTimer := @PLArea.MTimerPrc;
end;

procedure StopTimer;
begin
 if MTimerOn then
  begin
   MTimer.Free;
   MTimerOn := False;
  end;
end;

procedure TPlaylist.PLAreaMouseUp(Sender: TObject; Button: TMouseButton;
 Shift: TShiftState; X, Y: integer);
begin
 IsClicked := False;
 StopTimer;
end;

procedure TPlaylist.PLAreaMouseMove(Sender: TObject; Shift: TShiftState; X, Y: integer);
begin
 if IsClicked and ([ssLeft] = Shift) and (LastSelected <> -1) then
  begin
   if (Y < 0) or (Y >= PLArea.ClientHeight - PLArea.ClientHeight mod
     ListLineHeight) then
     StartTimer(Y)
   else
    begin
     StopTimer;
     DoMove(Y);
    end;
  end;
end;

procedure CreatePlayOrder;
var
 i, j, l: integer;
begin
 l := Length(PlayListItems);
 SetLength(PlayingOrder, l);
 if l = 0 then exit;
 if Direction = 0 then
   for i := 0 to l - 1 do
    begin
     j := l - i - 1;
     PlayingOrder[i] := j;
     PlayListItems[j]^.Tag := i;
    end
 else if Direction <> 2 then
   for i := 0 to l - 1 do
    begin
     PlayingOrder[i] := i;
     PlayListItems[i]^.Tag := i;
    end
 else
  begin
   for i := 0 to l - 1 do
     PlayListItems[i]^.Tag := -1;
   i := 0;
   if PlayingItem >= 0 then
    begin
     PlayListItems[PlayingItem]^.Tag := 0;
     PlayingOrder[0] := PlayingItem;
     i := 1;
    end;
   for i := i to l - 1 do
    begin
     repeat
       j := Random(l)
     until PlayListItems[j]^.Tag < 0;
     PlayListItems[j]^.Tag := i;
     PlayingOrder[i] := j;
    end;
  end;
 if PlayingItem = -1 then
   PlayingOrderItem := -1
 else
   PlayingOrderItem := PlayListItems[PlayingItem]^.Tag;
end;

procedure TFrmPLst.Add_Item_Dialog(Add: boolean);
var
 s, FN: string;
 i: integer;
 Skin: boolean;
begin
 FrmMain.OpenDialog1.Filter := GetFilterString(-1);
 if FrmMain.OpenDialog1.Execute then
  begin
   FN := FrmMain.OpenDialog1.FileName;
   s := ExtractFileDir(FN);
   FrmMain.OpenDialog1.FileName := ExtractFileName(FN);
   FrmMain.OpenDialog1.InitialDir := s;
   if AutoSaveDefDir then
     FrmMain.DefaultDirectory := s;
   Skin := True;
   for i := 0 to FrmMain.OpenDialog1.Files.Count - 1 do
     if not IsSkinFileType(GetFileTypeFromFNExt(
       ExtractFileExt(FrmMain.OpenDialog1.Files[i]))) then
      begin
       Skin := False;
       Break;
      end;
    try
     if not Skin and not Add then
      begin
       StopAndFreeAll;
       ClearPlayList;
      end;
     Add_Files(FrmMain.OpenDialog1.Files);
     if not Skin then CalculateTotalTime(False);
    finally
     if not Skin then
      begin
       CreatePlayOrder;
       RedrawPlaylist(0, True);
      end;
    end;
   if not Skin and not Add then PlayItem(0, pwPlay);
  end;
end;

{$IFDEF Windows}
procedure TFrmPLst.Add_CD_Dialog(Add: boolean);
var
 i, j: integer;
 WasInit: boolean;
begin
 if CDList.ShowModal = mrOk then
  begin
    try
     if not Add then
      begin
       StopAndFreeAll;
       ClearPlayList;
      end;

     for i := 0 to Length(CDDrives) - 1 do
       if CDList.ListBox1.Selected[i] then
        begin
         WasInit := CDIDs[i] <> 0;
         InitCDDevice(i);
          try
           for j := 1 to CDGetNumberOfTracks(i) do
             AddCDTrack(i, j, True);
          finally
           if not WasInit then CloseCDDevice(i);
          end;
        end;

     CalculateTotalTime(False)
    finally
     CreatePlayOrder;
     RedrawPlaylist(0, True);
    end;
   if not Add then PlayItem(0, pwPlay);
  end;
end;

{$ENDIF Windows}

function PlayWayToBASSEnc(Play: TPlayWay): TBASSEnc;
begin
 case Play of
   pwConvMP3: Result := tbeMP3;
   pwConvOGG: Result := tbeOGG;
   pwConvFLAC: Result := tbeFLAC;
 else
   Result := tbeOPUS;
  end;
end;

function PlayItem(Index: integer; Play: TPlayWay = pwPlay; Silent: boolean = False;
 const DestDir: string = ''): boolean;
var
 i: integer;
begin
 Result := True; //abort or blocking error flag (used by converters)
 if (Index < 0) or (Index >= Length(PlayListItems)) then
   Exit(False);
 PlayingOrderItem := Index;
 Index := PlayingOrder[Index];
 i := PlayingItem;
 PlayingItem := Index;
 FrmPLst.RedrawItemsLabel;
 if not IsCDFileType(CurFileType) or not
   IsCDFileType(PlayListItems[Index]^.FileType) then
   StopPlaying;
 FreePlayingResourses;
 if i >= 0 then RedrawItem(i);
 RedrawItem(Index);
 PrepareItem(Index);
 if not IsStreamOrModuleFileType(CurFileType) and not
   (Play in [pwConvMP3, pwConvOGG, pwConvFLAC, pwConvOPUS])
 {$IFDEF UseBassForEmu}
   and not IsAYChipFileType(CurFileType)
 {$ENDIF UseBassForEmu}
 then
   FreeAndUnloadBASS;
 {$IFDEF Windows}
 if not IsCDFileType(CurFileType) then
   FreeAllCD;
 {$ENDIF Windows}
 with PlayListItems[Index]^ do
  begin
   MakeVisible(Index, False);
   Scroll_Distination := Index;
   if Error <> FileNoError then
    begin
     Time_ms := 0;
     ClearTimeInd := True;
     FrmPLst.UpdateTray(Index);
     if Play = pwPlay then
       PostMessage(FrmMain.Handle, WM_PLAYNEXTITEM, 0, 0);
     Exit(False);
    end;

   i := -1;
   if Time = 0 then
    begin
     GetTime(FileHandle, PlayListItems[Index], Index, @ZRAM, i);
     RedrawItem(Index);
     if Error <> FileNoError then
      begin
       Time_ms := 0;
       ClearTimeInd := True;
       FrmPLst.UpdateTray(Index);
       if Play = pwPlay then
         PostMessage(FrmMain.Handle, WM_PLAYNEXTITEM, 0, 0);
       Exit(False);
      end;
    end;

   if Loop < 0 then
     Loop := i;
   LoopVBL := Loop;
   if LoopVBL < 0 then LoopVBL := 0;

   if PlayListItems[Index]^.Next <> nil then
    begin
     i := -1;
     if PlayListItems[Index]^.Next^.Time = 0 then
      begin
       GetTime(FileHandle, PlayListItems[Index]^.Next, Index, @RAM1, i);
       RedrawItem(Index);
       if Error <> FileNoError then
        begin
         Time_ms := 0;
         ClearTimeInd := True;
         FrmPLst.UpdateTray(Index);
         if Play = pwPlay then
           PostMessage(FrmMain.Handle, WM_PLAYNEXTITEM, 0, 0);
         Exit(False);
        end;
      end;
     if PlayListItems[Index]^.Next^.Loop < 0 then
       PlayListItems[Index]^.Next^.Loop := i;
    end;

   i := Time;
   if (PlayListItems[Index]^.Next <> nil) and (PlayListItems[Index]^.Next^.Time > i) then
     i := PlayListItems[Index]^.Next^.Time;

   if IsTimeMSFileType(FileType) then
    begin
     ProgrMax := Time;
     Time_ms := Time;
    end
   else if IsZ80EmuFileType(FileType) then
    begin
     Time_ms := round(Time / FrqZ80 * MaxTStates * 1000);
     PlConsts[0].Global_Tick_Max := Time;
    end
   else if FileType = FT.SNDH then
    begin
     Time_ms := round(time / Interrupt_Freq * 1000000);
     PlConsts[0].Global_Tick_Max := Time;
    end
   else if IsCDFileType(FileType) then
    begin
     ProgrMax := Time;
     Time_ms := round(Time * 1000 / 75);
    end
   else
    begin
     Time_ms := round(i / Interrupt_Freq * 1000000);
     PlConsts[0].Global_Tick_Max := Time;
     if PLConsts[1].TS <> $20 then
       PlConsts[1].Global_Tick_Max := Time
     else if PlayListItems[Index]^.Next <> nil then
       PlConsts[1].Global_Tick_Max := PlayListItems[Index]^.Next^.Time;
    end;

   if IsStreamFileType(FileType) then
     StreamPlayFrom := FormatSpec;

   FileAvailable := True;

   i := 0;
   if FrmMixer.CBChLst.Checked then
     if Number_Of_Channels > 0 then
      begin
       Set_Stereo(Number_Of_Channels);
       i := -1;
      end
     else if PLDef_Number_Of_Channels > 0 then
      begin
       Set_Stereo(PLDef_Number_Of_Channels);
       i := -1;
      end;
   if (i = 0) and (FileType = FT.SNDH) and FrmMixer.AtariMonoChk.Checked then
     Set_Stereo(1);

   if FrmMixer.CBChTypeLst.Checked then
     if Chip_Type <> No_Chip then
       ChType := Chip_Type
     else if PLDef_Chip_Type <> No_Chip then
       ChType := PLDef_Chip_Type;

   i := 0;
   if FrmMixer.CheckBox1.Checked then
     case Channel_Mode of
       0..6:
        begin
         FrmMain.Set_Mode(Channel_Mode);
         i := -1;
        end;
       -2:
        begin
         FrmMain.Set_Mode_Manual(AL, AR, BL, BR, CL, CR);
         i := -1;
        end;
       -1:
         case PLDef_Channel_Mode of
           0..6:
            begin
             FrmMain.Set_Mode(PLDef_Channel_Mode);
             i := -1;
            end;
           -2:
            begin
             FrmMain.Set_Mode_Manual(PLDef_AL, PLDef_AR, PLDef_BL,
               PLDef_BR, PLDef_CL, PLDef_CR);
             i := -1;
            end;
          end;
      end;
   if (i = 0) and (FileType = FT.SNDH) and FrmMixer.AtariYMMonoChk.Checked then
     FrmMain.Set_Mode(0); //todo PreAmp and DMAMax

   //todo и вообще всю вкладку Chan. ampl в миксере надо пересчитывать,
   //завести выбранные и текущие установки как для AY

   AYFileEnableAutoSwitch := False;

   if FrmMixer.CBChFrqLst.Checked then
     if AY_Freq >= 0 then
       FrmMain.Set_Chip_Frq(AY_Freq)
     else if PLDef_SoundChip_Frq >= 0 then
       FrmMain.Set_Chip_Frq(PLDef_SoundChip_Frq)
     else if IsZ80EmuFileType(CurFileType) then
      begin
       AYFileEnableAutoSwitch := True;
       FrmMain.Set_Chip_Frq(1773400);
      end
     else if (CurFileType = FT.YM2) or (CurFileType = FT.SNDH) then
       FrmMain.Set_Chip_Frq(2000000);

   if FrmMixer.CBIntFrqLst.Checked then
     if Int_Freq >= 0 then
       FrmMain.Set_Player_Frq(Int_Freq)
     else if PLDef_Player_Frq >= 0 then
       FrmMain.Set_Player_Frq(PLDef_Player_Frq)
     else if (CurFileType = FT.YM2) or (CurFileType = FT.SNDH) then
       FrmMain.Set_Player_Frq(50000);

   Calculate_Level_Tables2;

  end;
 FrmPLst.UpdateTray(Index);
 case Play of
   pwPlay: PlayCurrent;
   pwConvWAV: Result := WAV_Converter(Silent, DestDir);
   pwConvMP3, pwConvOGG, pwConvFLAC, pwConvOPUS:
     Result := BASS_Converter(Silent, DestDir, PlayWayToBASSEnc(Play));
   pwConvVTX: Result := VTX_Converter(Silent, DestDir);
   pwConvYM6: Result := YM6_Converter(Silent, DestDir);
   pwConvPSG: Result := PSG_Converter(Silent, DestDir);
   pwConvZXAY: Result := ZXAY_Converter(Silent, DestDir);
  end;
end;

procedure TFrmPLst.UpdateTray(Index: integer);
begin
 CurItem.PLStr := GetPlayListString(PlayListItems[Index]);
 with PlayListItems[Index]^ do
  begin
   CurItem.Title := Title;
   CurItem.Author := Author;
   CurItem.Programm := Programm;
   CurItem.Comment := Comment;
   CurItem.Tracker := Tracker;
   CurItem.FileName := FileName;
  end;
 {$IFDEF Windows}
 Application.Title := CurItem.PLStr;
 {$ELSE Windows}
 FrmMain.Caption := CurItem.PLStr;
 {$ENDIF Windows}
 FrmMain.TrayIcon1.Hint := CurItem.PLStr;
end;

procedure TFrmPLst.PlayNextItem;
var
 Tmp: integer;
begin
 Tmp := PlayingOrderItem + 1;
 if Tmp >= Length(PlayListItems) then
   if ListLooped and not AllErrored then
     Tmp := 0;
 PlayItem(Tmp, pwPlay);
end;

procedure TFrmPLst.PlayPreviousItem;
var
 Tmp: integer;
begin
 Tmp := PlayingOrderItem - 1;
 if Tmp < 0 then
   if ListLooped and not AllErrored then
     Tmp := Length(PlayListItems) - 1;
 PlayItem(Tmp, pwPlay);
end;

procedure TFrmPLst.FormHide(Sender: TObject);
begin
 if ButtZoneRoot <> nil then
   if ButList.Is_On then
     ButList.Switch_Off;
 FrmMain.MIPlaylist.Checked:=False;
end;

procedure ClearParams;
begin
 LastSelected := -1;
 Item_Displayed := -1;
 PlayingOrderItem := -1;
 PlayingItem := -1;
 ShownFrom := 0;
 Scroll_Distination := -1;
 Scroll_Offset := scr_lineheight;
 PLDef_Number_Of_Channels := 0;
 PLDef_Channel_Mode := -1;
 PLDef_SoundChip_Frq := -1;
 PLDef_Chip_Type := No_Chip;
 PLDef_Player_Frq := -1;
 ClearTimeInd := True;
end;

procedure ClearPlayListItems;
var
 i: integer;
begin
 LastSelected := -1;
 ShownFrom := 0;
 for i := Length(PlayListItems) - 1 downto 0 do
  begin
   if PlayListItems[i]^.Next <> nil then Dispose(PlayListItems[i]^.Next);
   Dispose(PlayListItems[i]);
  end;
 PlayListItems := nil;
end;

procedure ForceScrollForDisplay;
begin
 Item_Displayed := Scroll_Distination;
 Scroll_Offset := scr_lineheight;
 HorScrl_Offset := 0;
 ReprepareScroll;
end;

procedure ForceScrollForDelete;
begin
 ForceScrollForDisplay;
 Scroll_Distination := -1;
 Item_Displayed := -1;
end;

procedure ClearPlayList;
begin
 if Scroll_Distination <> Item_Displayed then
   ForceScrollForDelete;
 ClearPlayListItems;
 PlayingOrder := nil;
 PlayingOrderItem := -1;
 PlayingItem := -1;

 FrmPLst.ScBPLItems.SetParams(0, 0, 0, 1);

 FrmPLst.LTotTime.Caption := '0:00';
 FrmPLst.LQtyCurTotal.Caption := '0/0';

 PLArea.Canvas.Brush.Color := PLColorBk;
 PLArea.Canvas.FillRect(PLArea.ClientRect);
 ClearParams;
end;

procedure TFrmPLst.ConvertSelected(pw: TPlayWay);
var
 i: integer;
begin
 i := GetNumberOfSelectedItems;
 if i = 0 then
   Exit;
 if i = 1 then
   for i := 0 to Length(PlaylistItems) - 1 do
     if PlayListItems[i]^.Selected then
      begin
       if pw in [pwConvMP3, pwConvOGG, pwConvFLAC, pwConvOPUS] then
         with EncoderOptions[PlayWayToBASSEnc(pw)] do
           GroupOperation := False; //to show tag editor
       PlayItem(PlayListItems[i]^.Tag, pw);
       Exit;
      end;
 SaveToFolder(pw, False);
end;

procedure TFrmPLst.MenuWAVClick(Sender: TObject);
begin
 ConvertSelected(pwConvWAV);
end;

procedure TFrmPLst.MenuVTXClick(Sender: TObject);
begin
 ConvertSelected(pwConvVTX);
end;

procedure TFrmPLst.MenuYM6Click(Sender: TObject);
begin
 ConvertSelected(pwConvYM6);
end;

procedure TFrmPLst.MenuPSGClick(Sender: TObject);
begin
 ConvertSelected(pwConvPSG);
end;

procedure TFrmPLst.MenuZXAYClick(Sender: TObject);
begin
 ConvertSelected(pwConvZXAY);
end;

procedure TFrmPLst.MenuItemAdjustingClick(Sender: TObject);
var
 {%H-}Temp: integer;
begin
 if (LastSelected < 0) or (LastSelected >= Length(PlayListItems)) or
   not PlayListItems[LastSelected]^.Selected then exit;
 with TFrmPLIEdit.Create(Self) do
  try
   with PlayListItems[LastSelected]^ do
    begin
     EAuthor.Text := Author;
     ETitle.Text := Title;
     EProgram.Text := Programm;
     ETracker.Text := Tracker;
     EComputer.Text := Computer;
     EDate.Text := Date;
     EFName.Text := FileName;
     MComment.Text := Comment;
     SetPlayItems(Chip_Type, Number_Of_Channels, AY_Freq,
       Int_Freq, Channel_Mode, AL, AR, BL, BR, CL, CR);
     CBFType.ItemIndex := FileType;
     EFOffs.Text := IntToStr(Offset);
     EFLen.Text := IntToStr(Length);
     EFAddr.Text := IntToStr(Address);
     EFTime.Text := IntToStr(Time);
     EFLoop.Text := IntToStr(Loop);
     EFSpec.Text := IntToStr(FormatSpec);
     if ShowModal = mrOk then
      begin
       Author := UTF8Trim(EAuthor.Text);
       Title := UTF8Trim(ETitle.Text);
       Programm := UTF8Trim(EProgram.Text);
       Tracker := UTF8Trim(ETracker.Text);
       Computer := UTF8Trim(EComputer.Text);
       Date := UTF8Trim(EDate.Text);

       //Trim делать нельзя, в комменте может испортиться таг ASC или STP,
       //а он используется при "Save as"
       Comment := MComment.Text;

       FileName := UTF8Trim(EFName.Text);
       GetPlayItems(Chip_Type, Number_Of_Channels, AY_Freq,
         Int_Freq, Channel_Mode, AL, AR, BL, BR, CL, CR);
       if CBFType.ItemIndex <> -1 then
         FileType := CBFType.ItemIndex;
       Val(EFOffs.Text, Offset, Temp);
       Val(EFLen.Text, Length, Temp);
       Val(EFAddr.Text, Address, Temp);
       Val(EFTime.Text, Time, Temp);
       Val(EFLoop.Text, Loop, Temp);
       Val(EFSpec.Text, FormatSpec, Temp);
       RedrawItem(LastSelected);
       FrmPLst.UpdateTray(LastSelected);
       ReprepareScroll;

       //duration can be depending of not only Time, but Interrupt freq, etc
       CalculateTotalTime(False);
      end;
    end;
  finally
   Free;
  end;
end;

procedure DeleteDefaultPL;
begin
 if PLPath = '' then
   Exit;
 if FileExists(PLPath + DefaultPL) then
   DeleteFile(PLPath + DefaultPL);
end;

procedure TrySaveDefaultPL;

 function CheckAndWrite(const dir: string): boolean;
 var
   tmp: string;
 begin
   Result := False;
   SetCurrentDir(dir);
   if DiskFree(0) < 1000000 then
    Exit;
   tmp := ExpandFileName(DefaultPL);
   if not FileExists(tmp) then
     if not ForceDirectories(dir) then
      Exit;
    try
     SaveAYL(tmp);
     PLPath := dir;
     Result := True;
    except
    end;
 end;

begin
 if Uninstall then
   Exit;
 if PLPath = '' then
  begin
   Application.Title := 'Ay_Emul'; //avoid undesired behavior of GetAppConfigDirUTF8
   if not CheckAndWrite(GetAppConfigDirUTF8(False)) then
     if not CheckAndWrite(ExtractFilePath(GetProcessFileName)) then
       Exit;
  end
 else
   CheckAndWrite(PLPath);
end;

function LocateAndTryLoadDefaultPL: boolean;

 function CheckAtPath(const dir: string): boolean;
 begin
   Result := FileExists(IncludeTrailingBackslash(dir) + DefaultPL);
   if Result then PLPath := dir;
 end;

begin
 Result := False;
 if PLPath = '' then
  begin
   if not CheckAtPath(ExtractFilePath(GetProcessFileName)) then
    begin
     Application.Title := 'Ay_Emul'; //avoid undesired behavior of GetAppConfigDirUTF8
     if not CheckAtPath(GetAppConfigDirUTF8(False)) then
       Exit;
    end;
  end;
 if Length(PlayListItems) <> 0 then exit;
  try
   LoadAYL(IncludeTrailingBackslash(PLPath) + DefaultPL);
   Result := True;
  except
  end;
end;

function CheckFromPLFile(var FN: string): boolean;
begin
 Result := True;
 if FileIsURL(FN) then
   Exit;
 {$IFDEF Windows}
 if LowerCase(ExtractFileExt(FN)) = '.cda' then
   Exit;
 {$ELSE Windows}
 CheckPath(FN); //path delimeter in linux
 {$ENDIF Windows}
 if FileExists(FN) then
  begin
   FN := ExpandFileName(FN);
   Exit;
  end;
 Result := False;
end;

procedure CheckAndAddFromPLFile(FN: string);
begin
 if CheckFromPLFile(FN) then
   Add_Songs_From_File(FN, True);
end;

procedure LoadAYL(AYLName: string);
const
 NumOfTokens = 21;
 MyTokens: array[0..NumOfTokens - 1] of string =
   ('ChipType', 'Channels', 'ChannelsAllocation', 'ChipFrequency',
   'PlayerFrequency', 'Offset', 'Length', 'Address', 'Loop', 'Time', 'Original',
   'Name', 'Author', 'Program', 'Computer', 'Date', 'Comment', 'Tracker', 'Type',
   'ams_andsix', 'FormatSpec');
 MaxTokenLen = 18;
var
 m3uf: TextFile;
 String1, String2: string;
 TokenError: boolean;
 i2, Vers: integer;

 procedure ExtractToken(S1: string; var S2: string; var Ind: integer);
 var
   i: integer;
 begin
   i := 1;
   S2 := '';
   while (i <= MaxTokenLen) and (i <= Length(S1)) and (S1[i] <> '=') do
    begin
     S2 := S2 + S1[i];
     Inc(i);
    end;
   if i > Length(S1) then
    begin
     TokenError := True;
     exit;
    end;
   Ind := 0;
   while (Ind < NumOfTokens) and (MyTokens[Ind] <> S2) do Inc(Ind);
   if Ind = NumOfTokens then
    begin
     TokenError := True;
     exit;
    end;
   S2 := '';
   for i := i + 1 to Length(S1) do S2 := S2 + S1[i];
 end;

 procedure ExtractChType(S1: string; var ChT: ChTypes);
 begin
   if S1 = 'AY' then ChT := AY_Chip
   else if S1 = 'YM' then ChT := YM_Chip
   else
     TokenError := True;
 end;

 procedure ExtractChans(S1: string; var Chs: integer);
 begin
   if S1 = 'Mono' then Chs := 1
   else
   if S1 = 'Stereo' then Chs := 2
   else
     TokenError := True;
 end;

 procedure ExtractChanMode(S1: string; var ChM: integer;
 var a1, a2, a3, a4, a5, a6: byte);
 var
   i, j, Temp: integer;
   S2: string;
   ai: array[0..5] of byte;
 begin
   if S1 = 'Mono' then ChM := 0
   else
   if S1 = 'ABC' then ChM := 1
   else
   if S1 = 'ACB' then ChM := 2
   else
   if S1 = 'BAC' then ChM := 3
   else
   if S1 = 'BCA' then ChM := 4
   else
   if S1 = 'CAB' then ChM := 5
   else
   if S1 = 'CBA' then ChM := 6
   else
    begin
     ChM := -2;
     i := 1;
     S1 := S1 + ',';
     for j := 0 to 5 do
      begin
       S2 := '';
       while (i <= length(S1)) and (S1[i] <> ',') do
        begin
         S2 := S2 + S1[i];
         Inc(i);
        end;
       if i > length(S1) then
        begin
         TokenError := True;
         exit;
        end;
       Val(S2, ai[j], Temp);
       if Temp <> 0 then
        begin
         TokenError := True;
         exit;
        end;
       Inc(i);
      end;
     a1 := ai[0];
     a2 := ai[1];
     a3 := ai[2];
     a4 := ai[3];
     a5 := ai[4];
     a6 := ai[5];
    end;
 end;

 procedure ExtractInt64(S1: string; var Integ: int64);
 var
   Temp: integer;
 begin
   Val(S1, Integ, Temp);
   if Temp <> 0 then TokenError := True;
 end;

 procedure ExtractInteger(S1: string; var Integ: integer);
 var
   Temp: integer;
 begin
   Val(S1, Integ, Temp);
   if Temp <> 0 then TokenError := True;
 end;

 procedure ExtractFType(S1: string; var FT: Available_Types);
 begin
   FT := GetFileType(S1);
   if FT < 0 then TokenError := True;
 end;

 function ConvertCR(s: string): string;
 var
   i, i0, j: integer;
 begin
   if Vers < 3 then
    begin
     Result := s;
     exit;
    end;
   Result := '';
   i := 1;
   while i <= Length(s) do
    begin
     j := 0;
     i0 := i;
     while (i <= Length(s)) and (s[i] <> '\') do
      begin
       Inc(i);
       Inc(j);
      end;
     if j <> 0 then
       Result := Result + Copy(s, i0, j);
     if i >= Length(s) then break;
     if s[i + 1] = 'n' then
      begin
       s[i] := #13;
       s[i + 1] := #10;
      end
     else
      begin
       Inc(i, 2);
       Result := Result + s[i - 1];
      end;
    end;
 end;

var
 PLItemWork: TPlayListItem;
 UTF8: boolean;

 function Uni(s: string): string;
 begin
   if UTF8 then
     Result := s
   else
     Result := CPToUTF8(s);
 end;

 procedure LoadPLItem;
 begin
   FillDefPlayListItem(PLItemWork);
   with PLItemWork do
    begin
     FileName := String1;
     while not EOF(m3uf) do
      begin
       ReadLn(m3uf, String1);
       if String1 = '>' then
        begin
         if FileType < 0 then
          begin
           String1 := UpperCase(ExtractFileExt(FileName));
           FileType := GetFileTypeFromFNExt(String1);
           if FileType < 0 then //backward compatibility for multiformat exts
             if String1 = '.PSG' then
               FileType := FT.PSG
             else if String1 = '.AY' then
               FileType := FT.AY;
{           else if String1 = '.ASC' then
            FileType := FT.ASC;}
          end;
         break;
        end;
       ExtractToken(String1, String2, i2);
       if TokenError then break;
       case i2 of
         0: ExtractChType(String2, Chip_Type);
         1: ExtractChans(String2, Number_Of_Channels);
         2: ExtractChanMode(String2, Channel_Mode, AL, AR, BL, BR, CL, CR);
         3: ExtractInteger(String2, Ay_Freq);
         4: begin
           ExtractInteger(String2, Int_Freq);
           if (Vers = 0) and not TokenError then
             Int_Freq := Int_Freq * 1000;
          end;
         5: ExtractInt64(String2, Offset);
         6: ExtractInt64(String2, Length);
         7: ExtractInteger(String2, Address);
         8: ExtractInteger(String2, Loop);
         9: ExtractInteger(String2, Time);
         10: ExtractInt64(String2, UnpackedSize);
         11: Title := Uni(String2);
         12: Author := Uni(String2);
         13: Programm := Uni(String2);
         14: Computer := Uni(String2);
         15: Date := Uni(String2);
         16: Comment := ConvertCR(Uni(String2));
         17: Tracker := Uni(String2);
         18: ExtractFType(String2, FileType);
         19, 20: ExtractInteger(String2, FormatSpec);
        end;
      end;
    end;
 end;

var
 i: integer;
 PLItem: PPlayListItem;
begin
 UTF8 := False;
 if not FileExists(AYLName) then exit;
 AssignFile(m3uf, AYLName);
 Reset(m3uf);
  try
   if not EOF(m3uf) then
    begin
     Readln(m3uf, String1);
     Vers := -1;
     if Pos(Version_String, String1) = 1 then
      begin
       i := Length(String1) - Length(Version_String);
       if i > 0 then
         Val(Copy(String1, Length(Version_String) + 1, i), Vers, i);
       if i <> 0 then Vers := -1;
      end;
     if Vers in [0..6] then
      begin
       UTF8 := Vers > 5;
       SetCurrentDir(ExtractFileDir(AYLName));
       TokenError := False;
       if not EOF(m3uf) then
        begin
         ReadLn(m3uf, String1);
         if String1 = '<' then
           while not EOF(m3uf) do
            begin
             ReadLn(m3uf, String1);
             if String1 = '>' then
              begin
               if not EOF(m3uf) then ReadLn(m3uf, String1)
               else
                 TokenError := True;
               break;
              end;
             if String1 <> '' then
              begin
               ExtractToken(String1, String2, i2);
               if TokenError then break;
               case i2 of
                 0: ExtractChType(String2, PLDef_Chip_Type);
                 1: ExtractChans(String2, PLDef_Number_Of_Channels);
                 2: ExtractChanMode(String2, PLDef_Channel_Mode, PLDef_AL, PLDef_AR,
                     PLDef_BL, PLDef_BR, PLDef_CL, PLDef_CR);
                 3: ExtractInteger(String2, PLDef_SoundChip_Frq);
                 4: begin
                   ExtractInteger(String2, PLDef_Player_Frq);
                   if (Vers = 0) and not TokenError then
                     PLDef_Player_Frq := PLDef_Player_Frq * 1000;
                  end
               else
                 TokenError := True;
                end;
               if TokenError then break;
              end;
            end;

         while not TokenError do
          begin
           if EOF(m3uf) then
            begin
             String2 := '';
             TokenError := True;
            end
           else
             ReadLn(m3uf, String2);
           if not UTF8 then String1 := CPToUTF8(String1);
           {$IFNDEF Windows}
           CheckPath(String1); // path delimeter in linux
           {$ENDIF Windows}
           if String2 <> '<' then
            begin
             CheckAndAddFromPLFile(String1);
             String1 := String2;
            end
           else if CheckFromPLFile(String1) then
            begin
             LoadPLItem;
             if not TokenError then
              begin
               if IsSTSoundFileType(PLItemWork.FileType) and
                 (PLItemWork.UnpackedSize = 0) then
                begin
                 i := Length(PlaylistItems);
                 Add_Songs_From_File(PLItemWork.FileName, False);
                 if i <> Length(PlaylistItems) - 1 then exit;
                 with PlaylistItems[i]^ do
                  begin
                   PLItemWork.Offset := Offset;
                   PLItemWork.FileType := FileType;
                   PLItemWork.Length := Length;
                   PLItemWork.UnpackedSize := UnpackedSize;
                   PLItemWork.FormatSpec := FormatSpec;
                  end;
                end
               else
                 i := AddPlaylistItem(PLItem);
               if (PLItemWork.FormatSpec = -1) and
                 (IsZ80EmuFileType(PLItemWork.FileType) or
                 IsMIDIFileType(PLItemWork.FileType) or
                 (PLItemWork.FileType = FT.SNDH)) then
                 PLItemWork.FormatSpec := 0;
               PlaylistItems[i]^ := PLItemWork;
               RedrawItem(i);
               if not EOF(m3uf) then
                begin
                 Readln(m3uf, String1);
                 if String1 = '<' then //ts
                  begin
                   String1 := PLItemWork.FileName;
                   LoadPLItem;
                   if not TokenError then
                    begin
                     New(PlayListItems[i]^.Next);
                     PlayListItems[i]^.Next^ := PLItemWork;
                     if not EOF(m3uf) then Readln(m3uf, String1)
                     else
                       TokenError := True;
                    end;
                  end;
                end
               else
                 TokenError := True;
              end;
            end
           else
            begin
             while not EOF(m3uf) and (String2 <> '>') do Readln(m3uf, String2);
             if not EOF(m3uf) then Readln(m3uf, String1)
             else
               TokenError := True;
            end;
          end;
        end;
      end;
    end
  finally
   CloseFile(m3uf);
   ReprepareScroll;
  end;
end;

procedure SaveAYL(const AYLName: string);
const
 NChan: array[1..2] of array [0..6] of char =
   ('Mono', 'Stereo');
 ChanAl: array[0..6] of array [0..4] of char =
   ('Mono', 'ABC', 'ACB', 'BAC', 'BCA', 'CAB', 'CBA');
 ChipT: array[AY_Chip..YM_Chip] of array [0..1] of char =
   ('AY', 'YM');
var
 m3uf: TextFile;
 flag: boolean;

 procedure AddBr;
 begin
   if not Flag then
    begin
     Writeln(m3uf, '<');
     Flag := True;
    end;
 end;

 procedure WriteParam(s: string);
 begin
   AddBr;
   Write(m3uf, s);
 end;

 procedure WritelnParam(s: string);
 begin
   AddBr;
   Writeln(m3uf, s);
 end;

 function ConvCR(s: string): string;
 var
   i, i0, j: integer;
 begin
   Result := '';
   i := 1;
   while i <= Length(s) do
    begin
     j := 0;
     i0 := i;
     while (i <= Length(s)) and not (s[i] in ['\', #13]) do
      begin
       Inc(i);
       Inc(j);
      end;
     if j <> 0 then
       Result := Result + Copy(s, i0, j);
     if i > Length(s) then break;
     if s[i] = '\' then
      begin
       Result := Result + '\\';
       Inc(i);
      end
     else
      begin
       if i = Length(s) then break;
       Result := Result + '\n';
       Inc(i, 2);
      end;
    end;
 end;

 function RemoveTrash(s: string): string;
 var
   i: integer;
 begin
   Result := '';
   i := 1;
   while i <= Length(s) do
    begin
     if not (s[i] in [#13, #10, #26, #0]) then
       Result := Result + s[i];
     Inc(i);
    end;
 end;

 procedure SavePLItem(PLItem: PPlaylistItem);
 var
   FName: string;
 begin
   with PLItem^ do
    begin
     if (Number_Of_Channels <> PLDef_Number_Of_Channels) and
       (Number_Of_Channels > 0) then
       WritelnParam('Channels=' + NChan[Number_Of_Channels]);
     if (Channel_Mode <> PLDef_Channel_Mode) and (Channel_Mode <> -1) then
      begin
       WriteParam('ChannelsAllocation=');
       if Channel_Mode >= 0 then
         Writeln(m3uf, ChanAl[Channel_Mode])
       else
         Writeln(m3uf, IntToStr(AL) + ',' + IntToStr(AR) + ',' +
           IntToStr(BL) + ',' + IntToStr(BR) + ',' + IntToStr(CL) +
           ',' + IntToStr(CR));
      end;
     if ((AY_Freq <> PLDef_SoundChip_Frq) and (AY_Freq >= 0)) then
       WritelnParam('ChipFrequency=' + IntToStr(AY_Freq));
     if ((Int_Freq <> PLDef_Player_Frq) and (Int_Freq >= 0)) then
       WritelnParam('PlayerFrequency=' + IntToStr(Int_Freq));
     if (Chip_Type <> PLDef_Chip_Type) and (Chip_Type <> No_Chip) then
       WritelnParam('ChipType=' + ChipT[Chip_Type]);
     if Author <> '' then
       WritelnParam('Author=' + RemoveTrash(Author));
     if Title <> '' then
       WritelnParam('Name=' + RemoveTrash(Title));
     if Programm <> '' then
       WritelnParam('Program=' + RemoveTrash(Programm));
     if Tracker <> '' then
       WritelnParam('Tracker=' + RemoveTrash(Tracker));
     if Computer <> '' then
       WritelnParam('Computer=' + RemoveTrash(Computer));
     if Date <> '' then
       WritelnParam('Date=' + RemoveTrash(Date));
     if Comment <> '' then
       WritelnParam('Comment=' + RemoveTrash(ConvCR(Comment)));
     FName := ExtractFileExt(FileName);
     if (FileType <> GetFileTypeFromFNExt(FName)) or (FileType = FT.EPSG) or
       IsSTSoundFileType(FileType){ or (FileType = FT.ASC0)} then
       WritelnParam('Type=' + GetFileType(FileType));
     if (Address <> 0) and (FileType <> FT.FXM) then
       WritelnParam('Address=' + IntToStr(Address));
     if (FileType <> GetFileTypeFromFNExt(FName)) or (FileType = FT.VTX) or
       IsSTSoundFileType(FileType) or IsAYNativeFileType(FileType) then
       WritelnParam('Length=' + IntToStr(Length));
     if (FileType = FT.VTX) or IsSTSoundFileType(FileType) then
       WritelnParam('Original=' + IntToStr(UnpackedSize));
     if Offset <> 0 then
       WritelnParam('Offset=' + IntToStr(Offset));
     if Time <> 0 then
       WritelnParam('Time=' + IntToStr(Time));
     if Loop >= 0 then
       WritelnParam('Loop=' + IntToStr(Loop));
     if ((FileType = FT.FXM) and (FormatSpec <> 31)) or
       ((FormatSpec <> -1) and ((FileType = FT.YM5) or (FileType = FT.YM6) or
       (FileType = FT.EPSG) or IsCDFileType(FileType) or
       IsStreamFileType(FileType) or (FileType = FT.PT3))) or
       ((FormatSpec > 0) and ((FileType = FT.SNDH) or IsZ80EmuFileType(FileType) or
       IsMIDIFileType(FileType))) then
       if (FileType <> FT.AY) or (Offset = 0) then
         WritelnParam('FormatSpec=' + IntToStr(FormatSpec));
     if flag then
      begin
       if FileType = FT.FXM then
         Writeln(m3uf, 'Address=' + IntToStr(Address));
       Writeln(m3uf, '>');
       flag := False;
      end;
    end;
 end;

var
 i: integer;
begin
 AssignFile(m3uf, AYLName);
 Rewrite(m3uf);
  try
   Writeln(m3uf, Version_String + '6');
   flag := False;
   if PLDef_Number_Of_Channels > 0 then
     WritelnParam('Channels=' + NChan[PLDef_Number_Of_Channels]);
   if PLDef_Channel_Mode <> -1 then
    begin
     WriteParam('ChannelsAllocation=');
     if PLDef_Channel_Mode >= 0 then
       Writeln(m3uf, ChanAl[PLDef_Channel_Mode])
     else
       Writeln(m3uf, IntToStr(PLDef_AL) + ',' + IntToStr(PLDef_AR) +
         ',' + IntToStr(PLDef_BL) + ',' + IntToStr(PLDef_BR) +
         ',' + IntToStr(PLDef_CL) + ',' + IntToStr(PLDef_CR));
    end;
   if PLDef_SoundChip_Frq >= 0 then
     WritelnParam('ChipFrequency=' + IntToStr(PLDef_SoundChip_Frq));
   if PLDef_Player_Frq >= 0 then
     WritelnParam('PlayerFrequency=' + IntToStr(PLDef_Player_Frq));
   if PLDef_Chip_Type <> No_Chip then
     WritelnParam('ChipType=' + ChipT[PLDef_Chip_Type]);
   if flag then
    begin
     Writeln(m3uf, '>');
     flag := False;
    end;
   for i := 0 to Length(PlaylistItems) - 1 do
     with PlaylistItems[i]^ do
       if FileType >= 0 then
        begin
         Writeln(m3uf, FileName);
         SavePLItem(PlaylistItems[i]);
         if PlayListItems[i]^.Next <> nil then SavePLItem(PlayListItems[i]^.Next);
        end;
  finally
   CloseFile(m3uf);
  end;
end;

procedure TFrmPLst.Add_Files(SF: TStrings);
var
 Index: integer;
begin
 LongProcessPrepare;
 May_Quit2 := False; //user can switch it to abandon all searchings
  try
   with SF do
     for Index := 0 to Count - 1 do
      begin
       Add_File(Strings[Index], True, 0);
       Application.ProcessMessages;
       if May_Quit then
         Break;
      end;
   if Add_File_Errors <> '' then
    begin
     ShowMessage(Add_File_Errors);
     Add_File_Errors := '';
    end;
  finally
   LongProcessDone;
  end;
end;

procedure TFrmPLst.Add_File(FN: string; Detect: boolean; Playlist: integer);
var
 String1, Ext, Title, FTS: string;
 ExtM3u, hnd, i, Time, FT: integer;
begin
  try
    begin
     Ext := LowerCase(ExtractFileExt(FN));
     FT := GetFileTypeFromFNExt(Ext);
     FTS := GetFileType(FT);
     if IsSkinFileType(FT) then
       FrmMain.LoadSkin(FN, False)
     else if FTS = 'AYL' then
      begin
       if Playlist <> 1 then LoadAYL(FN);
      end
     else if FTS = 'CUE' then
      begin
       if Playlist <> 1 then LoadCUE(FN, '');
      end
     else if FTS = 'M3U' then
      begin
       if Playlist <> 1 then
        begin
         if not FileExists(FN) then exit;
         UniReadInit(hnd, URFile, FN, nil, -1);
          try
           if Ext <> '.m3u8' then
             UniDetectCharCode(hnd)
           else
             UniReadersData[hnd]^.UniCharCode := UCCUtf8;
           SetCurrentDir(ExtractFileDir(FN));
           ExtM3u := -1;
           Title := '';
           Time := -2;
           while UniReadersData[hnd]^.UniFilePos < UniReadersData[hnd]^.UniFileSize do
            begin
             UniReadLnUtf8(hnd, String1);
             if ExtM3u < 0 then
              begin
               if (Ext = '.m3u8') and (Pos(UTF8BOM, String1) = 1) then
                 String1 := Copy(String1, 4, Length(String1) - 3);
               if String1 = '#EXTM3U' then Inc(ExtM3u);
               Inc(ExtM3u);
               if ExtM3u > 0 then continue;
              end
             else if (ExtM3u > 0) and (Pos('#EXTINF:', String1) = 1) then
              begin
               i := Pos(',', String1);
               if i > 0 then
                begin
                 Title := Trim(Copy(String1, i + 1, Length(String1) - i));
                  try
                   Time := StrToInt(Copy(String1, 9, i - 9));
                  except
                   Time := -2;
                  end;
                 continue;
                end;
              end;
             i := Length(PlayListItems);
             CheckAndAddFromPLFile(String1);
             if i = Length(PlayListItems) - 1 then //only one item added
               if (Title <> '') or (Time <> -2) then
                begin
                 if PlayListItems[i]^.Title = '' then
                   PlayListItems[i]^.Title := Title;
                 if IsStreamOrModuleFileType(PlayListItems[i]^.FileType) then
                   if (Time = -1) or (Time = 0) then
                     PlayListItems[i]^.Time := -1
                   else if Time > 0 then
                    begin
                     PlayListItems[i]^.Time := Time * 1000;
                     if PlayListItems[i]^.FormatSpec = -1 then
                       //set BASS sync to this new time
                       PlayListItems[i]^.FormatSpec := 0;
                    end;
                end;
             Title := '';
             Time := -2;
            end;
          finally
           UniReadClose(hnd);
          end;
        end;
      end
     else if FTS = 'PLS' then
      begin
       if Playlist <> 1 then
        begin
         if not FileExists(FN) then exit;
         UniReadInit(hnd, URFile, FN, nil, -1);
          try
           UniReadersData[hnd]^.UniCharCode := UCCUtf8;
           UniReadLnUtf8(hnd, String1);
           if String1 <> '[playlist]' then
             Exit;
           SetCurrentDir(ExtractFileDir(FN));
           while UniReadersData[hnd]^.UniFilePos < UniReadersData[hnd]^.UniFileSize do
            begin
             UniReadLnUtf8(hnd, String1);
             if Length(String1) < 6 then continue;
             if LowerCase(Copy(String1, 1, 4)) <> 'file' then continue;
             i := Pos('=', String1);
             if (i = 0) or (i = Length(String1)) then continue;
             String1 := Copy(String1, i + 1, Length(String1) - i);
             CheckAndAddFromPLFile(String1);
            end;
          finally
           UniReadClose(hnd);
          end;
        end;
      end
     else if Playlist <> 2 then
       Add_Songs_From_File(FN, Detect);
    end;
  except
   on E: Exception do
     Add_File_Errors := Add_File_Errors + FN + ':'#13#10'(' + E.ClassName +
       ': ' + E.Message + ')' + #13#10;
  end;
end;

function RemoveAnyExt(const FileName: string): string;
var
 SExt: string;
 i: integer;
begin
 SExt := Trim(FileName);
 i := Length(SExt);
 while (i > 1) and (SExt[i] <> '.') do Dec(i);
 if i = 1 then
  begin
   Result := FileName;
   exit;
  end;
 Result := Copy(FileName, 1, i - 1);
end;

function RemoveStdExt(Ext: Available_Types; Force: boolean;
 const FileName: string): string;
var
 SExt: string;
 i: integer;
begin
 SExt := Trim(FileName);
 i := Length(SExt);
 while (i > 1) and (SExt[i] <> '.') do Dec(i);
 if i = 1 then
   Exit(FileName);
 SExt := UpperCase(Copy(SExt, i, Length(SExt) - i + 1));
 if (IsMatchFileTypeToFNExt(Ext, SExt)) or
   (Force and ((SExt = '.TRD') or (SExt = '.SCL') or (SExt = '.SNA'))) then
   Result := Copy(FileName, 1, i - 1)
 else
   Result := FileName;
end;

//Get filename for separated TS-pair
function GetTSFileName(const fn: string; N: integer): string;
var
 Ext: string;
begin
 Ext := ExtractFileExt(fn);
 Result := Copy(fn, 1, Length(fn) - Length(Ext)) + '.' + N.ToString + Ext;
end;

function TFrmPLst.GetDirForSave(out DirType: TDirType; n: integer;
 Silent: boolean; const DestDir: string = ''): string;
begin
 if not Silent then
  begin
   Result := ExtractFileDir(PlaylistItems[n]^.FileName);
   DirType := dtSource;
  end
 else
  begin
   if DestDir = '' then
    begin
     Result := GetTempDir;
     if Result = '' then
      begin
       Result := GetCurrentDir;
       DirType := dtCurrent;
      end
     else
       DirType := dtTemp;
    end
   else
    begin
     Result := DestDir;
     DirType := dtCustom;
    end;
  end;
end;

function TFrmPLst.GetFileNameForSave(const Dir: string; DirType: TDirType;
 n: integer; Silent: boolean; const Exten: string; TwoForTS: boolean): string;
var
 FN, FN1, FN2, suf, body: string;
 i, Len, MaxLen: integer;
begin
 Result := '';

 MaxLen := 255{Rewrite() limitation, todo without Rewrite() with MaxPathLen} -
   UTF8Length(IncludeTrailingPathDelimiter(Dir)) - UTF8Length(Exten);
 if TwoForTS then
   Dec(MaxLen, 2);
 if MaxLen <= 0 then
   Exit;

 //take file name from playlist item
 with PlaylistItems[n]^ do
  begin
   //check for original file name on disk image
   FN := Programm;
   if System.Length(FN) > ImageIDLen + 3 then
     if Copy(FN, 1, ImageIDLen) = ImageID then
      begin
       i := Pos('>', FN);
       if (i > ImageIDLen + 1) and (i < System.Length(FN)) and
         (FN[i - 1] = '-') then
         Result := RemoveStdExt(FileType, False,
           Trim(Copy(FN, i + 1, System.Length(FN) - i)));
      end;
   if Result = '' then
     //not found, using source file name without extension (if standard one)
     Result := RemoveStdExt(FileType, True, ExtractFileName(FileName));
  end;

 for i := 1 to Length(Result) do
   case Result[i] of
     #0..#$1f, '\', '/', '?', '*': Result[i] := '_';
     ':': Result[i] := ';';
     '|': Result[i] := 'l';
     '<': Result[i] := '{';
     '>': Result[i] := '}';
     '"': Result[i] := '''';
    end;

 if (Result = '.') or (Result = '..') then Result := '';

 if Silent then
   if (DirType = dtCustom) and PathBasedFileName then
     //user checked adding orginal path to file name
    begin
     Result := ExtractFilePath(PlaylistItems[n]^.FileName) + Result;
     Result := StringReplace(Result, ':\', '_', [rfReplaceAll]);
     Result := StringReplace(Result, ':/', '_', [rfReplaceAll]);
     Result := StringReplace(Result, '\', '_', [rfReplaceAll]);
     Result := StringReplace(Result, '/', '_', [rfReplaceAll]);
     Result := StringReplace(Result, ':', '_', [rfReplaceAll]);
    end;

 if UTF8Length(Result) > MaxLen then
   //strip result maxpath
   Result := UTF8Copy(Result, 1, MaxLen);

 i := 1;
 body := Result;
 suf := '';
 repeat
   FN := IncludeTrailingPathDelimiter(Dir) + body + suf + Exten;
   //adding path and extention
   if TwoForTS then
    begin
     FN1 := IncludeTrailingPathDelimiter(Dir) + body + suf + '.1' + Exten;
     FN2 := IncludeTrailingPathDelimiter(Dir) + body + suf + '.2' + Exten;
    end
   else
     FN1 := FN;

   if (not FileExists(FN1) and (not TwoForTS or not FileExists(FN2))) or
     (i = MaxInt) then
     //is unique file name or max suffix index riched
     Break;

   //adding ()-suffix to get unique file name
   Inc(i);
   suf := ' (' + IntToStr(i) + ')';
   Len := Length(suf);
   if MaxLen < Len then
     //no room for indexed suffix
     Break;

   if UTF8Length(body) > MaxLen - Len then
     //make room for suffix
     body := UTF8Copy(body, 1, MaxLen - Len);
 until False;

 if Silent then
  begin
   if (FileExists(FN1) or (TwoForTS and FileExists(FN2))) and
     (DirType in [dtCurrent, dtCustom]) then
     //not temp dir, overwriting not allowed
     Exit('')
   else
     Exit(FN);
  end
 else
  begin
   FrmMain.SaveDialog1.FileName := body + suf;
   FrmMain.SaveDialog1.Options := FrmMain.SaveDialog1.Options - [ofOverwritePrompt];
   Result := '';
    try
     while FrmMain.SaveDialog1.Execute do
      begin
       FN := FrmMain.SaveDialog1.FileName;
       if LowerCase(ExtractFileExt(FN)) <> Exten then FN += Exten;
       if TwoForTS then
        begin
         FN1 := GetTSFileName(FN, 1);
         FN2 := GetTSFileName(FN, 2);
         if not FileExists(FN2) then
           FN2 := '';
        end
       else
        begin
         FN1 := FN;
         FN2 := '';
        end;
       if not FileExists(FN1) then
         FN1 := '';
       if (FN1 <> '') or (FN2 <> '') then
        begin
         if (FN1 <> '') and (FN2 <> '') then
           FN2 := '&' + ExtractFileName(FN2);
         if MessageDlg(Mes_File + ' "' + FN1 + FN2 + '" ' + Mes_ExistsOverwrite,
           mtConfirmation, [mbYes, mbNo], 0) = mrNo then
           Continue;
        end;
       Exit(FN);
      end;
    finally
     FrmMain.SaveDialog1.Options := FrmMain.SaveDialog1.Options + [ofOverwritePrompt];
    end;
  end;
end;

function TFrmPLst.GetVarsForSave(PLItem, FType: integer; Silent: boolean;
 const DestDir: string; out Dir: string; out DirType: TDirType;
 out FN: string; out Exten: string; TwoForTS: boolean = False): boolean;
begin
 Exten := LowerCase(GetFNExt(FType, False));

 Dir := GetDirForSave(DirType, PLItem, Silent, DestDir);

 if not Silent then
  begin
   FrmMain.SaveDialog1.DefaultExt := Exten;
   FrmMain.SaveDialog1.Filter := GetFilterString(FType);
   FrmMain.SaveDialog1.InitialDir := Dir;
  end;

 Exten := '.' + Exten;

 FN := GetFileNameForSave(Dir, DirType, PLItem, Silent, Exten, TwoForTS);

 Result := FN <> '';
end;

function TFrmPLst.SaveFile(n: integer; Silent: boolean; out FN: string;
 const DestDir: string = ''): boolean;
const
 FXSM: integer = $4d535846;
var
 FileOut: file;

 function SaveF_(PLItem: PPLaylistItem; PBuf: PModTypes): integer;
 var
   o: integer;
 begin
   if (PLItem^.FileType = FT.ST1) or (PLItem^.FileType = FT.ST3) then
    begin
     Result := PBuf^.ST_Size;
     if Result = 0 then
       Result := 65536;
    end
   else if PLItem^.FileType = FT.STF then
    begin
     Result := PBuf^.STP_SamplesPointer + 30;
     if Result > 65536 then //лишняя проверка, но пусть будет
       Result := 65536;
    end
   else
    begin
     Result := PLItem^.Length;
     if PLItem^.FileType = FT.ASC0 then
       Inc(Result);
    end;

   if (PLItem^.FileType = FT.ASC) or (PLItem^.FileType = FT.ASC0) then
     InsertTitleASC(PBuf^, Result, UTF8ToCP(PLItem^.Comment))
   else if PLItem^.FileType = FT.STP then
     InsertTitleSTP(PBuf^, Result, UTF8ToCP(PLItem^.Comment))
   else if (PLItem^.FileType = FT.STC) or (PLItem^.FileType = FT.ST3) then
     InsertTitleSTC(PBuf^, Result, UTF8ToCP(PLItem^.Comment));
   o := 0;
   if (PLItem^.FileType = FT.FXM) then
    begin
     o := PLItem^.Address and $FFFF;
     if Result + o > 65536 then Result := 65536 - o;
     BlockWrite(FileOut, FXSM, 4);
     BlockWrite(FileOut, o, 2);
    end;
   BlockWrite(FileOut, PBuf^.Index[o], Result);
 end;

var
 Buffer, Buffer2: ModTypes;

 function SaveF: boolean;
 const
   TS: array[0..3] of char = '02TS';
 var
   l1, l2: integer;
   s: string;
 begin
   AssignFile(FileOut, FN);
   Rewrite(FileOut, 1);
   Result := True;
    try
      try
       l1 := SaveF_(PlaylistItems[n], @Buffer);
       if PlaylistItems[n]^.Next <> nil then
        begin
         l2 := SaveF_(PlaylistItems[n]^.Next, @Buffer2);
         s := UpperCase(GetFNExt(PlaylistItems[n]^.FileType, False));
         SetLength(s, 3); //todo безопаснее добить пробелами
         s := s + '!';
         BlockWrite(FileOut, s[1], 4);
         BlockWrite(FileOut, l1, 2);
         s := UpperCase(GetFNExt(PlaylistItems[n]^.Next^.FileType, False));
         SetLength(s, 3);
         s := s + '!';
         BlockWrite(FileOut, s[1], 4);
         BlockWrite(FileOut, l2, 2);
         BlockWrite(FileOut, TS[0], 4);
        end;
      finally
       CloseFile(FileOut);
      end;
    except
     Result := False;
     ShowException(ExceptObject, ExceptAddr);
    end;
 end;

var
 Exten, Dir: string;
 i: integer;
 DirType: TDirType;
begin
 FN := '';
 if (n < 0) or (n >= Length(PlayListItems)) then
   Exit(True);
 if not IsAYNativeFileType(PlaylistItems[n]^.FileType) then
   Exit(True);

 i := PlaylistItems[n]^.FileType;
 if i = FT.ASC0 then
   //todo: ASC0 преобразуется в ASC при загрузке, может сохранять как AS0? Вроде нет особого смысла...
   i := FT.ASC;
 if (i = FT.ST1) or (i = FT.ST3) then
   i := FT.STC;
 if i = FT.STF then
   i := FT.STP;

 if not GetVarsForSave(n, i, Silent, DestDir, Dir, DirType, FN, Exten) then
   //no room for file name or user canceled
   Exit(False);

 if not LoadTrackerModule(Buffer, PlaylistItems[n], n, 0, 0, nil, -1) then
   Exit(False);
 if PlaylistItems[n]^.Next <> nil then
   if not LoadTrackerModule(Buffer2, PlaylistItems[n]^.Next, n, 0, 0, nil, -1) then
     Exit(False);

 Result := SaveF;
end;

procedure TFrmPLst.MenuSaveAsClick(Sender: TObject);
var
 i: integer;
 FN: string;
begin
 i := GetNumberOfSelectedItems;
 if i = 0 then
   Exit;
 if i = 1 then
   for i := 0 to Length(PlaylistItems) - 1 do
     if PlayListItems[i]^.Selected then
      begin
       SaveFile(i, False, FN);
       Exit;
      end;
 SaveToFolder(pwSave, False);
end;

procedure TFrmPLst.MenuOpenInEditorClick(Sender: TObject);
begin
 {$IFDEF Windows}
 OpenInEditor;
 {$ELSE Windows}
 NonWin;
 {$ENDIF Windows}
end;

procedure TFrmPLst.FormDropFiles(Sender: TObject; const FileNames: array of string);
var
 nFiles, i: integer;
begin
 if LongProcess > 0 then
   //conversion, searching, etc is in progress
   Exit;

 LongProcessPrepare;
 May_Quit2 := False;
  try
   nFiles := Length(FileNames);
   for i := 0 to nFiles - 1 do
    begin
     if not DirectoryExists(FileNames[i]) then
       Add_File(FileNames[i], True, 0)
     else
       FrmPLst.SearchFilesInFolder(FileNames[i], True, True, 0);
     Application.ProcessMessages;
     if May_Quit then
       Break;
    end;
   if Add_File_Errors <> '' then
    begin
     ShowMessage(Add_File_Errors);
     Add_File_Errors := '';
    end;
  finally
   LongProcessDone;
   CalculateTotalTime(False);
   CreatePlayOrder;
  end;
 if CanSetFocus then
   //temporary given focus to main window to poll user input
   SetFocus;
end;

procedure TFrmPLst.SearchFilesInFolder(Dir: string; Recurse, Detect: boolean;
 Playlists: integer);
var
 SearchRec: TSearchRec;
 i: integer;
 s: string;
begin
 Dir := IncludeTrailingBackslash(Dir);
 if not DirectoryExists(Dir) then
   Exit;
 i := FindFirst(Dir + '*', faAnyFile, SearchRec);
 LongProcessPrepare(False);
  try
   while not May_Quit and (i = 0) do
    begin
     if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
       if SearchRec.Attr and faDirectory <> 0 then
        begin
         if Recurse then
          begin
           s := Dir + SearchRec.Name;
           {$IFDEF Windows}
           if not DirectoryExists(s) then
             s := Dir + UTF8Encode(WideString(SearchRec.FindData.cAlternateFileName));
           {$ENDIF Windows}
           SearchFilesInFolder(s,Recurse, Detect, Playlists);
          end;
        end
       else if SearchRec.Size > 0 then
        begin
         s := Dir + SearchRec.Name;
         {$IFDEF Windows}
         if not FileExists(s) then
           s := Dir + UTF8Encode(WideString(SearchRec.FindData.cAlternateFileName));
         {$ENDIF Windows}
         Add_File(s, Detect, Playlists);
        end;
     i := FindNext(SearchRec);
     Application.ProcessMessages;
    end;
  finally
   FindClose(SearchRec);
   LongProcessDone;
  end;
end;

procedure TFrmPLst.Add_Directory_Dialog(Add: boolean);
var
 s3, s4: string;
begin
 s3 := Mes_OpenFilesFromFolder;
 if AutoSaveDefDir and DirectoryExists(FrmMain.DefaultDirectory) then
   s4 := FrmMain.DefaultDirectory
 else
   s4 := FrmMain.OpenDialog1.InitialDir;
 if ChooseDirectory(s4, s3, [cdoRecurse, cdoDetect, cdoPlaylists]) then
  begin
   LongProcessPrepare;
   FrmMain.OpenDialog1.InitialDir := s4;
   if AutoSaveDefDir then
     FrmMain.DefaultDirectory := s4;
    try
     if not Add then
      begin
       StopAndFreeAll;
       ClearPlayList;
      end;
     May_Quit2 := False;
     SearchFilesInFolder(s4,AddFolderRecurseDirs, AddFolderDoDetect,
       AddFolderPlaylists);
     if Add_File_Errors <> '' then
      begin
       ShowMessage(Add_File_Errors);
       Add_File_Errors := '';
      end;
     CalculateTotalTime(False);
    finally
     CreatePlayOrder;
     RedrawPlaylist(0, True);
     LongProcessDone;
    end;
   if not Add then PlayItem(0, pwPlay);
  end;
end;

function TimeSToStr(ms: integer): string;
begin
 SetLength(Result{%H-}, 4);
 Result[4] := char(ms mod 10 + 48);
 ms := ms div 10;
 Result[3] := char(ms mod 6 + 48);
 ms := ms div 6;
 Result[2] := ':';
 Result[1] := char(ms mod 10 + 48);
 ms := ms div 10;
 if ms = 0 then exit;
 Result := char(ms mod 6 + 48) + Result;
 ms := ms div 6;
 if ms = 0 then exit;
 Result := IntToStr(ms) + ':' + Result;
end;

function GetPlayListTime(PLItem: PPLayListItem; var Time0: integer): integer;
var
 i: integer;
begin
 with PLItem^ do
  begin
   Result := 0;
   Time0 := Time;
   if (Next <> nil) and (Next^.Time > Time0) then Time0 := Next^.Time;
   if Time0 = 0 then exit;
   if IsTimeMSFileType(FileType) then
     Result := round(Time0 / 1000)
   else if IsZ80EmuFileType(FileType) then
     Result := round(Time0 / FrqZ80 * MaxTStates)
   else if IsCDFileType(FileType) then
     Result := round(Time0 / 75)
   else
    begin
     if (not FrmMixer.CBIntFrqLst.Checked) or ((Int_Freq < 0) and
       (PLDef_Player_Frq < 0)) then
       i := FrmMixer.FrqPlTemp
     else if Int_Freq >= 0 then
       i := Int_Freq
     else
       i := PLDef_Player_Frq;
     Result := round(Time0 / i * 1000);
    end;
  end;
end;

function GetPlayListTimeStr(PLItem: PPLayListItem): string;
var
 i, Time: integer;
begin
 Time := GetPlayListTime(PLItem, i);
 if i > 0 then
   Result := TimeSToStr(Time)
 else
   Result := '';
end;

function GetPlayListFileType(PLItem: PPLayListItem): string;
begin
 Result := GetFileType(PLItem^.FileType);
 if PLItem^.Next = nil then
  begin
   if (PLItem^.FileType = FT.PT3) and (PLItem^.FormatSpec = 0) then
     Result := Result + 'TS';
   exit;
  end;
 if PLItem^.FileType = PLItem^.Next^.FileType then
   Result := Result + 'x2'
 else
   Result := Result + '+' + GetFileType(PLItem^.Next^.FileType);
end;

function FormatScrollString(const Author, Title, FileNameFull: string;
 FileType: Available_Types): string;
var
 FileName: string;
begin
 if (Author <> '') and (Title <> '') then
   Result := Author + ' - ' + Title
 else if Author <> '' then
   Result := Author
 else if Title <> '' then
   Result := Title
 else
  begin
   FileName := RemoveStdExt(FileType, False, ExtractFileName(FileNameFull));
   if FileName <> '' then
     Result := FileName
   else
     Result := FileNameFull;
  end;
end;

function GetPlayListString(PLItem: PPLayListItem): string;
var
 Err: ErrorCodes;
 A, T: string;
begin
 with PLItem^ do
  begin
   Err := Error;
   if (Next <> nil) and (Err = FileNoError) then
     Err := Next^.Error;
   if Err = FileNoError then
    begin
     A := Author;
     T := Title;
     if Next <> nil then
      begin
       if A = '' then
         A := Next^.Author;
       if T = '' then
         T := Next^.Title;
      end;
     Result := FormatScrollString(A, T, FileName, FileType);
    end
   else if (Err <> ErBASSError) or (BASSErrorString = '') then
     Result := ExtractFileName(FileName) + ' (' + Errors[Err] + ')'
   else
     Result := ExtractFileName(FileName) + ' (' + BASSErrorString + ')';
  end;
end;

procedure RedrawItemRealy(i, n: integer);
var
 t, s: string;
 Client: TRect;
 BkColor, TxtColor: TColor;
 tw: integer;
 Err: ErrorCodes;
begin
 with PlayListItems[n]^ do
  begin
   Err := Error;
   if (Next <> nil) and (Err = FileNoError) then
     Err := Next^.Error;
   if Selected then
    begin
     BkColor := PLColorBkSel;
     if Err = FileNoError then
      begin
       if PlayingItem = n then
         TxtColor := PLColorPlSel
       else
         TxtColor := PLColorSel;
      end
     else
       TxtColor := PLColorErrSel;
    end
   else
    begin
     if PlayingItem = n then
       BkColor := PLColorBkPl
     else
       BkColor := PLColorBk;
     if Err = FileNoError then
      begin
       if PlayingItem = n then
         TxtColor := PLColorPl
       else
         TxtColor := PLColor;
      end
     else
       TxtColor := PLColorErr;
    end;
   PLArea.Canvas.Font.Color := TxtColor;
   PLArea.Canvas.Brush.Color := BkColor;

   s := GetPlayListString(PlayListItems[n]);
   if Err = FileNoError then
    begin
     t := GetPlayListTimeStr(PlayListItems[n]);
     if t = '' then
      begin
       if not FileIsURL(FileName) then
         NeedGetTime(n); //add to queue
       t := GetPlayListFileType(PlayListItems[n]);
      end
     else
       t := GetPlayListFileType(PlayListItems[n]) + ' ' + t;
     tw := PLArea.Canvas.TextWidth(t);
    end
   else
     tw := 0;
   CheckStringFitting(PLArea.Canvas.Handle, s, PLArea.ClientWidth - tw - 4);
   Client.Left := 0;
   Client.Top := i * ListLineHeight;
   Client.Right := PLArea.ClientWidth - tw;
   Client.Bottom := (i + 1) * ListLineHeight;
   PLArea.Canvas.TextRect(Client, Client.Left, Client.Top, s);
   if Err = FileNoError then
    begin
     Client.Left := Client.Right;
     Client.Right := PLArea.ClientWidth;
     PLArea.Canvas.TextRect(Client, Client.Left, Client.Top, t);
    end;
  end;
end;

procedure RedrawItem(n: integer);
begin
 if DisablePLRedraw then
   Exit;
 if (n < ShownFrom) or (n >= ShownFrom + PLArea.ClientHeight div ListLineHeight) then
   Exit;
 if not FrmPLst.Visible then
   Exit;
 RedrawItemRealy(n - ShownFrom, n);
end;

procedure RedrawPlaylist(From: integer; OnlyItems: boolean);
var
 i, n, na, nmax: integer;
 Client: TRect;
begin
 ShownFrom := From;
 if DisablePLRedraw then
   Exit;
 if not FrmPLst.Visible then
   Exit;
 na := Length(PlayListItems);
 if na <> 0 then
  begin
   nmax := PLArea.ClientHeight div ListLineHeight;
   n := na - From;
   if n > nmax then
     n := nmax
   else if n < nmax then
    begin
     Dec(From, nmax - n);
     n := nmax;
     if From < 0 then
      begin
       Inc(n, From);
       From := 0;
      end;
     ShownFrom := From;
    end;
   for i := 0 to n - 1 do
     RedrawItemRealy(i, i + From);
   if not OnlyItems then
    begin
     Client.Left := 0;
     Client.Top := n * ListLineHeight;
     Client.Right := PLArea.ClientWidth;
     Client.Bottom := PLArea.ClientHeight;
     PLArea.Canvas.Brush.Color := PLColorBk;
     PLArea.Canvas.FillRect(Client);
    end;
  end
 else if not OnlyItems then
  begin
   PLArea.Canvas.Brush.Color := PLColorBk;
   PLArea.Canvas.FillRect(PLArea.ClientRect);
  end;
 CalculatePlaylistScrollBar;
end;

procedure FillDefPlayListItem(var PLItem: TPlayListItem);
begin
 with PLItem do
  begin
   Author := '';
   Title := '';
   Programm := '';
   Tracker := '';
   Comment := '';
   Computer := '';
   Date := '';
   FileName := '';
   Offset := 0;
   Length := -1;
   Address := 0;
   Loop := -1;
   Time := 0;
   UnpackedSize := 0;
   FileType := -1;
   UnpackedSize := 0;
   Loop := -1;
   Ay_Freq := -1;
   Int_Freq := -1;
   Channel_Mode := -1;
   Chip_Type := No_Chip;
   Number_Of_Channels := 0;
   Time := 0;
   Error := FileNoError;
   FormatSpec := -1;
   Selected := False;
   Next := nil;
  end;
end;

function AddPlayListItem(var PLItem: PPlayListItem): integer;
begin
 New(PLItem);
 FillDefPlayListItem(PLItem^);
 Result := Length(PlayListItems);
 SetLength(PlayListItems, Result + 1);
 PlayListItems[Result] := PLItem;
 FrmPLst.RedrawItemsLabel;
end;

procedure TPlayList.PlayListPaint(Sender: TObject);
begin
 RedrawPlaylist(ShownFrom, False);
end;

constructor TPlayList.Create(AOwner: TComponent);
var
 TS: TTextStyle;
begin
 inherited Create(AOwner);
 Parent := TWinControl(AOwner);
 ControlStyle := [csClickEvents, csDoubleClicks, csCaptureMouse];
 TabStop := True;
 //  FrmPLst.SetFocusedControl(Self); //LCL 0.9.27 b18700
 ParentColor := False;
 BevelInner := bvLowered;
 Align := alClient;
 ShownFrom := 0;
 Color := clNone;
 TS := Canvas.TextStyle;
 TS.Clipping := True;
 TS.Opaque := True;
 Canvas.TextStyle := TS;
 PopupMenu := FrmPLst.PopupMenu1;
 OnMouseDown := @PLAreaMouseDown;
 OnMouseUp := @PLAreaMouseUp;
 OnMouseMove := @PLAreaMouseMove;
 OnMouseWheelDown := @PLAreaMouseWheelDown;
 OnMouseWheelUp := @PLAreaMouseWheelUp;
 OnDblClick := @PLAreaDblClick;
 OnKeyDown := @PLAreaKeyDown;
 OnKeyUp := @PLAreaKeyUp;
 OnPaint := @PlayListPaint;
end;

procedure TFrmPLst.FormCreate(Sender: TObject);
begin
 //default playlist colors
 PLColorBkSel := GetSysColor(COLOR_HIGHLIGHT);
 PLColorBkPl := GetSysColor(COLOR_WINDOW) - $100D10;
 if integer(PLColorBkPl) < 0 then PLColorBkPl := 0;
 PLColorBk := GetSysColor(COLOR_WINDOW);

 PLColorPlSel := $FF80FF;
 PLColorPl := $0DA00D;

 PLColorSel := GetSysColor(COLOR_HIGHLIGHTTEXT);
 PLColor := GetSysColor(COLOR_WINDOWTEXT);

 PLColorErrSel := $FFFF00;
 PLColorErr := $FF;

 ClearParams;
 FrmPLst.SetDirection(1);
 PLArea := TPlayList.Create(FrmPLst);

end;

procedure ClearSelection;
var
 i: integer;
begin
 LastSelected := -1;
 for i := 0 to Length(PlayListItems) - 1 do
   with PlayListItems[i]^ do
     if Selected then
      begin
       Selected := False;
       RedrawItem(i);
      end;
end;

procedure TPlayList.PLAreaMouseDown(Sender: TObject; Button: TMouseButton;
 Shift: TShiftState; X, Y: integer);
var
 i, n, sfr, sto: integer;
begin
 i := PLArea.ClientHeight div ListLineHeight;
 n := Y div ListLineHeight;
 if Button = mbLeft then
  begin
   IsClicked := True;
   if (Y >= 0) and (n < i) then
    begin
     Inc(n, ShownFrom);
     if n < Length(PlayListItems) then
      begin
       if not (ssCtrl in Shift) then
         for i := 0 to Length(PlayListItems) - 1 do
           with PlayListItems[i]^ do
             if Selected and (i <> n) then
              begin
               Selected := False;
               RedrawItem(i);
              end;
       if not (ssShift in Shift) or (LastSelected = -1) then
        begin
         LastSelected := n;
         if not PlaylistItems[n]^.Selected then
          begin
           PlaylistItems[n]^.Selected := True;
           RedrawItem(n);
          end
         else if ssCtrl in Shift then
          begin
           PlaylistItems[n]^.Selected := False;
           RedrawItem(n);
          end;
        end
       else
        begin
         if LastSelected > n then
          begin
           sfr := n;
           sto := LastSelected;
          end
         else
          begin
           sfr := LastSelected;
           sto := n;
          end;
         for i := sfr to sto do
           with PlayListItems[i]^ do
             if not Selected then
              begin
               Selected := True;
               RedrawItem(i);
              end;
        end;
      end
     else
       ClearSelection;
    end
   else
     ClearSelection;
  end
 else if Button = mbRight then
   if (Y >= 0) and (n < i) then
    begin
     Inc(n, ShownFrom);
     if n < Length(PlayListItems) then
      begin
       if not PlaylistItems[n]^.Selected then
        begin
         ClearSelection;
         PlaylistItems[n]^.Selected := True;
         RedrawItem(n);
        end;
       LastSelected := n;
      end;
    end;
end;

procedure Do_LineDown;
begin
 if ShownFrom < Length(PlayListItems) - PLArea.ClientHeight div ListLineHeight then
   RedrawPlaylist(ShownFrom + 1, True);
end;

procedure Do_LineUp;
begin
 if ShownFrom > 0 then
   RedrawPlaylist(ShownFrom - 1, True);
end;

procedure TPlayList.PLAreaMouseWheelDown(Sender: TObject; Shift: TShiftState;
 MousePos: TPoint; var Handled: boolean);
begin
 Handled := True;
 Do_LineDown;
end;

procedure TPlayList.PLAreaMouseWheelUp(Sender: TObject; Shift: TShiftState;
 MousePos: TPoint; var Handled: boolean);
begin
 Handled := True;
 Do_LineUp;
end;

procedure TPlayList.PLAreaDblClick(Sender: TObject);
begin
 if (GetKeyState(VK_SHIFT) and 128 <> 0) or (GetKeyState(VK_CONTROL) and 128 <> 0) then
   exit;
 if LastSelected < 0 then exit;
 PlayItem(PlayListItems[LastSelected]^.Tag, pwPlay);
 if Direction = 2 then CreatePlayOrder;
end;

procedure TFrmPLst.SBAddClick(Sender: TObject);
begin
 if GetKeyState(VK_SHIFT) and 128 <> 0 then
   Add_Directory_Dialog(True)
 {$IFDEF Windows}
 else if GetKeyState(VK_CONTROL) and 128 <> 0 then
   Add_CD_Dialog(True)
 {$ENDIF Windows}
 else
   Add_Item_Dialog(True);
 if CanSetFocus then
   //return focus to playlist window (lost due main window focused
   //to poll user input for abort process)
   SetFocus;
end;

procedure TFrmPLst.SBClearClick(Sender: TObject);
begin
 ClearPlayList;
end;

procedure TFrmPLst.SBSaveClick(Sender: TObject);
var
 i: integer;
 m3uf: TextFile;
 FName: string;
begin
 FrmMain.SaveDialog1.InitialDir := FrmMain.OpenDialog1.InitialDir;
 FrmMain.SaveDialog1.FileName := '';
 FrmMain.SaveDialog1.DefaultExt := '';
 FrmMain.SaveDialog1.Filter :=
   GetFilterString(GetFileType('AYL')) + '|' + GetFilterString(GetFileType('M3U'));
 FrmMain.SaveDialog1.FilterIndex := 1;
 if FrmMain.SaveDialog1.Execute then
  begin
   FName := LowerCase(ExtractFileExt(FrmMain.SaveDialog1.FileName));
   if FrmMain.SaveDialog1.FilterIndex = 2 then
    begin
     if FName <> '.m3u' then
       FName := FrmMain.SaveDialog1.FileName + '.m3u'
     else
       FName := FrmMain.SaveDialog1.FileName;
     AssignFile(m3uf, FName);
     Rewrite(m3uf);
      try
       for i := 0 to Length(PlaylistItems) - 1 do
         Writeln(m3uf, PlayListItems[i]^.FileName);
      finally
       CloseFile(m3uf);
      end;
    end
   else
    begin
     if FName <> '.ayl' then
       FName := FrmMain.SaveDialog1.FileName + '.ayl'
     else
       FName := FrmMain.SaveDialog1.FileName;
     SaveAYL(FName);
    end;
  end;
end;

procedure TryGetTime(n: integer);
var
 FileHandleTime: integer;
begin
 with PlayListItems[n]^ do
   if (Error = FileNoError) and
     ((Time = 0) or ((Next <> nil) and (Next^.Time = 0))) then
    begin
     if not IsStreamOrModuleFileType(FileType) and not IsCDFileType(FileType) then
       UniReadInit(FileHandleTime, URFile, FileName, nil, -1);
      try
       if Time = 0 then
         GetTime(FileHandleTime, PlayListItems[n], n, nil, Loop);
       if (Next <> nil) and (Next^.Time = 0) then
         GetTime(FileHandleTime, PlaylistItems[n]^.Next, n, nil, Loop);
      except
       on EBASSError do Error := ErBASSError;
       on EFileStructureError do Error := ErBadFileStructure
       else
         Error := ErReadingFile;
      end;
     if not IsStreamOrModuleFileType(FileType) and not IsCDFileType(FileType) then
       UniReadClose(FileHandleTime);
     if (Error <> FileNoError) or (Time <> 0) then
      begin
       RedrawItem(n);
       Dec(n, Item_Displayed);
       if (n >= -1) and (n <= 1) then
         ReprepareScroll;
      end;
    end;
end;

procedure NeedGetTime(n: integer);
begin
 with PlayListItems[n]^ do
   if ((Time <= 0) or ((Next <> nil) and (Next^.Time <= 0))) and
     (GetTimeQueue.IndexOf({%H-}Pointer(n)) < 0) then
     //don't add twice or if already got time
     GetTimeQueue.Add({%H-}Pointer(n));
end;

procedure PollGetTimeRequest;
begin
 if GetTimeQueue.Count = 0 then
   Exit;
 TryGetTime({%H-}PtrInt(GetTimeQueue.First));
 GetTimeQueue.Remove(GetTimeQueue.First);
end;

procedure DeletePlayListItem(n: integer);
var
 i, c: integer;
begin
 if n < 0 then exit;
 c := Length(PlayListItems) - 1;
 if n > c then exit;
 if PlaylistItems[n]^.Next <> nil then Dispose(PlaylistItems[n]^.Next);
 Dispose(PlayListItems[n]);
 for i := n + 1 to c do
   PlayListItems[i - 1] := PlayListItems[i];
 SetLength(PlayListItems, c);
 FrmPLst.RedrawItemsLabel;
end;

procedure DeletePlayListItemAndReprepare(Index: integer);
begin
 if (Scroll_Distination <> Item_Displayed) and (Index = Scroll_Distination) then
   ForceScrollForDelete;
 if Index < PlayingItem then
  begin
   Dec(PlayingItem);
   FrmPLst.RedrawItemsLabel;
  end
 else if Index = PlayingItem then
  begin
   PlayingItem := -1;
   FrmPLst.RedrawItemsLabel;
  end;
 if Index < Scroll_Distination then
   Dec(Scroll_Distination)
 else if Index = Scroll_Distination then
   Scroll_Distination := -1;
 if Index < Item_Displayed then
   Dec(Item_Displayed)
 else if Index = Item_Displayed then
   Item_Displayed := -1;
 DeletePlayListItem(Index);
 ReprepareScroll;
end;

procedure TPlayList.PLAreaKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
var
 LS, Index, n: integer;

 procedure CheckVis;
 begin
   LastSelected := Index;
   if not (ssCtrl in Shift) then PlayListItems[Index]^.Selected := True;
   MakeVisible(Index, False);
 end;

 function CheckClr: boolean;
 begin
   Result := not (ssShift in Shift) and not (ssCtrl in Shift);
 end;

 procedure Do_Home;
 var
   i: integer;
 begin
   if Length(PlayListItems) <> 0 then
    begin
     if CheckClr or (LastSelected = -1) then
      begin
       ClearSelection;
       PlayListItems[0]^.Selected := True;
      end
     else if not (ssCtrl in Shift) then
       for i := 0 to LastSelected do
         PlayListItems[i]^.Selected := True;
     LastSelected := 0;
     RedrawPlayList(0, True);
    end;
 end;

 procedure Do_End;
 var
   i: integer;
 begin
   if Length(PlayListItems) <> 0 then
    begin
     if CheckClr or (LastSelected = -1) then
      begin
       ClearSelection;
       PlayListItems[Length(PlayListItems) - 1]^.Selected := True;
      end
     else if not (ssCtrl in Shift) then
       for i := LastSelected to Length(PlayListItems) - 1 do
         PlayListItems[i]^.Selected := True;
     LastSelected := Length(PlayListItems) - 1;
     RedrawPlayList(LastSelected, True);
    end;
 end;

begin

 if LongProcess > 0 then
   //conversion, searching, etc is in progress
  begin
   DoCheckQuitKey(Key);
   if Key = 0 then
     Exit;
  end;

 case Key of
   VK_DELETE:
     if Length(PlayListItems) <> 0 then
      begin
       LS := LastSelected;
        try
         for Index := Length(PlayListItems) - 1 downto 0 do
           if PlayListItems[Index]^.Selected then
             DeletePlayListItemAndReprepare(Index);
         if LS >= Length(PlayListItems) then LS := Length(PlayListItems) - 1;
         LastSelected := LS;
         if LS >= 0 then PlayListItems[LS]^.Selected := True;
        finally
         RedrawPlaylist(ShownFrom, False);
         CreatePlayOrder;
         CalculateTotalTime(False);
        end;
      end;
   VK_DOWN:
     if Length(PlayListItems) <> 0 then
      begin
       Index := LastSelected + 1;
       LastSelected := -1;
       if CheckClr then ClearSelection;
       if Index < Length(PlayListItems) then CheckVis;
      end;
   VK_UP:
     if Length(PlayListItems) <> 0 then
      begin
       Index := LastSelected - 1;
       LastSelected := -1;
       if CheckClr then ClearSelection;
       if Index = -2 then Index := Length(PlayListItems) - 1;
       if Index >= 0 then CheckVis;
      end;
   VK_HOME:
     Do_Home;
   VK_END:
     Do_End;
   VK_PRIOR:
     if ssCtrl in Shift then
       Do_Home
     else if Length(PlayListItems) <> 0 then
      begin
       if (LastSelected = ShownFrom) and (ShownFrom <> 0) then
        begin
         Dec(ShownFrom, PLArea.ClientHeight div ListLineHeight);
         if ShownFrom < 0 then ShownFrom := 0;
        end;
       if CheckClr then
        begin
         ClearSelection;
         PlayListItems[ShownFrom]^.Selected := True;
        end
       else
         for Index := 0 to LastSelected do
           PlayListItems[Index]^.Selected := True;
       LastSelected := ShownFrom;
       RedrawPlaylist(ShownFrom, True);
      end;
   VK_NEXT:
     if ssCtrl in Shift then
       Do_End
     else if Length(PlayListItems) <> 0 then
      begin
       n := PLArea.ClientHeight div ListLineHeight;
       if (LastSelected = ShownFrom + n - 1) and
         (ShownFrom <> Length(PlayListItems) - 1) then
        begin
         Inc(ShownFrom, n);
         if ShownFrom >= Length(PlayListItems) then
           ShownFrom := Length(PlayListItems) - 1;
        end;
       LS := ShownFrom + n - 1;
       if LS >= Length(PlayListItems) then
         LS := Length(PlayListItems) - 1;
       if CheckClr then
        begin
         ClearSelection;
         PlayListItems[LS]^.Selected := True;
        end
       else
         for Index := LastSelected to LS do
           PlayListItems[Index]^.Selected := True;
       LastSelected := LS;
       RedrawPlaylist(ShownFrom, True);
      end;
   VK_SPACE:
     if (LastSelected >= 0) and (LastSelected < Length(PlayListItems)) then
      begin
       PlayListItems[LastSelected]^.Selected :=
         not PlayListItems[LastSelected]^.Selected;
       RedrawItem(LastSelected);
      end;
   VK_INSERT:
     FrmPLst.SBAddClick(Sender);
   VK_RETURN:
     PLAreaDblClick(Sender);
   Ord('A'):
     if (Length(PlayListItems) <> 0) and (ssCtrl in Shift) then
      begin
       for Index := 0 to Length(PlayListItems) - 1 do
         PlayListItems[Index]^.Selected := True;
       RedrawPlaylist(ShownFrom, True);
      end;
   VK_ESCAPE:
     FrmPLst.Visible := False;
   VK_F7:
     FrmPLst.Finditem1Click(Sender);
 else
  begin
   FrmMain.OnKeyDown(Sender, Key, Shift);
   Exit;
  end;
  end;
 Key := 0;
end;

procedure TPlayList.PLAreaKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
begin
 FrmMain.OnKeyUp(Sender, Key, Shift);
end;

function CalculateTotalTime(Force: boolean): boolean;
var
 i, t, l, tmp: integer;
 s: string;
begin
 Result := False;
 if not FrmPLst.LTotTime.Enabled then
   Exit;
 if Force then
  begin
   FrmPLst.LTotTime.Enabled := False;
   LongProcessPrepare(False);
  end;
 t := 0;
 Result := True;
  try
   l := Length(PlaylistItems);
   for i := 0 to l - 1 do
     with PlayListItems[i]^ do
      begin
       if Force then
         TryGetTime(i);
       if Time > 0 then
         Inc(t, GetPlayListTime(PlaylistItems[i], tmp))
       else if Error = FileNoError then
         Result := False;
       if Force then
        begin
         Application.ProcessMessages;
         if May_Quit or (l <> System.Length(PlaylistItems)) then
           //user canceled or new items appeared during calc?
          begin
           Result := False;
           Break;
          end;
        end;
      end;
   s := TimeSToStr(t);
   if not Result then
    begin
     s := s + '+';
     FrmPLst.LTotTime.Cursor := crHandPoint;
    end
   else
     FrmPLst.LTotTime.Cursor := crDefault;
   FrmPLst.LTotTime.Caption := s;
  finally
   if Force then
    begin
     FrmPLst.LTotTime.Enabled := True;
     LongProcessDone;
    end;
  end;
end;

procedure TFrmPLst.LTotTimeMouseDown(Sender: TObject; Button: TMouseButton;
 Shift: TShiftState; X, Y: integer);
begin
 CalculateTotalTime(True);
end;

procedure CalculatePlaylistScrollBar;
var
 l, p, max, page, pos: integer;
begin
 l := Length(PlayListItems);
 if l = 0 then
  begin
   max := 0;
   page := 1;
   pos := 0;
  end
 else
  begin
   p := PLArea.ClientHeight div ListLineHeight;
   if l < p then l := p;
   max := l - 1;
   {$IFNDEF Windows}
   //todo: issue in LCL-bugtracker (min,max,position,pagesize - поведение отличается в Win32 и Gtk2)
//   dec(max,p-1); //mask LCL error (seems fixed)
   Inc(max); //mask LCL error (new issue)
   {$ENDIF Windows}
   page := p;
   pos := ShownFrom;
  end;
 FrmPLst.ScBPLItems.SetParams(pos, 0, max, page);
end;

procedure TFrmPLst.PopupMenu1Popup(Sender: TObject);
var
 i, Count: integer;
begin
 MenuItemAdjusting.Enabled := False;
 MenuConvert.Enabled := False;
 MenuSaveAs.Enabled := False;
 MenuOpenInEditor.Enabled := False;

 if (LastSelected < 0) or (LastSelected >= Length(PlayListItems)) then
   Exit;

 Count := 0;
 for i := 0 to Length(PlayListItems) - 1 do
   if PlayListItems[i]^.Selected then
     Inc(Count);

 if Count = 0 then
   Exit;

 //ensure that LastSelected contains correct value
 if not PlayListItems[LastSelected]^.Selected then
   for i := 0 to Length(PlayListItems) - 1 do
     if PlayListItems[i]^.Selected then
      begin
       LastSelected := i;
       Break;
      end;

 MenuItemAdjusting.Enabled := True;

 if Count > 1 then
   //multiselection, enable all menu items, check inside of handler
  begin
   MenuConvert.Enabled := True;
   MenuWAV.Enabled := True;
   MenuMP3.Enabled := True;
   MenuZXAY.Enabled := True;
   MenuVTX.Enabled := True;
   MenuYM6.Enabled := True;
   MenuPSG.Enabled := True;
   MenuSaveAs.Enabled := True;
   MenuOpenInEditor.Enabled := True;
  end
 else
   //selected single item, disable specific for its type
  begin
   if not IsStreamOrModuleFileType(PlayListItems[LastSelected]^.FileType) and
     not IsCDFileType(PlayListItems[LastSelected]^.FileType) and
     not IsMIDIFileType(PlayListItems[LastSelected]^.FileType) then
    begin
     MenuConvert.Enabled := True;
     MenuWAV.Enabled := True;
     MenuMP3.Enabled := True;
     MenuZXAY.Enabled := False;
     MenuVTX.Enabled := True;
     MenuYM6.Enabled := True;
     MenuPSG.Enabled := True;
     if PlayListItems[LastSelected]^.FileType = FT.VTX then
       MenuVTX.Enabled := False
     else if (PlayListItems[LastSelected]^.FileType = FT.YM5) or
       (PlayListItems[LastSelected]^.FileType = FT.YM6) then
       MenuYM6.Enabled := False
     else if PlayListItems[LastSelected]^.FileType = FT.PSG then
       MenuPSG.Enabled := False
     else if (PlayListItems[LastSelected]^.FileType = FT.OUT) or
       (PlayListItems[LastSelected]^.FileType = FT.EPSG) or
       (PlayListItems[LastSelected]^.FileType = FT.AY) or
       (PlayListItems[LastSelected]^.FileType = FT.AYM) then
       MenuZXAY.Enabled := True
     else if IsAYNativeFileType(PlayListItems[LastSelected]^.FileType) then
      begin
       MenuSaveAs.Enabled := True;
       MenuOpenInEditor.Enabled := True;
      end;
    end;
  end;
end;

procedure TFrmPLst.SetDirection(Dir: integer);
var
 Bmp: TBitmap;
begin
 if Direction = Dir then exit;
 Direction := Dir;
 Bmp := TBitmap.Create;
 ImageList1.GetBitmap(Dir, Bmp);
 SBDirection.Glyph := Bmp;
 Bmp.Free;
end;

procedure TFrmPLst.SBLoopClick(Sender: TObject);
begin
 ListLooped := SBLoop.Down;
end;

procedure TFrmPLst.SBDirectionClick(Sender: TObject);
var
 Dir: integer;
begin
 Dir := (Direction + 1) and 3;
 SetDirection(Dir);
 CreatePlayOrder;
end;

procedure TFrmPLst.FormActivate(Sender: TObject);
begin
 IsClicked := False;
end;

procedure TFrmPLst.RandomSortClick(Sender: TObject);
var
 i, i1, i2: integer;
 PLI: pointer;
begin
 if Length(PlaylistItems) < 2 then exit;
  try
   for i := 0 to Length(PlaylistItems) - 1 do
     PlayListItems[i]^.Tag := 0;
   i := Length(PlaylistItems) div 2;
   while i > 0 do
    begin
     repeat
       i1 := Random(Length(PlaylistItems));
     until PlaylistItems[i1]^.Tag = 0;
     PlaylistItems[i1]^.Tag := 1;
     repeat
       i2 := Random(Length(PlaylistItems));
     until PlaylistItems[i2]^.Tag = 0;
     PlaylistItems[i2]^.Tag := 1;
     if PlayingItem = i1 then
       PlayingItem := i2
     else if PlayingItem = i2 then
       PlayingItem := i1;
     if Item_Displayed = i1 then
       Item_Displayed := i2
     else if Item_Displayed = i2 then
       Item_Displayed := i1;
     if Scroll_Distination = i1 then
       Scroll_Distination := i2
     else if Scroll_Distination = i2 then
       Scroll_Distination := i1;
     PLI := PlaylistItems[i1];
     PlaylistItems[i1] := PlaylistItems[i2];
     PlaylistItems[i2] := PLI;
     Dec(i);
    end;
   ReprepareScroll;
  finally
   CreatePlayOrder;
   RedrawItemsLabel;
   RedrawPlaylist(0, True);
  end;
end;

procedure TFrmPLst.SBToolsClick(Sender: TObject);
var
 Pt: TPoint;
begin
 Pt.x := SBTools.Width;
 Pt.y := 0;
 Pt := SBTools.ClientToScreen(Pt);
 PopupMenu2.Popup(Pt.x, Pt.y);
end;

function AllErrored: boolean;
var
 i: integer;
begin
 Result := False;
 for i := 0 to Length(PlaylistItems) - 1 do
   if PlayListItems[i]^.Error = FileNoError then exit;
 Result := True;
end;

procedure MyQuickSort(Compare: TMyCompare);

 procedure QuickSort(L, R: integer);
 var
   I, J, P: integer;
   N: pointer;
 begin
   repeat
     I := L;
     J := R;
     P := (L + R) shr 1;
     repeat
       while Compare(I, P) < 0 do Inc(I);
       while Compare(J, P) > 0 do Dec(J);
       if I <= J then
        begin
         N := PlaylistItems[J];
         PlaylistItems[J] := PlaylistItems[I];
         PlaylistItems[I] := N;
         if P = I then
           P := J
         else if P = J then
           P := I;
         Inc(I);
         Dec(J);
        end;
     until I > J;
     if L < J then QuickSort(L, J);
     L := I;
   until I >= R;
 end;

var
 temp, i: integer;
 PI, ID, SD: pointer;
begin
 temp := Length(PlaylistItems) - 1;
 if temp > 0 then
  begin
   PI := PlaylistItems[PlayingItem];
   ID := PlaylistItems[Item_Displayed];
   SD := PlaylistItems[Scroll_Distination];
    try
     QuickSort(0, temp);
     for i := 0 to temp do
       if PlaylistItems[i] = PI then
        begin
         PlayingItem := i;
         break;
        end;
     for i := 0 to temp do
       if PlaylistItems[i] = ID then
        begin
         Item_Displayed := i;
         break;
        end;
     for i := 0 to temp do
       if PlaylistItems[i] = SD then
        begin
         Scroll_Distination := i;
         break;
        end;
     ReprepareScroll;
    finally
     CreatePlayOrder;
     FrmPLst.RedrawItemsLabel;
     RedrawPlaylist(0, True);
    end;
  end;
end;

function CompareFileNames(Index1, Index2: integer): integer;
begin
 Result := UTF8CompareText(PlaylistItems[Index1]^.FileName,
   PlaylistItems[Index2]^.FileName);
end;

function CompareTitles(Index1, Index2: integer): integer;
begin
 Result := UTF8CompareText(PlaylistItems[Index1]^.Title, PlaylistItems[Index2]^.Title);
 if Result = 0 then Result := CompareFileNames(Index1, Index2);
end;

function CompareAuthors(Index1, Index2: integer): integer;
begin
 Result := UTF8CompareText(PlaylistItems[Index1]^.Author, PlaylistItems[Index2]^.Author);
 if Result = 0 then Result := CompareTitles(Index1, Index2);
end;

function CompareTypes(Index1, Index2: integer): integer;
var
 FT1, FT2: Available_Types;
begin
 FT1 := PlaylistItems[Index1]^.FileType;
 FT2 := PlaylistItems[Index2]^.FileType;
 Result := 0;
 if FT1 <> FT2 then
  begin
   if FT1 = -1 then
     Result := -1
   else if FT2 = -1 then
     Result := 1
   else
     Result := CompareText(GetFileType(FT1), GetFileType(FT2));
  end;
 if Result = 0 then Result := CompareAuthors(Index1, Index2);
end;

procedure TFrmPLst.ByauthorSortClick(Sender: TObject);
begin
 MyQuickSort(@CompareAuthors);
end;

procedure TFrmPLst.BytitleSortClick(Sender: TObject);
begin
 MyQuickSort(@CompareTitles);
end;

procedure TFrmPLst.ByfilenameSortClick(Sender: TObject);
begin
 MyQuickSort(@CompareFileNames);
end;

procedure TFrmPLst.Byfiletype1Click(Sender: TObject);
begin
 MyQuickSort(@CompareTypes);
end;

procedure TFrmPLst.ScBPLItemsScroll(Sender: TObject; ScrollCode: TScrollCode;
 var ScrollPos: integer);

 procedure SetSI;
 var
   l, p: integer;
 begin
   l := Length(PlayListItems);
   p := PLArea.ClientHeight div ListLineHeight;
   if ScrollPos > l - p then
     ScrollPos := l - p;
   if ScrollPos < 0 then
     ScrollPos := 0;
   if ScrollPos <> ShownFrom then
     RedrawPlaylist(ScrollPos, True);
 end;

begin
 case ScrollCode of
   scLineDown:
    begin
     ScrollPos := ScBPLItems.Position + 1;
     SetSI;
    end;
   scLineUp:
    begin
     ScrollPos := ScBPLItems.Position - 1;
     SetSI;
    end;
   scPageDown:
    begin
     ScrollPos := ScBPLItems.Position + ScBPLItems.PageSize;
     SetSI;
    end;
   scPageUp:
    begin
     ScrollPos := ScBPLItems.Position - ScBPLItems.PageSize;
     SetSI;
    end;
   scTrack:
    begin
     SetSI;
    end;
 else
   ScrollPos := ScBPLItems.Position;
  end;
end;

procedure TFrmPLst.FormDestroy(Sender: TObject);
begin
 StopTimer;
 ClearPlayListItems;
 FreeAndNil(PLArea);
end;

procedure TFrmPLst.Finditem1Click(Sender: TObject);
begin
 with TFrmFndPLItm.Create(Self) do
  try
   ShowModal;
  finally
   Free;
  end;
end;

procedure TFrmPLst.Deduplicate1Click(Sender: TObject);
var
 i, j: integer;
 yes: boolean;
begin
 if Length(PlaylistItems) < 1 then exit;
 yes := False;
  try
   i := 0;
   j := 1;
   repeat
     j := i + 1;
     repeat
       if (PlayListItems[i]^.FileName = PlayListItems[j]^.FileName) and
         (PlayListItems[i]^.FormatSpec = PlayListItems[j]^.FormatSpec) and
         (PlayListItems[i]^.Offset = PlayListItems[j]^.Offset) then
        begin
         yes := True;
         DeletePlayListItemAndReprepare(j);
        end
       else
         Inc(j);
     until j >= Length(PlaylistItems);
     Inc(i);
   until i >= Length(PlaylistItems) - 1;
  finally
   if yes then
    begin
     RedrawPlaylist(ShownFrom, False);
     CreatePlayOrder;
     CalculateTotalTime(False);
    end;
  end;
end;

function TFrmPLst.GetNumberOfSelectedItems: integer;
var
 i: integer;
begin
 Result := 0;
 for i := 0 to Length(PlaylistItems) - 1 do
   if PlaylistItems[i]^.Selected then
     Inc(Result);
end;

procedure TFrmPLst.MenuFLACClick(Sender: TObject);
begin
 ConvertSelected(pwConvFLAC);
end;

procedure TFrmPLst.MenuMP3Click(Sender: TObject);
begin
 ConvertSelected(pwConvMP3);
end;

procedure TFrmPLst.MenuOGGClick(Sender: TObject);
begin
 ConvertSelected(pwConvOGG);
end;

procedure TFrmPLst.MenuOPUSClick(Sender: TObject);
begin
 ConvertSelected(pwConvOPUS);
end;

procedure TFrmPLst.MIAllToFLACClick(Sender: TObject);
begin
 SaveToFolder(pwConvFLAC, True);
end;

procedure TFrmPLst.MIAllToMP3Click(Sender: TObject);
begin
 SaveToFolder(pwConvMP3, True);
end;

procedure TFrmPLst.MIAllToOGGClick(Sender: TObject);
begin
 SaveToFolder(pwConvOGG, True);
end;

procedure TFrmPLst.MIAllToOPUSClick(Sender: TObject);
begin
 SaveToFolder(pwConvOPUS, True);
end;

procedure TFrmPLst.MIAllToZXAYClick(Sender: TObject);
begin
 SaveToFolder(pwConvZXAY, True);
end;

procedure TFrmPLst.MIAllToVTXClick(Sender: TObject);
begin
 SaveToFolder(pwConvVTX, True);
end;

procedure TFrmPLst.MenuItem5Click(Sender: TObject);
begin
 SaveToFolder(pwConvYM6, True);
end;

procedure TFrmPLst.MIAllToPSGClick(Sender: TObject);
begin
 SaveToFolder(pwConvPSG, True);
end;

procedure TFrmPLst.SaveToFolder(Way: TPlayWay; All: boolean);
var
 i: integer;
 FN, Fld: string;
 DoConv: boolean;
begin
 if Length(PlaylistItems) = 0 then
   Exit;
 if not All then
   if GetNumberOfSelectedItems = 0 then
     Exit;
 Fld := '';
 //get path of some early item
 for i := 0 to Length(PlaylistItems) - 1 do
   if (All or PlaylistItems[i]^.Selected) and not
     FileIsURL(PlaylistItems[i]^.FileName) then
    begin
     Fld := ExtractFileDir(PlaylistItems[i]^.FileName);
     if DirectoryExistsUTF8(Fld) then
       Break;
     Fld := '';
    end;
 if Fld = '' then
   if AutoSaveDefDir and DirectoryExists(FrmMain.DefaultDirectory) then
     //saved music dir exists
     Fld := FrmMain.DefaultDirectory
   else
     //last opened file dir
     Fld := FrmMain.OpenDialog1.InitialDir;
 if ChooseDirectory(Fld, Mes_SaveToFolder, [cdoPathToName]) then
  begin
   if not DirectoryExistsUTF8(Fld) then
     if not ForceDirectoriesUTF8(Fld) or not DirectoryExistsUTF8(Fld)
     {need if 'nul' "created"} then
      begin
       ShowMessage(Mes_CantCreateDestFolder + ': ' + Fld);
       Exit;
      end;
   LongProcessPrepare(Way <> pwSave);
    try
     {по просьбе AAA не запоминаем   FrmMain.OpenDialog1.InitialDir := Fld;
     if AutoSaveDefDir then
      FrmMain.DefaultDirectory := Fld;}
     DoConv := True;
     for i := 0 to Length(PlaylistItems) - 1 do
       if All or PlaylistItems[i]^.Selected then
        begin
         if Way = pwSave then
           DoConv := SaveFile(i, True, FN, Fld)
         else
          begin
           if (i = 0) and (Way in [pwConvMP3, pwConvOGG, pwConvFLAC, pwConvOPUS]) then
             with EncoderOptions[PlayWayToBASSEnc(Way)] do
               GroupOperation := False; //to show tag editor once
           DoConv := PlayItem(PlayListItems[i]^.Tag, Way, True, Fld);
          end;
         if not DoConv then
           //user canceled or some crytical error
          begin
           if not May_Quit then
            //don't show if user aborted (will be shown later)
            ShowMessage(Format(Mes_NotFinished + '%D: %S',[i+1,GetPlayListString(PlayListItems[i])]));
           Exit;
          end;
         Application.ProcessMessages;
         if May_Quit then
           Break;
        end;
    finally
     LongProcessDone;
    end;
  end;
end;

procedure TFrmPLst.SaveToFolder1Click(Sender: TObject);
begin
 SaveToFolder(pwSave, True);
end;

procedure TFrmPLst.ConvToWAV1Click(Sender: TObject);
begin
 SaveToFolder(pwConvWAV, True);
end;

procedure TFrmPLst.FormConstrainedResize(Sender: TObject;
 var MinWidth, MinHeight, MaxWidth, MaxHeight: TConstraintSize);
begin
 MinWidth := LTotTime.Left + LTotTime.Width + Panel1.Left;
 MinHeight := Panel1.Height + ListLineHeight * 3;
 Constraints.MinWidth := MinWidth;
 Constraints.MinHeight := MinHeight;
end;

procedure TFrmPLst.FormShow(Sender: TObject);
begin
 FrmMain.MIPlaylist.Checked:=True;
end;

procedure TFrmPLst.RedrawItemsLabel;
begin
 LQtyCurTotal.Caption := IntToStr(PlayingItem + 1) + '/' +
   IntToStr(Length(PlayListItems));
end;

function LoadCUE(CUEName, FilterName: string): boolean;
const
 NumOfTokens = 13;
 MyTokens: array[0..NumOfTokens - 1] of string =
   ('CATALOG', 'CDTEXTFILE', 'FILE', 'FLAGS', 'INDEX', 'ISRC', 'PERFORMER', 'POSTGAP',
   'PREGAP', 'REM', 'SONGWRITER', 'TITLE', 'TRACK');
 MaxTokenLen = 10;
var
 hnd: integer;
 String1, String2: string;

 function ExtractToken(S1: string; var S2: string; var Ind: integer): boolean;
 var
   i: integer;
 begin
   Result := False;
   i := 1;
   S2 := '';
   while (i <= MaxTokenLen) and (i <= Length(S1)) and (S1[i] <> ' ') do
    begin
     S2 := S2 + S1[i];
     Inc(i);
    end;
   if i > Length(S1) then exit;
   S2 := UpperCase(S2);
   Ind := 0;
   while (Ind < NumOfTokens) and (MyTokens[Ind] <> S2) do Inc(Ind);
   if Ind = NumOfTokens then exit;
   S2 := '';
   for i := i + 1 to Length(S1) do S2 := S2 + S1[i];
   Result := True;
 end;

 procedure ExtractString(var S1, S2: string);
 var
   i: integer;
   stopchar: char;
   s: string;
 begin
   S1 := Trim(S1);
   S2 := '';
   if Length(S1) = 0 then exit;
   i := 1;
   stopchar := ' ';
   if S1[1] = '"' then
    begin
     Inc(i);
     stopchar := '"';
    end;
   s := '';
   while (i <= Length(S1)) and (S1[i] <> stopchar) do
    begin
     s := s + S1[i];
     Inc(i);
    end;
   while (i <= Length(S1)) do
    begin
     S2 := S2 + S1[i];
     Inc(i);
    end;
   S1 := s;
   S2 := Trim(S2);
 end;

 function ExtractTime(S1: string; var n1, n2: integer): boolean;
 var
   s: string;
   i: integer;
 begin
   Result := False;
    try
     ExtractString(S1, s);
     n1 := StrToInt(S1);
     i := Pos(':', s);
     if (i < 2) or (i = Length(s)) then exit;
     n2 := StrToInt(Copy(s, 1, i - 1)) * 60 * 1000;
     s := Copy(s, i + 1, Length(s) - i);
     i := Pos(':', s);
     if (i < 2) or (i = Length(s)) then exit;
     Inc(n2, int64(StrToInt(Copy(s, 1, i - 1))) * 1000 +
       round(StrToInt(Copy(s, i + 1, Length(s) - i)) / 75 * 1000));
     Result := True;
    except
    end;
 end;

var
 prevtrack, tracknum, cuetime: integer;
 PLItemWork: TPlayListItem;
 PLItem: PPlayListItem;
 FromFile: boolean;

 function AddTrack: boolean;
 begin
   Result := False;
   if tracknum = -1 then
     Exit;
   if PLItemWork.FormatSpec = -1 then
     Exit; //error
   if PLItemWork.Time = 0 then
     PLItemWork.Time := cuetime - PLItemWork.FormatSpec;
   prevtrack := AddPlaylistItem(PLItem);
   PlaylistItems[prevtrack]^ := PLItemWork;
   Result := True;
   RedrawItem(prevtrack);
 end;

 function GetFT(const s: string): Available_Types;
 begin
   Result := GetFileTypeFromFNExt(ExtractFileExt(s));
 end;

var
 bassh: integer;
 CUESHEET: string;

 procedure GetSongInfo_Tag(OGG_APE: boolean);
 var
   p: PChar;
   l, tl, cl: longword;
   Tag: string;
 begin
   if OGG_APE then
     p := BASS_ChannelGetTags(bassh, BASS_TAG_APE)
   else
     p := BASS_ChannelGetTags(bassh, BASS_TAG_OGG);
   if p = nil then exit;
   repeat
     l := StrLen(p);
     tl := 0;
     while (tl < l) and (PArray0OfByte(p)[tl] <> Ord('=')) do Inc(tl);
     if (tl = l) or (tl = 0) then break;
     if tl < l - 1 then
      begin
       SetLength(Tag, tl);
       Move(p^, Tag[1], tl);
       cl := l - tl - 1;
       if UpperCase(Tag) = 'CUESHEET' then
        begin
         SetLength(CUESHEET, cl);
         Move(PArray0OfByte(p)[tl + 1], CUESHEET[1], cl);
         break;
        end;
       SetLength(Tag, 0);
      end;
     Inc(p, l + 1);
   until pbyte(p)^ = 0;
 end;

 function eof2: boolean;
 begin
   if FromFile then
     Result := UniReadersData[hnd]^.UniFilePos >= UniReadersData[hnd]^.UniFileSize
   else
     Result := UniReadersData[hnd]^.UniOffset >= UniReadersData[hnd]^.UniDataSize;
 end;

 procedure ReadLn2(var s: string);
 begin
   UniReadLnUtf8(hnd, s);
 end;

var
 i, i1, i2: integer;
 CUEFILE, CUEPERFORMER, CUESONGWRITER, CUETITLE, CUEDATE, CUEGENRE, CUECOMMENT: string;
 CUEFileType: Available_Types;
 globalstrings: boolean;

 tmbass: QWORD;
begin
 Result := False;
 tracknum := -1;
 prevtrack := -1;
 globalstrings := True;
 CUEFILE := '';
 CUEPERFORMER := '';
 CUESONGWRITER := '';
 CUETITLE := '';
 CUEDATE := '';
 CUEGENRE := '';
 CUECOMMENT := '';
 CUESHEET := '';
 CUEFileType := -1;
 FromFile := FileExists(CUEName);
 if FromFile then
  begin
   SetCurrentDir(ExtractFileDir(CUEName));
   if FilterName <> '' then
    begin
     FilterName := ExpandFileName(FilterName);
    end;
   UniReadInit(hnd, URFile, CUEName, nil, -1);
   UniDetectCharCode(hnd);
  end
 else if FilterName <> '' then
  begin
   String1 := GetFileType(GetFT(FilterName));
   if (String1 <> 'FLAC') and (String1 <> 'OGG') and (String1 <> 'WV') then
     Exit;
   LoadBASS;
   if not BASSInitialized then InitBASS(BASS_NOSOUNDDEVICE, SampleRate, 0, 0);
   bassh := BASS_StreamCreateFile2({BDLL,}PChar(FilterName), BASS_STREAM_DECODE);
   if bassh = 0 then RaiseLastBASSError;
    try
     if String1 = 'WV' then
       GetSongInfo_Tag(True)
     else
       GetSongInfo_Tag(False);
    finally
     BASS_StreamFree(bassh);
    end;
   UniReadInit(hnd, URMemory, '', @CUESHEET[1], Length(CUESHEET));
   UniReadersData[hnd]^.UniCharCode := UCCUtf8;
  end;
  try
   if not eof2 then
    begin
     repeat
       ReadLn2(String1);
       String1 := Trim(String1);
       if String1 = '' then continue;
       if String1[1] = ';' then continue;
       if not ExtractToken(String1, String2, i) then break;

{  ('CATALOG'0,'CDTEXTFILE'1,'FILE'2,'FLAGS'3,'INDEX'4,'ISRC'5,'PERFORMER'6,'POSTGAP'7,
   'PREGAP'8,'REM'9,'SONGWRITER'10,'TITLE'11,'TRACK'12);}
       case i of
         2:
          begin
           if tracknum <> -1 then
            begin
             if not AddTrack then exit;
             tracknum := -1;
             prevtrack := -1;
            end;
           globalstrings := True;
           CUEFILE := '';
           if FromFile then
            begin
             ExtractString(String2, String1);
             {$IFNDEF Windows}
        CheckPath(String2); //path delimeter in linux
             {$ENDIF Windows}
             String2 := ExpandFileName(String2);
            end
           else
             String2 := FilterName;
           if (FilterName = '') or (UTF8UpperCase(String2) =
             UTF8UpperCase(FilterName)) then
            begin
             CUEFileType := GetFT(String2);
             if (CUEFileType <> -1) and FileExists(String2) then
              begin
               CUEFILE := String2;
               LoadBASS;
               if not BASSInitialized then
                 InitBASS(BASS_NOSOUNDDEVICE, SampleRate, 0, 0);
               bassh := BASS_StreamCreateFile2(PChar(String2), BASS_STREAM_DECODE);
               if bassh = 0 then RaiseLastBASSError;
                try
                 tmbass := BASS_ChannelGetLength(bassh, BASS_POS_BYTE);
                 if tmbass = QWORD(-1) then RaiseLastBASSError;
                 cuetime := trunc(BASS_ChannelBytes2Seconds(bassh, tmbass) * 1000);
                finally
                 BASS_StreamFree(bassh);
                end;
              end;
            end;
          end;
         4:
          begin
           if tracknum <> -1 then
             if ExtractTime(String2, i1, i2) then
               if i1 in [0, 1] then
                begin
                 PLItemWork.FormatSpec := i2;
                 if (prevtrack <> -1) and (PlaylistItems[prevtrack]^.Time <> 0) then
                   PlaylistItems[prevtrack]^.Time :=
                     i2 - PlaylistItems[prevtrack]^.FormatSpec;
                end;
           globalstrings := True;
          end;
         6:
          begin
           ExtractString(String2, String1);
           if globalstrings then
             CUEPERFORMER := String2
           else
           if tracknum <> -1 then
             PLItemWork.Author := String2;
          end;
         9:
          begin
           ExtractString(String2, String1);
           if String2 = 'DATE' then CUEDATE := String1
           else if String2 = 'GENRE' then CUEGENRE := String1
           else if String2 = 'COMMENT' then CUECOMMENT := String1;
          end;
         10:
          begin
           ExtractString(String2, String1);
           if globalstrings then
             CUESONGWRITER := String2
           else
           if tracknum <> -1 then
             if PLItemWork.Author = '' then
               PLItemWork.Author := String2
             else
               PLItemWork.Comment := PLItemWork.Comment + #13#10'Songwriter: ' + String2;
          end;
         11:
          begin
           ExtractString(String2, String1);
           if globalstrings then
             CUETITLE := String2
           else
           if tracknum <> -1 then
             PLItemWork.Title := String2;
          end;
         12:
           if CUEFILE <> '' then
            begin
             if tracknum <> -1 then
              begin
               if not AddTrack then exit;
              end;
             Inc(tracknum);
             globalstrings := False;
             FillDefPlayListItem(PLItemWork);
             with PLItemWork do
              begin
               FileName := CUEFILE;
               FileType := CUEFileType;
               Title := CUETITLE;
               Author := CUEPERFORMER;
               if Author = '' then Author := CUESONGWRITER;
               if CUEPERFORMER <> '' then Comment := 'Perfomer: ' + CUEPERFORMER;
               if CUESONGWRITER <> '' then
                 Comment := Comment + #13#10'Songwriter: ' + CUESONGWRITER;
               if CUETITLE <> '' then Comment := Comment + #13#10'Title: ' + CUETITLE;
               if CUEGENRE <> '' then Comment := Comment + #13#10'Genre: ' + CUEGENRE;
               if CUECOMMENT <> '' then
                 Comment := Comment + #13#10'Comment: ' + CUECOMMENT;
               Date := CUEDATE;
              end;
            end;
        end;
     until eof2;
     AddTrack;
    end;
  finally
   UniReadClose(hnd);
   Result := prevtrack <> -1;
   ReprepareScroll;
  end;
end;

end.
