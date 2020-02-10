program FileSystem;

uses
  Windows,
  Messages,
  SysUtils,
  Generics.Collections,
  StrUtils;

type
  TFileData = record
    findData : WIN32_FIND_DATA;
    handle : HWND;
  end;
  TFileList = TList<TFileData>;

var
  Msg        : TMSG;
  LWndClass  : TWndClass;
  hMainHandle: HWND;
  hButton    : HWND;
  hTreeView  : HWND;
  hStatic    : HWND;
  hEdit      : HWND;
  hFontText  : HWND;
  hFontButton: HWND;
  fontName : PWideChar;
  text: PWideChar;
  hdcc: HDC;
  rcClient: TRect;
  hIcon1 : HICON;

  //MyData
  data: WIN32_FIND_DATA;
  fileHandle : HWND;
  tHandle2 : HWND;
  currentPath : string;
  files : TFileList;

procedure ReleaseResources;
begin
  DestroyWindow(hButton);
  DestroyWindow(hStatic);
  DestroyWindow(hEdit);
  DeleteObject(hFontText);
  DeleteObject(hFontButton);
  PostQuitMessage(0);
end;


function GetFileFromHandle(handle : HWND) : TFileData;
var
  tempFile : TFileData;
begin
  for tempFile in files do
    begin
      if(tempFile.handle = handle) then
      begin
        Result := tempFile;
        exit;
      end;
    end;
end;

function WindowProc(hWnd, Msg:Longint; wParam : WPARAM; lParam: LPARAM):Longint; stdcall;
var
  fileData : TFileData;
  isDirectory : Boolean;
begin
  case Msg of
      WM_COMMAND: begin

        writeLn('hwnd: ', hWnd, ' wParam: ', wParam, ' lParam: ', lParam);

        fileData := GetFileFromHandle(lParam);

        writeln(fileData.findData.cFileName);

        isDirectory := fileData.findData.dwFileAttributes = 16;

        //MessageBox(hMainHandle,'You pressed the button Hello', 'Hello',MB_OK or MB_ICONINFORMATION);
        //DestroyWindow(hButton);
        //writeLn(lParam);
      end;

      WM_DESTROY: ReleaseResources();
  end;
  Result:=DefWindowProc(hWnd,Msg,wParam,lParam);
end;

function DrawFile(iteratorX : Integer; iteratorY : Integer) : HWND;
var
  btnWidth : Integer;
  btnHeight : Integer;
  handle : HWND;

begin
  btnWidth := 150;
  btnHeight := 60;

  //Create the button with the file name
  handle :=CreateWindow('Button', data.cFileName, WS_VISIBLE or WS_CHILD or BS_PUSHBUTTON or BS_TEXT, 10+(iteratorX*200), 130+(iteratorY*(btnHeight div 2)*3), btnWidth, btnHeight, hMainHandle, 0, hInstance, nil);
  SendMessage(hButton,WM_SETFONT,hFontButton,0);

  Result := handle; //Return the newly created handle (in this case, a button handle)
end;


procedure AddFileToList(data: WIN32_FIND_DATA; handle : HWND);
var
  fileData : TFileData;
begin
  fileData.findData := data;
  fileData.handle := handle;

  files.Add(fileData);
end;

procedure DrawDirectory();
  var
    iteratorX : Integer;
    iteratorY : Integer;
    handle : HWND;
    i : Integer;
    tempFile : TFileData;
begin
       iteratorX := 0;
       iteratorY := 0;

       fileHandle := FindFirstFile(PWideChar(currentPath), data);

       handle := DrawFile(iteratorX, iteratorY);
       AddFileToList(data, handle);

       //Increment this variable that will be used to make space between all subsequent buttons that will be created
       iteratorX := iteratorX + 1;

       while (FindNextFile(fileHandle, data)) do begin

        handle := DrawFile(iteratorX, iteratorY);
        AddFileToList(data, handle);

        iteratorX := iteratorX + 1;

        //writeln(IfThen(data.dwFileAttributes = 16, 'Is Dir', 'I have no idea'));

        if ((iteratorX mod 5 = 0)) then
          begin
            iteratorY := iteratorY + 1;
            iteratorX := 0;
          end;

       end;

end;

procedure DrawElements;
var
  pathStr : string;
begin
  //RegisterClass(tagWin LWndClass);
  Windows.RegisterClass(lWndClass);
  hMainHandle := CreateWindow(LWndClass.lpszClassName,'Window Title', WS_CAPTION or WS_MINIMIZEBOX or WS_SYSMENU or WS_VISIBLE or WS_VSCROLL,
      (GetSystemMetrics(SM_CXSCREEN) div 2)-600,
      (GetSystemMetrics(SM_CYSCREEN) div 2)-350, 1200,650,0,0,hInstance,nil);

  fontName := 'Comic Sans MS';

  //Create the fonts to use
  hFontText := CreateFont(-35,0,0,0,0,0,0,0,DEFAULT_CHARSET,OUT_DEFAULT_PRECIS,CLIP_DEFAULT_PRECIS,DEFAULT_QUALITY,VARIABLE_PITCH or FF_SWISS, fontName);
  hFontButton := CreateFont(-14,0,0,0,0,0,0,0,DEFAULT_CHARSET,OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,DEFAULT_QUALITY,VARIABLE_PITCH or FF_SWISS, fontName);

  pathStr := 'Directory: ' + currentPath;
  pathStr := pathStr.Remove(pathStr.IndexOf('*')); //Get rid of the asterisk

  hStatic := CreateWindow('Static', PWideChar(pathStr), WS_VISIBLE or WS_CHILD or SS_LEFT, 10, 10, 360, 44, hMainHandle, 0, hInstance, nil);
  SendMessage(hStatic,WM_SETFONT,hFontText,0);

  DrawDirectory();
end;

begin
  //create the window
  LWndClass.hInstance := hInstance;

  //initialize struct
  with LWndClass do
    begin
      lpszClassName := 'MyWinApiWnd';
      Style         := CS_PARENTDC or CS_BYTEALIGNCLIENT;
      hIcon         := LoadIcon(hInstance,'MAINICON');
      lpfnWndProc   := @WindowProc;
      hbrBackground := COLOR_BTNFACE+1;
      hCursor       := LoadCursor(0,IDC_ARROW);
    end;

  currentPath := 'C:\\*';
  files := TList<TFileData>.Create;

  DrawElements();

  //message loop
  while GetMessage(Msg,0,0,0) do
  begin
    TranslateMessage(Msg);
    DispatchMessage(Msg);
  end;

end.
