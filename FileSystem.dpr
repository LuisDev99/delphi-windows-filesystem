program FileSystem;

uses
  Windows,
  Messages,
  SysUtils,
  CommCtrl,
  Generics.Collections,
  StrUtils,
  ShellApi;

type
  TFileData = record
    findData : WIN32_FIND_DATA;
    handle   : HWND;
  end;
  TFileList = TList<TFileData>;

var
  Msg         : TMSG;
  LWndClass   : TWndClass;
  hMainHandle : HWND;
  hButton     : HWND;
  hTreeView   : HWND;
  hStatic     : HWND;
  hEdit       : HWND;
  hFontText   : HWND;
  hFontButton : HWND;
  fontName    : PWideChar;
  text        : PWideChar;
  hdcc        : HDC;
  rcClient    : TRect;
  hIcon1      : HICON;
  tHandle2    : HWND;
  data        : WIN32_FIND_DATA;
  currentPath : string;
  fileList    : TFileList;
  hPathBtn    : HWND;
  dwAttr      : HWND;
  hdcStatic   : HDC;
  hBitMapy    : HBITMAP;

  hSmallWnd         : HWND;
  hSmallWndEdit     : HWND;
  hSmallOkBtn       : HWND;
  hSmallCancelBtn   : HWND;
  newFileName_str   : string;
  isSmallWndOpen    : Boolean;
  isFileBeingCreated: Boolean;

  hCreateFileBtn  : HWND;
  hCreateDirBtn   : HWND;

label exity;


procedure PaintImage(isDir : Boolean);
var
  rect   : TRect;
  hdxcc  : HDC;
  brush  : HBRUSH;
  bitty  : HBITMAP;
  x      : Integer;
  y      : Integer;
  tempFile : TFileData;
begin

  x := 29;
  y := x;

  hdxcc := GetDC(hStatic);
  bitty := HBITMAP(LoadImage(0, PWideChar('C:/Users/DELL/Documents/Siso2/folderKadosh.bmp'), IMAGE_BITMAP, x, y, LR_LOADFROMFILE));
  brush := CreatePatternBrush(bitty);
  GetWindowRect(hStatic, rect);
  FillRect(hdxcc, rect, brush);
  DeleteObject(brush);
  ReleaseDC(hStatic, hdxcc);
end;

procedure ReleaseResources;
begin
  DestroyWindow(hButton);
  DestroyWindow(hStatic);
  DestroyWindow(hEdit);
  DeleteObject(hFontText);
  DeleteObject(hFontButton);
  PostQuitMessage(0);
end;

procedure UpdatePath(newPath : string);
begin
  currentPath := newPath;
end;

function isPathDirectory(path : string) : Boolean;
var
  fileHandle  : HWND;
begin
  fileHandle := FindFirstFile(PWideChar(path + '*'), data);

  if(fileHandle = 4294967295) then
  begin
    Result := false;
    exit;
  end;

  Result := true;

end;

function CreateAHorizontalScrollBar(hwndParent : HWND; sbHeight : Integer) : HWND;
var
  rect : TRECT;
begin
  if (not GetClientRect(hwndParent, rect)) then
  begin
    Result := 0;
    writeln('Create a horizontal scroll bar function failed');
    exit;
  end;

  Result := CreateWindowEx(0, 'SCROLLBAR', nil, WS_CHILD or WS_VISIBLE or SBS_VERT, rect.Left + sbHeight, rect.Bottom - sbHeight, rect.Right , sbHeight, hwndParent, 0, hInstance, nil );

end;

function GetFileFromHandle(handle : HWND) : TFileData;
var
  tempFile : TFileData;
begin
  for tempFile in fileList do
    begin
      if(tempFile.handle = handle) then
      begin
        Result := tempFile;
        exit;
      end;
    end;
end;

function DrawFile(iteratorX : Integer; iteratorY : Integer; data : WIN32_FIND_DATA) : HWND;
var
  btnWidth  : Integer;
  btnHeight : Integer;
  handle    : HWND;

begin
  btnWidth  := 150;
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

  fileList.Add(fileData);
end;

procedure DrawDirectory();
  var
    iteratorX   : Integer;
    iteratorY   : Integer;
    handle      : HWND;
    fileHandle  : HWND;
    tempFile    : TFileData;
