program QuickChartTest;

uses
  System.StartUpCopy,
  FMX.Forms,
  ufrmMain in 'ufrmMain.pas' {Form1},
  QuickChart in 'QuickChart.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
