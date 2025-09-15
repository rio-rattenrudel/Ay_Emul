{
This is part of AY Emulator project
AY-3-8910/12 Emulator
Version 3.0 for Windows and Linux
Author Sergey Vladimirovich Bulba
(c)1999-2025 S.V.Bulba
}

unit Languages;

{$mode objfpc}{$H+}

interface

resourcestring
 Mes_WinVersion = 'Supported in Windows version only';
 Mes_InvalidLZH = 'LZH compressed data is not valid';
 Mes_ReadAfterEndOfFile = 'Read after end of file';
 Mes_SeekAfterEndOfFile = 'Seek after end of file';
 Mes_ReadAfterEndOfData = 'Read after end of data';
 Mes_FileSeekError = 'FileSeek error';
 Mes_FileOpenError = 'FileOpen error';
 Mes_FileReadError = 'FileRead error';
 Mes_UnsupportedAYMHeader = 'Unsupported AYM-file header';
 Mes_UnsupportedAYMRevision = 'Unsupported AYM-file revision';
 Mes_TrackLength = 'Track length';
 Mes_SelectMixerDivice = 'Select mixer device:';
 Mes_NoValidDestForMixer = 'No valid destinations for selected mixer device';
 Mes_SelectDestination = 'Select destination:';
 Mes_NoVolumeControlsFound = 'No volume controls found for selected destination';
 Mes_SelectControl = 'Select control:';
 Mes_Stop = 'Stop';
 Mes_Begin = 'Begin';
 Tit_AppIcon = 'Application icon';
 Tit_TrayIcon = 'Tray icon';
 Tit_StartMenuIcon = '''Start'' menu icon';
 Tit_MusicIcon = 'Music files icon';
 Tit_SkinIcon = 'Skin files icon';
 Tit_PlaylistIcon = 'Playlists icon';
 Tit_BASSIcon = 'BASS files icon';
 Tit_Author = 'Author:';
 Tit_Icon = 'Icon';
 Mes_OpenFilesFromFolder = 'Open files from folder:';
 Mes_SaveToFolder = 'Save to folder:';
 Mes_CantCreateDestFolder = 'Can not create destination folder';
 Mes_File = 'File';
 Mes_ExistsOverwrite = 'exists. Overwrite?';
 Mes_notFoundOrDenied = 'not found or access denied';
 Mes_AnalisisOfFile = 'Analisis of file';
 Mes_UserInterrupted = 'Interrupted because of user wish.';
 Mes_GroupOpStopped = 'Operation canceled';
 Mes_SelectFolder = 'Select folder';
 Mes_notAy_Emul20Skin = 'is not AY-3-8910/12 Emulator v2.0 Skin File';
 Mes_SearchStringNotFound = 'Search string not found';
 Mes_UnhandledErrorAddFile = 'Unhandled error during adding file';
 Mes_DamagedFileIceDepack = 'Error: damaged file - SNDH ICE depacking';
 SNDH_RippedBy = 'Ripped by';
 SNDH_ConvertedBy = 'Converted by';
 Mes_NoSongPlaying = 'no song playing...';
 Mes_CantOpen = 'Can''t open';
 Mes_FIR = 'FIR';
 Mes_PTS = 'pts';
 Mes_Averager = 'Averager';
 Mes_ExcRegAdm = '(excepting restoring file registration data, administrator rights needed)';
 Mes_AyEmulRemoved = 'Ay_Emul data is removed from your system';
 Mes_CloseBye = 'Close the program and delete Ay_Emul folder to complete uninstall. See you!';
 Mes_UnsupportedAYHeader = 'Unsupported AY-file header';
 Mes_UnsupportedAYType = 'Unsupported AY-file type';
 Mes_CantCalcSTPAddr = 'Can''t calculate STP init address';
 Mes_UnsupTSStruct = 'Unsupported TS-file structure';
 Mes_UnsupportedVTXHeader = 'Unsupported VTX-file header';
 Mes_UnsupportedYMHeader = 'Unsupported YM-file header';
 Mes_UnsupportedPSGVersion = 'Unsupported PSG-file version';
 Mes_UnsupportedEPSGCType = 'Unsupported EPSG-file computer type';
 Mes_UnsupportedPSGHeader = 'Unsupported PSG-file header';
 Mes_ToSmallST11 = 'ST11 block is too small in AY-file';
 Mes_CantExtractTrkNum = 'Can''t extract track number from CDA file name';
 AYEmul_AppTitle =
   'AY-3-8910, AY-3-8912 and YM2149F Emulator, Player, Converter and Music Ripper';
 T_AllFiles = 'All files';
 T_AllSupFiles = 'All supported types';
 Mes_AYEmulFmtLoadError = 'Ay_Emul.fmt loading error in line';
 Mes_MiliSec = 'ms';
 Mes_SystemVolCtrlsNotDetected = 'System volume controls not detected';
 Mes_MP3DateHint = 'Integer number from 1 to 9999';
 Mes_AnyString = 'Any string';
 Mes_OPUSDateHint =
   'Either YYYY/YYYY-MM/YYYY-MM-DD or valid date in system regional settings form';
 Mes_MP3QualityHint = 'From 0 to 9 (0 for best, 9 for fast)';
 Mes_OGGQualityHint =
   'From -1.0 to 10.0 (-1.0 for fast, 10 for best). Used instead of bitrate.';
 Mes_FLACQualityHint = 'From 0 to 8 (0 for fast, 8 for best)';
 Mes_OPUSQualityHint = 'From 0 to 10 (0 for fast, 10 for best)';
 Mes_MP3BitrateHint = 'Only values accepted defined in the drop down list';
 Mes_OGGBitrateHint = 'Positive integer number (kbit/s)';
 Mes_OPUSBitrateHint = 'From 6 to 256 kbit/s per channel';

 Mes_CantCreateTrayIcon = 'Can''t create tray icon';
 Mes_NotFinished = 'Process is not finished, aborted at item #';

var
 //since LCL depricated GetDeaultLang, we need store SetDeaultLang result here:
 DefaultLang: string = 'en';

 //lang selected in options
 Lang: string = 'en';

implementation

end.
