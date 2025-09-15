{
This is part of AY Emulator project
AY-3-8910/12 Emulator
Version 3.0 for Windows and Linux
Author Sergey Vladimirovich Bulba
(c)1999-2025 S.V.Bulba
}

unit FileTypes;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLType, Dialogs;

type

 TFTCategory = (TFTCAudio,TFTCPlaylist,TFTCSkin,TFTCBASS);

//Supported types
 Available_Types = integer;

const
 PrecalcFTNum = 31;
 PrecalcFT:array[0..PrecalcFTNum] of string[4] =
 ('OUT','ZXAY','EPSG','AY','AYM','ST1','STC','ST3','ASC','ASC0','STF','STP','PSC','FLS',
  'FTC','PT1','PT2','PT3','SQT','GTR','FXM','PSM','VTX','YM','YM2','YM3','YM3b',
  'YM5','YM6','PSG','TS','SNDH');

var
 FT:record
  case boolean of
  False:(All:array[0..PrecalcFTNum] of integer);
  True: (OUT,ZXAY,EPSG,AY,AYM,ST1,STC,ST3,ASC,ASC0,STF,STP,PSC,FLS,FTC,
   PT1,PT2,PT3,SQT,GTR,FXM,PSM,VTX,YM,YM2,YM3,YM3b,YM5,YM6,PSG,TS,SNDH:integer);
 end;

{$ifndef Windows}
procedure WriteIconsAsPNG(PerUser:boolean);
procedure DeleteIcons(PerUser:boolean);
procedure MimeTypesReg(PerUser:boolean);
procedure DeleteMimeTypes(PerUser:boolean);
{$endif Windows}

procedure AppReg(PerUser:boolean);
procedure FileTypeReg(PerUser:boolean;FileTypeCat:TFTCategory);
function IsFileTypeReg(FileTypeCat:TFTCategory):boolean;
procedure FileExtAssoc(PerUser:boolean;const FileExt:string;FileTypeCat:TFTCategory;SetDefault:boolean);
function IsFileExtAssoc(const FileExt:string;FileTypeCat:TFTCategory):boolean;
procedure UnregisterApp(PerUser:boolean);

procedure GetFileTypes(FT:TStrings);
function IsStreamFileType(FT:integer):boolean;
function IsCDFileType(FT:integer):boolean;
function IsStreamOrModuleFileType(FT:integer):boolean;
function IsModuleFileType(FT:integer):boolean;
function IsAYChipFileType(FT:integer):boolean;
function IsTimeMSFileType(FT_:integer):boolean;
function IsZ80EmuFileType(FT_:integer):boolean;
function IsSTSoundFileType(FT_:integer):boolean;
function IsMIDIFileType(FT:integer):boolean;
function IsAYNativeFileType(FT:integer):boolean;
function IsVBLFileType(FT_:integer):boolean;
function IsSkinFileType(FT:integer):boolean;
function GetFileType(FT:integer):string;
function GetFileType(const FT:string):integer;
function GetFNExt(FT:integer;IncludePoint:boolean=True):string;
procedure GetFNExtsCat(AY,BASS,PL,Skin:TStrings);
function IsMatchFileTypeToFNExt(FT:integer;FNExt:string):boolean;
function GetFilterString(FT:integer):string;
function GetFileTypeFromFNExt(FNExt:string):integer;
function GetEditorString(FT:integer):string;
function IsMatch(FT:integer;Offset:integer;const Match:string):boolean;

implementation

uses
  {$ifdef Windows}assoc,{$else}Graphics, IntfGraphics, FPImage,{$endif Windows}
  WinVersion, MainWin, UniReader, Tools, Languages;

const
FTCats:array[TFTCategory] of string =
 ('Ay_Emul Audio File','Ay_Emul Playlist File',
  'Ay_Emul Skin File','Ay_Emul BASS File');

type
  TArrOfInt = array of integer;
  TArrOfStr = array of string;
  TArrOfLangStr = record
    Common:string;
    Langs,LangStrs:TArrOfStr;
  end;

  TFormatsSections = (FStype,FScommand,FSgroup,FSfnext,FSformat);
const
  FSNames:array[TFormatsSections] of string =
   ('type','command','group','fnext','format');
var
  SubSections:array[TFormatsSections] of TArrOfStr;
  commandParams:array of record
    nodisplay:boolean;
    name,param:string;
    visname:TArrOfLangStr;
    pref:integer;
  end;
  groupParams:array of record
    types,commands:TArrOfInt;
    desc:TArrOfLangStr;
  end;
  fnextParams:array of record
   desc:TArrOfLangStr;
  end;
  formatParams:array of record
    tp,matchprior:integer;
    fnext:TArrOfInt;
    specific:boolean;
    mimetypes:TArrOfStr;
    editor:string;
    desc:TArrOfLangStr;
    matches:array of array of record
      Offset:integer;
      Value:string;
    end;
  end;

function GetLangStr(Lang:string;const aStr:TArrOfLangStr):string;
var
  i,j:integer;
begin
if Lang <> '' then
 for j := 0 to 1 do
  begin
   for i := 0 to Length(aStr.Langs)-1 do
    if Lang = aStr.Langs[i] then
     exit(aStr.LangStrs[i]);
   if Length(Lang) <= 2 then
    break;
   Lang := Copy(Lang,1,2); //ru_RU -> ru
  end;
