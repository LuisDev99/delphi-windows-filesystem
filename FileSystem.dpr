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
    hLabel   : HWND;
  end;
  THandles = record
    mainHandle : HWND;
    hLabel     : HWND;
  end;
  TFileList = TList<TFileData>;
  TFiles = TList<WIN32_FIND_DATA>;

const BackFileIconPath = 'C:/Users/DELL/Documents/Siso2/backIcon_bmp.bmp';
const FolderIconPath = 'C:/Users/DELL/Documents/Siso2/Windows_folder_icon_bmp.bmp';
const FileIconPath = 'C:/Users/DELL/Documents/Siso2/file_icon2_bmp.bmp';
const TextFileIconPath = 'C:/Users/DELL/Documents/Siso2/txtIcon_bmp.bmp';
const SearchIconPath = 'C:/Users/DELL/Documents/Siso2/searchIcon2_bmp.bmp';
const CreateFileIconPath = 'C:/Users/DELL/Documents/Siso2/createFileIcon_bmp.bmp';
const CreateFolderIconPath = 'C:/Users/DELL/Documents/Siso2/createFolderIcon_bmp.bmp';
const ExecutableFileIconPath = 'C:/Users/DELL/Documents/Siso2/exeFileIcon_1_bmp.bmp';

const DELETE_FILE_ID = 21010101;
const COPY_FILE_ID = 41010101;

var
  Msg               : TMSG;
  LWndClass         : TWndClass;
  hMainHandle       : HWND;
  hButton           : HWND;
  hTreeView         : HWND;
  hStatic           : HWND;
  hEdit             : HWND;
  hFontText         : HWND;
  hFontFiles        : HWND;
  hFontButton       : HWND;
  fontName          : PWideChar;
  data              : WIN32_FIND_DATA;
  currentPath       : string;
  fileList          : TFileList;
  pureFileList      : TFiles;
  hPathBtn          : HWND;
  hUpBtn            : HWND;
  hDownBtn          : HWND;

  newFileName_str   : string;
  isSmallWndOpen    : Boolean;
  isFileBeingCreated: Boolean;

  hPrev             : HTREEITEM;
  hPrevRootItem     : HTREEITEM;
  hPrevLev2Item     : HTREEITEM;

  g_nOpen           : Integer;
  g_nClosed         : Integer;
  g_nDocument       : Integer;

  nLevel            : Integer;

  selectedFileOrDir : HWND;

  hCreateFileBtn, hCreateDirBtn  : HWND;
  hCreateFileIcon, hCreateFolderIcon, hBackIcon : HBITMAP;
  FileExtensionIconMap : TDictionary<string, HBITMAP>;
  hSmallWnd, hSmallWndEdit, hSmallOkBtn, hSmallCancelBtn : HWND;
  hFolderIcon, hFileIcon, hTxtFileIcon, hExeFileIcon, hSearchPathIcon : HBITMAP;

label exity;

procedure InitTreeViewImageListView();
var
 himl   : HIMAGELIST;
 hbmp   : HBITMAP;
begin
 himl := ImageList_Create(60, 60, 0, 32, 0);
 writeln('Creating Image List Status: ', SysErrorMessage(GetLastError));

 g_nOpen     := ImageList_Add(himl, hFileIcon, HBITMAP(0));
 g_nClosed   := ImageList_Add(himl, hFolderIcon, HBITMAP(0));
 g_nDocument := ImageList_Add(himl, hSearchPathIcon, HBITMAP(0));

 TreeView_SetImageList(hTreeView, himl, TVSIL_NORMAL);

end;

function AddItemToTree( strName : string; nLevel : Integer ) : HTREEITEM;
var
  tvi   : tagTVITEMA;
  tvins : tagTVINSERTSTRUCTA;
  hti   : HTREEITEM;
