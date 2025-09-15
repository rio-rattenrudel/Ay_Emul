{
This is part of AY Emulator project
AY-3-8910/12 Emulator
Version 3.0 for Windows and Linux
Author Sergey Vladimirovich Bulba
(c)1999-2025 S.V.Bulba
}

unit EncOptsEdit;

{$mode ObjFPC}{$H+}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
 Spin, basscode;

type

 { TFrmEncOptsEditor }

 TFrmEncOptsEditor = class(TForm)
   BSkip: TButton;
   Bevel1: TBevel;
   Bevel2: TBevel;
   BApply: TButton;
   BRestore: TButton;
   CBQuality: TCheckBox;
   CBBitrate: TCheckBox;
   CBAuthor: TCheckBox;
   CBTitle: TCheckBox;
   CBDate: TCheckBox;
   CBComment: TCheckBox;
   CmBBitrate: TComboBox;
   ETitle: TEdit;
   ECustom: TEdit;
   EAuthor: TEdit;
   EDate: TEdit;
   LComment: TLabel;
   LDate: TLabel;
   LAuthor: TLabel;
   LTitle: TLabel;
   SEVBR: TFloatSpinEdit;
   GBBitrate: TGroupBox;
   RBDefault: TRadioButton;
   RBConstrained: TRadioButton;
   RBFixed: TRadioButton;
   RBAverage: TRadioButton;
   RBVariable: TRadioButton;
   SEQualityFloat: TFloatSpinEdit;
   LOptsHint: TLabel;
   LCustom: TLabel;
   LResult: TLabel;
   MComment: TMemo;
   MResult: TMemo;
   MOptsHint: TMemo;
   SEQualityInt: TSpinEdit;
   procedure BRestoreClick(Sender: TObject);
   procedure CBAuthorChange(Sender: TObject);
   procedure CBBitrateChange(Sender: TObject);
   procedure CBCommentChange(Sender: TObject);
   procedure CBDateChange(Sender: TObject);
   procedure CBQualityChange(Sender: TObject);
   procedure CBTitleChange(Sender: TObject);
   procedure CmBBitrateChange(Sender: TObject);
   procedure EAuthorChange(Sender: TObject);
   procedure ECustomChange(Sender: TObject);
   procedure EDateChange(Sender: TObject);
   procedure ETitleChange(Sender: TObject);
   procedure FormShow(Sender: TObject);
   procedure MCommentChange(Sender: TObject);
   procedure RBAverageChange(Sender: TObject);
   procedure RBConstrainedChange(Sender: TObject);
   procedure RBDefaultChange(Sender: TObject);
   procedure RBFixedChange(Sender: TObject);
   procedure RBVariableChange(Sender: TObject);
   procedure SEQualityFloatChange(Sender: TObject);
   procedure SEQualityIntChange(Sender: TObject);
   procedure SEVBRChange(Sender: TObject);
 private
   OpsLoading,//flag if controls filled programmatically (not by user edition)
   OpsEdited, //flag if some change was made
   OpsSaved: boolean; //flag if previous state was saved
   procedure FillControls(const Ops: TEncoderOptions);
   procedure FillOptions;
 public
   OpsInitial: PEncoderOptions;
   OpsFilled: TEncoderOptions; //FillOptions storage
 end;

var
 FrmEncOptsEditor: TFrmEncOptsEditor;

implementation

uses
 basslight;

 {$R *.lfm}

 { TFrmEncOptsEditor }

procedure TFrmEncOptsEditor.CBQualityChange(Sender: TObject);
begin
 if OpsLoading then
   Exit;
 SEQualityInt.Enabled := CBQuality.Checked;
 SEQualityFloat.Enabled := CBQuality.Checked;
 case OpsInitial^.Enc of
   tbeOGG:
     if CBQuality.Checked then
       //bitrate control ignored in this mode
      begin
       RBDefault.Checked := True;
       CBBitrate.Checked := False;
      end;
  end;
 FillOptions;
end;

procedure TFrmEncOptsEditor.CBTitleChange(Sender: TObject);
begin
 if OpsLoading then
   Exit;
 FillOptions;
