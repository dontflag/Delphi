unit Delphi_Methods;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs;

type
  TForm1 = class(TForm)
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.dfm}

procedure TSProject.RunInterpDebug; //first-time pressing makes only initialization of the interpreter
var                                 //the execution proceeds after subsequent user actions
  i: integer;
  FileName: string;
  Execute: boolean;
  InitFunc,RunProc,StopProc: Pointer;
begin
  SoftForm := TSoftForm(FForm);
  if SoftForm.ActiveSchema <> nil then begin
    if TSSprutSchema(SoftForm.ActiveSchema).Method.IsSenderDeclar  then begin //class schema
      MessageDlg(IfLang('Debug is not available for a method declaration!','Отладка для объявления метода невозможна!'),mtInformation,[mbOk],0);
      Exit;
    end;
  end else if SoftForm.TextMethod <> nil then
    if SoftForm.TextMethod.IsSenderDeclar then begin
      MessageDlg(IfLang('Debug is not available for a method declaration!','Отладка для объявления метода невозможна!'),mtInformation,[mbOk],0);
      Exit;
    end;
  DM.JvFldrDlg.Title := IfLang('Select a section to debug','Выберите отлаживаемый раздел');
  if DM.JvFldrDlg.Directory = '' then  //directory stores last opened path due the current program session
    DM.JvFldrDlg.Directory := ExtractFilePath(ExtractFileDir(ParamStr(0))) + 'Projects\';
  Execute := DM.jvFldrDlg.Execute;
  if Execute then
    FileName := DM.JvFldrDlg.Directory;
  if FileName = '' then begin
    if Execute then
      MessageDlg(IfLang('Section file not found!','Файл раздела не найден!'),mtError,[mbOk],0);
    Exit;
  end;
  //FileName := SectionName; //get current section name, if the same TSMethod object is used in different sections
  InterpLib := LoadLibrary('Interpreter.dll'); //check connection with interpreter
  InitFunc := GetProcAddress(InterpLib, PChar('Init'));
  RunProc := GetProcAddress(InterpLib, PChar('Run'));
  StopProc := GetProcAddress(InterpLib, PChar('Stop'));
  InterpDebug := ((InitFunc <> nil) and (RunProc <> nil) and (StopProc <> nil));
  if InterpDebug then
    try
      Globals := TStringList.Create;
      Locals := TStringList.Create;
      FillGlobals; //create and fill variable lists
      FillLocals;
      for i:=0 to Globals.Count-1 do begin  //create and fill default values  in lists
        if Globals.Objects[i] <> nil then
          if Globals.Objects[i] is TSParam then //parameter of the method has no Value field
            TSCustomObject(Globals.Objects[i]).DebugValue := TSParam(Globals.Objects[i]).DefValue
          else
            TSCustomObject(Globals.Objects[i]).DebugValue := TSObject(Globals.Objects[i]).Value;
      end;
      for i:=0 to Locals.Count-1 do begin
        if Locals.Objects[i] <> nil then
          if Locals.Objects[i] is TSParam then
            TSCustomObject(Locals.Objects[i]).DebugValue := TSParam(Locals.Objects[i]).DefValue
          else
            TSCustomObject(Locals.Objects[i]).DebugValue := TSObject(Locals.Objects[i]).Value;
      end; 
      Init(FileName,Globals,Locals);
      with TSoftForm(FForm) do
        if ActiveSchema <> nil then
          DebugMethod := TSSprutSchema(ActiveSchema).Method
        else if TextMethod <> nil then
          DebugMethod := TextMethod;
      //Debug Vertex is not going to be set due initialization, until it will become necessary
      InterpDebugPause := True;
    except
      on E : Exception do
        MessageDlg(IfLang('Error during calling Init: ', 'Ошибка вызова функции Init: ')+E.Message, mtWarning, [mbOK], 0);
    end
  else begin
    MessageDlg(IfLang('It is not possible to connect to interpreter.', 'Не удаётся установить связь с интерпретатором'), mtWarning, [mbOK], 0);
    Exit;
  end;
  FDEditValueFr := TEditValueFr.Create(nil); //temporary
  FForm.Caption := FormCaption + IfLang(' [Running]',' [Выполнение]');
  TSoftForm(FForm).DebugSB.Panels[6].Text := DM.JvFldrDlg.DisplayName;
end;

procedure TSProject.StopInterpDebug;
var
  i: integer;
begin
  if not InterpDebug then
    Exit;
  {for i:=0 to Globals.Count-1 do    //DebugValue clears in the interpreter
    TSCustomObject(Globals.Objects[i]).DebugValue := '';
  for i:=0 to Locals.Count-1 do
    try
      TSCustomObject(Locals.Objects[i]).DebugValue := '';
    except
      on EInvalidPointer do ShowMessage('Invalid pointer!');
    end; }
  FNextLine := 'Stop'; //20.04.17 when the program save is occured - server will fill this field
  CallStopProc;//Stop
  DebugVertex := nil;
  DebugMethod := nil;
  FDEditValueFr.Hide; //temporary
  FDEditValueFr.Free;
  FForm.Caption := FormCaption;
 { FreeAndNil(Globals); //The objects are saved in memory, but you dont have to delete them, because these are the objects of object model of the soft editor
  FreeAndNil(Locals);} //lists clears in the interpreter
  FreeLibrary(InterpLib);
  FNextLine := ''; 