begin

  tvi.mask := TVIF_TEXT or TVIF_IMAGE or TVIF_SELECTEDIMAGE or TVIF_PARAM;

  //Set text of the item
  tvi.pszText    := PansiChar(strName);
  tvi.cchTextMax := SizeOf(tvi.pszText) div SizeOf(tvi.pszText[0]);

  //Assume the item is not a parent item, so give it a document image
  tvi.iImage := 1;
  tvi.iSelectedImage := 1;

  //Save the heading level in the item's application-defined data area
  tvi.lParam := LParam(nLevel);
  tvins.item := tvi;
  tvins.hInsertAfter := hPrev;

  //Set the parent item based on the specified level
  if(nLevel = 1) then
    begin
      tvins.hParent := TVI_ROOT;
    end
   else if(nLevel = 2) then
    begin
      tvins.hParent := hPrevRootItem;
    end
   else
    tvins.hParent := hPrevLev2Item;


   //Add the item to the tree-view control
   hPrev := HTREEITEM(SendMessage(hTreeView, TVM_INSERTITEM, 0, tvi.lParam));

   if(hPrev = nil) then
   begin
    Result := nil;
    exit;
   end;

   if(nLevel = 1) then
     begin
      hPrevRootItem := hPrev;
     end
   else if(nLevel = 2) then
     begin
       hPrevLev2Item := hPrev;
     end;


   if(nLevel > 1) then
   begin
    hti := TreeView_GetParent(hTreeView, hPrev);
    tvi.mask := TVIF_IMAGE or TVIF_SELECTEDIMAGE;
    tvi.hItem := hti;
    tvi.iImage := g_nClosed;
    tvi.iSelectedImage := g_nClosed;
    TreeView_SetItemA(hTreeView, tvi);
   end;

   Result := hPrev;
end;

procedure InitTreeViewItems();
var
  hti : HTREEITEM;
  i: Integer;
begin
  for i := 0 to 5 do
  begin
    hti := AddItemToTree('Hola' + IntToStr(i), i);

    if(hti = nil) then
    begin
      writeln('Did not work, try harder');
      exit;
    end;
  end;


end;

procedure CreateTreeView();
var
  rcClient  : TRect;
begin
  InitCommonControls();

  GetClientRect(hMainHandle, rcClient);

  hTreeView := CreateWindowEx(0, WC_TREEVIEW, 'Tree View', WS_VISIBLE or WS_CHILD or WS_BORDER or TVS_HASLINES, 10, 130, 180, 550, hMainHandle, 0, hInstance, 0);

  InitTreeViewImageListView();
  InitTreeViewItems();

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

function GetIconFromFileExtension(fileName : string) : HBITMAP;
var
  icon  : HBITMAP;
begin
  //Lazy checking to see if the fileName is a directory or not
  if(not fileName.Contains('.')) then
    begin
       FileExtensionIconMap.TryGetValue('folder', icon);
    end
  else
    begin
      if(fileName.Equals('..')) then
        begin
          FileExtensionIconMap.TryGetValue('back', icon);
        end
      else if(fileName.Contains('.exe')) then
        begin
          FileExtensionIconMap.TryGetValue('exe', icon);
        end
      else if(fileName.Contains('.txt')) then
        begin
          FileExtensionIconMap.TryGetValue('txt', icon);
        end
      else
        begin
          FileExtensionIconMap.TryGetValue('file', icon);
        end
    end;

  Result := icon;

end;

function isPathDirectory(path : string) : Boolean;
var
  fileHandle  : HWND;
  filePath    : string;
begin
  filePath := path + '*';

  fileHandle := FindFirstFile(PWideChar(filePath), data);

  if(fileHandle = 4294967295) then
  begin
    Result := false;
    exit;
  end;

  Result := true;

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

function DrawFile(iteratorX : Integer; iteratorY : Integer; data : WIN32_FIND_DATA) : THandles;
var
  btnWidth  : Integer;
  btnHeight : Integer;
  handles   : THandles;
  xPos      : Integer;
  yPos      : Integer;
  labelWidth: Integer;
  hFileIcon : HBITMAP;
