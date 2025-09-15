{
This is part of AY Emulator project
AY-3-8910/12 Emulator
Version 3.0 for Windows and Linux
Author Sergey Vladimirovich Bulba
(c)1999-2025 S.V.Bulba
}

unit basstags;

{$mode objfpc}{$H+}

{ $define debugmeta}

interface

uses
 Classes, SysUtils, lazutf8, basslight;

type
 TTags = record
   Title, Artist, Comment, Date: string;
 end;

function TAGS_Read_Meta(handle: HStream; var Tags: TTags): boolean;
function TAGS_Read(handle: HStream; var Tags: TTags; APE: boolean): boolean;

implementation

uses
 Convs;

type
 TagTypes = (ID3V1, ID3V2, OGG, WMA, APEV1, APEV2, HTTP, ICY);
 PID3v1 = ^TID3v1;

 TID3v1 = packed record
   Tag: array[0..2] of char;
   Title, Author, Album: array[0..29] of char;
   Year: array[0..3] of char;
   Comment: array[0..29] of char;
   Genre: byte;
 end;
 PID3V2Header = ^TID3V2Header;

 TID3V2Header = packed record
   Tag: array[0..2] of char;
   VerMajor, VerMinor, Flags: byte;
   Size: DWORD;
 end;
 PID3V23ExtHeader = ^TID3V23ExtHeader;

 TID3V23ExtHeader = packed record
   Size: DWORD;
   Flags: word;
   PaddingSize: DWORD;
 end;
 PID3V24ExtHeader = ^TID3V24ExtHeader;

 TID3V24ExtHeader = packed record
   Size: DWORD;
   NFlags, Flags: byte;
 end;
 PID3V2Frame = ^TID3V2Frame;

 TID3V2Frame = packed record
   Id, Size: DWORD;
   Flags: word;
 end;
 PA = ^TA;
 TA = packed array [0..0] of byte;
 STags = array[0..3] of string;

const
 BassTagTypes: array[TagTypes] of DWORD =
   (BASS_TAG_ID3, BASS_TAG_ID3V2, BASS_TAG_OGG, BASS_TAG_WMA, BASS_TAG_APE,
   BASS_TAG_APE, BASS_TAG_HTTP, BASS_TAG_ICY);
 OGGTags: STags = ('TITLE', 'ARTIST', 'COMMENT', 'DATE');
 WMATags: STags = ('TITLE', 'AUTHOR', 'DESCRIPTION', 'WM/YEAR');
 APETags: STags = ('TITLE', 'ARTIST', 'COMMENT', 'YEAR');
 ICYTags: STags = ('ICY-NAME', '', 'ICY-DESCRIPTION', '');

function ExtractID3V2Tags(p: pointer; var Tags: TTags): boolean;
const
 MaxHSize = 1000000; //temporary
 TIT2 = $32544954; //title
 TPE1 = $31455054; //artist
 COMM = $4d4d4f43; //comment
 TYER = $52455954; //year
 TDRC = $43524454; //recording time
