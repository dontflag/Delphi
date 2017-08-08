unit Delphi_threads_applying;

interface

procedure RunProc;

implementation

procedure RunProc;
var
  i: integer;

begin
  if DebugMode <> rmAuto then
    Takt := Takt+1;
  case DebugMode of
    rmAuto: begin
        if BP.Count>0 then
          CurLine := BP[0]
        else begin
          if DebugDummyForm = nil then
            DebugDummyForm := DebugDummyForm.Create(Application);
          DebugThread := TDebugThread.Create(True);
          DebugThread.Priority := tpNormal;
          DebugThread.FreeOnTerminate:=true;
          DebugThread.Resume;
        end;
        ModeStr := 'Auto_'; //значения обновляются по окончании прогона
      end;
    rmStep: ModeStr := 'Step_';
    rmInto: ModeStr := 'Into_';
    rmToEOF: ModeStr := 'ToEOF_';
  end;
  if ((BP.Count = 0) and (ModeStr = 'Auto_')) then
    Exit;
  if BP.Count > 0 then
    CurLine := BP[0]
  else
    CurLine := '0.0';
  for i:=0 to DebuggerGlobals.Count-1 do
    TSCustomObject(DebuggerGlobals.Objects[i]).DebugValue := {ModeStr+}IntToStr(i);//+ ') ' +TSCustomObject(Globals.Objects[i]).DebugValue;
  for i:=0 to DebuggerLocals.Count-1 do
    TSCustomObject(DebuggerLocals.Objects[i]).DebugValue := {ModeStr+}IntToStr(i);//+ ') ' +TSCustomObject(Locals.Objects[i]).DebugValue;

end;

end.
 