begin
  btnWidth  := 80;
  btnHeight := 80;

  labelWidth := string(data.cFileName).Length * 2 + 100; //Label's width will be according to the file name size

  xPos :=  200 + (iteratorX * 150);
  yPos :=  130 + (iteratorY * (btnHeight div 2) * 3);

  hFileIcon := GetIconFromFileExtension(data.cFileName);

  //Create the button with a background image
  handles.mainHandle := CreateWindowW('Button', data.cFileName, WS_VISIBLE or WS_CHILD or BS_BITMAP, xPos, yPos, btnWidth, btnHeight, hMainHandle, 0, hInstance, nil);
  SendMessageW(handles.mainHandle,BM_SETIMAGE,IMAGE_BITMAP, LPARAM(hFileIcon));

  //Create the label which contains the file name
  handles.hLabel := CreateWindowEx(2,'Edit', data.cFileName, WS_VISIBLE or WS_CHILD or ES_LEFT, xPos, yPos + btnHeight + 10, labelWidth, 20,hMainHandle,0,hInstance,nil);
  SendMessage(handles.hLabel,WM_SETFONT,hFontFiles,0);

  Result := handles; //Returns the newly created handle (in this case, a button handle)
end;

procedure AddFileToList(data: WIN32_FIND_DATA; handles : THandles);
var
  fileData : TFileData;
begin
  fileData.findData := data;
  fileData.handle := handles.mainHandle;
  fileData.hLabel := handles.hLabel;

  fileList.Add(fileData);
end;

procedure LoadDirectoryIntoList();
 var
  fileHandle : HWND;
  fileData   : WIN32_FIND_DATA;
begin

  //Reset the pureFileList
  pureFileList.Clear();

  fileHandle := FindFirstFile(PWideChar(currentPath + '*'), fileData);

  pureFileList.Add(fileData);

  while (FindNextFile(fileHandle, fileData)) do begin
    pureFileList.Add(fileData);
  end;

end;

procedure DrawDirectory();
var
  iteratorX     : Integer;
  iteratorY     : Integer;
  fileHandle    : HWND;
  handles       : THandles;
  startingIndex : Integer;
  data          : TFileData;
  i: Integer;
begin
  iteratorX := 0;
  iteratorY := 0;

  if(not isPathDirectory(currentPath + '*')) then
  begin
    exit;
  end;

  LoadDirectoryIntoList(); //Reads the current directory path and adds them into the pureFileList array

  startingIndex := nLevel * 7;

  if(startingIndex >= pureFileList.Count) then
    exit;

  for i := startingIndex to 35 do
    begin
      if(i = pureFileList.Count) then
        exit;

      data.findData := pureFileList[i];

      handles := DrawFile(iteratorX, iteratorY, data.findData);
      AddFileToList(data.findData, handles);

      //Increment this variable that will be used to make space between all subsequent buttons that will be created
      iteratorX := iteratorX + 1;

      if ((iteratorX mod 7 = 0)) then
      begin
        iteratorY := iteratorY + 1;
        iteratorX := 0;
      end;

    end;

end;

procedure DrawElements();
var
  pathStr : string;
begin

  pathStr := currentPath;

  //Textbox with the latest currentPath (In every render, redraw the textbox to display the latest path string)
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
     DestroyWindow(tempfile.hLabel);
   end;

   fileList.Clear();
end;

function isCommandFromAButton(lParam: LPARAM) :  Boolean;
var
  tempFile : TFileData;