Result := aStr.Common;
end;

function GetGroup(FileTypeCat:TFTCategory):integer;
var
  i:integer;
begin
for i := 0 to Length(SubSections[FSgroup])-1 do
 if SubSections[FSgroup][i] = FTCats[FileTypeCat] then
  begin
   Result := i;
   exit;
  end;
Result := -1;
end;

{$ifdef Windows}
function FTCatIconPath(n:integer):string;
begin
Result := GetProcessFileName + ',';
case n of
-1:
 Result := Result + IntToStr(AppIconNumber);
0:
 Result := Result + IntToStr(MusIconNumber);
1:
 Result := Result + IntToStr(ListIconNumber);
2:
 Result := Result + IntToStr(SkinIconNumber);
3:
 Result := Result + IntToStr(BASSIconNumber);
end;
end;
{$endif}

{$ifndef Windows}

function FTCatIconPath(n:integer):string;
begin
case n of
-1:
 Result := Format('Ay_Emul%.2u',[AppIconNumber]);
0:
 Result := Format('Ay_Emul%.2u',[MusIconNumber]);
1:
 Result := Format('Ay_Emul%.2u',[ListIconNumber]);
2:
 Result := Format('Ay_Emul%.2u',[SkinIconNumber]);
3:
 Result := Format('Ay_Emul%.2u',[BASSIconNumber]);
else
 Result := '';
end;
end;

function GetXDG_DATA_HOME:string;
begin
Result := GetEnvironmentVariable('XDG_DATA_HOME');
if Result = '' then
 Result := IncludeTrailingBackslash(GetEnvironmentVariable('HOME')) + '.local/share/'
else
 Result := IncludeTrailingBackslash(Result);
end;

function GetXDG_DATA_DIR(PerUser:boolean;const SubDir:string):string;
var
 dir,dirs,res:string;

  procedure GetNext;
  var
   i:integer;
  begin
  i := Pos(':',dirs);
  if i = 0 then
   begin
    dir := dirs;
    dirs := '';
   end
  else
   begin
    dir := Copy(dirs,1,i-1);
    dirs := Copy(dirs,i+1,Length(dirs)-i);
   end;
  end;

begin
if PerUser then
 Result := GetXDG_DATA_HOME+SubDir
else
 begin
  dirs := GetEnvironmentVariable('XDG_DATA_DIRS');
  if dirs = '' then
   dirs := '/usr/local/share/:/usr/share/';
  Result := '';
  repeat
   GetNext; if dir = '' then exit;
   res := IncludeTrailingBackslash(dir)+SubDir;
   if Result = '' then Result := res;
   if DirectoryExists(res) then
    begin
     Result := res;
     exit;
    end;
  until False;
 end;
end;

procedure WriteIconsAsPNG(PerUser:boolean);
var
  icon:TIcon;
  png:TPortableNetworkGraphic;
  i,x,y,w:integer;
  intf,intfi: TLazIntfImage;
  col: TFPColor;
  hicolor,subf:string;
begin
hicolor := GetXDG_DATA_DIR(PerUser,'icons/hicolor')+'/';
icon := TIcon.Create;
png := TPortableNetworkGraphic.Create;
png.PixelFormat:=pf32bit;
for i := 0 to NOfIcons do
 begin
  icon.LoadFromResourceName(hInstance,Format('ICON%.2u',[i]));
  w := icon.Width; if w <> icon.Height then continue;
//  if not (w in [16,22,24,32,36,48,64,72,96,128,192,256,512]) then continue;
  subf := IntToStr(w); subf := subf+'x'+subf+'/apps';
  ForceDirectories(hicolor+subf);
  png.SetSize(w,w);
  intf := png.CreateIntfImage;
  intfi := icon.CreateIntfImage;
  for y := 0 to w-1 do
   for x := 0 to w-1 do
    begin
     if intfi.Masked[x,y] then
      col := colTransparent
     else
      col := icon.Canvas.Colors[x,y];
     intf.Colors[x,y] := col;
    end;
  intfi.Free;
  png.LoadFromIntfImage(intf);
  intf.Free;
  png.SaveToFile(hicolor+subf+'/'+Format('Ay_Emul%.2u',[i])+'.png');
 end;
png.Free;
icon.Free;
end;

procedure DeleteIcons(PerUser:boolean);
var
  icon:TIcon;
  i,w:integer;
  hicolor,subf:string;
begin
hicolor := GetXDG_DATA_DIR(PerUser,'icons/hicolor')+'/';
if not DirectoryExists(hicolor) then exit;
icon := TIcon.Create;
for i := 0 to NOfIcons do
 begin
  icon.LoadFromResourceName(hInstance,Format('ICON%.2u',[i]));
  w := icon.Width; if w <> icon.Height then continue;
  subf := IntToStr(w);
  subf := hicolor+subf+'x'+subf+'/apps/'+Format('Ay_Emul%.2u',[i])+'.png';
  if FileExists(subf) then
   DeleteFile(subf);
 end;
icon.Free;
end;

function GetGrpForTp(tp:integer):integer;
var
 i,j:integer;
begin
for i := 0 to Length(groupParams)-1 do
 for j := 0 to Length(groupParams[i].types)-1 do
  if groupParams[i].types[j] = tp then
   begin
    Result := i;
    exit;
   end;
Result := -1;
end;

