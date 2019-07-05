unit Unit1;

{$mode objfpc}{$H+}


interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, Menus,
  StdCtrls, BaseUnix, Unix;

type

  { Tcpufreqgui }

  Tcfg = record
    version, gov, max, min : byte;
    tpc, ppc : boolean;
  end;

  Tcpufreqgui = class(TForm)
    Apply: TButton;
    maxBox: TComboBox;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    minBox: TComboBox;
    maxF: TLabel;
    minF: TLabel;
    OpenDialog1: TOpenDialog;
    Quit: TButton;
    mkDefault: TButton;
    SaveDialog1: TSaveDialog;
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
    procedure ApplyClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure MenuItem2Click(Sender: TObject);
    procedure MenuItem3Click(Sender: TObject);
    procedure MenuItem4Click(Sender: TObject);
    procedure MenuItem5Click(Sender: TObject);
    procedure MenuItem6Click(Sender: TObject);
    procedure mkDefaultClick(Sender: TObject);
    procedure QuitClick(Sender: TObject);
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
  governors: TStringList;
  clocksGhz: TStringList;
  i: integer;
  curMin: byte;
  curMax: byte;
  selGov: string;
  msg: longint;
  cfgFile: file of Tcfg;
  cfg: Tcfg;
  sysdc: textfile;
  aStr: string;
  user: integer;
  tpcRep: byte;
  ppcRep: byte;

const
  workPath = '/sys/devices/system/cpu/cpufreq/policy0/';
  ignorePath = '/sys/module/processor/parameters/';
  fileVer = 1;


implementation

{$R *.lfm}

{ Tcpufreqgui }


procedure Tcpufreqgui.Timer1Timer(Sender: TObject);
begin
  refreshInfo;
end;

procedure Tcpufreqgui.Timer1StartTimer(Sender: TObject);
begin
  //refreshInfo;
end;

procedure Tcpufreqgui.FormCreate(Sender: TObject);
begin
  user := fpgeteuid;
  if user <> 0 then
  begin
    Application.MessageBox('Must be run as root!', 'Error');
    halt;
  end;
  if not FileExists(workPath+'scaling_governor') then
  begin
    Application.MessageBox('Cpufrequtils required but not found.', 'Error');
    halt;
  end;
  Timer1.Enabled := true;
  refreshInfo;
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

  AssignFile(theFile, workpath+'scaling_governor');
  reset(theFile);
  ReadLn(theFile, selGov);
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

  AssignFile(theFile, workPath+'scaling_max_freq');
  reset(theFile);
  ReadLn(theFile, stringIn);
  maxBox.Items := clocksGhz;
  for i:=0 to maxBox.Items.Count-1 do
  begin
    if clocks[i] = stringIn then maxBox.ItemIndex:=i;
  end;
  CloseFile(theFile);

  AssignFile(theFile, workPath+'scaling_min_freq');
  reset(theFile);
  ReadLn(theFile, stringIn);
  minBox.Items := clocksGhz;
  for i:=0 to maxBox.Items.Count-1 do
  begin
    if clocks[i] = stringIn then minBox.ItemIndex:=i;
  end;

  AssignFile(theFile, workPath+'scaling_available_governors');
  reset(theFile);
  Readln(theFile, stringIn);
  governors := TStringList.Create;
  governors.Delimiter:=' ';
  governors.DelimitedText := stringIn;
  CloseFile(theFile);
  governorBox.Items := governors;
  for i:=0 to governorBox.Items.Count-1 do
  begin
    if governorBox.Items[i] = selGov then governorBox.ItemIndex := i;
  end;
end;

procedure Tcpufreqgui.MenuItem2Click(Sender: TObject);
begin

end;

procedure Tcpufreqgui.MenuItem3Click(Sender: TObject);
begin
 ShowMessage('Written by Thedarkb'+sLineBreak+'Licensed under the three clause BSD. © 2019'+
 sLineBreak+sLineBreak+'Icon by RJ, also known as Dellguy.'+sLineBreak+sLineBreak+
 'Version 1.0');
end;

procedure Tcpufreqgui.MenuItem4Click(Sender: TObject);
begin
  ShowMessage('If the clock speed will not climb above the BIOS limit, you may'+
  ' need to disable one or both forms of throttling. This has the potential'+
  ' to cause data loss or even damage to your computer so do this only as a'+
  ' last resort on hardware that you are willing to lose.'+sLineBreak+sLineBreak+
  'The "Apply on Boot" button only functions on systemd based distros.'+sLineBreak+sLineBreak+
  'An invalid configuration is usually due to the minimum clock speed being set'+
  ' above the maximum.'+sLineBreak+sLineBreak+
  'Configurations are only valid for the CPUs they were created for.'+sLineBreak+sLineBreak+
  'Issues and suggestions may be posted to'+sLineBreak+
  'https://github.com/thedarkb/cpufreq-gui');