begin

  if( (lParam = hPathBtn) or
      (lParam = hSmallOkBtn) or
      (lParam = hSmallCancelBtn) or
      (lParam = hUpBtn) or
      (lParam = hDownBtn)
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

  //Label that displays the specified string
  CreateWindow('Static', PWideChar(str_message), WS_VISIBLE or WS_CHILD or WS_EX_TRANSPARENT, (wndWidth div 2) - 85, (wndHeight div 2) - 120, 170, 20, hSmallWnd, 0, hInstance, nil);

  //Label
  CreateWindow('Static', '>', WS_VISIBLE or WS_CHILD or WS_EX_TRANSPARENT, 10, (wndHeight div 2) - 55, 10, 15, hSmallWnd, 0, hInstance, nil);

  //Textbox of the new file's name
  hSmallWndEdit := CreateWindowEx(2, 'Edit', PWideChar(newFileName_str), WS_VISIBLE or WS_CHILD or ES_LEFT or ES_AUTOHSCROLL or WS_BORDER, 20, (wndHeight div 2) - 60, wndWidth - 40, 30, hSmallWnd,0,hInstance,nil);

  //Create file btn
  hSmallOkBtn := CreateWindow('Button', 'Create', WS_VISIBLE or WS_CHILD or BS_PUSHBUTTON or BS_TEXT, (wndWidth div 2) - 120, (wndWidth div 2) + 40, 100, 40, hSmallWnd, 0, hInstance, nil);

  //Cancel btn
  hSmallCancelBtn := CreateWindow('Button', 'Cancel', WS_VISIBLE or WS_CHILD or BS_PUSHBUTTON or BS_TEXT, (wndWidth div 2), (wndWidth div 2) + 40, 100, 40, hSmallWnd, 0, hInstance, nil);

end;

procedure KillMessageBox();
begin
  DestroyWindow(hSmallWnd);

  //Reset variables
  isSmallWndOpen := false;
  newFileName_str := '';
end;

procedure HandleCreationOfFile();
var
  bTest            : Boolean;
  hFile            : HWND;
  fileCompleteName : string;
begin

  if(newFileName_str.IsEmpty) then
    exit;

  bTest := false;
  fileCompleteName := currentPath + '\\' + newFileName_str;

  if(isFileBeingCreated = true) then
  begin
    hFile := CreateFile(PWideChar(fileCompleteName), GENERIC_READ, FILE_SHARE_READ, nil, CREATE_NEW, FILE_ATTRIBUTE_NORMAL, 0);
  end
  else begin
    bTest := CreateDirectory(PWideChar(fileCompleteName), nil);

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

function DoesFileHandleExist(hFile : HWND) : Boolean;
var
  tempFile : TFileData;
begin
  for tempFile in fileList do
   begin
     if(tempFile.handle = hFile) then
     begin
       Result := true;
       exit;
     end;
   end;

   Result := false;
end;

procedure DeleteSelectedFileOrDirectory();
var
  filePath            : string;
  fileData            : TFileData;
  Info                : TSHFileOpStruct;
  fileOperationStatus : Integer;
begin

  //Get file's data from the global variable selectedFileOrDir
  fileData := GetFileFromHandle(selectedFileOrDir);

  //Construct the file's absolute path
  filePath := currentPath + string(fileData.findData.cFileName);

  //Initialize the struct for the SHFIleOperation function parameter
  with Info do
  begin
    Wnd                   := hMainHandle;
    wFunc                 := FO_DELETE;
    pFrom                 := PWideChar(filePath);
    pTo                   := PWideChar('');
    fFlags                := FOF_NOCONFIRMATION or FOF_SILENT;
    fAnyOperationsAborted := false;
    hNameMappings         := 0;
    lpszProgressTitle     := PWideChar('');
  end;

  if(isPathDirectory(filePath + '\\')) then
    begin
      fileOperationStatus := SHFileOperation(Info);
    end
  else
    begin
      fileOperationStatus := SHFileOperation(Info);
    end;

    writeln('File being deleted: ', filePath);
    writeln('File operation status code: ', fileOperationStatus);
end;

function WindowProc(hWnd, Msg:Longint; wParam : WPARAM; lParam: LPARAM):Longint; stdcall;
var
  fileData          : TFileData;
  str               : string;
  editText          : PWideChar;
  buffer            : array[0..63] of char;
  pathFromTheFuture : string;
  command           : string;
  hPopUpMenu        : HMENU;
  cursorPoint       : TPoint;
  fileHandleExist   : Boolean;
label endOfFunction, destroySmallWnd, repaintFiles;
begin

  case Msg of
      WM_CREATE: begin

        //Load all the icons
        hBackIcon         := HBITMAP(LoadImageW(0, PWideChar(BackFileIconPath),       IMAGE_BITMAP, 80, 80, LR_LOADFROMFILE));
        hFolderIcon       := HBITMAP(LoadImageW(0, PWideChar(FolderIconPath),         IMAGE_BITMAP, 80, 80, LR_LOADFROMFILE));
        hFileIcon         := HBITMAP(LoadImageW(0, PWideChar(FileIconPath),           IMAGE_BITMAP, 80, 80, LR_LOADFROMFILE));
        hTxtFileIcon      := HBITMAP(LoadImageW(0, PWideChar(TextFileIconPath),       IMAGE_BITMAP, 80, 80, LR_LOADFROMFILE));
        hExeFileIcon      := HBITMAP(LoadImageW(0, PWideChar(ExecutableFileIconPath), IMAGE_BITMAP, 80, 80, LR_LOADFROMFILE));
        hSearchPathIcon   := HBITMAP(LoadImageW(0, PWideChar(SearchIconPath),         IMAGE_BITMAP, 80, 80, LR_LOADFROMFILE));
        hCreateFileIcon   := HBITMAP(LoadImageW(0, PWideChar(CreateFileIconPath),     IMAGE_BITMAP, 80, 80, LR_LOADFROMFILE));
        hCreateFolderIcon := HBITMAP(LoadImageW(0, PWideChar(CreateFolderIconPath),   IMAGE_BITMAP, 80, 80, LR_LOADFROMFILE));
      end;

      WM_VSCROLL: begin
        writeln('Scrolling');
      end;

      WM_MOUSEHWHEEL: begin
        write('Mouse wheeling');
      end;

      WM_CONTEXTMENU: begin
        writeln('Button: ', lParam, ', W: ', wParam,' was right clicked');
        Writeln('File: ', string(GetFileFromHandle(wParam).findData.cFileName));

        fileHandleExist := DoesFileHandleExist(wParam);

        //Check if the user right-clicked a file or folder, if not, exit
        if(not fileHandleExist) then
        begin
          selectedFileOrDir := 0;
          goto endOfFunction;
        end;

        selectedFileOrDir := wParam;

        GetCursorPos(cursorPoint);

        hPopupMenu := CreatePopupMenu();
        InsertMenu(hPopupMenu, 0, MF_BYPOSITION or MF_STRING, COPY_FILE_ID, PWideChar('Copy'));
        InsertMenu(hPopupMenu, 0, MF_BYPOSITION or MF_STRING, DELETE_FILE_ID, PWideChar('Delete'));
        SetForegroundWindow(hWnd);
        TrackPopupMenu(hPopupMenu, TPM_BOTTOMALIGN or TPM_LEFTALIGN, cursorPoint.X, cursorPoint.Y, 0, hWnd, 0);

      end;

      WM_COMMAND: begin

        //writeln('Something happen');
        //writeln('WParam: ', wParam, ', lParam: ', lParam);

        //Read the up button
        if(lParam = hUpBtn) then
        begin
          if(nLevel > 0) then
            nLevel := nLevel - 1;

          goto repaintFiles;
        end;

        //Read the down button
        if(lParam = hDownBtn) then
        begin
          nLevel := nLevel + 1;

          goto repaintFiles;
        end;

        //Read the context menu's button click event
        if(wParam = DELETE_FILE_ID) then
        begin
          DeleteSelectedFileOrDirectory();
          goto repaintFiles;
        end;

        //If command is from an event fired from the search textbox, grab the textbox's text and update the path
        if(lParam = hEdit) then
        begin
          editText := buffer;
          GetWindowText(hEdit, editText, 1024);
          UpdatePath(editText);
          goto endOfFunction;
        end;

        //If command is from an event fired from the message box's textbox, grab the textbox's text and update the path
        if(lParam = hSmallWndEdit) then
        begin
          editText := buffer;
          GetWindowText(hSmallWndEdit, editText, 1024);
          newFileName_str := editText;
          goto endOfFunction;
        end;

        //Check for the create file button event
        if(lParam = hCreateFileBtn) then
        begin

          //If the message box window is open, dont proceed
          if(isSmallWndOpen) then
            goto endOfFunction;

          isFileBeingCreated := true;
          ShowMessageBox('Enter the file name');
          isSmallWndOpen := true;
        end;

        //Check for the create directory button event
        if(lParam = hCreateDirBtn) then
        begin

          //If the message box window is open, dont proceed
          if(isSmallWndOpen) then
            goto endOfFunction;

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
          goto endOfFunction;

        //Process the cancel button from the message box
        if(lParam = hSmallCancelBtn) then
        begin
          KillMessageBox();
          goto endOfFunction;
        end;

        //Process the create button from the message box
        if(lParam = hSmallOkBtn) then
        begin
          HandleCreationOfFile();
          KillMessageBox();
          goto repaintFiles;
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
            goto endOfFunction;
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

          goto endOfFunction;
        end;


        UpdatePath(pathFromTheFuture);

        DestroyWindow(hEdit); //Destroy the label that shows the current path to display the new path

        nLevel := 0;

        repaintFiles:
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
          goto endOfFunction;
        end;

        ReleaseResources();

      end;
  end;

  endOfFunction:
    Result:=DefWindowProc(hWnd,Msg,wParam,lParam);
end;

procedure InitFileExtensionMap();
begin
  FileExtensionIconMap.Add('back', hBackIcon);
  FileExtensionIconMap.Add('folder', hFolderIcon);
  FileExtensionIconMap.Add('file', hFileIcon);
  FileExtensionIconMap.Add('txt', hTxtFileIcon);
  FileExtensionIconMap.Add('exe', hExeFileIcon);
end;

begin
  LWndClass.hInstance := hInstance;

  hPrev := HTREEITEM(TVI_FIRST);
  hPrevRootItem     := 0;
  hPrevLev2Item     := 0;
  selectedFileOrDir := 0;
  nLevel            := 0;

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
  hMainHandle := CreateWindow(LWndClass.lpszClassName,'Window Title', WS_CAPTION or WS_MINIMIZEBOX or WS_SYSMENU or WS_VISIBLE,
      10,
      10, 1300,850,0,0,hInstance,nil);

  fontName := 'Comic Sans MS';

  //Create the fonts to use
  hFontText   := CreateFont(-20,0,0,0,0,0,0,0,DEFAULT_CHARSET,OUT_DEFAULT_PRECIS,CLIP_DEFAULT_PRECIS,DEFAULT_QUALITY,VARIABLE_PITCH or FF_SWISS, fontName);
  hFontButton := CreateFont(-14,0,0,0,0,0,0,0,DEFAULT_CHARSET,OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,DEFAULT_QUALITY,VARIABLE_PITCH or FF_SWISS, fontName);
  hFontFiles  := CreateFont(18,0,0,0,0,0,0,0,DEFAULT_CHARSET,OUT_DEFAULT_PRECIS,CLIP_DEFAULT_PRECIS,DEFAULT_QUALITY,VARIABLE_PITCH or FF_SWISS, fontName);

  currentPath  := 'C:\\';
  fileList     := TList<TFileData>.Create;
  pureFileList := TList<WIN32_FIND_DATA>.Create;
  FileExtensionIconMap := TDictionary<string,HBITMAP>.Create;
  InitFileExtensionMap();

  //Label
  hStatic := CreateWindowEx(2,'Edit', 'Path: ', WS_VISIBLE or WS_CHILD or ES_LEFT, 20, 35, 73, 50,hMainHandle,0,hInstance,nil);
  SendMessage(hStatic, WM_SETFONT, hFontText, 0);

  //Search btn
  hPathBtn := CreateWindowW('Button', 'Search', WS_VISIBLE or WS_CHILD or BS_BITMAP, 70, 75, 60, 60, hMainHandle, 0, hInstance, nil);
  SendMessageW(hPathBtn, BM_SETIMAGE, IMAGE_BITMAP, LPARAM(hSearchPathIcon));

  //Create file btn
  hCreateFileBtn := CreateWindow('Button', 'Create File', WS_VISIBLE or WS_CHILD or BS_PUSHBUTTON or BS_TEXT, 180, 75, 100, 40, hMainHandle, 0, hInstance, nil);
  SendMessage(hCreateFileBtn,WM_SETFONT,hFontButton,0);

  //Create directory btn
  hCreateDirBtn := CreateWindow('Button', 'Create Directory', WS_VISIBLE or WS_CHILD or BS_PUSHBUTTON or BS_TEXT, 290, 75, 120, 40, hMainHandle, 0, hInstance, nil);
  SendMessage(hCreateDirBtn,WM_SETFONT,hFontButton,0);

  //Up Button
  hUpBtn   := CreateWindow('Button', '^', WS_VISIBLE or WS_CHILD or BS_PUSHBUTTON or BS_TEXT, 1250, 300, 40, 40, hMainHandle, 0, hInstance, nil);

  //Down Button
  hDownBtn := CreateWindow('Button', 'v', WS_VISIBLE or WS_CHILD or BS_PUSHBUTTON or BS_TEXT, 1250, 350, 40, 40, hMainHandle, 0, hInstance, nil);

  DrawElements();

  CreateTreeView();

  while GetMessage(Msg,0,0,0) do
  begin
    TranslateMessage(Msg);
    DispatchMessage(Msg);
  end;

end.