begin
  iteratorX := 0;
  iteratorY := 0;

  if(not isPathDirectory(currentPath + '*')) then
  begin
    exit;
  end;

  fileHandle := FindFirstFile(PWideChar(currentPath + '*'), data);

  handle := DrawFile(iteratorX, iteratorY, data);
  AddFileToList(data, handle);

  //Increment this variable that will be used to make space between all subsequent buttons that will be created
  iteratorX := iteratorX + 1;

  while (FindNextFile(fileHandle, data)) do begin

    handle := DrawFile(iteratorX, iteratorY, data);
    AddFileToList(data, handle);

    iteratorX := iteratorX + 1;

    //writeln(IfThen(data.dwFileAttributes = 16, 'Is Dir', 'I have no idea'));

    if ((iteratorX mod 6 = 0)) then
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

  pathStr := currentPath;

  //Textbox with the latest currentPath
  hEdit := CreateWindowEx(2, 'Edit', PWideChar(pathStr), WS_VISIBLE or WS_CHILD or ES_LEFT or ES_AUTOHSCROLL,70,35,900,33,hMainHandle,0,hInstance,nil);

  SendMessage(hEdit,WM_SETFONT,hFontText,0);

  DrawDirectory();
end;

procedure DestroyAllFiles();
var
  tempFile : TFileData;
begin
   for tempFile in fileList do
   begin
     DestroyWindow(tempFile.handle);
   end;

   fileList.Clear();
end;

function isCommandFromAButton(lParam: LPARAM) :  Boolean;
var
  tempFile : TFileData;
begin

  if( (lParam = hPathBtn) or
      (lParam = hSmallOkBtn) or
      (lParam = hSmallCancelBtn)
  ) then
  begin
       Result := true;
       exit;
  end;

  for tempFile in fileList do
   begin
     if(tempFile.handle = lParam) then
     begin
       Result := true;
       exit;
     end;
   end;

   Result := false;
end;

procedure ShowMessageBox(str_message : string);
var
  wndWidth  : Integer;
  wndHeight : Integer;
begin
  wndWidth := 270;
  wndHeight := 270;

  newFileName_str := ''; //Reset file name

  hSmallWnd := CreateWindow(LWndClass.lpszClassName,'Best File System', WS_CAPTION or WS_MINIMIZEBOX or WS_SYSMENU or WS_VISIBLE,
      (GetSystemMetrics(SM_CXSCREEN) div 2)-400,
      (GetSystemMetrics(SM_CYSCREEN) div 2)-250, wndWidth,wndHeight,0,0, hInstance,nil);

  //Label
  CreateWindow('Static', PWideChar(str_message), WS_VISIBLE or WS_CHILD or WS_EX_TRANSPARENT, (wndWidth div 2) - 85, (wndHeight div 2) - 120, 170, 20, hSmallWnd, 0, hInstance, nil);

  //Label
  CreateWindow('Static', '>', WS_VISIBLE or WS_CHILD or WS_EX_TRANSPARENT, 10, (wndHeight div 2) - 55, 10, 15, hSmallWnd, 0, hInstance, nil);

  //Textbox
  hSmallWndEdit := CreateWindowEx(2, 'Edit', PWideChar(newFileName_str), WS_VISIBLE or WS_CHILD or ES_LEFT or ES_AUTOHSCROLL or WS_BORDER, 20, (wndHeight div 2) - 60, wndWidth - 40, 30, hSmallWnd,0,hInstance,nil);

  //Create file btn
  hSmallOkBtn := CreateWindow('Button', 'Create', WS_VISIBLE or WS_CHILD or BS_PUSHBUTTON or BS_TEXT, (wndWidth div 2) - 120, (wndWidth div 2) + 40, 100, 40, hSmallWnd, 0, hInstance, nil);

  //Create file btn
  hSmallCancelBtn := CreateWindow('Button', 'Cancel', WS_VISIBLE or WS_CHILD or BS_PUSHBUTTON or BS_TEXT, (wndWidth div 2), (wndWidth div 2) + 40, 100, 40, hSmallWnd, 0, hInstance, nil);

end;

procedure KillMessageBox();
begin
  DestroyWindow(hSmallWnd);

  //Reset variables
  isSmallWndOpen := false;
  newFileName_str := '';
end;

procedure HandleCreation();
var
  bTest            : Boolean;
  hFile            : HWND;
  fileAttr         : Integer;
  fileCompleteName : string;
