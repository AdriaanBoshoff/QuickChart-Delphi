unit QuickChart;

interface

uses
  System.SysUtils, System.Classes, System.Net.HttpClient, System.Net.URLClient,
  System.JSON, System.NetEncoding;

type
  EApiException = class(Exception)
  private
    FStatusCode: Integer;
    FResponseBody: string;
  public
    constructor Create(const AMessage: string; AStatusCode: Integer; const AResponseBody: string);
    property StatusCode: Integer read FStatusCode;
    property ResponseBody: string read FResponseBody;
  end;

  TChart = class
  private
    FWidth: Integer;
    FHeight: Integer;
    FDevicePixelRatio: Double;
    FFormat: string;
    FBackgroundColor: string;
    FKey: string;
    FVersion: string;
    FConfig: string;
    FScheme: string;
    FHost: string;
    FPort: Integer;

    function BuildBaseJson: TJSONObject;
    function GetBaseUrl: string;
  public
    constructor Create(const AScheme: string = ''; const AHost: string = ''; APort: Integer = 0);

    function GetUrl: string;
    function GetShortUrl: string;
    function ToByteArray: TBytes;
    procedure ToFile(const AFilePath: string);

    property Width: Integer read FWidth write FWidth;
    property Height: Integer read FHeight write FHeight;
    property DevicePixelRatio: Double read FDevicePixelRatio write FDevicePixelRatio;
    property Format: string read FFormat write FFormat;
    property BackgroundColor: string read FBackgroundColor write FBackgroundColor;
    property Key: string read FKey write FKey;
    property Version: string read FVersion write FVersion;
    property Config: string read FConfig write FConfig;
    property Scheme: string read FScheme write FScheme;
    property Host: string read FHost write FHost;
    property Port: Integer read FPort write FPort;
  end;

implementation

{ EApiException }

constructor EApiException.Create(const AMessage: string; AStatusCode: Integer; const AResponseBody: string);
begin
  inherited Create(AMessage);
  FStatusCode := AStatusCode;
  FResponseBody := AResponseBody;
end;

{ TChart }

constructor TChart.Create(const AScheme: string; const AHost: string; APort: Integer);
begin
  inherited Create;

  FWidth := 500;
  FHeight := 300;
  FDevicePixelRatio := 1.0;
  FFormat := 'png';
  FBackgroundColor := 'transparent';

  if AHost <> '' then
  begin
    FHost := AHost;
    if AScheme <> '' then
    begin
      FScheme := AScheme;
      if APort <> 0 then
        FPort := APort
      else if AScheme = 'http' then
        FPort := 80
      else
        FPort := 443;
    end
    else
    begin
      FScheme := 'https';
      FPort := 443;
    end;
  end
  else
  begin
    FScheme := 'https';
    FHost := 'quickchart.io';
    FPort := 443;
  end;
end;

function TChart.GetBaseUrl: string;
begin
  Result := System.SysUtils.Format('%s://%s:%d', [FScheme, FHost, FPort]);
end;

function TChart.BuildBaseJson: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('width', TJSONNumber.Create(FWidth));
  Result.AddPair('height', TJSONNumber.Create(FHeight));
  Result.AddPair('backgroundColor', FBackgroundColor);
  Result.AddPair('devicePixelRatio', TJSONNumber.Create(FDevicePixelRatio));
  Result.AddPair('format', FFormat);
  Result.AddPair('chart', FConfig);
  if FKey <> '' then
    Result.AddPair('key', FKey);
  if FVersion <> '' then
    Result.AddPair('version', FVersion);
end;

function TChart.GetUrl: string;
var
  Params: string;
begin
  if FConfig = '' then
    raise Exception.Create('You must set Config on the QuickChart object before generating a URL');

  Params := 'w=' + IntToStr(FWidth) + '&h=' + IntToStr(FHeight) + '&devicePixelRatio=' + FloatToStr(FDevicePixelRatio) + '&f=' + FFormat + '&bkg=' + TNetEncoding.URL.Encode(FBackgroundColor) + '&c=' + TNetEncoding.URL.Encode(FConfig);

  if FKey <> '' then
    Params := Params + '&key=' + TNetEncoding.URL.Encode(FKey);
  if FVersion <> '' then
    Params := Params + '&v=' + TNetEncoding.URL.Encode(FVersion);

  Result := GetBaseUrl + '/chart?' + Params;
end;

function TChart.GetShortUrl: string;
var
  Http: THTTPClient;
  JsonObj: TJSONObject;
  JsonStr: string;
  RequestBody: TStringStream;
  Response: IHTTPResponse;
  ResponseJson: TJSONObject;
  UrlValue: TJSONValue;
begin
  if FConfig = '' then
    raise Exception.Create('You must set Config on the QuickChart object before generating a URL');

  Http := THTTPClient.Create;
  JsonObj := BuildBaseJson;
  try
    JsonStr := JsonObj.ToJSON;
    RequestBody := TStringStream.Create(JsonStr, TEncoding.UTF8);
    try
      Response := Http.Post(GetBaseUrl + '/chart/create', RequestBody, nil, [TNameValuePair.Create('Content-Type', 'application/json')]);

      if (Response.StatusCode < 200) or (Response.StatusCode >= 300) then
        raise EApiException.Create('Unsuccessful response from API', Response.StatusCode, Response.ContentAsString);

      ResponseJson := TJSONObject.ParseJSONValue(Response.ContentAsString) as TJSONObject;
      try
        UrlValue := ResponseJson.GetValue('url');
        if UrlValue = nil then
          raise Exception.Create('No URL returned in API response');
        Result := UrlValue.Value;
      finally
        ResponseJson.Free;
      end;
    finally
      RequestBody.Free;
    end;
  finally
    JsonObj.Free;
    Http.Free;
  end;
end;

function TChart.ToByteArray: TBytes;
var
  Http: THTTPClient;
  JsonObj: TJSONObject;
  JsonStr: string;
  RequestBody: TStringStream;
  Response: IHTTPResponse;
  ResponseStream: TBytesStream;
begin
  if FConfig = '' then
    raise Exception.Create('You must set Config on the QuickChart object before generating a URL');

  Http := THTTPClient.Create;
  JsonObj := BuildBaseJson;
  try
    JsonStr := JsonObj.ToJSON;
    RequestBody := TStringStream.Create(JsonStr, TEncoding.UTF8);
    ResponseStream := TBytesStream.Create;
    try
      Response := Http.Post(GetBaseUrl + '/chart', RequestBody, ResponseStream, [TNameValuePair.Create('Content-Type', 'application/json')]);

      if (Response.StatusCode < 200) or (Response.StatusCode >= 300) then
        raise EApiException.Create('Unsuccessful response from API', Response.StatusCode, Response.ContentAsString);

      Result := ResponseStream.Bytes;
      SetLength(Result, ResponseStream.Size);
    finally
      RequestBody.Free;
      ResponseStream.Free;
    end;
  finally
    JsonObj.Free;
    Http.Free;
  end;
end;

procedure TChart.ToFile(const AFilePath: string);
var
  Bytes: TBytes;
  Stream: TFileStream;
begin
  Bytes := ToByteArray;
  Stream := TFileStream.Create(AFilePath, fmCreate);
  try
    Stream.WriteBuffer(Bytes[0], Length(Bytes));
  finally
    Stream.Free;
  end;
end;

end.