end;

procedure TFrmEncOptsEditor.CmBBitrateChange(Sender: TObject);
begin
 if not OpsLoading then
   FillOptions;
end;

procedure TFrmEncOptsEditor.EAuthorChange(Sender: TObject);
begin
 if OpsLoading then
   Exit;
 FillOptions;
end;

procedure TFrmEncOptsEditor.ECustomChange(Sender: TObject);
begin
 if not OpsLoading then
   FillOptions;
end;

procedure TFrmEncOptsEditor.EDateChange(Sender: TObject);
begin
 if OpsLoading then
   Exit;
 FillOptions;
end;

procedure TFrmEncOptsEditor.ETitleChange(Sender: TObject);
begin
 if OpsLoading then
   Exit;
 FillOptions;
end;

procedure TFrmEncOptsEditor.FormShow(Sender: TObject);
begin
 if OpsInitial^.GroupOperation then
  begin
   CBAuthor.Visible := True;
   CBTitle.Visible := True;
   CBDate.Visible := True;
   CBComment.Visible := True;
   EAuthor.Enabled := False;
   EAuthor.Color := clForm;
   EAuthor.Clear;
   ETitle.Enabled := False;
   ETitle.Color := clForm;
   ETitle.Clear;
   EDate.Enabled := False;
   EDate.Color := clForm;
   EDate.Clear;
   MComment.Enabled := False;
   MComment.Color := clForm;
   MComment.Clear;
  end
 else
  begin
   LAuthor.Visible := True;
   LTitle.Visible := True;
   LDate.Visible := True;
   LComment.Visible := True;
   EAuthor.Enabled := True;
   EAuthor.Color := clDefault;
   ETitle.Enabled := True;
   ETitle.Color := clDefault;
   EDate.Enabled := True;
   EDate.Color := clDefault;
   MComment.Enabled := True;
   MComment.Color := clDefault;
  end;
 FillControls(OpsInitial^);
 FillOptions;
 OpsEdited := False;
 OpsSaved := False;
end;

procedure TFrmEncOptsEditor.MCommentChange(Sender: TObject);
begin
 if OpsLoading then
   Exit;
 FillOptions;
end;

procedure TFrmEncOptsEditor.RBAverageChange(Sender: TObject);
begin
 if OpsLoading then
   Exit;
 case OpsInitial^.Enc of
   tbeMP3:
     if RBAverage.Checked then
      begin
       //average bitrate requires bitrate value
       CBBitrate.Checked := True;
       if CmBBitrate.Text = '' then
         CmBBitrate.Text := '128';
       //only for variable bitrate
       SEVBR.Enabled := False;
      end;
   tbeOGG:
     if RBAverage.Checked then
      begin
       //quality mode must be turned off if need bitrate
       CBQuality.Checked := False;
       //average bitrate requires bitrate value
       CBBitrate.Checked := True;
       if CmBBitrate.Text = '' then
         CmBBitrate.Text := '128';
      end;
   tbeOPUS:
     if RBAverage.Checked then
      begin
       //average bitrate requires bitrate value
       CBBitrate.Checked := True;
       if CmBBitrate.Text = '' then
         CmBBitrate.Text := '128';
      end;
  end;
 FillOptions;
end;

procedure TFrmEncOptsEditor.RBConstrainedChange(Sender: TObject);
begin
 if not OpsLoading then
   FillOptions;
end;

procedure TFrmEncOptsEditor.RBDefaultChange(Sender: TObject);
begin
 if OpsLoading then
   Exit;
 case OpsInitial^.Enc of
   tbeMP3:
     if RBDefault.Checked then
      begin
       //only for variable bitrate
       SEVBR.Enabled := False;
       //not used for generating options string in this case
       CBBitrate.Checked := False;
      end;
   tbeOGG, tbeOPUS:
     if RBDefault.Checked then
       //bitrate is ignored
       CBBitrate.Checked := False;
  end;

 FillOptions;
end;