begin

  fileAttr := FILE_ATTRIBUTE_NORMAL;

  bTest := false;
  fileCompleteName := currentPath + '\\' + newFileName_str;

  if(isFileBeingCreated = true) then
  begin
    hFile := CreateFile(PWideChar(fileCompleteName), GENERIC_READ, FILE_SHARE_READ, nil, CREATE_NEW, FILE_ATTRIBUTE_NORMAL, 0);
  end
  else begin
    fileAttr := FILE_ATTRIBUTE_DIRECTORY;
    bTest := CreateDirectory(PWideChar(fileCompleteName), 0);

    if(bTest = false) then
    begin
      writeln('Creation of dir failed: ', SysErrorMessage(GetLastError));
    end;
    exit;
  end;

  bTest := CloseHandle(hFile);

  if (bTest = false) then
  begin
    writeln('File: ', fileCompleteName, ' was not created');
  end
  else
    writeln(fileCompleteName, ' -> I was created');

end;

function WindowProc(hWnd, Msg:Longint; wParam : WPARAM; lParam: LPARAM):Longint; stdcall;
var
  fileData          : TFileData;
  isDirectory       : Boolean;
  str               : string;
  editText          : PWideChar;
  size              : Integer;
  buffer            : array[0..1023] of char;
  pathFromTheFuture : string;
  command           : string;
