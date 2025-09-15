{
This is part of AY Emulator project
AY-3-8910/12 Emulator
Version 3.0 for Windows and Linux
Author Sergey Vladimirovich Bulba
(c)1999-2025 S.V.Bulba
}

program Ay_Emul;

{$mode objfpc}{$H+}

uses
 {$DEFINE UseCThreads}
 {$IFDEF UNIX}{$IFDEF UseCThreads}
 cthreads,
 {$ENDIF}{$ENDIF}
 Interfaces,
 LCLIntf,
 SysUtils,
 Forms,
 Dialogs,
 {$IFDEF Windows}
 Midi,
 CDviaMCI,
 SelectCDs,
 assoc,
 {$ENDIF Windows}
 basslight,
 basscode,
 basstags,
 About,
 MainWin,
 LH5,
 HeadEdit,
 Mixer,
 PlayList,
 ProgBox,
 ItemEdit,
 Tools,
 Z80,
 JmpTime,
 Players,
 AY,
 Convs,
 UniReader,
 Languages,
 FindPLItem,
 digidrum,
 WinVersion,
 Options,
 SelVolCtrl,
 seldir,
 digsound,
 digsoundcode,
 mixerctl,
 FileTypes,
 mc68000,
 sndh,
 atari,
 sometypes,
 settings,
 mxhelper,
 SNDHTimeDB,
 EncOptsEdit;

 {$R *.res}

begin
 FileMode := 0; //ReadOnly for Reset();
 OnShowException := @Ay_Emul_ShowException;
 {$IFNDEF Windows}
 IsConsole := False; //temporary for show exceptions in messagebox instead of linux console
 {$ENDIF Windows}

 if not IPCSendParams then
  begin
   StartIPC;
   {$IFDEF Windows}
   StartDDE;
   {$ENDIF Windows}
 Application.Scaled:=True;
   Application.Initialize;
   Application.CreateForm(TFrmMain, FrmMain);
   Application.CreateForm(TFrmMixer, FrmMixer);
   Application.CreateForm(TFrmPLst, FrmPLst);
   Application.CreateForm(TFrmMxHlp, FrmMxHlp);
   Application.CreateForm(TSelDirDlg, SelDirDlg);
   {$IFDEF Windows}
   Application.CreateForm(TCDList, CDList);
   {$ENDIF Windows}
   Application.OnException := @FrmMain.Ay_Emul_ShowExceptionA;
   {$IFDEF Windows}
   FrmMain.Visible := False; //does not work in GTK2 properly (strange behaviour)
   {$ENDIF Windows}
    try
     FrmMain.CommandLineAndRegCheck;
    except
     ShowException(ExceptObject, ExceptAddr);
    end;
   {$IFDEF Windows}
   FrmMain.Visible := True; //does not work in GTK2 properly (strange behaviour)
   {$ENDIF Windows}
   Application.Run;
   {$IFDEF Windows}
   StopDDE;
   {$ENDIF Windows}
   StopIPC;
  end;
end.
