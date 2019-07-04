unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, Menus,
  StdCtrls;

type

  { Tcpufreqgui }

  Tcpufreqgui = class(TForm)
    Apply: TButton;
    maxBox: TComboBox;
    minBox: TComboBox;
    maxF: TLabel;
    minF: TLabel;
    Quit: TButton;
    mkDefault: TButton;
    throttleBoxes: TCheckGroup;
    governorBox: TComboBox;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Governor: TLabel;
    Label2: TLabel;
    bios: TLabel;
    Label4: TLabel;
    maxFreq: TLabel;
    Label6: TLabel;
    minFreq: TLabel;
    Label8: TLabel;
    curLbl: TLabel;
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure Timer1StartTimer(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure refreshInfo;
  private

  public

  end;

var
  cpufreqgui: Tcpufreqgui;
  intIn: longint;
  running: boolean;
  theFile: textfile;
  stringIn: string;
  testString: string;
  ghzVal: real;
  clocks: TStringList;
  clocksGhz: TStringList;
  i: integer;

const
  workPath = '/sys/devices/system/cpu/cpufreq/policy0/';
  ignorePath = '/sys/module/processor/parameters/';


implementation

{$R *.lfm}

{ Tcpufreqgui }

procedure Tcpufreqgui.Timer1Timer(Sender: TObject);
begin
  refreshInfo;
end;

procedure Tcpufreqgui.Timer1StartTimer(Sender: TObject);
begin
  refreshInfo;
end;

procedure Tcpufreqgui.FormCreate(Sender: TObject);
begin
  AssignFile(theFile, ignorepath+'ignore_ppc');
  reset(theFile);
  Readln(theFile, stringIn);
  val(stringIn, intIn);
  if intIn = 1 then
  throttleBoxes.Checked[1] := true;
  CloseFile(theFile);

  AssignFile(theFile, ignorepath+'ignore_tpc');
  reset(theFile);
  Readln(theFile, stringIn);
  val(stringIn, intIn);
  if intIn = 1 then
  throttleBoxes.Checked[0] := true;
  CloseFile(theFile);

  AssignFile(theFile, workPath+'scaling_available_frequencies');
  reset(theFile);
  Readln(theFile, stringIn);
  clocks := TStringList.Create;
  clocks.Delimiter:=' ';
  clocks.DelimitedText := stringIn;
  CloseFile(theFile);
  clocksGhz := TStringList.Create;
  for i:=0 to clocks.Count-1 do
  begin
    val(clocks[i], ghzVal);
    ghzVal := ghzVal / 100;
    str(ghzVal, stringIn);
    clocksGhz.Add(LeftStr(stringIn, 5)+'GHz');
  end;
  maxBox.Items := clocksGhz;
  minBox.Items := clocksGhz;
end;


procedure Tcpufreqgui.refreshInfo;
begin
  AssignFile(theFile, workPath+'cpuinfo_cur_freq');
  reset(theFile);
  ReadLn(theFile, stringIn);
  val(stringIn, ghzVal);
  ghzVal := ghzVal / 100;
  Str(ghzVal, stringIn);
  stringIn := LeftStr(stringIn, 5)+'GHz';
  curLbl.Caption := stringIn;
  CloseFile(theFile);

  AssignFile(theFile, workPath+'bios_limit');
  reset(theFile);
  ReadLn(theFile, stringIn);
  val(stringIn, ghzVal);
  ghzVal := ghzVal / 100;
  Str(ghzVal, stringIn);
  stringIn := LeftStr(stringIn, 5)+'GHz';
  bios.Caption := stringIn;
  CloseFile(theFile);

  AssignFile(theFile, workPath+'cpuinfo_min_freq');
  reset(theFile);
  ReadLn(theFile, stringIn);
  val(stringIn, ghzVal);
  ghzVal := ghzVal / 100;
  Str(ghzVal, stringIn);
  stringIn := LeftStr(stringIn, 5)+'GHz';
  minFreq.Caption := stringIn;
  CloseFile(theFile);

  AssignFile(theFile, workPath+'cpuinfo_max_freq');
  reset(theFile);
  ReadLn(theFile, stringIn);
  val(stringIn, ghzVal);
  ghzVal := ghzVal / 100;
  Str(ghzVal, stringIn);
  stringIn := LeftStr(stringIn, 5)+'GHz';
  maxFreq.Caption := stringIn;
  CloseFile(theFile);


end;

end.