function CheckSpecSymbols(const aStr:string):string;
begin
Result := StringReplace(aStr,'&','&amp;',[rfReplaceAll]);
//" - не обязательно менять для содержимого контейнера
Result := StringReplace(Result,'"','&quot;',[rfReplaceAll]);
Result := StringReplace(Result,'<','&lt;',[rfReplaceAll]);
Result := StringReplace(Result,'>','&gt;',[rfReplaceAll]);
end;

procedure WriteMimeXML(const Dir:string);
var
 o,nexto:integer;
 v,nextv,vtype:string;

 function GetNextMatch:boolean;
 var
  i:integer;
 begin
 Result := False; if v = '' then exit;
 nextv := ''; nexto := o; vtype := 'string';
 for i := 1 to Length(v) do
  begin
    inc(o);
    case v[i] of
    #0..#31,#128..#255:
     begin
      Result := True;
      if nextv = '' then
       begin
        nextv := IntToStr(Ord(v[i]));
        vtype := 'byte';
        v := Copy(v,i+1,Length(v)-i);
       end
      else
       begin
        dec(o);
        v := Copy(v,i,Length(v)-i+1);
       end;
      exit;
     end;
    '&':
     nextv := nextv + '&amp;';
    '"':
     nextv := nextv + '&quot;';
    '<':
     nextv := nextv + '&lt;';
    '>':
     nextv := nextv + '&gt;';
    else
     nextv := nextv + v[i];
    end;
  end;
 v := '';
 Result := True;
 end;

var
 mcnt:integer;

 function GetSpc:string;
 begin
 SetLength(Result{%H-},8+mcnt*2);
 FillChar(Result[1],8+mcnt*2,' ');
 end;

var
 i,j,k,m:integer;
 f:Text;
begin
ForceDirectories(Dir);
Assign(f,IncludeTrailingBackslash(Dir)+'Ay_Emul.xml');
Rewrite(f);
Writeln(f,'<?xml version="1.0" encoding="UTF-8"?>');
Writeln(f,'<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">');
for i := 0 to Length(formatParams)-1 do
 begin
  if not formatParams[i].specific then continue;
  if Length(formatParams[i].mimetypes) = 0 then continue;
  Writeln(f,'    <mime-type type="',formatParams[i].mimetypes[0],'">');
  if formatParams[i].desc.Common <> '' then
  Writeln(f,'        <comment>',CheckSpecSymbols(formatParams[i].desc.Common),'</comment>');
  for j := 0 to Length(formatParams[i].desc.Langs)-1 do
   Writeln(f,'        <comment xml:lang="',formatParams[i].desc.Langs[j],'">',CheckSpecSymbols(formatParams[i].desc.LangStrs[j]),'</comment>');
  for j := 1 to Length(formatParams[i].mimetypes)-1 do
   Writeln(f,'        <alias type="',formatParams[i].mimetypes[j],'"/>');
  if Length(formatParams[i].matches) <> 0 then
   begin
    Writeln(f,'        <magic priority="',formatParams[i].matchprior,'">');
    for j := 0 to Length(formatParams[i].matches)-1 do
     begin
      m := Length(formatParams[i].matches[j])-1;
      mcnt := 0;
      for k := 0 to m do
       begin
        o := formatParams[i].matches[j][k].Offset;
        v := formatParams[i].matches[j][k].Value;
        while GetNextMatch do
         begin
          inc(mcnt);
          Write(f,GetSpc,'<match type="'+vtype+'" offset="',nexto,'" value="',nextv);
          if (k < m) or (v <> '') then
           Writeln(f,'">')
          else
           Writeln(f,'"/>');
         end;
       end;
      while mcnt > 1 do
       begin
        dec(mcnt);
        Writeln(f,GetSpc,'</match>');
       end;
     end;
    Writeln(f,'        </magic>');
   end;
  Writeln(f,'        <icon name="'+FTCatIconPath(GetGrpForTp(formatParams[i].tp))+'"/>');
  if Length(formatParams[i].fnext) <> 0 then
   begin
//      Writeln(f,'        <glob-deleteall/>');
    for j := 0 to Length(formatParams[i].fnext)-1 do
     begin
      Writeln(f,'        <glob pattern="*.'+SubSections[FSfnext][formatParams[i].fnext[j]]+'"/>');
//        Writeln(f,'        <glob pattern="*.'+UpperCase(formatParams[i].fnext[j])+'"/>');
     end;
   end;
  Writeln(f,'    </mime-type>');
 end;
Writeln(f,'</mime-info>');
Close(f);
end;

procedure MimeTypesReg(PerUser:boolean);
var
 Mime:string;
begin
Mime := GetXDG_DATA_DIR(PerUser,'mime');
WriteMimeXML(Mime+'/packages');
CmdExecute('update-mime-database',[Mime]);
end;

procedure DeleteMimeTypes(PerUser:boolean);
var
 Mime,Dir:string;
begin
Mime := GetXDG_DATA_DIR(PerUser,'mime');
Dir := Mime+'/packages/Ay_Emul.xml';
if not FileExists (Dir) then exit;
if DeleteFile(Dir) then
 CmdExecute('update-mime-database',[Mime]);
end;

function IsCmdForType(cmd,tp:integer):boolean;
var
 i,j,k:integer;
