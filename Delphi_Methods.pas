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

procedure TSProject.RunInterpDebug; //первоначальное нажатие проводит только инициализацию
var                                 //выполнение проводится после дальнейших действия пользователя
  i: integer;
  FileName: string;
  Execute: boolean;
  InitFunc,RunProc,StopProc: Pointer;
begin
  SoftForm := TSoftForm(FForm);
  if SoftForm.ActiveSchema <> nil then begin
    if TSSprutSchema(SoftForm.ActiveSchema).Method.IsSenderDeclar  then begin//схема класса
      MessageDlg(IfLang('Debug is not available for a method declaration!','Отладка для объявления метода невозможна!'),mtInformation,[mbOk],0);
      Exit;
    end;
  end else if SoftForm.TextMethod <> nil then
    if SoftForm.TextMethod.IsSenderDeclar then begin
      MessageDlg(IfLang('Debug is not available for a method declaration!','Отладка для объявления метода невозможна!'),mtInformation,[mbOk],0);
      Exit;
    end;
  DM.JvFldrDlg.Title := IfLang('Select a section to debug','Выберите отлаживаемый раздел');
  if DM.JvFldrDlg.Directory = '' then  //directory запоминает последний открытый путь в рамках текущего сеанса программы
    DM.JvFldrDlg.Directory := ExtractFilePath(ExtractFileDir(ParamStr(0))) + 'Projects\';
  Execute := DM.jvFldrDlg.Execute;
  if Execute then
    FileName := DM.JvFldrDlg.Directory;
  if FileName = '' then begin
    if Execute then
      MessageDlg(IfLang('Section file not found!','Файл раздела не найден!'),mtError,[mbOk],0);
    Exit;
  end;
  //FileName := SectionName; //получим имя раздела, если один и тот же объект TSMethod задействован в двух разделах
  InterpLib := LoadLibrary('Interpreter.dll'); //просто проверяем соединение с интерпретатором
  InitFunc := GetProcAddress(InterpLib, PChar('Init'));
  RunProc := GetProcAddress(InterpLib, PChar('Run'));
  StopProc := GetProcAddress(InterpLib, PChar('Stop'));
  InterpDebug := ((InitFunc <> nil) and (RunProc <> nil) and (StopProc <> nil));
  if InterpDebug then
    try
      Globals := TStringList.Create;
      Locals := TStringList.Create;
      FillGlobals; //создадим и заполним списки
      FillLocals;
      for i:=0 to Globals.Count-1 do begin  //создадим и заполним базовые значения в списках
        if Globals.Objects[i] <> nil then
          if Globals.Objects[i] is TSParam then //у параметра нету поля Value
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
      //Debug Vertex при инициализации не определяем, пока не появится необходимость обратного
      InterpDebugPause := True;
    except
      on E : Exception do
        MessageDlg(IfLang('Error during calling Init: ', 'Ошибка при вызове функции Init: ')+E.Message, mtWarning, [mbOK], 0);
    end
  else begin
    MessageDlg(IfLang('It is not possible to connect to interpreter.', 'Не удаётся установить связь с интерпретатором'), mtWarning, [mbOK], 0);
    Exit;
  end;
  FDEditValueFr := TEditValueFr.Create(nil); //временно
  FForm.Caption := FormCaption + IfLang(' [Running]',' [Выполнение]');
  TSoftForm(FForm).DebugSB.Panels[6].Text := DM.JvFldrDlg.DisplayName;
end;

procedure TSProject.StopInterpDebug;
var
  i: integer;
begin
  if not InterpDebug then
    Exit;
  {for i:=0 to Globals.Count-1 do    //очищение DebugValue происходит в интерпретаторе
    TSCustomObject(Globals.Objects[i]).DebugValue := '';
  for i:=0 to Locals.Count-1 do
    try
      TSCustomObject(Locals.Objects[i]).DebugValue := '';
    except
      on EInvalidPointer do ShowMessage('Invalid pointer!');
    end; }
  FNextLine := 'Stop'; //20.04.17 когда будет сохранение состояний программы - сервер сам будет поле заполнять
  CallStopProc;//Stop
  DebugVertex := nil;
  DebugMethod := nil;
  FDEditValueFr.Hide; //временно
  FDEditValueFr.Free;
  FForm.Caption := FormCaption;
 { FreeAndNil(Globals); //объекты остаются в памяти, но удалять их и не надо, тк это объекты объектной модели программы
  FreeAndNil(Locals);} //списки очищаются в интерпретаторе
  FreeLibrary(InterpLib);
  FNextLine := ''; //см. 'Stop'
end;

procedure TSProject.CallRunProc(Mode: TRunMode);
var
  BPList: TStringList;
  i: integer;
begin
  BPList := TStringList.Create;
  FOldDebugTime := FDebugTime;
  for i:= 0 to BreakpointsCount-1 do //ID для графики - VertexID, для текста - Line
    BPList.Add(IntToStr(TSBreakpoint(FBreakpoints[i]).Method.MetID)+'.'+IntToStr(TSBreakpoint(FBreakpoints[i]).ID));
  if not InterpDebug then
    MessageDlg(IfLang('It is not possible to connect to interpreter', 'Не удаётся установить связь с интерпретатором'), mtWarning, [mbOK], 0)
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
        if Length(NextLine)>0 then //пока что там либо 0.0, либо адрес, либо ''
          if TSVertex(DebugMethod.Schema[i]).VertexID = StrToInt(copy(NextLine,pos('.',NextLine)+1,Length(NextLine))) then
            DebugVertex := TSCustomSprutAction(DebugMethod.Schema[i]);
    end else if DebugMethod.Text[DebugMethod.TextLang] <> nil then
      if Length(NextLine)>0 then //пока что там либо 0.0, либо адрес, либо ''
        DebugLine := StrToInt(copy(NextLine,pos('.',NextLine)+1,Length(NextLine)))-1;
    DebugSB.Panels[cTaktPanel].Text := IntToStr(FDebugTime);
  end;
  FreeAndNil(BPList);
  DebugMethod.GoIn;
  if ((Mode = rmAuto) and (BreakpointsCount = 0)) then begin
    UpdateDebugWindows;
    Exit;
  end;
  InterpDebugPause := True; //прогон завершён, на бп встали => выполнение приостановлено
  UpdateDebugWindows;
end;

procedure TSProject.CallStopProc;
var
  i: integer;
begin
  Stop(FNextLine,FDebugTime); //пауза
  //MessageDlg('NextLine: ' +FNextLine + '; DebugTime: ' +IntToStr(FDebugTime), mtInformation, [mbOk],0);
  for i:=0 to BreakpointsCount-1 do //вдруг брекпойнт на первой "строке"
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
 