procedure TFrmEncOptsEditor.RBFixedChange(Sender: TObject);
begin
 if OpsLoading then
   Exit;
 case OpsInitial^.Enc of
   tbeMP3:
     if RBFixed.Checked then
      begin
       //fixed bitrate requires bitrate value
       CBBitrate.Checked := True;
       if CmBBitrate.Text = '' then
         CmBBitrate.Text := '128';
       //only for variable bitrate
       SEVBR.Enabled := False;
      end;
   tbeOGG:
     if RBFixed.Checked then
      begin
       //quality mode must be turned off if need bitrate
       CBQuality.Checked := False;
       //fixed bitrate for requires bitrate value
       CBBitrate.Checked := True;
       if CmBBitrate.Text = '' then
         CmBBitrate.Text := '128';
      end;
   tbeOPUS:
     if RBFixed.Checked then
      begin
       //fixed bitrate requires bitrate value
       CBBitrate.Checked := True;
       if CmBBitrate.Text = '' then
         CmBBitrate.Text := '128';
      end;
  end;
 FillOptions;
end;

procedure TFrmEncOptsEditor.RBVariableChange(Sender: TObject);
begin
 if OpsLoading then
   Exit;
 case OpsInitial^.Enc of
   tbeMP3:
     if RBVariable.Checked then
       SEVBR.Enabled := True;
  end;
 FillOptions;
end;

procedure TFrmEncOptsEditor.SEQualityFloatChange(Sender: TObject);
begin
 if not OpsLoading then
   FillOptions;
end;

procedure TFrmEncOptsEditor.SEQualityIntChange(Sender: TObject);
begin
 if not OpsLoading then
   FillOptions;
end;

procedure TFrmEncOptsEditor.SEVBRChange(Sender: TObject);
begin
 if OpsLoading then
   Exit;
 RBVariable.Checked := True;
 FillOptions;
end;

procedure TFrmEncOptsEditor.CBBitrateChange(Sender: TObject);
begin
 if OpsLoading then
   Exit;
 CmBBitrate.Enabled := CBBitrate.Checked;
 case OpsInitial^.Enc of
   tbeMP3:
     if CBBitrate.Checked then
      begin
       if RBDefault.Checked or RBVariable.Checked then
        begin
         if CmBBitrate.Text = '' then
           //non empty value required for fixed, empty will be ignored for variable
           //so fill anyway, user will correct if need another
           CmBBitrate.Text := '128';
         if RBDefault.Checked then
           //will be ignored if default, so force fixed
           RBFixed.Checked := True;
        end;
      end
     else if RBAverage.Checked or RBFixed.Checked then
       //options not available without bitrate value
       RBDefault.Checked := True;
   tbeOGG:
     if CBBitrate.Checked then
      begin
       //turn off quality mode
       CBQuality.Checked := False;
       if CmBBitrate.Text = '' then
         //user can correct if need other, but we need non-empty
         CmBBitrate.Text := '128';
       if RBDefault.Checked then
         //will be ignored if default, so force fixed
         RBFixed.Checked := True;
      end
     else if RBAverage.Checked or RBFixed.Checked then
       //options not available without bitrate value
       RBDefault.Checked := True;
   tbeOPUS:
     if CBBitrate.Checked then
      begin
       if CmBBitrate.Text = '' then
         //user can correct if need other, but we need non-empty
         CmBBitrate.Text := '128';
       if RBDefault.Checked then
         //will be ignored if default, so force fixed
         RBFixed.Checked := True;
      end
     else if RBAverage.Checked or RBFixed.Checked then
       //options not available without bitrate value
       RBDefault.Checked := True;
  end;
 FillOptions;
end;

procedure TFrmEncOptsEditor.CBCommentChange(Sender: TObject);
begin
 if OpsLoading then
   Exit;
 FillOptions;
end;

procedure TFrmEncOptsEditor.CBDateChange(Sender: TObject);
begin
 if OpsLoading then
   Exit;
 FillOptions;
end;

procedure TFrmEncOptsEditor.BRestoreClick(Sender: TObject);
begin
 if OpsEdited then
  begin
   FillControls(OpsInitial^); //restore initial state
   OpsSaved := True;
   OpsEdited := False;
  end
 else if OpsSaved then
  begin
   FillControls(OpsFilled); //restore saved options
   OpsEdited := True; //was edited if saved
  end;
