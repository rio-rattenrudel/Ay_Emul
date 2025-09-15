//Micro ST beta version 10
//Author Sergey Bulba, svbulba@gmail.com, http://bulba.untergrund.net
//(c)2001-2017 Bulba S.V.

type
  PSTARSCREAM_PROGRAMREGION = ^TSTARSCREAM_PROGRAMREGION;
  TSTARSCREAM_PROGRAMREGION = record
   lowaddr,highaddr:longword;
   offset:pointer;
  end;

  PSTARSCREAM_DATAREGION = ^TSTARSCREAM_DATAREGION;
  TSTARSCREAM_DATAREGION = record
   lowaddr,highaddr:longword;
   memorycall,userdata:pointer;
  end;

  TS68000CONTEXT = record
   fetch:PSTARSCREAM_PROGRAMREGION;
   readbyte,readword,writebyte,writeword:PSTARSCREAM_DATAREGION;
   s_fetch:PSTARSCREAM_PROGRAMREGION;
   s_readbyte,s_readword,s_writebyte,s_writeword:PSTARSCREAM_DATAREGION;
   u_fetch:PSTARSCREAM_PROGRAMREGION;
   u_readbyte,u_readword,u_writebyte,u_writeword:PSTARSCREAM_DATAREGION;
   resethandler:procedure;
   dreg,areg:array[0..7] of longword;
   asp,pc,odometer:longword;
   interrupts:array[0..7] of byte;
   sr:word;
   contextfiller00:word;
  end;

function s68000init:integer;external name '_s68000init';
function s68000reset:longword;external name '_s68000reset';
function s68000exec(n:integer):longword;external name '_s68000exec';
function s68000interrupt(level,vector:integer):integer;external name '_s68000interrupt';
procedure s68000flushInterrupts;external name '_s68000flushInterrupts';
function s68000GetContextSize:integer;external name '_s68000GetContextSize';
procedure s68000GetContext(context:pointer);external name '_s68000GetContext';
procedure s68000SetContext(context:pointer);external name '_s68000SetContext';
function s68000fetch(address:longword):integer;external name '_s68000fetch';
function s68000readOdometer:longword;external name '_s68000readOdometer';
function s68000tripOdometer:longword;external name '_s68000tripOdometer';
function s68000controlOdometer(n:integer):longword;external name '_s68000controlOdometer';
procedure s68000releaseTimeslice;external name '_s68000releaseTimeslice';
function s68000readPC:longword;external name '_s68000readPC';
{$ifdef DebugI}
function cpudebug_interactive(cpun:integer;p1,p2,p3,p4:pointer):integer; cdecl;external;
{$endif}

var
  s68000context:TS68000CONTEXT; external name '_s68000context';

{$ifdef Windows}
{$ifdef cpu64}
{$L Starcpu64W.o}
{$else}
{$L Starcpu32W.o}
{$endif}
{$else}
{$ifdef cpu64}
{$L Starcpu64L.o}
{$else}
{$L Starcpu32L.o}
{$endif}
{$endif}

{$ifdef DebugI}
{$ifdef Windows}
//function AllocConsole:LongBool; stdcall; external 'kernel32.dll';
{$ifdef cpu64}
{$L cpudebug64W.o}
{$else}
{$linklib C:\libs\MinGW\lib\libcrtdll.a}
{$L cpudebug32W.o}
{$endif}
{$else}
{$ifdef cpu64}
{$L cpudebug64L.o}
{$else}
{$L cpudebug32L.o}
{$endif}
{$endif}
{$endif}

