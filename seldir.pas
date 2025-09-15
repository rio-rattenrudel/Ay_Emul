{
This is part of AY Emulator project
AY-3-8910/12 Emulator
Version 3.0 for Windows and Linux
Author Sergey Vladimirovich Bulba
(c)1999-2025 S.V.Bulba
}

unit seldir;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs,
  EditBtn, StdCtrls, ExtCtrls;

type

  { TSelDirDlg }

  TSelDirDlg = class(TForm)
    BOk: TButton;
    BCancel: TButton;
    CBPathToName: TCheckBox;
    GBOptions: TGroupBox;
    GBPlaylist: TGroupBox;
    RBPLIncl: TRadioButton;
    RBPLExcl: TRadioButton;
    RBPLOnly: TRadioButton;
    CBRecurse: TCheckBox;
    CBDoDetect: TCheckBox;
    DirEdit: TDirectoryEdit;
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

  TChDirOpts = (cdoRecurse,cdoDetect,cdoPlaylists,cdoPathToName);
  TChDirOptsSet = set of TChDirOpts;

function ChooseDirectory(var Dir:string;const Capt:string;Extra:TChDirOptsSet):boolean;

var
  SelDirDlg: TSelDirDlg;

implementation

uses
  MainWin;

{$R *.lfm}

function ChooseDirectory(var Dir:string;const Capt:string;Extra:TChDirOptsSet):boolean;
begin
Result := False;
SelDirDlg.DirEdit.Directory:=Dir;
SelDirDlg.DirEdit.DialogTitle:=Capt;
SelDirDlg.Caption:=Capt;
SelDirDlg.CBRecurse.Visible:=cdoRecurse in Extra;
SelDirDlg.CBDoDetect.Visible:=cdoDetect in Extra;
SelDirDlg.GBPlaylist.Visible:=cdoPlaylists in Extra;
SelDirDlg.CBPathToName.Visible:=cdoPathToName in Extra;
SelDirDlg.CBRecurse.Checked := AddFolderRecurseDirs;
SelDirDlg.CBDoDetect.Checked := AddFolderDoDetect;
SelDirDlg.RBPLIncl.Checked := AddFolderPlaylists = 0;
SelDirDlg.RBPLExcl.Checked := AddFolderPlaylists = 1;
SelDirDlg.RBPLOnly.Checked := AddFolderPlaylists = 2;
SelDirDlg.CBPathToName.Checked := PathBasedFileName;
if SelDirDlg.ShowModal = mrOk then
 begin
  if SelDirDlg.CBRecurse.Visible then
    AddFolderRecurseDirs := SelDirDlg.CBRecurse.Checked;
  if SelDirDlg.CBDoDetect.Visible then
    AddFolderDoDetect := SelDirDlg.CBDoDetect.Checked;
  if SelDirDlg.GBPlaylist.Visible then
    if SelDirDlg.RBPLIncl.Checked then
     AddFolderPlaylists := 0
    else if SelDirDlg.RBPLExcl.Checked then
     AddFolderPlaylists := 1
    else if SelDirDlg.RBPLOnly.Checked then
     AddFolderPlaylists := 2;
  if SelDirDlg.CBPathToName.Visible then
    PathBasedFileName := SelDirDlg.CBPathToName.Checked;
  Dir := SelDirDlg.DirEdit.Directory;
  Result := True;
 end;
end;

{ TSelDirDlg }

procedure TSelDirDlg.FormShow(Sender: TObject);
begin
if DirEdit.CanSetFocus then
 DirEdit.SetFocus;
end;

end.