end;

procedure TFrmEncOptsEditor.CBAuthorChange(Sender: TObject);
begin
 if OpsLoading then
   Exit;
 FillOptions;
end;

procedure TFrmEncOptsEditor.FillControls(const Ops: TEncoderOptions);
begin
 OpsLoading := True;
 if Ops.GroupOperation then
  begin
   CBAuthor.Checked := Ops.UseAuthor;
   CBTitle.Checked := Ops.UseTitle;
   CBDate.Checked := Ops.UseDate;
   CBComment.Checked := Ops.UseComment;
  end
 else
  begin
   if Ops.UseAuthor then
     EAuthor.Text := Ops.TagAuthor
   else
     EAuthor.Clear;
   if Ops.UseTitle then
     ETitle.Text := Ops.TagTitle
   else
     ETitle.Clear;
   if Ops.UseDate then
     EDate.Text := Ops.TagDate
   else
     EDate.Clear;
   if Ops.UseComment then
     MComment.Text := Ops.TagComment
   else
     MComment.Clear;
  end;
 MResult.Text := GetEncOptions(Ops);
 ECustom.Text := Ops.CustomKeys;
 MOptsHint.Text := EncoderOptionsHints[Ops.Enc];
 EDate.Hint := EncoderDateHints[Ops.Enc];
 SEQualityInt.Visible := Ops.Enc <> tbeOGG;
 SEQualityFloat.Visible := not SEQualityInt.Visible;
 CBQuality.Checked := Ops.Quality >= 0;
 case Ops.Enc of
   tbeMP3: SEQualityInt.MaxValue := 9;
   tbeFLAC: SEQualityInt.MaxValue := 8;
   tbeOPUS: SEQualityInt.MaxValue := 10;
  end;
 case Ops.Enc of
   tbeOGG: SEQualityFloat.Hint := EncoderQualityHints[tbeOGG];
 else
   SEQualityInt.Hint := EncoderQualityHints[Ops.Enc];
  end;
 SEQualityInt.Enabled := CBQuality.Checked;
 SEQualityFloat.Enabled := CBQuality.Checked;
 if CBQuality.Checked then
   case Ops.Enc of
     tbeOGG: SEQualityFloat.Value := Ops.Quality / 10 - 1;
   else
     SEQualityInt.Value := Ops.Quality;
    end;
 GBBitrate.Visible := Ops.Enc <> tbeFLAC;
 if GBBitrate.Visible then
  begin
   CBBitrate.Checked := Ops.BitRate <> 0;
   if CBBitrate.Checked then
     CmBBitrate.Text := IntToStr(Abs(Ops.BitRate))
   else
     CmBBitrate.Text := '';
   CmBBitrate.Enabled := CBBitrate.Checked;
   case Ops.Enc of
     tbeMP3:
      begin
       SEVBR.Enabled := Ops.VBR >= 0;
       if SEVBR.Enabled then
        begin
         RBVariable.Checked := True;
         SEVBR.Value := Ops.VBR / 1000;
        end
       else if Ops.BitRate < 0 then
         RBAverage.Checked := True
       else if Ops.BitRate > 0 then
         RBFixed.Checked := True
       else
         RBDefault.Checked := True;
       RBConstrained.Enabled := False;
       CmBBitrate.Style := csDropDownList;
      end;
     tbeOGG:
      begin
       if Ops.Quality >= 0 then
         RBDefault.Checked := True
       else if Ops.BitRate < 0 then
         RBAverage.Checked := True
       else if Ops.BitRate > 0 then
         RBFixed.Checked := True
       else
         RBDefault.Checked := True;
       RBVariable.Enabled := False;
       SEVBR.Enabled := False;
       RBConstrained.Enabled := False;
       CmBBitrate.Style := csDropDown;
      end;
     tbeOPUS:
      begin
       if Ops.VBR >= 0 then
         RBConstrained.Checked := True
       else if Ops.BitRate > 0 then
         RBFixed.Checked := True
       else if Ops.BitRate < 0 then
         RBAverage.Checked := True
       else
         RBDefault.Checked := True;
       RBVariable.Enabled := False;
       SEVBR.Enabled := False;
       CmBBitrate.Style := csDropDown;
      end;
    end;
   CmBBitrate.Hint := EncoderBitrateHints[Ops.Enc];
  end;
 OpsLoading := False;