begin
for i := 0 to Length(groupParams)-1 do
 for j := 0 to Length(groupParams[i].types)-1 do
  if groupParams[i].types[j] = tp then
    for k := 0 to Length(groupParams[i].commands)-1 do
     if groupParams[i].commands[k] = cmd then
      begin
       Result := True;
       exit;
      end;
Result := False;
end;

procedure WriteAppDesktop(Dir:string;cmd:integer);
var
 f:Text;
 i,j:integer;
begin
Dir := IncludeTrailingBackslash(Dir)+'Ay_Emul/';
ForceDirectories(Dir);
Assign(f,Dir+SubSections[FScommand][cmd]+'.desktop');
Rewrite(f);
Writeln(f,'[Desktop Entry]');
Writeln(f,'Name=',commandParams[cmd].visname.Common);
for i := 0 to Length(commandParams[cmd].visname.Langs)-1 do
 Writeln(f,'Name[',commandParams[cmd].visname.Langs[i],']=',commandParams[cmd].visname.LangStrs[i]);
Writeln(f,'TryExec=',GetProcessFileName);
Writeln(f,'Exec="',GetProcessFileName,'" ',commandParams[cmd].param,'%F');
Write(f,'MimeType=');
for i := 0 to length(formatParams)-1 do
 if IsCmdForType(cmd,formatParams[i].tp) then
  for j := 0 to Length(formatParams[i].mimetypes)-1 do
   Write(f,formatParams[i].mimetypes[j],';');
Writeln(f);
Writeln(f,'Icon=',Format('Ay_Emul%.2u',[AppIconNumber]));
Writeln(f,'Categories=AudioVideo;Audio;Player;GTK;');
Writeln(f,'Terminal=false');
Writeln(f,'Type=Application');
if commandParams[cmd].nodisplay then
 Writeln(f,'NoDisplay=true');
if commandParams[cmd].pref >= 0 then
 Writeln(f,'InitialPreference=',commandParams[cmd].pref);
Close(f);
end;

{$endif Windows}

{$ifdef Windows}
function Verbs(FileTypeCat:TFTCategory):TArrOfStr;
var
  i,l:integer;
begin
Result := nil;
i := GetGroup(FileTypeCat); if i < 0 then exit;
l := Length(groupParams[i].commands); if l = 0 then exit;
SetLength(Result,l);
for l := 0 to l-1 do
 with commandParams[groupParams[i].commands[l]] do
  Result[l] := name + #0 + GetLangStr(FrmMain.Get_Language,visname) +
    #0'"' + GetProcessFileName + '"'#0 + param + '"%1"' + #0 + DdeServiceName;
end;
{$endif Windows}

procedure AppReg(PerUser:boolean);
{$ifdef Windows}
var
 Exts:array of string;
 i,c:integer;
{$else}
var
 App:string;
 i:integer;
{$endif Windows}
begin
{$ifdef Windows}
c := Length(SubSections[FSfnext]); SetLength(Exts,c);
for i := 0 to c-1 do
 Exts[i] := '.'+SubSections[FSfnext][i];
RegApp(PerUser,GetProcessFileName,'',FTCatIconPath(-1),
   AYEmul_AppTitle,Exts,Verbs(TFTCAudio));
{$else}
App := GetXDG_DATA_DIR(PerUser,'applications');
for i := 0 to Length(SubSections[FScommand])-1 do
 WriteAppDesktop(App,i);
CmdExecute('update-desktop-database',[App]);
{$endif Windows}
end;