type
 TSz = packed array [0..3] of byte;

 function TagSize(sz: DWORD): DWORD;
 begin
   Result := TSz(sz)[3] + TSz(sz)[2] * 128 + TSz(sz)[1] * 128 * 128 + TSz(sz)[0] * 128 * 128 * 128;
 end;

 function BLDWORD(sz: DWORD): DWORD;
 begin
   Result := TSz(sz)[3] + TSz(sz)[2] * 256 + TSz(sz)[1] * 256 * 256 + TSz(sz)[0] * 256 * 256 * 256;
 end;

 function ValidId(sz: DWORD): boolean;
 type
   TCh = packed array [0..3] of char;
 begin
   Result := (TCh(sz)[0] in ['0'..'9', 'A'..'Z']) and
     (TCh(sz)[1] in ['0'..'9', 'A'..'Z']) and
     (TCh(sz)[2] in ['0'..'9', 'A'..'Z']) and
     (TCh(sz)[3] in ['0'..'9', 'A'..'Z']);
 end;

 function DecodeSynchronized(p: PChar; sz: integer): string;
 var
   i: integer;
   ff: boolean;
 begin
   Result := '';
   if sz = 0 then exit;
   ff := False;
   for i := 0 to sz - 1 do
    begin
     if (p^ <> #0) or not ff then
       Result := Result + p^;
     ff := p^ = #$ff;
     Inc(p);
    end;
 end;

 function PO(ofs: DWORD): pointer;
 begin
   Result := @PA(p)^[ofs];
 end;

 function TextId23(Id: DWORD): boolean;
 begin
   Result := (Id = TIT2) or (Id = TPE1) or (Id = TYER);
 end;

 function TextId24(Id: DWORD): boolean;
 begin
   Result := (Id = TIT2) or (Id = TPE1) or (Id = TDRC);
 end;

var
 TempTags: TTags;

 procedure ExtractString(Id: DWORD; p: pointer; sz: integer; enc: byte);
 var
   s: string;
   c: char;
   i, j: integer;
 begin
   if ((enc = 1) and (sz < 4)) or ((enc = 2) and (sz < 2)) or
     ((enc in [1, 2]) and (sz and 1 <> 0)) then exit;
   SetLength(s, sz);
   move(p^, s[1], sz);
   case enc of
     0, 3: //ansi, utf-8
      begin
       if Id = COMM then
         for i := 1 to sz - 1 do
           if s[i] = #0 then s[i] := #10;
       s := s + #0;
       if enc = 0 then
         s := CPToUTF8(Trim(PChar(s)))
       else
         s := UTF8Trim(PChar(s));
      end;
     1, 2: //unicode
      begin
       j := 2;
       if enc = 2 then j := 0;
       if (enc = 2) or ((s[1] = #$FE) and (s[2] = #$FF)) then
        begin
         for i := 1 to (sz - j) div 2 do
          begin
           c := s[i * 2 + j - 1];
           s[i * 2 + j - 1] := s[i * 2 + j];
           s[i * 2 + j] := c;
          end;
        end
       else if (s[1] <> #$FF) or (s[2] <> #$FE) then exit;
       if Id = COMM then
         for i := 1 to sz div 2 - 1 do
           if (s[i * 2 - 1] = #0) and (s[i * 2] = #0) then s[i * 2 - 1] := #10;
       s := s + #0#0;
       s := UTF8Encode(Trim(WideString(pwidechar(@s[j + 1]))));
      end;
    end;
   case Id of
     TIT2:
       TempTags.Title := s;
     TPE1:
       TempTags.Artist := s;
     COMM:
       TempTags.Comment := s;
     TYER, TDRC:
       TempTags.Date := s;
    end;
 end;

var
 HSize, Ptr: DWORD;

 function Get23Tag: boolean;
 var
   i: integer;
   d, sz: DWORD;
   b: byte;
 begin
   Result := False;
   if PID3V2Header(p)^.Flags and $40 <> 0 then
     with PID3V23ExtHeader(PO(Ptr))^ do
      begin
       d := BLDWORD(PaddingSize);
       if HSize <= d then exit;
       Dec(HSize, d);
       Inc(Ptr, 4 + BLDWORD(Size));
      end;
   if Ptr + SizeOf(TID3V2Frame) > HSize then exit;
   repeat
     with PID3V2Frame(PO(Ptr))^ do
      begin
       if Id = 0 then break;
       if not ValidId(Id) or (Size = 0) or (Flags and %1111100011111 <> 0) then exit;
       sz := BLDWORD(Size);
       if Ptr + SizeOf(TID3V2Frame) + sz > HSize then exit;
       if ((Flags and %1100000000000000) = 0) then //not encrypted and not compressed
        begin
         i := Ord((Flags and %10000000000000) <> 0); //is group byte?
         if TextId23(Id) or (Id = COMM) then
          begin
           d := Ptr + SizeOf(TID3V2Frame) + DWORD(i);
           b := pbyte(PO(d))^;
           if not (b in [0, 1]) then exit;
           if Id = COMM then
            begin
             Inc(i, 3);
             Inc(d, 3);
            end;
           i := sz - i - 1;
           if i < 0 then exit;
           if i <> 0 then ExtractString(Id, PO(d + 1), i, b);
          end;
        end;
       Inc(Ptr, sz + SizeOf(TID3V2Frame));
      end;
   until Ptr + SizeOf(TID3V2Frame) > HSize;
   Result := True;
 end;

 function Get24Tag(DecodeSync: boolean): boolean;
 var
   i: integer;
   d, sz, sz1: DWORD;
   b: byte;
   s: string;
   f: pointer;
 begin
   Result := False;
   if PID3V2Header(p)^.Flags and $40 <> 0 then
     with PID3V24ExtHeader(PO(Ptr))^ do
      begin
       if (NFlags <> 1) or (Flags and %10001111 <> 0) or (Size and $80808080 <> 0) then
         exit;
       Inc(Ptr, TagSize(Size));
      end;
   if PID3V2Header(p)^.Flags and $10 <> 0 then
    begin
     if HSize <= 10 then exit;
     Dec(HSize, 10);
    end;
   if Ptr + SizeOf(TID3V2Frame) > HSize then exit;
   repeat
     with PID3V2Frame(PO(Ptr))^ do
      begin
       if Id = 0 then break;
       if not ValidId(Id) or (Size = 0) or (Size and $80808080 <> 0) or
         (Flags and %1011000010001111 <> 0) then exit;
       sz := TagSize(Size);
       if Ptr + SizeOf(TID3V2Frame) + sz > HSize then exit;
       if ((Flags and %110000000000) = 0) then //not encrypted and not compressed
        begin
         i := Ord((Flags and %100000000000000) <> 0); //is group byte?
         if (Flags and %100000000) <> 0 then Inc(i, 4); //is data length?
         if TextId24(Id) or (Id = COMM) then
          begin
           f := PO(Ptr + SizeOf(TID3V2Frame));
           sz1 := sz;
           if DecodeSync or ((Flags and %1000000000) <> 0) then
            begin
             s := DecodeSynchronized(f, sz);
             f := @s[1];
             sz1 := Length(s);
            end;
           b := PA(f)^[i];
           if not (b in [0..3]) then exit;
           Inc(i);
           if Id = COMM then Inc(i, 3);
           d := i;
           i := sz1 - i;
           if i < 0 then exit;
           if i <> 0 then ExtractString(Id, @PA(f)^[d], i, b);
          end;
        end;
       Inc(Ptr, sz + SizeOf(TID3V2Frame));
      end;
   until Ptr + SizeOf(TID3V2Frame) > HSize;
   Result := True;
 end;

var
 s: string;
begin
 Result := False;
  try
   with PID3V2Header(p)^ do
    begin
     //validation
     if Tag <> 'ID3' then exit;
     if VerMajor > 4 then exit;
     if VerMinor = 255 then exit;
     if VerMajor < 4 then
      begin
       if Flags and %111111 <> 0 then exit;
      end
     else
     if Flags and %11111 <> 0 then exit;
     if Size and $80808080 <> 0 then exit;
     HSize := TagSize(Size) + 10;
     if HSize > MaxHSize then exit;
     Ptr := 10;
     TempTags.Artist := '';
     TempTags.Title := '';
     TempTags.Comment := '';
     TempTags.Date := '';
     if VerMajor < 4 then
      begin
       if Flags and $80 <> 0 then //Unsynchronisation
        begin
         s := DecodeSynchronized(PO(10), HSize - 10);
         p := @s[1];
         HSize := Length(s);
         Ptr := 0;
        end;
       Result := Get23Tag;
      end
     else
       Result := Get24Tag(Flags and $80 <> 0);
    end;
   if Result then
    begin
     Tags.Title := TempTags.Title;
     Tags.Artist := TempTags.Artist;
     Tags.Comment := TempTags.Comment;
     Tags.Date := TempTags.Date;
    end;
  except
  end;
end;

function ExtractID3V1Tags(p: PID3v1; var Tags: TTags; Merge: boolean): boolean;
var
 s: string;

 function Prep: string;
 begin
   Result := CPToUTF8(Trim(PChar(s)));
 end;

begin
 Result := True;
 if not Merge or (Tags.Artist = '') then
  begin
   s := p^.Author;
   Tags.Artist := Prep;
  end;
 if not Merge or (Tags.Title = '') then
  begin
   s := p^.Title;
   Tags.Title := Prep;
  end;
 if not Merge or (Tags.Comment = '') then
  begin
   s := p^.Comment;
   Tags.Comment := Prep;
  end;
 if not Merge or (Tags.Date = '') then
  begin
   s := p^.Year;
   Tags.Date := Prep;
  end;
end;

function MergeID3V1Tags(handle: HStream; var Tags: TTags): boolean;
var
 p: PChar;
begin
 Result := False;
 p := BASS_ChannelGetTags(handle, BassTagTypes[ID3V1]);
 if p = nil then exit;
 Result := ExtractID3V1Tags(PID3v1(p), Tags, True);
end;

function ExtractUTF8Tags(p: PChar; var Tags: TTags;
 const ST: STags; Ch: char; CanANSI: boolean): boolean;
var
 tl, cl: longword;
 f: boolean;

 function GetString: string;
 begin
   SetLength(Result{%H-}, cl);
   Move(PA(p)^[tl + 1], Result[1], cl);
   if not CanANSI then
     Result := UTF8Trim(PChar(Result))
   else
    begin
     if FindInvalidUTF8Codepoint(PChar(Result), Length(Result)) >= 0 then
       Result := CPToUTF8(Trim(PChar(Result)));
    end;
   f := True;
 end;

var
 l: longword;
 Tag: string;
begin
 f := False;
 repeat
   l := StrLen(p);
   tl := 0;
   while (tl < l) and (PA(p)^[tl] <> Ord(Ch)) do Inc(tl);
   if (tl = l) or (tl = 0) then break;
   if tl < l - 1 then
    begin
     SetLength(Tag, tl);
     Move(p^, Tag[1], tl);
     cl := l - tl - 1;
     Tag := UpperCase(Tag);
     if Tag = ST[0] then
       Tags.Title := GetString
     else if Tag = ST[1] then
       Tags.Artist := GetString
     else if Tag = ST[2] then
       Tags.Comment := GetString
     else if Tag = ST[3] then
       Tags.Date := GetString;
     SetLength(Tag, 0);
    end;
   p := @PA(p)^[l + 1];
 until pbyte(p)^ = 0;
 Result := f;
end;

function ExtractShoutcastTags(p: PChar; var Tags: TTags): boolean;
begin
 p := @PA(p)^[StrLen(p) + 1];
 Result := ExtractUTF8Tags(p, Tags, ICYTags, ':', True);
end;

function ExtractTags(handle: HStream; TagType: TagTypes; var Tags: TTags): boolean;
var
 p: PChar;
begin
 Result := False;
 p := BASS_ChannelGetTags(handle, BassTagTypes[TagType]);
 if p = nil then exit;
 case TagType of
   ID3V1: Result := ExtractID3V1Tags(PID3v1(p), Tags, False);
   ID3V2: Result := ExtractID3V2Tags(p, Tags);
   OGG: Result := ExtractUTF8Tags(p, Tags, OGGTags, '=', False);
   WMA: Result := ExtractUTF8Tags(p, Tags, WMATags, '=', False);
   APEV1: Result := ExtractUTF8Tags(p, Tags, APETags, '=', True);
   APEV2: Result := ExtractUTF8Tags(p, Tags, APETags, '=', False);
   HTTP, ICY: Result := ExtractShoutcastTags(p, Tags);
  end;
end;

function TAGS_Read_META(handle: HStream; var Tags: TTags): boolean;
var
 s, s1: string;
 i: integer;

 {$ifdef debugmeta}
 f:TextFile;
 {$endif debugmeta}
begin
 Tags.Artist := '';
 Tags.Title := '';
 Tags.Comment := '';
 Tags.Date := '';
 Result := False;
 s := BASS_ChannelGetTags(handle, BASS_TAG_META);
 if s = '' then exit;

 {$ifdef debugmeta}
 AssignFile(f,ExtractFilePath(ParamStr{UTF8}(0))+'metatst.txt');
 if FileExists(ExtractFilePath(ParamStr{UTF8}(0))+'metatst.txt') then
  Append(f)
 else
  Rewrite(f);
 try
  Writeln(f,s);
 {$endif debugmeta}

 //too mach stations with bad meta strings, so trying to decode typical errors
 if Pos('StreamTitle=''', s) <> 1 then exit;
 s := Copy(s, 14, Length(s) - 13);
 i := Pos('StreamUrl=''', s) - 1;
 if i < 0 then i := Length(s);
 if i = 0 then exit;
 if s[i] = ';' then Dec(i);
 if i = 0 then exit;
 if s[i] = '''' then Dec(i);
 //if i = 0 then exit; //отсутствие результата - тоже результат
 SetLength(s, i);

 {$ifdef debugmeta}
  Writeln(f,s);
 {$endif debugmeta}

 //Пробуем анализировать как две подстроки, разделенные ' - '
 //"Неслабое радио" (http://stream0.radiostyle.ru:8000/neslaboe) таким разделителем
 //может и ANSI-строки разделить, и UTF16BE c BOM - дурдом в общем
 s1 := '';
 i := Pos(' - ', s);
 if i <> 0 then
  begin
   s1 := Copy(s, 1, i - 1);
   s := Copy(s, i + 3, Length(s) - i - 2);
  end;

 s1 := GarbageDecoder(s1);
 s := GarbageDecoder(s);

 //if (s1 = '') and (s = '') then exit; //см. выше ;)

 {$ifdef debugmeta}
  Writeln(f,UTF8ToCP(s1),' <-> ',UTF8ToCP(s));
 finally
  CloseFile(f);
 end;
 {$endif debugmeta}

 Tags.Artist := Trim(s1);
 Tags.Title := Trim(s);
 Result := True;
end;

function TAGS_Read(handle: HStream; var Tags: TTags; APE: boolean): boolean;
begin
 Tags.Artist := '';
 Tags.Title := '';
 Tags.Comment := '';
 Tags.Date := '';
 Result := ExtractTags(handle, ID3V2, Tags);
 Result := MergeID3V1Tags(handle, Tags) or Result;
 if not Result then
   Result := ExtractTags(handle, OGG, Tags);
 if not Result then
   Result := ExtractTags(handle, WMA, Tags);
 if not Result then
   if APE then
     Result := ExtractTags(handle, APEV1, Tags)  //BASS_APE
   else
     Result := ExtractTags(handle, APEV2, Tags); //BASSWV
 if not Result then
   Result := ExtractTags(handle, HTTP, Tags);
 if not Result then
   Result := ExtractTags(handle, ICY, Tags);
 if not Result then
   Result := TAGS_Read_Meta(handle, Tags);
end;

end.