end;

procedure TFrmEncOptsEditor.FillOptions;
begin
 OpsEdited := True;
 OpsFilled := OpsInitial^;

 if OpsFilled.GroupOperation then
  begin
   OpsFilled.UseAuthor := CBAuthor.Checked;
   OpsFilled.UseTitle := CBTitle.Checked;
   OpsFilled.UseDate := CBDate.Checked;
   OpsFilled.UseComment := CBComment.Checked;
  end
 else
  begin
   OpsFilled.UseAuthor := EAuthor.Text <> '';
   OpsFilled.TagAuthor := EAuthor.Text;
   OpsFilled.UseTitle := ETitle.Text <> '';
   OpsFilled.TagTitle := ETitle.Text;
   OpsFilled.UseDate := EDate.Text <> '';
   OpsFilled.TagDate := EDate.Text;
   OpsFilled.UseComment := MComment.Text <> '';
   OpsFilled.TagComment := MComment.Text;
  end;

 OpsFilled.CustomKeys := ECustom.Text;

 if not CBQuality.Checked then
   OpsFilled.Quality := -1
 else if OpsFilled.Enc = tbeOGG then
   OpsFilled.Quality := Trunc((SEQualityFloat.Value + 1) * 10 + 0.5)
 else
   OpsFilled.Quality := SEQualityInt.Value;

 case OpsFilled.Enc of
   tbeMP3:
    begin
     if RBVariable.Checked then
      begin
       OpsFilled.VBR := Trunc(SEVBR.Value * 1000 + 0.5);
       //can be used with bitrate value
       if CBBitrate.Checked then
         TryStrToInt(CmBBitrate.Text, OpsFilled.BitRate);
      end
     else
       OpsFilled.VBR := -1;
     if RBAverage.Checked then
       if TryStrToInt(CmBBitrate.Text, OpsFilled.BitRate) then
         OpsFilled.BitRate := -OpsFilled.BitRate
       else
         //average BR require bitrate value
         OpsFilled.BitRate := -128;
     if RBFixed.Checked then
       if not TryStrToInt(CmBBitrate.Text, OpsFilled.BitRate) then
         //fixed BR require bitrate value
         OpsFilled.BitRate := 128;
    end;
   tbeOGG:
    begin
     if RBAverage.Checked then
       if TryStrToInt(CmBBitrate.Text, OpsFilled.BitRate) then
         OpsFilled.BitRate := -OpsFilled.BitRate
       else
         //average BR require bitrate value
         OpsFilled.BitRate := -128;
     if RBFixed.Checked then
       if not TryStrToInt(CmBBitrate.Text, OpsFilled.BitRate) then
         //fixed BR require bitrate value
         OpsFilled.BitRate := 128;
    end;
   tbeOPUS:
    begin
     if RBConstrained.Checked then
      begin
       OpsFilled.VBR := 0;
       //can be used with bitrate value
       if CBBitrate.Checked then
         TryStrToInt(CmBBitrate.Text, OpsFilled.BitRate);
      end
     else
       OpsFilled.VBR := -1;
     if RBFixed.Checked then
       if not TryStrToInt(CmBBitrate.Text, OpsFilled.BitRate) then
         //fixed BR require bitrate value
         OpsFilled.BitRate := 128;
     if RBAverage.Checked then
       if TryStrToInt(CmBBitrate.Text, OpsFilled.BitRate) then
         OpsFilled.BitRate := -OpsFilled.BitRate
       else
         //average BR require bitrate value
         OpsFilled.BitRate := -128;
    end;
  end;
 MResult.Text := GetEncOptions(OpsFilled);
end;

end.