procedure FileTypeReg(PerUser:boolean;FileTypeCat:TFTCategory);
{$ifdef Windows}
var
  i:integer;
{$endif Windows}
begin
{$ifdef Windows}
i := GetGroup(FileTypeCat); if i < 0 then exit;
RegProgID(PerUser,FTCats[FileTypeCat]+#0+GetLangStr(FrmMain.Get_Language,groupParams[i].desc)
   +#0+FTCatIconPath(Ord(FileTypeCat)),Verbs(FileTypeCat));
{$endif Windows}
end;

function IsFileTypeReg(FileTypeCat:TFTCategory):boolean;
begin
{$ifdef Windows}
Result := IsRegProgID(FTCats[FileTypeCat]);
{$else Windows}
Result := False;
{$endif Windows}
end;

procedure FileExtAssoc(PerUser:boolean;const FileExt:string;FileTypeCat:TFTCategory;SetDefault:boolean);
begin
{$ifdef Windows}
RegFileExts(PerUser,[IntToStr(Ord(SetDefault))+#0+FileExt+#0+FTCats[FileTypeCat]]);
{$endif Windows}
end;

function IsFileExtAssoc(const FileExt:string;FileTypeCat:TFTCategory):boolean;
begin
{$ifdef Windows}
Result := IsRegFileExt(FileExt,FTCats[FileTypeCat]); //todo check path to exe
{$else Windows}
Result := False;
{$endif Windows}
end;

procedure UnregisterApp(PerUser:boolean);
var
{$ifdef Windows}
 i:TFTCategory;
{$else}
 App,Dir:string;
 i:integer;
{$endif Windows}
begin
{$ifdef Windows}
for i := Low(TFTCategory) to High(TFTCategory) do
 DelProgID(FTCats[i]);
DelApp(PerUser,ExtractFileName(GetProcessFileName));
AssocChanged;
{$else}
App := GetXDG_DATA_DIR(PerUser,'applications');
Dir := IncludeTrailingBackslash(App)+'Ay_Emul';
if not DirectoryExists(Dir) then exit;
for i := 0 to Length(SubSections[FScommand])-1 do
 if FileExists(Dir+'/'+SubSections[FScommand][i]+'.desktop') then
  DeleteFile(Dir+'/'+SubSections[FScommand][i]+'.desktop');
RemoveDir(Dir);
CmdExecute('update-desktop-database',[App]);
{$endif Windows}
end;

procedure GetFileTypes(FT:TStrings);
var
  i:integer;
begin
FT.Clear;
for i := 0 to Length(formatParams)-1 do
 FT.Add(SubSections[FSformat][i]);
end;

function IsStreamFileType(FT:integer):boolean;
begin
Result := (FT >= 0) and (FT < Length(formatParams)) and
 (SubSections[FStype][formatParams[FT].tp] = 'WAV');
end;

function IsCDFileType(FT:integer):boolean;
begin
Result := (FT >= 0) and (FT < Length(formatParams)) and
 (SubSections[FStype][formatParams[FT].tp] = 'CDA');
end;

function IsStreamOrModuleFileType(FT:integer):boolean;
var
 s:string;
begin
Result := (FT >= 0) and (FT < Length(formatParams));
if not Result then
 exit;
s := SubSections[FStype][formatParams[FT].tp];
Result := ((s = 'WAV') or (s = 'MOD'));
end;

function IsModuleFileType(FT:integer):boolean;
begin
Result := (FT >= 0) and (FT < Length(formatParams)) and
  (SubSections[FStype][formatParams[FT].tp] = 'MOD');
end;

function IsAYChipFileType(FT:integer):boolean;
var
 s:string;
begin
Result := (FT >= 0) and (FT < Length(formatParams));
if not Result then
 exit;
s := SubSections[FStype][formatParams[FT].tp];
Result :=
  (s = 'AY') or
  (s = 'AYR') or
  (s = 'AYRS') or
  (s = 'AYEMUL');
end;

function IsTimeMSFileType(FT_:integer):boolean;
var
 s:string;
begin
Result := (FT_ = FT.OUT) or (FT_ = FT.ZXAY) or (FT_ = FT.EPSG);
if Result then
 exit;
Result := (FT_ >= 0) and (FT_ < Length(formatParams));
if not Result then
 exit;
s := SubSections[FStype][formatParams[FT_].tp];
Result :=
  (s = 'WAV') or
  (s = 'MOD') or
  (s = 'MIDI');
end;

function IsZ80EmuFileType(FT_:integer):boolean;
begin
Result := (FT_ = FT.AY) or (FT_ = FT.AYM);
end;

function IsSTSoundFileType(FT_:integer):boolean;
begin
Result :=
  (FT_ = FT.YM) or
  (FT_ = FT.YM2) or
  (FT_ = FT.YM3) or
  (FT_ = FT.YM3b) or
  (FT_ = FT.YM5) or
  (FT_ = FT.YM6);
end;

function IsMIDIFileType(FT:integer):boolean;
begin
Result := (FT >= 0) and (FT < Length(formatParams)) and
 (SubSections[FStype][formatParams[FT].tp] = 'MIDI');
end;

function IsAYNativeFileType(FT:integer):boolean;
begin
Result := (FT >= 0) and (FT < Length(formatParams)) and
 (SubSections[FStype][formatParams[FT].tp] = 'AY');
end;

function IsVBLFileType(FT_:integer):boolean;
var
  s:string;
begin
if FT_ = FT.SNDH then
 exit(True);
Result := (FT_ >= 0) and (FT_ < Length(formatParams));
if Result then
 begin
  s := SubSections[FStype][formatParams[FT_].tp];
  Result := (s = 'AY') or (s = 'AYR');
 end;
end;

function IsSkinFileType(FT:integer):boolean;
begin
Result := (FT >= 0) and (FT < Length(formatParams)) and
 (SubSections[FStype][formatParams[FT].tp] = 'Skin');
end;

function GetFileType(FT:integer):string;
begin
if (FT >= 0) and (FT < Length(formatParams)) then
 Result := SubSections[FSformat][FT]
else
 Result := '';
end;

function GetFileType(const FT:string):integer;
var
  i:integer;
begin
for i := 0 to Length(formatParams)-1 do
 if SubSections[FSformat][i] = FT then
  begin
   Result := i;
   exit;
  end;
Result := -1;
end;

function GetFNExt(FT:integer;IncludePoint:boolean=True):string;
begin
if (FT >= 0) and (FT < Length(formatParams)) and (Length(formatParams[FT].fnext) > 0) then
 begin
  Result := SubSections[FSfnext][formatParams[FT].fnext[0]];
  if IncludePoint then Result := '.'+Result;
 end
else
 Result := '';
end;

procedure GetFNExtsCat(AY,BASS,PL,Skin:TStrings);
var
  i,j:integer;

  procedure Add(S:TStrings);
  var
   Ext:string;
   k:integer;
  begin
   Ext := '.'+UpperCase(SubSections[FSfnext][formatParams[i].fnext[j]]);
   for k := S.Count-1 downto 0 do
    if S.Strings[k] = Ext then exit;
   S.Append(Ext);
  end;

begin
for i := 0 to Length(formatParams)-1 do
 begin
  j := Length(formatParams[i].fnext)-1; if j < 0 then continue;
  if IsStreamOrModuleFileType(i) then
   for j := 0 to j do
    Add(BASS)
  else if SubSections[FStype][formatParams[i].tp] = 'PL' then
   for j := 0 to j do
    Add(PL)
  else if SubSections[FStype][formatParams[i].tp] = 'Skin' then
   for j := 0 to j do
    Add(Skin)
  else for j := 0 to j do
   Add(AY);
 end;
end;

function IsMatchFileTypeToFNExt(FT:integer;FNExt:string):boolean;
var
  i:integer;
begin
if (FT >= 0) and (FT < Length(formatParams)) and (Length(formatParams[FT].fnext) > 0) then
 begin
   FNExt := UpperCase(FNExt);
   for i := 0 to Length(formatParams[FT].fnext)-1 do
    if '.'+UpperCase(SubSections[FSfnext][formatParams[FT].fnext[i]]) = FNExt then
     begin
      Result := True;
      exit;
     end;
 end;
Result := False;
end;

function GetFilterString(FT:integer):string;
const
 T_ExtraTypes = '*.trd;*.scl;*.sna;*.$*;*.!*;*.fdi;*.tap;*.tzx;*.td0';
var
 i,imax,j,l:integer;
 Mask,MaskAll,Desc:string;
begin
if FT < 0 then
 begin
  i := 0;
  imax := Length(formatParams)-1;
 end
else
 begin
  i := FT;
  imax := FT;
 end;
Result := ''; MaskAll := '';
for i := i to imax do
 begin
  l := Length(formatParams[i].fnext)-1; if l < 0 then continue;
  if fnextParams[formatParams[i].fnext[0]].desc.Common = '' then continue;
  Desc := GetLangStr(FrmMain.Get_Language,fnextParams[formatParams[i].fnext[0]].desc) + ' ('; //todo " (EXT)" need only in WinXP and Linux?
  Mask := '';
  for j := 0 to l do
   begin
    Desc := Desc + UpperCase(SubSections[FSfnext][formatParams[i].fnext[j]]);
    Mask := Mask + '*.'+SubSections[FSfnext][formatParams[i].fnext[j]];
    {$ifndef Windows} //OpenDialog file mask is case sensitive in GTK2
    Mask := Mask + ';*.'+UpperCase(SubSections[FSfnext][formatParams[i].fnext[j]]);
    {$endif}
    if j < l then
     begin
      Desc := Desc + ',';
      Mask := Mask + ';';
     end
    else
     Desc := Desc + ')';
   end;
  Desc := Desc + '|' + Mask + '|';
  if Pos(Desc,Result) > 0 then continue;
  Result := Result + Desc;
  if FT < 0 then
   begin
    if MaskAll <> '' then MaskAll := MaskAll + ';';
    MaskAll := MaskAll + Mask;
   end;
 end;
if Result = '' then exit;
if FT < 0 then
 begin
  Result := T_AllSupFiles+'|'+MaskAll+';'+T_ExtraTypes
  {$ifndef Windows} //OpenDialog file mask is case sensitive in GTK2
  +';'+UpperCase(T_ExtraTypes)
  {$endif}
  +'|'+Result+T_AllFiles+'|*';
 end
else
 SetLength(Result,Length(Result)-1);
end;

function GetFileTypeFromFNExt(FNExt:string):integer;
var
 i,j:integer;
begin
FNExt := UpperCase(FNExt);
Result := -1;
for i := 0 to Length(formatParams)-1 do
 for j := 0 to Length(formatParams[i].fnext)-1 do
  if '.'+UpperCase(SubSections[FSfnext][formatParams[i].fnext[j]]) = FNExt then
   begin
    if Result >= 0 then //more than one :(
     exit(-2);
    Result := i;
    break;
   end;
end;

function GetEditorString(FT:integer):string;
begin
if (FT >= 0) and (FT < Length(formatParams)) then
 Result := formatParams[FT].editor
else
 Result := '';
end;

function IsMatch(FT:integer;Offset:integer;const Match:string):boolean;
var
 i,j:integer;
begin
if (FT >= 0) and (FT < Length(formatParams)) then
 for i := 0 to Length(formatParams[FT].matches)-1 do
  for j := 0 to Length(formatParams[FT].matches[i])-1 do
   if (formatParams[FT].matches[i][j].Offset = Offset) and
      (formatParams[FT].matches[i][j].Value = Match) then
    begin
     Result := True;
     exit;
    end;
Result := False;
end;

procedure load_formats;
var
 s:string;
 Section:TFormatsSections = FStype;
 SubSection:integer = -1;
 ValName,ValVal:string;

 function AddName(const n:string;sect:TFormatsSections):integer;
 var
   i:integer;
 begin
 Result := Length(SubSections[sect]);
 for i := 0 to Result-1 do
  if SubSections[sect][i] = n then
   begin
     Result := i;
     exit;
   end;
 SetLength(SubSections[sect],Result+1);
 SubSections[sect][Result] := n;
 case sect of
 FScommand:
   begin
    SetLength(commandParams,Result+1);
    commandParams[Result].name:='';
    commandParams[Result].param:='';
    commandParams[Result].nodisplay:=True;
    commandParams[Result].visname.Common:='';
    commandParams[Result].visname.Langs := nil;
    commandParams[Result].visname.LangStrs := nil;
    commandParams[Result].pref:=-1;
   end;
 FSgroup:
   begin
    SetLength(groupParams,Result+1);
    groupParams[Result].types := nil;
    groupParams[Result].commands := nil;
    groupParams[Result].desc.Common := '';
    groupParams[Result].desc.Langs := nil;
    groupParams[Result].desc.LangStrs := nil;
   end;
 FSfnext:
   begin
    SetLength(fnextParams,Result+1);
    fnextParams[Result].desc.Common := '';
    fnextParams[Result].desc.Langs := nil;
    fnextParams[Result].desc.LangStrs := nil;
   end;
 FSformat:
   begin
    SetLength(formatParams,Result+1);
    formatParams[Result].tp := -1;
    formatParams[Result].specific := False;
    formatParams[Result].mimetypes := nil;
    formatParams[Result].fnext := nil;
    formatParams[Result].desc.Common := '';
    formatParams[Result].desc.Langs := nil;
    formatParams[Result].desc.LangStrs := nil;
    formatParams[Result].matchprior := 50;
    formatParams[Result].matches := nil;
   end;
 end;
 end;

  function SetNamedSection(sect:TFormatsSections):boolean;
  var
   s1:string;
   plus:integer;
  begin
  plus := -1;
  s1 := '[' + FSNames[sect] + ' ';
  if Pos(s1,s) = 1 then
   plus := 0
  else if sect in [FScommand,FSformat] then
   begin
    s1 := '[' + FSNames[sect] + '+ ';
    if Pos(s1,s) = 1 then
     plus := 1;
   end;
  Result := plus >= 0;
  if Result then
   begin
    Section := sect;
    s1 := Copy(s,Length(s1)+1,Length(s)-Length(s1)-1);
    SubSection := AddName(s1,sect);
    case sect of
    FScommand:
     if plus > 0 then
      commandParams[SubSection].nodisplay := False;
    FSformat:
     begin
      if plus > 0 then
       formatParams[SubSection].specific := True;
      for plus := 0 to PrecalcFTNum do
       if PrecalcFT[plus] = s1 then
        begin
         FT.All[plus] := SubSection;
         break;
        end;
     end;
    end;
   end;
  end;

  function SetSection:boolean;
  var
   iSection:TFormatsSections;
  begin
  Result := False;
  if (s[1] <> '[') or (s[length(s)] <> ']') then
    exit;
  for iSection := Low(TFormatsSections) to High(TFormatsSections) do
   if SetNamedSection(iSection) then
    begin
     Result := True;
     exit;
    end;
  end;

  function SetSectionValue:boolean;

   function Check(const vnm:string;var vvl:string):boolean;
   begin
   Result := ValName = vnm;
   if Result then
    vvl := ValVal;
   end;

   function CheckN(const vnm:string;N:integer;var vvl:integer):boolean;
   var
    i:integer;
   begin
   Result := ValName = vnm;
   if Result then
    if TryStrToInt(ValVal,i) and (i >= 0) and (i <= N) then
     vvl := i
    else
     Result := False;
   end;

   function CheckLang(const vnm:string;var vvl:TArrOfLangStr):boolean;
   var
    l,l1:integer;

    procedure AddLang;
    var
     i,r:integer;
     Lang:string;
    begin
     Lang := Copy(ValName,l+2,l1-2-l);
     r := -1;
     for i := 0 to Length(vvl.Langs)-1 do
      if vvl.Langs[i] = Lang then
       begin
        r := i;
        break;
       end;
     if r < 0 then
      begin
       r := Length(vvl.Langs);
       SetLength(vvl.Langs,r+1);
       SetLength(vvl.LangStrs,r+1);
       vvl.Langs[r] := Lang;
      end;
     vvl.LangStrs[r] := ValVal;
    end;

   begin
   Result := Check(vnm,vvl.Common); if Result then exit;
   if Pos(vnm,ValName) = 0 then exit;
   l := Length(vnm); l1 := Length(ValName);
   if (l < l1-3) and (ValName[l+1] = '[') and (ValName[l1] = ']') then
    begin
     AddLang;
     Result := True;
    end;
   end;

   var
    ikey:string;

    procedure GetNext;
    var
     i:integer;
    begin
    i := Pos(';',ValVal);
    if i = 0 then
     begin
      ikey := ValVal;
      ValVal := '';
     end
    else
     begin
      ikey := Copy(ValVal,1,i-1);
      ValVal := Copy(ValVal,i+1,Length(ValVal)-i);
     end;
    end;

   function CheckListI(const vnm:string;const keys:TArrOfStr;var nkeys:TArrOfInt):boolean;
   var
    i,l:integer;
   begin
    Result := ValName = vnm; if not Result then exit;
    repeat
      GetNext;
      if ikey = '' then break;
      l := -1;
      for i := 0 to Length(keys)-1 do
       if keys[i] = ikey then
        begin
         l := Length(nkeys);
         SetLength(nkeys,l+1);
         nkeys[l] := i;
         break;
        end;
     Result := l >= 0;
    until not Result;
   end;

   function CheckList(const vnm:string;var nkeys:TArrOfStr):boolean;
   var
    l:integer;
   begin
    Result := ValName = vnm; if not Result then exit;
    repeat
      GetNext;
      if ikey = '' then break;
      l := Length(nkeys);
      SetLength(nkeys,l+1);
      nkeys[l] := ikey;
      Result := True;
    until False;
   end;

   function CheckI(const vnm:string;const keys:TArrOfStr;var nkey:integer):boolean;
   var
    i:integer;
   begin
    Result := ValName = vnm; if not Result then exit;
    for i := 0 to Length(keys)-1 do
     if keys[i] = ValVal then
      begin
       nkey := i;
       Result := True;
       exit;
      end;
   end;

   function CheckFnexts(var fnexts:TArrOfInt):boolean;
   var
    l:integer;
   begin
   Result := ValName = 'fnext'; if not Result then exit;
   l := 0;
   repeat
     GetNext;
     if ikey = '' then break;
     SetLength(fnexts,l+1);
     fnexts[l] := AddName(ikey,FSfnext);
     inc(l);
   until False;
   end;

  function CheckMatch:boolean;
  var
   level,mnum,l,offs,valui:integer;
   valu:string;
  begin
   Result := False;
   if Pos('match',ValName) <> 1 then exit;
   if Length(ValName) > 5 then
    begin
     if not TryStrToInt(Copy(ValName,6,Length(ValName)-5),level) then
      exit;
    end
   else
    level := 1;
   if level > Length(formatParams[SubSection].matches) + 1 then exit;
   l := Pos(':',ValVal); if l <= 1 then exit;
   if l >= Length(ValVal) then exit;
   if not TryStrToInt(Copy(ValVal,1,l-1),offs) or (offs < 0) then exit;
   if level > Length(formatParams[SubSection].matches) then
    begin
     SetLength(formatParams[SubSection].matches,level);
     formatParams[SubSection].matches[level-1] := nil;
    end;
   valu := '';
   repeat
     inc(l);
     if Ord(ValVal[l]) > 127 then exit;
     if ValVal[l] <> '#' then
      valu := valu + ValVal[l]
     else
      begin
       inc(l);
       if l > Length(ValVal) then exit;
       if ValVal[l] = '#' then
        valu := valu + '#'
       else
        begin
         valui := 0;
         repeat
          case ValVal[l] of
          '0'..'9':
           valui := valui*10 + Ord(ValVal[l])-Ord('0');
          ';':break;
          else
           exit;
          end;
          inc(l);
          if l > Length(ValVal) then exit;
         until False;
         if valui > 255 then exit;
         valu := valu + Char(valui);
        end;
      end;
   until l >= Length(ValVal);
   mnum := Length(formatParams[SubSection].matches[level-1]);
   SetLength(formatParams[SubSection].matches[level-1],mnum+1);
   formatParams[SubSection].matches[level-1][mnum].Offset:=offs;
   formatParams[SubSection].matches[level-1][mnum].Value:=valu;
   Result := True;
  end;

  var
   i:integer;
  begin
  Result := False;
  if SubSection < 0 then exit;
  i := Pos('=',s); if (i <= 1) or (i >= Length(s)) then
   exit;
  ValName := Copy(s,1,i-1); ValVal := Copy(s,i+1,Length(s)-i);
  case Section of
  FScommand:
    begin
      if not Check('name',commandParams[SubSection].name) then
       if not Check('param',commandParams[SubSection].param) then
        if not CheckLang('visname',commandParams[SubSection].visname) then
         if not CheckN('pref',10,commandParams[SubSection].pref) then
          exit;
      Result := True;
    end;
  FSgroup:
    begin
      if not CheckListI('types',SubSections[FStype],groupParams[SubSection].types) then
       if not CheckListI('commands',SubSections[FScommand],groupParams[SubSection].commands) then
        if not CheckLang('desc',groupParams[SubSection].desc) then
         exit;
      Result := True;
    end;
  FSfnext:
   begin
     if not CheckLang('desc',fnextParams[SubSection].desc) then
      exit;
     Result := True;
   end;
  FSformat:
    begin
      if not CheckI('type',SubSections[FStype],formatParams[SubSection].tp) then
       if not CheckList('mimetype',formatParams[SubSection].mimetypes) then
        if not CheckFnexts(formatParams[SubSection].fnext) then
         if not CheckLang('desc',formatParams[SubSection].desc) then
          if not Check('editor',formatParams[SubSection].editor) then
           if not CheckN('matchprior',100,formatParams[SubSection].matchprior) then
            if not CheckMatch then
             exit;
      Result := True;
    end;
  end;
  end;

var
 rs:TResourceStream;
 URHandle,line:integer;
begin
 FillChar(FT,SizeOf(FT),255);
 rs := TResourceStream.Create(HInstance,'FILETYPES',RT_RCDATA);
 UniReadInit(URHandle,URMemory,'',rs.Memory,rs.Size);
 UniReadersData[URHandle]^.UniCharCode := UCCUtf8;
 try
  line := 0;
  while UniReadersData[URHandle]^.UniOffset < UniReadersData[URHandle]^.UniDataSize do
   begin
    UniReadLnUtf8(URHandle,s);
    inc(line);
    if (s = '') or (s[1] = '#') then continue;
    if not SetSection then
     if not SetSectionValue then
      begin
       ShowMessage(Mes_AYEmulFmtLoadError + ' '+IntToStr(line));
       Halt(1);
      end;
   end;
 finally
  UniReadClose(URHandle);
  rs.Free;
 end;
end;

initialization

load_formats;

finalization

end.