label exity, destroySmallWnd, repaintFS;
begin

  case Msg of
      WM_VSCROLL: begin
        writeln('Scrolling');
      end;

      WM_MOUSEHWHEEL: begin
        write('Mouse wheeling');
      end;

      WM_COMMAND: begin

        //If command is from an event fired from the search textbox, grab the textbox's text and update the path
        if(lParam = hEdit) then
        begin
          editText := buffer;
          GetWindowText(hEdit, editText, 1024);
          { writeln('Textbox text: ', editText); }
          UpdatePath(editText);
          goto exity;
        end;

        //If command is from an event fired from the message box's textbox, grab the textbox's text and update the path
        if(lParam = hSmallWndEdit) then
        begin
          editText := buffer;
          GetWindowText(hSmallWndEdit, editText, 1024);
          { writeln('Message box textbox text: ', editText); }
          newFileName_str := editText;
          goto exity;
        end;

        //Check for the create file button event
        if(lParam = hCreateFileBtn) then
        begin

          //If the message box window is open, dont proceed
          if(isSmallWndOpen) then
            goto exity;

          isFileBeingCreated := true;
          ShowMessageBox('Enter the file name');
          isSmallWndOpen := true;
        end;

        //Check for the create directory button event
        if(lParam = hCreateDirBtn) then
        begin

          //If the message box window is open, dont proceed
          if(isSmallWndOpen) then
            goto exity;

          isFileBeingCreated := false; //Directory is whats being created
          ShowMessageBox('Enter the directory name');
          isSmallWndOpen := true;
        end;


        {
          When creating a textbox, the OS fires an event and enters to this
          code section, and falls through the WM_COMMAND case from the switch statement
          And doing so, it will go through an infinite loop because this case statement
          repaints the screen every time (thus, firing an event again), but we
          only want to repaint if a file was clicked, soo check if the handle is
          a button handle, if its not a button handle, then exit the function
          because its another action like editing the text box or something else
          and we want to stop repainting the screen because it will raise an event
        }
        if((not isCommandFromAButton(lParam))) then  //This saves a lot of lifes
          goto exity;

        //Process the cancel button from the message box
        if(lParam = hSmallCancelBtn) then
        begin
          KillMessageBox();
          goto exity;
        end;

        //Process the create button from the message box
        if(lParam = hSmallOkBtn) then
        begin
          HandleCreation();
          KillMessageBox();
          goto repaintFS;
        end;

        //If a button was clicked, lParam will have the handle of the button
        fileData := GetFileFromHandle(lParam);

        str := fileData.findData.cFileName;

        pathFromTheFuture := IfThen(hPathBtn = lParam, currentPath, (currentPath + str + '\\'));

        if(not isPathDirectory(pathFromTheFuture)) then
        begin
          command := 'Unknown file extension';

          MessageBox(hMainHandle,'Its a file!', 'Hello', MB_OK or MB_ICONINFORMATION);
          pathFromTheFuture := pathFromTheFuture.Remove(pathFromTheFuture.LastIndexOf('\') - 1);  //Get rid of the '\\' from the string

          if(pathFromTheFuture.Contains('.exe')) then
          begin
            command := 'open';
            ShellExecute(HInstance, PWideChar(command), PWideChar(pathFromTheFuture), nil, nil, SW_SHOWNORMAL);
            goto exity;
          end;

          { Execute custom commands }
          if(pathFromTheFuture.Contains('.txt')) then
          begin
            command := 'code';
          end;

          if(not (command = 'Unknown file extension')) then
            begin
              ShellExecute(HInstance, nil, PWideChar(command), PWideChar(pathFromTheFuture), nil, SW_SHOWNORMAL);
              writeln(SysErrorMessage(GetLastError));
            end
          else
            begin
              writeln('unknown file extension ok?');
            end;

          goto exity;
        end;


        UpdatePath(pathFromTheFuture);

        DestroyWindow(hEdit); //Destroy the label that shows the current path to display the new path

        repaintFS:
          DestroyAllFiles();
          DrawElements(); //Repaint new path directory
      end;

      WM_DESTROY: begin

        {
          If the window that is getting close is the message box window,
          then just destroy that window and avoid closing the entire
          application by just checking if the incoming window handle is equal
          to the hSmallWnd handle (which is the message box window)
        }
        if(hSmallWnd = hWnd) then
        begin
          KillMessageBox();
          goto exity;
        end;

        ReleaseResources();

      end;
  end;

  exity:
    Result:=DefWindowProc(hWnd,Msg,wParam,lParam);
end;


begin
  LWndClass.hInstance := hInstance;

  with LWndClass do
    begin
      lpszClassName := 'MyWinApiWnd';
      Style         := CS_PARENTDC or CS_BYTEALIGNCLIENT;
      hIcon         := LoadIcon(hInstance,'MAINICON');
      lpfnWndProc   := @WindowProc;
      hbrBackground := COLOR_BTNFACE;
      hCursor       := LoadCursor(0,IDC_ARROW);
    end;

  Windows.RegisterClass(lWndClass);

  //Main Window
  hMainHandle := CreateWindow(LWndClass.lpszClassName,'Window Title', WS_CAPTION or WS_MINIMIZEBOX or WS_SYSMENU or WS_VISIBLE or WS_VSCROLL,
      (GetSystemMetrics(SM_CXSCREEN) div 2)-600,
      (GetSystemMetrics(SM_CYSCREEN) div 2)-350, 1200,650,0,0,hInstance,nil);

  //CreateAHorizontalScrollBar(hMainHandle, (GetSystemMetrics(SM_CYSCREEN) div 2)-350);

  fontName := 'Comic Sans MS';

  //Create the fonts to use
  hFontText := CreateFont(-20,0,0,0,0,0,0,0,DEFAULT_CHARSET,OUT_DEFAULT_PRECIS,CLIP_DEFAULT_PRECIS,DEFAULT_QUALITY,VARIABLE_PITCH or FF_SWISS, fontName);
  hFontButton := CreateFont(-14,0,0,0,0,0,0,0,DEFAULT_CHARSET,OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,DEFAULT_QUALITY,VARIABLE_PITCH or FF_SWISS, fontName);

  currentPath := 'C:\\';
  fileList := TList<TFileData>.Create;

  //Label
  hStatic := CreateWindow('Static', 'Path: ', WS_VISIBLE or WS_CHILD or WS_EX_TRANSPARENT, 20, 35, 40, 40, hMainHandle, 0, hInstance, nil);
  SendMessage(hStatic, WM_SETFONT, hFontText, 0);


  //Search btn
  hPathBtn := CreateWindow('Button', 'Search', WS_VISIBLE or WS_CHILD or BS_PUSHBUTTON or BS_TEXT, 70, 75, 100, 40, hMainHandle, 0, hInstance, nil);
  SendMessage(hPathBtn,WM_SETFONT,hFontButton,0);

  //Create file btn
  hCreateFileBtn := CreateWindow('Button', 'Create File', WS_VISIBLE or WS_CHILD or BS_PUSHBUTTON or BS_TEXT, 180, 75, 100, 40, hMainHandle, 0, hInstance, nil);
  SendMessage(hCreateFileBtn,WM_SETFONT,hFontButton,0);

  //Create directory btn
  hCreateDirBtn := CreateWindow('Button', 'Create Directory', WS_VISIBLE or WS_CHILD or BS_PUSHBUTTON or BS_TEXT, 290, 75, 120, 40, hMainHandle, 0, hInstance, nil);
  SendMessage(hCreateDirBtn,WM_SETFONT,hFontButton,0);


  DrawElements();

  //  PAINT
  //PaintImage(true);

  //ShowMessageBox('Enter the new file name');

  while GetMessage(Msg,0,0,0) do
  begin
    TranslateMessage(Msg);
    DispatchMessage(Msg);
  end;

end.
