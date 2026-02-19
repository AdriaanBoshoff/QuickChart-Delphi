unit ufrmMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects;

type
  TForm1 = class(TForm)
    btn1: TButton;
    img1: TImage;
    procedure btn1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses
  QuickChart;

{$R *.fmx}

procedure TForm1.btn1Click(Sender: TObject);
begin
  var chart := TChart.Create;
  try
    chart.Width := Trunc(img1.Width);
    chart.Height := Trunc(img1.Height);
    chart.Config := '''
            {
                type: 'line',
                data: {
                    labels: ['Q1', 'Q2', 'Q3', 'Q4'],
                    datasets: [{
                    label: 'Users',
                    data: [50, 60, 70, 180]
                    }]
                }
            }
            ''';

    chart.ToFile('.\test.png');

    img1.Bitmap.LoadFromFile('.\test.png');
  finally
    chart.Free;
  end;
end;

end.

