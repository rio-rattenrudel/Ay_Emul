{
This is part of AY Emulator project
AY-3-8910/12 Emulator
Version 3.0 for Windows and Linux
Author Sergey Vladimirovich Bulba
(c)1999-2025 S.V.Bulba
}

unit UniReader;

{$mode objfpc}{$H+}

interface

uses
 SysUtils, LazFileUtils;

const
 BufferSize = 32768;
 MaxHandle = 2;

type

 PReadBlock = ^TReadBlock;
 TReader = procedure(Handle:integer;PBuffer:pointer;Size:Int64;Reader:PReadBlock);
 TReadBlock = record
  Depacker:TReader;
  Closer:procedure;
  Next:PReadBlock;
 end;

 UniReaders = (URFile,URMemory);
 UniDepacker = (UDLZH);
 UniDepackers = array of UniDepacker;
 UniCharCodes = (UCCUnknown,UCCAnsi,UCCOem,UCCUtf8,UCCUtf16fffe,UCCUtf16feff);

 PUniReadersData = ^TUniReadersData;
 TUniReadersData = record
  UniType:UniReaders;
  ReadersRoot:PReadBlock;
  UniFilePos,UniFileSize,UniOffset,UniDataSize:Int64;
  UniFile:THandle;
  FileBuffer:array[0..BufferSize - 1] of byte;
  DirectReader:TReadBlock;
  BufferPos,BufferReaden:integer;
  UniMemory:pointer;
  UniCharCode:UniCharCodes;
  UniPrevReadLn:string;
 end;

var
 UniReadersData:array[0..MaxHandle] of PUniReadersData = (nil,nil,nil);

 procedure UniRead(Handle:integer;PBuf:pointer;Size:integer);
 procedure UniReadLnUtf8(Handle:integer;var s:string);
 procedure UniDetectCharCode(Handle:integer);//don't use with depackers
 procedure UniReadInit(var Handle:integer;Reader:UniReaders;FileName:string;pMem:pointer;DataSize:integer);
 procedure UniReadClose(Handle:integer);
 procedure UniAddDepacker(Handle:integer;UD:UniDepacker);
 procedure UniFileSeek(Handle:integer;Pos:Int64);

 procedure FileSeekTry(Handle:THandle;FOffset:Int64);
 function FileReadTry(Handle:THandle;out Buffer;Count:Int64):Int64;
 function FileGetCurrentOffset(Handle:THandle):Int64;

implementation

uses
 LH5, Languages, Convs, LazUtf8, sometypes;

procedure ReadDataBlockFromFile(Handle:integer;PBuffer:pointer;Size:Int64;
                                Reader:PReadBlock);
var
 Readen:integer;
begin
if Size = 0 then exit;
with UniReadersData[Handle]^ do
if BufferPos = BufferReaden then
 begin
  if Size >= BufferSize then
   begin
    Readen := FileReadTry(UniFile,PBuffer^,Size);
    if Readen < Size then
     raise Exception.Create(Mes_ReadAfterEndOfFile);
    inc(UniFilePos,Size);
   end
  else
   begin
    BufferReaden := FileReadTry(UniFile,FileBuffer,BufferSize);
    if BufferReaden < Size then
     raise Exception.Create(Mes_ReadAfterEndOfFile);
    Move(FileBuffer,PBuffer^,Size);
    BufferPos := Size;
    inc(UniFilePos,Size);
   end;
 end
else
 begin
  if Size <= Int64(BufferReaden) - Int64(BufferPos) then
   begin
    Move(FileBuffer[BufferPos],PBuffer^,Size);
    inc(BufferPos,Size);
    inc(UniFilePos,Size);
   end
  else
   begin
    Readen := BufferReaden - BufferPos;
    Move(FileBuffer[BufferPos],PBuffer^,Readen);
    BufferPos := BufferReaden;
    inc(UniFilePos,Readen);
    ReadDataBlockFromFile(Handle,@PArray0OfByte(PBuffer)[Readen],Size - Readen,nil);
   end;
 end;
end;

procedure UniFileSeek(Handle:integer;Pos:Int64);
var
 NewBufferPos:Int64;
