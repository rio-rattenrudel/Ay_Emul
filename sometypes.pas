unit sometypes;

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils;

type
  TArrayOfByte = array of byte;
  TArrayOfInteger = array of integer;
  TArrayOfString = array of string;

  PArray0OfByte = PByte; {^TArray0OfByte;
  TArray0OfByte = packed array[0..0] of byte;}

implementation

end.

