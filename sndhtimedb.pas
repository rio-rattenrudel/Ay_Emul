{
This is part of AY Emulator project
AY-3-8910/12 Emulator
Version 3.0 for Windows and Linux
Author Sergey Vladimirovich Bulba
(c)1999-2025 S.V.Bulba
}

unit SNDHTimeDB;

{
Loads and works with duration database in timedb.inc.h of SC68's SNDH music
duration database. Copyright (c) 1998-2020 Benjamin Gerard.

Used if SNDH-file either has no duration data in header or has but need correction.

You can look for data base updates here:
https://sourceforge.net/p/sc68/code/HEAD/tree/file68/src/timedb.inc.h
}

interface

uses
 SysUtils,Dialogs;

procedure SNDHTimeDBInit;
procedure hash68(data:PByte;len:integer;var hash:longword);
procedure SNDHTimeDBSeek(aHash:longword;aTune:integer;out aTime:integer);

var
 SNDHTimeDBLoaded:boolean = False;

implementation

type
 SNDHTimeDBItem = record
   case Integer of
   0:(All:qword);
   1:(timeloword:word;
      timehibyte,tune:byte;
      hash:longword);
   2:(lo,hi:longword);
 end;

const
 RecSz = SizeOf(SNDHTimeDBItem);

var
  SNDHTimeDBItems:array of SNDHTimeDBItem;

//Based on function from file68.c from //http://sourceforge.net/users/benjihan
//(Copyright (c) 1998-2016 Benjamin Gerard)
//
//For first piece of data call with hash=0
procedure hash68(data:PByte;len:integer;var hash:longword);
begin
while len > 0 do
 begin
   hash := hash + data^; Inc(data);
   hash := hash + (hash shl 10);
   hash := hash xor (hash shr 6);
   Dec(len);
 end;
end;

function CompareStrMem(const s:string;p:pointer):boolean;inline;
begin
Result:=CompareMem(@s[1],p,Length(s));
end;

procedure QuickSortSNDHTimeDB(L,R:Integer);
var
  I, J, P: Integer;
  N:Int64;
begin
  repeat
    I := L;
    J := R;
    P := (L + R) shr 1;
    repeat
      while SNDHTimeDBItems[I].All < SNDHTimeDBItems[P].All do Inc(I);
      while SNDHTimeDBItems[J].All > SNDHTimeDBItems[P].All do Dec(J);
      if I <= J then
      begin
        N := SNDHTimeDBItems[J].All;
        SNDHTimeDBItems[J].All := SNDHTimeDBItems[I].All;
        SNDHTimeDBItems[I].All := N;
        if P = I then
          P := J
        else if P = J then
          P := I;
        Inc(I);
        Dec(J);
      end;
    until I > J;
    if L < J then QuickSortSNDHTimeDB(L, J);
    L := I;
  until I >= R;
end;

function SNDHTimeDBLoadTxt(const fn:string):boolean;
const
 Hdr = ' TIMEDB_ENTRY( ';
var
 Item:integer;

 procedure Err(const mes:string='');
 var
  s:string;
 begin
 s := 'timedb.inc.h error in line '+IntToStr(Item+1);
 if mes <> '' then
  s := s + ': '+ mes;
 ShowMessage(s);
 Result := False;
 end;

var
 f:Text;
 s:string;
 i:integer;

begin
Result := True;
Item := 0;
try
 AssignFile(f,FN);
 Reset(f);
 try
  while not eof(f) do
   begin
    if (Item mod 1024) = 0 then
     SetLength(SNDHTimeDBItems,Item+1024);
    Readln(f,s);
    if Length(s) < 61 then //minimum if without comment
     begin
      Err('too short'); Break;
     end;
    if not CompareStrMem(Hdr, @s[1]) then
     begin
      Err('"'+Hdr+'" absent'); Break;
     end;
    if not TryStrToInt('$'+Copy(s,16,8),i) then
     begin
      Err('bad hash'); Break;
     end;
    SNDHTimeDBItems[Item].hash := i;
    if not TryStrToInt(TrimLeft(Copy(s,25,3)),i) or (i <= 0) or (i > $100) then //6 bits in SC68
     begin
      Err('bad tune number'); Break;
     end;
    SNDHTimeDBItems[Item].tune := i-1;
    if not TryStrToInt(TrimLeft(Copy(s,29,10)),i) or (i <= 0) or (i > $FFFFFF) then //20 bits in SC68
     begin
      Err('bad duration'); Break;
     end;
    SNDHTimeDBItems[Item].timeloword := i;
    SNDHTimeDBItems[Item].timehibyte := Hi(i);
    Inc(Item);
   end;
 finally
  Close(f);
 end;
except
 Err;
end;
if Item >= 0 then
 SetLength(SNDHTimeDBItems,Item);
if Item > 1 then
 QuickSortSNDHTimeDB(0,Item-1);
SNDHTimeDBLoaded := Result;
end;

function SNDHTimeDBSave(const fn:string):boolean;
var
 f:file;
begin
Result := True;
try
 Assign(f,fn);
 Rewrite(f,1);
 try
  BlockWrite(f,SNDHTimeDBItems[0],Length(SNDHTimeDBItems)*RecSz);
 finally
  Close(f);
 end;
except
 Result := False;
end;
end;

procedure SNDHTimeDBLoad(const fn:string);
var
 f:file;
 sz:Int64;
begin
if not FileExists(fn) then
 Exit;
try
 Assign(f,fn);
 Reset(f,1);
 try
  sz := FileSize(f);
  if (sz > 0) and (sz mod RecSz = 0) then
   begin
    SetLength(SNDHTimeDBItems,sz div RecSz);
    BlockRead(f,SNDHTimeDBItems[0],sz);
    SNDHTimeDBLoaded := True;
   end;
 finally
  Close(f);
 end;
except
end;
end;

procedure SNDHTimeDBInit;
var
 fnt,fn:string;
begin
fn := ExtractFilePath(ParamStr(0));
fnt := fn + 'timedb.inc.h'; fn := fn + 'sndhtimedb';
if FileExists(fnt) then
 if not FileExists(fn) or (FileAge(fnt) <> FileAge(fn)) then
  begin
   if SNDHTimeDBLoadTxt(fnt) then
    if SNDHTimeDBSave(fn) then
     FileSetDate(fn,FileAge(fnt));
   Exit;
  end;
SNDHTimeDBLoad(fn);
end;

procedure SNDHTimeDBSeek(aHash:longword;aTune:integer;out aTime:integer);
var
 low,high,mid:integer;
 midVal,key:SNDHTimeDBItem;
begin
low := 0; high := Length(SNDHTimeDBItems)-1;
key.hash := aHash; key.lo := 0; key.tune:= aTune;

while low <= high do
 begin
  mid := low + (high - low) div 2;
  midVal.All := SNDHTimeDBItems[mid].All and $ffffffffff000000;

  if midVal.All < key.All then
   low := mid + 1
  else if midVal.All > key.All then
   high := mid - 1
  else
   begin
    aTime := SNDHTimeDBItems[mid].All and $ffffff;
    Exit;
   end;
 end;
end;

end.