begin
with UniReadersData[Handle]^ do
 begin
  if UniFilePos = Pos then exit;
  if Pos > UniFileSize then
   raise Exception.Create(Mes_SeekAfterEndOfFile);
  NewBufferPos := Int64(BufferPos) + Pos - UniFilePos;
  UniFilePos := Pos;
  if (NewBufferPos >= 0) and (NewBufferPos < Int64(BufferReaden)) then
   BufferPos := NewBufferPos
  else
   begin
    FileSeekTry(UniFile,Pos);
    BufferPos := BufferReaden;
   end;
 end;
end;

procedure ReadDataBlockFromMemory(Handle:integer;PBuffer:pointer;Size:Int64;
                                Reader:PReadBlock);
begin
with UniReadersData[Handle]^ do
 begin
  if UniOffset + Size > UniDataSize then
   raise Exception.Create(Mes_ReadAfterEndOfData);
  Move(PArray0OfByte(UniMemory)[UniOffset],PBuffer^,Size);
  Inc(UniOffset,Size);
 end;
end;

procedure UniRead(Handle:integer;PBuf:pointer;Size:integer);
begin
with UniReadersData[Handle]^.ReadersRoot^ do
 Depacker(Handle,PBuf,Size,Next);
end;

procedure UniReadLnUtf8(Handle:integer;var s:string);
var
 sa:string;
 x0D,x0A:boolean;

 procedure AddChar(Force:boolean);
 var
  ch1,ch2:char;
 begin
 case UniReadersData[Handle]^.UniCharCode of
 UCCUtf16fffe:
  begin
   try
    UniRead(Handle,@ch1,1);UniRead(Handle,@ch2,1);
   except
    x0D := True; x0A := True; exit;
   end;
   if (ch1 = #13) and (ch2 = #0) then x0D := True;
   if (ch1 = #10) and (ch2 = #0) then x0A := True;
   if (not x0D and not x0A) or Force then sa := sa + ch1 + ch2;
  end;
  UCCUtf16feff:
   begin
    try
     UniRead(Handle,@ch1,1);UniRead(Handle,@ch2,1);
    except
     x0D := True; x0A := True; exit;
    end;
    if (ch1 = #0) and (ch2 = #13) then x0D := True;
    if (ch1 = #0) and (ch2 = #10) then x0A := True;
    if(not x0D and not x0A) or Force then sa := sa + ch2 + ch1;
   end;
  else
    begin
     try
      UniRead(Handle,@ch1,1);
     except
      x0D := True; x0A := True; exit;
     end;
     if ch1 = #13 then x0D := True;
     if ch1 = #10 then x0A := True;
     if (not x0D and not x0A) or Force then sa := sa + ch1;
    end;
 end;
 end;

 procedure CnvStr;
 begin
 case UniReadersData[Handle]^.UniCharCode of
 UCCUnknown:
  begin
   if ASCII(sa) then exit;
   if FindInvalidUTF8Codepoint(pchar(sa),length(sa)) >= 0 then
    sa := CPToUTF8(sa) //todo: charcode detector
   else
    UniReadersData[Handle]^.UniCharCode := UCCUtf8;
  end;
 UCCUtf16fffe,UCCUtf16feff:
  begin
   sa := sa + #0#0;
   sa := UTF8Encode(WideString(PWideChar(@sa[1])));
  end;
 UCCUtf8:;
 else
  sa := CPToUTF8(sa);
 end;
 end;

begin
s := UniReadersData[Handle]^.UniPrevReadLn; UniReadersData[Handle]^.UniPrevReadLn := '';
if (s = #13) or (s = #10) then
 begin
  s := ''; exit;
 end;
sa := ''; x0D := False; x0A := False;
repeat
 AddChar(False);
until x0D or x0A;
CnvStr; s := s + sa;
if x0D and x0A then exit;
sa := ''; AddChar(True);
if x0D and x0A then exit;
CnvStr; UniReadersData[Handle]^.UniPrevReadLn := sa;
end;

procedure UniDetectCharCode(Handle:integer);//don't use if depacker added
var
  Chars:array[0..2] of byte;
  Offs:integer;
begin
Offs := 0; UniReadersData[Handle]^.UniCharCode:=UCCUnknown;
try
 try
  UniRead(Handle,@Chars[0],3);
 except
  exit;
 end;
if (Chars[0] = $FF) and (Chars[1] = $FE) then
 begin
  UniReadersData[Handle]^.UniCharCode:=UCCUtf16fffe;
  Offs := 2;
 end
else if (Chars[0] = $FE) and (Chars[1] = $FF) then
 begin
  UniReadersData[Handle]^.UniCharCode:=UCCUtf16feff;
  Offs := 2;
 end
else if (Chars[0] = $EF) and (Chars[1] = $BB) and (Chars[2] = $BF) then
 begin
  UniReadersData[Handle]^.UniCharCode:=UCCUtf8;
  Offs := 3;
 end;
finally
 case UniReadersData[Handle]^.UniType of
 URMemory:UniReadersData[Handle]^.UniOffset := Offs;
 URFile:UniFileSeek(Handle,Offs);
 end;
end;
end;

procedure UniReadInit(var Handle:integer;Reader:UniReaders;FileName:string;pMem:pointer;DataSize:integer);
var
 i:integer;
begin
for i := 0 to MaxHandle do
 if UniReadersData[i] = nil then
  begin
   Handle := i;
   break
  end;
New(UniReadersData[Handle]);
with UniReadersData[Handle]^ do
 begin
  UniType := Reader;
  UniCharCode := UCCUnknown;
  UniPrevReadLn := '';
  case Reader of
  URFile:
   begin
    UniFilePos := 0;
    BufferPos := 0;
    BufferReaden := 0;
    UniFile := FileOpen(FileName,fmOpenRead or fmShareDenyWrite);
    if UniFile = THandle(-1) then
     raise Exception.Create(Mes_FileOpenError);
    UniFileSize := FileSizeUTF8(FileName);
    if (DataSize >= 0) and (DataSize < UniFileSize) then
     UniDataSize := DataSize
    else
     UniDataSize := UniFileSize;
    with DirectReader do
     begin
      Depacker := @ReadDataBlockFromFile;
      Next := nil;
     end;
   end;
  URMemory:
   begin
    UniMemory := pMem;
    UniOffset := 0;
    UniDataSize := DataSize;
    with DirectReader do
     begin
      Depacker := @ReadDataBlockFromMemory;
      Next := nil;
     end;
   end;
  end;
  ReadersRoot := @DirectReader;
 end;
end;

procedure UniReadClose(Handle:integer);
var
 DepackerReader,p:PReadBlock;
begin
with UniReadersData[Handle]^ do
 begin
  if UniType = URFile then
  FileClose(UniFile);
  DepackerReader := ReadersRoot;
  p := DepackerReader^.Next;
  while p <> nil do
   begin
    DepackerReader^.Closer;
    Dispose(DepackerReader);
    DepackerReader := p;
    p := DepackerReader^.Next;
   end
 end;
Dispose(UniReadersData[Handle]);
UniReadersData[Handle] := nil;
end;

procedure UniAddDepacker(Handle:integer;UD:UniDepacker);
var
 DepackerReader:PReadBlock;
begin
with UniReadersData[Handle]^ do
case UD of
UDLZH:
  begin
   New(DepackerReader);
   with DepackerReader^ do
    begin
     Depacker := @LZHDepacker;
     Closer := @LZHDepackerDone;
     Next := ReadersRoot;
    end;
   InitLZHDepacker(Handle,ReadersRoot);
   ReadersRoot := DepackerReader;
  end;
end;
end;

procedure FileSeekTry(Handle:THandle;FOffset:Int64);
begin
if FileSeek(Handle,FOffset,fsFromBeginning) = -1 then
 raise Exception.Create(Mes_FileSeekError);
end;

function FileReadTry(Handle:THandle;out Buffer;Count:Int64):Int64;
begin
Result := FileRead(Handle,Buffer,Count);
if Result = -1 then
 raise Exception.Create(Mes_FileReadError);
end;

function FileGetCurrentOffset(Handle:THandle):Int64;
begin
Result := FileSeek(Handle,0,fsFromCurrent);
if Result = -1 then
 raise Exception.Create(Mes_FileSeekError);
end;

end.