end;

procedure Tcpufreqgui.MenuItem5Click(Sender: TObject);
begin
  if SaveDialog1.Execute then
  begin
    cfg.version := fileVer;
    cfg.gov := governorBox.ItemIndex;
    cfg.min := minBox.ItemIndex;
    cfg.max := maxBox.ItemIndex;
    cfg.tpc := throttleBoxes.Checked[0];
    cfg.ppc := throttleBoxes.Checked[1];

    AssignFile(cfgFile, SaveDialog1.FileName);
    rewrite(cfgFile);
    write(cfgFile, cfg);
    CloseFile(cfgFile);
  end;
end;

procedure Tcpufreqgui.MenuItem6Click(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    AssignFile(cfgFile, OpenDialog1.FileName);
    Reset(cfgFile);
    Read(cfgFile, cfg);
    CloseFile(cfgFile);
    if cfg.version <> fileVer then
    begin
      ShowMessage('Incompatible file version.');
      Exit;
    end;
    if cfg.gov < governorBox.Items.Count then governorBox.ItemIndex := cfg.gov
    else
      begin
        ShowMessage('Invalid configuration.');
        Exit;
      end;
    if cfg.min < minBox.Items.Count then minBox.ItemIndex := cfg.min
    else
      begin
        ShowMessage('Invalid configuration.');
        Exit;
      end;
    if cfg.max < maxBox.Items.Count then maxBox.ItemIndex := cfg.max
    else
      begin
        ShowMessage('Invalid configuration.');
        Exit;
      end;
    throttleBoxes.Checked[0] := cfg.tpc;
    throttleBoxes.Checked[1] := cfg.ppc;
  end;
end;

procedure Tcpufreqgui.mkDefaultClick(Sender: TObject);
begin
  if throttleBoxes.Checked[0] then tpcRep := 1 else tpcRep:=0;
  if throttleBoxes.Checked[1] then ppcRep := 1 else ppcRep:=0;

  AssignFile(theFile, '/etc/tmpfiles.d/cpufreq.conf');
  rewrite(theFile);
  aStr := 'w '+workPath+'scaling_governor - - - - '+governors[governorBox.ItemIndex];
  writeln(theFile, aStr);

  aStr := 'w '+workPath+'scaling_max_freq - - - - '+clocks[maxBox.ItemIndex];
  writeln(theFile, aStr);

  aStr := 'w '+workPath+'scaling_min_freq - - - - '+clocks[minBox.ItemIndex];
  writeln(theFile, aStr);

  aStr := 'w '+ignorePath+'ignore_tpc - - - - '+IntToStr(tpcRep);
  writeln(theFile, aStr);

  aStr := 'w '+ignorePath+'ignore_ppc - - - - '+IntToStr(ppcRep);
  writeln(theFile, aStr);
  CloseFile(theFile);

  fpsystem('systemd-tmpfiles --prefix=/sys --create');
end;

procedure Tcpufreqgui.QuitClick(Sender: TObject);
begin
  halt;
end;

procedure Tcpufreqgui.ApplyClick(Sender: TObject);
label skip;
begin
  if maxBox.ItemIndex > minBox.ItemIndex then
  begin
    msg := Application.MessageBox('Invalid configuration, cannot apply!', 'Error');
    goto skip; //I know it's bad, but it just skips to the end of this procedure.
  end;

  AssignFile(theFile, workPath+'scaling_max_freq');
  rewrite(theFile);
  write(theFile, clocks[maxBox.ItemIndex]);
  CloseFile(theFile);

  AssignFile(theFile, workPath+'scaling_min_freq');
  rewrite(theFile);
  write(theFile, clocks[minBox.ItemIndex]);
  CloseFile(theFile);

  AssignFile(theFile, workPath+'scaling_governor');
  rewrite(theFile);
  write(theFile, governorBox.Items[governorBox.ItemIndex]);
  CloseFile(theFile);

  AssignFile(theFile, ignorePath+'ignore_tpc');
  rewrite(theFile);
  if throttleBoxes.Checked[0] then write(theFile, '1');
  if not throttleBoxes.Checked[0] then write(theFile, '0');
  CloseFile(theFile);

  AssignFile(theFile, ignorePath+'ignore_ppc');
  rewrite(theFile);
  if throttleBoxes.Checked[1] then write(theFile, '1');
  if not throttleBoxes.Checked[1] then write(theFile, '0');
  CloseFile(theFile);
  skip:
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

