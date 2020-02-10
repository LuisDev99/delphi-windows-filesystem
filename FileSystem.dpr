program FileSystem;

uses
  Windows,
  Messages,
  SysUtils,
  StrUtils;

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
  tHandle1 : HWND;
  tHandle2 : HWND;
  i : Integer;
  currentPath : string;

procedure ReleaseResources;
begin
  DestroyWindow(hButton);
  DestroyWindow(hStatic);
  DestroyWindow(hEdit);
  DeleteObject(hFontText);
  DeleteObject(hFontButton);
  PostQuitMessage(0);
end;

function WindowProc(hWnd,Msg:Longint; wParam : WPARAM; lParam: LPARAM):Longint; stdcall;
begin
  case Msg of
      WM_COMMAND: begin
        MessageBox(hMainHandle,'You pressed the button Hello', 'Hello',MB_OK or MB_ICONINFORMATION);
        DestroyWindow(hButton);
        writeLn(lParam);
      end;

      WM_DESTROY: ReleaseResources();
  end;
  Result:=DefWindowProc(hWnd,Msg,wParam,lParam);
end;


procedure DrawDirectory();
  var
    iteratorX : Integer;
    iteratorY : Integer;
    btnWidth : Integer;
    btnHeight : Integer;
begin

       iteratorX := 0;
       iteratorY := 0;
       btnWidth := 150;
       btnHeight := 60;

       tHandle1 := FindFirstFile( PWideChar(currentPath), data); //Get the first file of the C: directory
       //writeln(data.cFileName);

       //Create the button from the first file name
       hButton:=CreateWindow('Button',data.cFileName, WS_VISIBLE or WS_CHILD or BS_PUSHBUTTON or BS_TEXT, 10+(iteratorX*200), 130+(iteratorY*(btnHeight div 2)*3), btnWidth, btnHeight, hMainHandle, 0, hInstance, nil);
       SendMessage(hButton,WM_SETFONT,hFontButton,0);

       //Increment this variable that will be used to make space between all subsequent buttons that will be created
       iteratorX := iteratorX + 1;

       while (FindNextFile(tHandle1, data)) do begin

             //writeln(data.cFileName);
             hButton := CreateWindow('Button', data.cFileName, WS_VISIBLE or WS_CHILD or BS_PUSHBUTTON or BS_TEXT, 10+(iteratorX*200), 130+(iteratorY*(btnHeight div 2)*3), btnWidth, btnHeight, hMainHandle, 0, hInstance, nil);
             SendMessage(hButton,WM_SETFONT,hFontButton,0);
             iteratorX := iteratorX + 1;

             writeln(IfThen(data.dwFileAttributes = 16, 'Is Dir', 'I have no idea'));

             //If five buttons have been created in the row, its time to be in another row
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
  RegisterClass(LWndClass);
  hMainHandle := CreateWindow(LWndClass.lpszClassName,'Window Title', WS_CAPTION or WS_MINIMIZEBOX or WS_SYSMENU or WS_VISIBLE,
      (GetSystemMetrics(SM_CXSCREEN) div 2)-600,
      (GetSystemMetrics(SM_CYSCREEN) div 2)-350, 1200,900,0,0,hInstance,nil);

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

  DrawElements();

  //message loop
  while GetMessage(Msg,0,0,0) do
  begin
    TranslateMessage(Msg);
    DispatchMessage(Msg);
  end;

end.