end;

procedure TSProject.CallRunProc(Mode: TRunMode);
var
  BPList: TStringList;
  i: integer;
begin
  BPList := TStringList.Create;
  FOldDebugTime := FDebugTime;
  for i:= 0 to BreakpointsCount-1 do //for graphic bp - VertexID, for text - Line
    BPList.Add(IntToStr(TSBreakpoint(FBreakpoints[i]).Method.MetID)+'.'+IntToStr(TSBreakpoint(FBreakpoints[i]).ID));
  if not InterpDebug then
    MessageDlg(IfLang('It is not possible to connect to interpreter', 'Не удаётся установить связь с интерпретатором!'), mtWarning, [mbOK], 0)
  else begin
    InterpDebugPause := False;
    FNextLine := '';
    Base.Run(Mode,BPList,FNextLine,FDebugTime);
  end;
  //MessageDlg('NextLine: ' +FNextLine + '; DebugTime: ' +IntToStr(FDebugTime), mtInformation, [mbOk],0);
  for i:=0 to BreakpointsCount-1 do
    if FNextLine = IntToStr(TSBreakpoint(FBreakpoints[i]).Method.MetID)+'.'+IntToStr(TSBreakpoint(FBreakpoints[i]).ID) then
      with TSBreakpoint(Breakpoints[i]) do begin
        PassIndex := PassIndex+1;
        if PassIndex > Breakcount then
          PassIndex := PassIndex - Breakcount;
        if PassIndex <> Breakcount then begin
          Base.Run(Mode,BPList,FNextLine,FDebugTime);
          Exit;
        end;
      end;
  with TSoftForm(FForm) do begin
    DebugVertex := nil;
    DebugLine := 0;
    if DebugMethod.Schema <> nil then begin
      for i:=0 to DebugMethod.Schema.Count-1 do
        if Length(NextLine)>0 then //there is '0.0' or adress or ''
          if TSVertex(DebugMethod.Schema[i]).VertexID = StrToInt(copy(NextLine,pos('.',NextLine)+1,Length(NextLine))) then
            DebugVertex := TSCustomSprutAction(DebugMethod.Schema[i]);
    end else if DebugMethod.Text[DebugMethod.TextLang] <> nil then
      if Length(NextLine)>0 then //there is '0.0' or adress or ''
        DebugLine := StrToInt(copy(NextLine,pos('.',NextLine)+1,Length(NextLine)))-1;
    DebugSB.Panels[cTaktPanel].Text := IntToStr(FDebugTime);
  end;
  FreeAndNil(BPList);
  DebugMethod.GoIn;
  if ((Mode = rmAuto) and (BreakpointsCount = 0)) then begin
    UpdateDebugWindows;
    Exit;
  end;
  InterpDebugPause := True; //running is over, the program is on the breakpoint => execution is paused
  UpdateDebugWindows;
end;

procedure TSProject.CallStopProc;
var
  i: integer;
begin
  Stop(FNextLine,FDebugTime); //pause
  //MessageDlg('NextLine: ' +FNextLine + '; DebugTime: ' +IntToStr(FDebugTime), mtInformation, [mbOk],0);
  for i:=0 to BreakpointsCount-1 do //if breakpoint is on the first line
    if FNextLine = IntToStr(TSBreakpoint(FBreakpoints[i]).Method.MetID)+'.'+IntToStr(TSBreakpoint(FBreakpoints[i]).ID) then
      with TSBreakpoint(Breakpoints[i]) do begin
        PassIndex := PassIndex+1;
        if PassIndex > Breakcount then
          PassIndex := PassIndex - Breakcount;
      end;
  if FNextLine <> 'Stop' then
    with TSoftForm(FForm) do begin
      DebugVertex := nil;
      DebugLine := 0;
      if DebugMethod.Schema <> nil then begin
        for i:=0 to DebugMethod.Schema.Count-1 do
          if TSVertex(DebugMethod.Schema[i]).VertexID = StrToInt(copy(NextLine,pos('.',NextLine)+1,Length(NextLine))) then
            DebugVertex := TSCustomSprutAction(DebugMethod.Schema[i]);
      end else if DebugMethod.Text[DebugMethod.TextLang] <> nil then
        DebugLine := StrToInt(copy(NextLine,pos('.',NextLine)+1,Length(NextLine)));
      DebugMethod.GoIn;
      DebugSB.Panels[cTaktPanel].Text := IntToStr(FDebugTime);
      InterpDebugPause := True;
    end
  else begin
    InterpDebugPause := False;
    InterpDebug := false;
  end;
  UpdateDebugWindows;
end;

end.
 
