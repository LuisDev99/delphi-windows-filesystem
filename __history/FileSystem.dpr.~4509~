
program FileSystem;


uses
  Windows,
  Messages,
  SysUtils,
  CommCtrl,
  Generics.Collections,
  StrUtils,
  ShellApi,
  ShlObj,
  ComObj,
  ActiveX,
  Types,
  Math,
  WinShell in 'WinShell.pas';

//WinShell in 'WinShell.pas';

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
  TVNode = record
    name         : string;
    fullPath     : string;
    ID           : Integer;   // Look up identifier
    hItem        : HTREEITEM; // Where to insert
    hParentItem  : HTREEITEM; // Keep Track of where its coming from
  end;
  TIcon = record
    hSmall   : HBITMAP;
    hNormal  : HBITMAP;
  end;
  TFileList     = TList<TFileData>;
  TFiles        = TList<WIN32_FIND_DATA>;
  THack         = TList<Integer>;
  TVNodeList    = TList<TVNode>;

const TV_ICON_SIZE = 20;

const SMALL_SIZE = 30;

const BackFileIconPath       = 'C:/Users/DELL/Documents/Siso2/backIcon_bmp.bmp';
const FolderIconPath         = 'C:/Users/DELL/Documents/Siso2/Windows_folder_icon_bmp.bmp';
const FileIconPath           = 'C:/Users/DELL/Documents/Siso2/file_icon2_bmp.bmp';
const MenuIconPath           = 'C:/Users/DELL/Documents/Siso2/menu_icon_bmp.bmp';
const PngFileIconPath        = 'C:/Users/DELL/Documents/Siso2/png_icon_bmp.bmp';
const TextFileIconPath       = 'C:/Users/DELL/Documents/Siso2/txtIcon_bmp.bmp';
const SearchIconPath         = 'C:/Users/DELL/Documents/Siso2/searchIcon2_bmp.bmp';
const ShortcutIconPath       = 'C:/Users/DELL/Documents/Siso2/shortcut_icon_bmp.bmp';
const SymLinkIconPath        = 'C:/Users/DELL/Documents/Siso2/symlink_icon_bmp.bmp';
const CreateFileIconPath     = 'C:/Users/DELL/Documents/Siso2/createFileIcon_bmp.bmp';
const CreateFolderIconPath   = 'C:/Users/DELL/Documents/Siso2/createFolderIcon_bmp.bmp';
const ExecutableFileIconPath = 'C:/Users/DELL/Documents/Siso2/exeFileIcon_1_bmp.bmp';

const DELETE_FILE_CONTEXT_MENU_BTN_ID      = 21010101;
const COPY_FILE_CONTEXT_MENU_BTN_ID        = 41010101;
const PASTE_FILE_CONTEXT_MENU_BTN_ID       = 61010101;
const CUT_FILE_CONTEXT_MENU_BTN_ID         = 71010101;
const CREATE_SYM_LINK_CONTEXT_MENU_BTN_ID  = 71010102;
const CREATE_HARD_LINK_CONTEXT_MENU_BTN_ID = 71010103;
const CREATE_SHORTCUT_CONTEXT_MENU_BTN_ID  = 71010104;

{ Context Menu File operations }
const OPERATION_CUTTING = 1;
const OPERATION_COPYING = 2;

const FILES_PER_ROW = 7;
const MAX_AMOUNT_OF_FILES_ON_SCREEN = 35;

const TOP_BODY_X = 200;
const TOP_BODY_Y = 140;

const SEARCH_BAR_X_POS = 73;
const SEARCH_BAR_Y_POS = 35;

const INVALID_FILE = 'No file name will ever have this same exact string , soo yeah';

var
  Msg               : TMSG;
  LWndClass         : TWndClass;
  LTWndClass        : TWndClass;
  hMainHandle       : HWND;
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
  nodeList          : TVNodeList;
  hPathBtn          : HWND;
  hUpBtn            : HWND;
  hDownBtn          : HWND;
  hStyleBtn         : HWND;

  hack : THack;

  newFileName_str   : string;
  isSmallWndOpen    : Boolean;
  isFileBeingCreated: Boolean;
  selectedFile_Operation : Integer;

  isLinear          : Boolean;

  hPrev             : HTREEITEM;
  hPrevRootItem     : HTREEITEM;
  hPrevLev2Item     : HTREEITEM;

  g_nOpen           : Integer;
  g_nClosed         : Integer;
  g_nDocument       : Integer;
  g_nUniqueID       : Integer;
  g_nForbiddenHandle: HWND;

  nLevel            : Integer;
  insertStructAddr  : Integer;


  rightClicked_selectedFileOrDir : HWND;
  selectedFileOrDirName_forCopying  : string;


  hCreateFileBtn, hCreateDirBtn, hSmallWnd    : HWND;
  hSmallWndEdit, hSmallOkBtn, hSmallCancelBtn : HWND;

  { Icon Handles }
  hCreateFileIcon, hCreateFolderIcon, hSearchPathIcon, hMenuIcon, hSmallFolderIcon : HBITMAP;

  { Icon Structs  }
  tBackIcon, tShortCutIcon, tSymLinkIcon     : TIcon;
  tFolderIcon, tFileIcon, tTxtFileIcon       : TIcon;
  tExeFileIcon, tPngFileIcon                 : TIcon;


  FileExtensionIconMap : TDictionary<string, TIcon>;
  TreeViewNodesMap     : TDictionary<string, TVNode>;

label exity;

procedure ColorMessagePrinter(messageStr : string; typeOfMessage : string; color : Integer);
var
  ConOut: THandle;
  BufInfo: TConsoleScreenBufferInfo;
begin
  ConOut := TTextRec(Output).Handle;
    GetConsoleScreenBufferInfo(ConOut, BufInfo);
    SetConsoleTextAttribute(TTextRec(Output).Handle, FOREGROUND_INTENSITY or color);

    write(typeOfMessage);

    SetConsoleTextAttribute(ConOut, BufInfo.wAttributes);

    writeln(messageStr);
end;

procedure PrintInfoMsg(info : string);
begin
    ColorMessagePrinter(info, 'INFO: ', FOREGROUND_BLUE);
end;

procedure PrintLogMsg(info : string);
begin
    ColorMessagePrinter(info, 'LOG: ', FOREGROUND_GREEN);
end;

procedure PrintErrorMsg(info : string);
begin
    ColorMessagePrinter(info, 'ERROR: ', FOREGROUND_RED);
end;

procedure PrintDebugMsg(info : string);
begin
     ColorMessagePrinter(info, 'DEBUG >> ', FOREGROUND_GREEN or FOREGROUND_RED);
end;

function ExecuteProcess(const FileName, Params: string; Folder: string; WaitUntilTerminated, WaitUntilIdle, RunMinimized: boolean; var ErrorCode: integer): boolean;
var
  CmdLine: string;
  WorkingDirP: PChar;
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
begin
  Result := true;
  CmdLine := '"' + FileName + '" ' + Params;
  if Folder = '' then Folder := ExcludeTrailingPathDelimiter(ExtractFilePath(FileName));
  ZeroMemory(@StartupInfo, SizeOf(StartupInfo));
  StartupInfo.cb := SizeOf(StartupInfo);
  if RunMinimized then
    begin
      StartupInfo.dwFlags := STARTF_USESHOWWINDOW;
      StartupInfo.wShowWindow := SW_SHOWMINIMIZED;
    end;
  if Folder <> '' then WorkingDirP := PChar(Folder)
  else WorkingDirP := nil;
  if not CreateProcess(nil, PChar(CmdLine), nil, nil, false, 0, nil, WorkingDirP, StartupInfo, ProcessInfo) then
    begin
      Result := false;
      ErrorCode := GetLastError;
      exit;
    end;
  with ProcessInfo do
    begin
      CloseHandle(hThread);
      if WaitUntilIdle then WaitForInputIdle(hProcess, INFINITE);
      if WaitUntilTerminated then
        repeat
          //Application.ProcessMessages;
        until MsgWaitForMultipleObjects(1, hProcess, false, INFINITE, QS_ALLINPUT) <> WAIT_OBJECT_0 + 1;
      CloseHandle(hProcess);
    end;
end;

function isPathDirectory(path : string) : Boolean;
var
  fileHandle  : HWND;
  filePath    : string;
  recData     : TSearchRec;
begin
  if(not path.EndsWith('\\')) then
  begin
    PrintErrorMsg('The path string should end with double back slash -> "\\"');
  end;

  filePath := path + '*';

  fileHandle := FindFirstFile(PWideChar(filePath), data);

  if(fileHandle = 4294967295) then
  begin
    Result := false;
    exit;
  end;

  g_nForbiddenHandle := fileHandle;
  recData.FindHandle := fileHandle;
  FindClose(recData);
  Result := true;

end;

function GetTVNodeFromItemID(nodeID : Integer): TVNode;
var
  node  : TVNode;
begin

  for node in nodeList do
  begin
    if(node.ID = nodeID) then
    begin
      Result := node;
      exit;
    end;
  end;

  Result := node;
end;

function GetTVNodeFromTreeViewSelectedItemHandle(tvHwnd: HWND) : TVNode;
var
  pSelectedItem         : TTVItem;
  hTreeSelectedItem     : HTREEITEM;
  secondBuffer          : array[0..1023] of WideChar;
begin
  hTreeSelectedItem    := TreeView_GetSelection(tvHwnd);
  pSelectedItem.hItem  := hTreeSelectedItem;
  pSelectedItem.mask   := TVIF_TEXT;
  pSelectedItem.cchTextMax := 1023;
  pSelectedItem.pszText := secondBuffer;

  TreeView_GetItem(hTreeView, pSelectedItem);

  //pSelectedItem.LParam holds the unique ID of the tree view node
  Result := GetTVNodeFromItemID(pSelectedItem.lParam);
end;

procedure InitTreeViewImageListView();
var
 himl   : HIMAGELIST;
begin

 himl := ImageList_Create(TV_ICON_SIZE, TV_ICON_SIZE , 0, 3, 0);

 PrintDebugMsg('Got here');

 g_nOpen     := ImageList_Add(himl, hSmallFolderIcon, HBITMAP(0));
 g_nClosed   := ImageList_Add(himl, hSmallFolderIcon, HBITMAP(0));
 g_nDocument := ImageList_Add(himl, hSmallFolderIcon, HBITMAP(0));

 if (ImageList_GetImageCount(himl) < 3) then
        PrintLogMsg('Init of tree view image list failed miserably');

 TreeView_SetImageList(hTreeView, himl, TVSIL_NORMAL);

end;

function AddItemToTreeView ( strName : string; uniqueID : Integer; hNodeParent : HTREEITEM ) : HTREEITEM;
var
  tvi   : tagTVITEMA;
  tvins : tagTVINSERTSTRUCTA;
begin

  tvi.mask := TVIF_TEXT or TVIF_IMAGE or TVIF_SELECTEDIMAGE or TVIF_PARAM;

  //Set text of the item
  tvi.pszText    := PAnsiChar(PWideChar(strname));
  tvi.cchTextMax := strName.Length;

  //Assume the item is not a parent item, so give it a document image
  tvi.iImage := g_nDocument;
  tvi.iSelectedImage := g_nDocument;

  //Save the heading level in the item's application-defined data area
  tvi.lParam := LParam(uniqueID);
  tvins.item := tvi;
  tvins.hInsertAfter := hPrev;

  //Choose where to insert the new item
  tvins.hParent := hNodeParent;

  //Add the item to the tree-view control
  Result := HTREEITEM(SendMessage(hTreeView, TVM_INSERTITEM, 0, lParam(@tvins)));

end;

function AddNodeToTreeView (const node : TVNode) : HTREEITEM;
begin
   Result := AddItemToTreeView(node.name, node.ID, node.hParentItem);
end;

function IsDirectoryLoadedIntoTreeViewAlready(path : string) : Boolean;
var
  node : TVNode;
begin

  for node in nodeList do
  begin
    if(node.fullPath = path) then
    begin
      Result := true;
      exit;
    end;
  end;

  Result := false;
end;

procedure LoadDirectoryIntoTreeViewNodeList(path : string; hNodeParent : HTREEITEM);
var
  node        : TVNode;
  fileHandle  : HWND;
  fileData    : WIN32_FIND_DATA;

begin
  path        := path + '\\';

  fileHandle := FindFirstFile(PWideChar(path + '*'), fileData);


  repeat

    if((string(fileData.cFileName) = '.') or (string(fileData.cFileName) = '..')) then
      continue;

    //Avoid duplication on a tree view node
    if(IsDirectoryLoadedIntoTreeViewAlready(path + fileData.cFileName)) then
    begin
      PrintInfoMsg('Directory already exists in the treeview! Skipping the addition to the treeview');
      exit;
    end;

    if(isPathDirectory(path + fileData.cFileName + '\\')) then
    begin
      node.name        := fileData.cFileName;
      node.fullPath    := path + node.name;
      node.ID          := g_nUniqueID;
      node.hParentItem := hNodeParent;
      node.hItem       := AddNodeToTreeView(node);

      g_nUniqueID := g_nUniqueID + 1;

      nodeList.Add(node);
    end;

  until (FindNextFile(fileHandle, fileData) = FALSE);

end;

procedure CreateTreeView();
begin
  InitCommonControls();

  hTreeView := CreateWindowEx(0, WC_TREEVIEW, LTWndClass.lpszClassName, WS_VISIBLE or WS_BORDER or WS_CHILD or TVS_HASBUTTONS or TVS_LINESATROOT, 10, TOP_BODY_Y, 180, 550, hMainHandle, 0, hInstance, nil);

  InitTreeViewImageListView();
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

procedure ReleaseResources;
begin
  DestroyWindow(hEdit);
  DestroyWindow(hStatic);
  DestroyWindow(hPathBtn);
  DestroyWindow(hCreateFileBtn);
  DestroyWindow(hCreateDirBtn);
  DestroyWindow(hUpBtn);
  DestroyWindow(hDownBtn);
  DestroyWindow(hTreeView);

  DestroyAllFiles();

  DeleteObject(hFontText);
  DeleteObject(hFontFiles);
  DeleteObject(hFontButton);

  DestroyWindow(hMainHandle);

  PostQuitMessage(0);
end;

procedure UpdatePath(newPath : string);
begin
  currentPath := newPath;
end;

function GetIconFromFileExtension(fileName : string) : TIcon;
var
  icon     : TIcon;
  fullPath : string;
  fileAttr : DWORD;
begin

  fullPath := currentPath + fileName + '\\';

  if(isPathDirectory(fullPath) and (not (fileName.Equals('..')))) then
    begin
       FileExtensionIconMap.TryGetValue('folder', icon);
    end
  else
    begin

      fullPath := fullPath.Remove(fullPath.LastIndexOf('\\'));
      fileAttr := GetFileAttributes(PWideChar(fullPath));

      if(fileAttr = FILE_ATTRIBUTE_REPARSE_POINT) then
        begin
          FileExtensionIconMap.TryGetValue('symlink', icon);
        end
      else if(fileName.Equals('..')) then
        begin
          FileExtensionIconMap.TryGetValue('back', icon);
        end
      else if(fileName.EndsWith('.exe')) then
        begin
          FileExtensionIconMap.TryGetValue('exe', icon);
        end
      else if(fileName.EndsWith('.txt')) then
        begin
          FileExtensionIconMap.TryGetValue('txt', icon);
        end
      else if(fileName.EndsWith('.lnk')) then
        begin
          FileExtensionIconMap.TryGetValue('shortcut', icon);
        end
      else if(fileName.EndsWith('.png')) then
        begin
          FileExtensionIconMap.TryGetValue('png', icon);
        end
      else
        begin
          FileExtensionIconMap.TryGetValue('file', icon);
        end
    end;

  Result := icon;

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

  labelWidth := string(data.cFileName).Length * 2 + 100; //Label's width will be according to the file's name size

  xPos :=  TOP_BODY_X + (iteratorX * 150);
  yPos :=  TOP_BODY_Y + (iteratorY * (btnHeight div 2) * 3);

  hFileIcon := GetIconFromFileExtension(data.cFileName).hNormal;

  //Create the button with a background image (the image being the icon depending on the file's type)
  handles.mainHandle := CreateWindowW('Button', data.cFileName, WS_VISIBLE or WS_CHILD or BS_BITMAP, xPos, yPos, btnWidth, btnHeight, hMainHandle, 0, hInstance, nil);
  SendMessageW(handles.mainHandle,BM_SETIMAGE,IMAGE_BITMAP, LPARAM(hFileIcon));

  //Create the label which contains the file's name
  handles.hLabel := CreateWindowEx(2,'Edit', data.cFileName, WS_VISIBLE or WS_CHILD or ES_LEFT, xPos, yPos + btnHeight + 10, labelWidth, 20,hMainHandle,0,hInstance,nil);
  SendMessage(handles.hLabel,WM_SETFONT,hFontFiles,0);

  Result := handles; //Returns the newly created handle (in this case, a button handle)
end;

function DrawSmallFile(iteratorX : Integer; iteratorY : Integer; data : WIN32_FIND_DATA) : THandles;
var
  btnWidth  : Integer;
  btnHeight : Integer;
  handles   : THandles;
  xPos      : Integer;
  yPos      : Integer;
  labelWidth: Integer;
  hFileIcon : HBITMAP;
begin
  btnWidth  := SMALL_SIZE;
  btnHeight := SMALL_SIZE;

  labelWidth := string(data.cFileName).Length * 2 + 100; //Label's width will be according to the file's name size

  xPos :=  TOP_BODY_X + (iteratorX * 200);
  yPos :=  TOP_BODY_Y + (iteratorY * (btnHeight div 2) * 3);

  hFileIcon := GetIconFromFileExtension(data.cFileName).hSmall;

  //Create the button with a background image (the image being the icon depending on the file's type)
  handles.mainHandle := CreateWindowW('Button', data.cFileName, WS_VISIBLE or WS_CHILD or BS_BITMAP, xPos, yPos, btnWidth, btnHeight, hMainHandle, 0, hInstance, nil);
  SendMessageW(handles.mainHandle,BM_SETIMAGE,IMAGE_BITMAP, LPARAM(hFileIcon));

  //Create the label which contains the file's name
  handles.hLabel := CreateWindowEx(2,'Edit', data.cFileName, WS_VISIBLE or WS_CHILD or ES_LEFT, xPos + btnWidth + 2, yPos, labelWidth, 20,hMainHandle,0,hInstance,nil);
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

  PrintLogMsg( 'Size of the directory lisT: ' + IntToStr( pureFileList.Count ) );

end;

procedure DrawDirectoryScatter();
var
  iteratorX     : Integer;
  iteratorY     : Integer;
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

  startingIndex := nLevel * FILES_PER_ROW;

  if(startingIndex >= pureFileList.Count) then
    exit;

  for i := startingIndex to pureFileList.Count do
    begin

      if(i = pureFileList.Count) then
        exit;

      data.findData := pureFileList[i];

      handles := DrawFile(iteratorX, iteratorY, data.findData);
      AddFileToList(data.findData, handles);

      //Increment this variable that will be used to make space between all subsequent buttons that will be created
      iteratorX := iteratorX + 1;

      if ((iteratorX mod FILES_PER_ROW = 0)) then
      begin
        iteratorY := iteratorY + 1;
        iteratorX := 0;
      end;

    end;

end;

procedure DrawDirectoryLinear();

const FILES_PER_COLUMN = 12;
var
  iteratorX     : Integer;
  iteratorY     : Integer;
  handles       : THandles;
  data          : TFileData;
  startingIndex : Integer;
  i             : Integer;
begin

  iteratorX := 0;
  iteratorY := 0;

  if(not isPathDirectory(currentPath + '*')) then
  begin
    exit;
  end;

  LoadDirectoryIntoList(); //Reads the current directory path and adds them into the pureFileList array

  startingIndex := nLevel * FILES_PER_COLUMN;

  for i := startingIndex to pureFileList.Count do
    begin

      if(i = pureFileList.Count) then
        exit;

      data.findData := pureFileList[i];

      handles := DrawSmallFile(iteratorX, iteratorY, data.findData);
      AddFileToList(data.findData, handles);

      //Increment this variable that will be used to make space between all subsequent buttons that will be created
      iteratorY := iteratorY + 1;

      if ((iteratorY mod FILES_PER_COLUMN = 0)) then
      begin
        iteratorX := iteratorX + 1;
        iteratorY := 0;
      end;

    end;

end;

procedure DrawElements();
var
  pathStr : string;
begin

  pathStr := currentPath;

  //Textbox with the latest currentPath (In every render, redraw the textbox to display the latest path string)
  hEdit := CreateWindowEx(2, 'Edit', PWideChar(pathStr), WS_VISIBLE or WS_CHILD or ES_LEFT or ES_AUTOHSCROLL or WS_BORDER, SEARCH_BAR_X_POS, SEARCH_BAR_Y_POS, 1100, 33,hMainHandle,0,hInstance,nil);
  SendMessage(hEdit,WM_SETFONT,hFontText,0);

  if(isLinear) then
    begin
      DrawDirectoryLinear();
    end
  else
    begin
      DrawDirectoryScatter();
    end;
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
  CreateWindowEx(2,'Edit', PWideChar(str_message), WS_VISIBLE or WS_CHILD or ES_LEFT, (wndWidth div 2) - 85, (wndHeight div 2) - 120, 170, 20, hSmallWnd,0,hInstance,nil);

  //Label
  CreateWindowEx(2,'Edit', '>', WS_VISIBLE or WS_CHILD or ES_LEFT, 10, (wndHeight div 2) - 55, 10, 15, hSmallWnd,0,hInstance,nil);

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

  //Reset the variables that the message box uses
  newFileName_str := '';
  isSmallWndOpen  := false;

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
      PrintErrorMsg('Creation of dir failed: ' + SysErrorMessage(GetLastError));
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

procedure CreateSymLink(path : string);
var
  dwFlags       : Integer;
  alternateName : string;
  status        : Boolean;
begin
  if(path = INVALID_FILE) then
    exit;

  alternateName := path + IntToStr(Random(20));

  if(isPathDirectory(path + '\\')) then
    begin
      dwFlags := SYMBOLIC_LINK_FLAG_DIRECTORY or 2;
    end
  else
    begin
      dwFlags := 0 or 2;
    end;

  status := CreateSymbolicLink(PWideChar(alternateName), PWideChar(path), dwFlags);

  PrintLogMsg('Status of creation of symbolic link: ' + BoolToStr(status) + ', GetLastError Message: ' + SysErrorMessage(GetLastError()));

  selectedFileOrDirName_forCopying := INVALID_FILE;
end;

procedure CreateHardLinkss(path : string);
var
  alternateName : string;
  status        : Boolean;
begin
  if(path = INVALID_FILE) then
    exit;

  //Hard links only for files
  if(isPathDirectory(path + '\\')) then
    exit;

  alternateName := path.Remove( path.LastIndexOf('.') ) + IntToStr(Random(20)) + path.Substring( path.LastIndexOf('.'));

  status := CreateHardLink(PWideChar(alternateName), PWideChar(path), nil);

  PrintLogMsg('Status of creation of hard link: ' + BoolToStr(status) + ', GetLastError Message: ' + SysErrorMessage(GetLastError()));

  selectedFileOrDirName_forCopying := INVALID_FILE;
end;

procedure CreateShortCut(path : string);
var
  IObject: IUnknown;
  SLink: IShellLink;
  PFile: IPersistFile;
begin

  if(path = INVALID_FILE) then
    exit;

  IObject:=CreateComObject(CLSID_ShellLink);
  SLink:=IObject as IShellLink;
  PFile:=IObject as IPersistFile;
  with SLink do
  begin
    SetArguments(PChar('Hola'));
    SetDescription(PChar('Shortcut by LuisDev99'));
    SetPath(PChar(path));
  end;
  path := path + '.lnk';
  PFile.Save(PWChar(WideString(path)), FALSE);

  selectedFileOrDirName_forCopying := INVALID_FILE;
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

procedure TraverseDirectory(path : string);
 var
  fileHandle  : HWND;
  fileData    : WIN32_FIND_DATA;
  currentFile : string;
begin

  fileHandle := FindFirstFile(PWideChar(path + '*'), fileData);

  repeat
    //Avoid a infinite loop by ignoring this file names
    if((string(fileData.cFileName) = '.') or (string(fileData.cFileName) = '..')) then
      continue;

    currentFile := path + fileData.cFileName;

    if(isPathDirectory(currentFile + '\\')) then
      begin
        TraverseDirectory(currentFile + '\\');
      end
    else
      begin
         writeln('File: ', fileData.cFileName);
      end;
  until FindNextFile(fileHandle, fileData) = False;

end;

procedure DeepDeletionOfFiles(root : string);
var
  fileData    : TSearchRec;
  sourceFile  : string;
begin

  FindFirst(root + '\\*', faAnyFile, fileData);
  sourceFile := root + '\\' + fileData.Name;

  repeat
    //Avoid a infinite loop by ignoring this file names
    if((string(fileData.Name) = '.') or (string(fileData.Name) = '..')) then
    begin
      continue;
    end;

    sourceFile := root + '\\' + fileData.Name;

    if(fileData.Attr = FILE_ATTRIBUTE_DIRECTORY) then
      begin
        DeepDeletionOfFiles(sourceFile);
      end
    else
      begin
        DeleteFileW(PWideChar(sourceFile));
      end;
  until FindNext(fileData) <> 0;

  PrintLogMsg('Closing -> ' + fileData.Name);
  FindClose(fileData);
  RemoveDirectory(PWideChar(root));
end;

procedure DeepCopyOfFiles(origin : string; destination : string);
 var
  fileHandle  : HWND;
  fileData    : WIN32_FIND_DATA;
  sourceFile  : string;
  newFile     : string;
begin
  fileHandle := FindFirstFile(PWideChar(origin + '*'), fileData);

  repeat
    //Avoid a infinite loop by ignoring this file names
    if((string(fileData.cFileName) = '.') or (string(fileData.cFileName) = '..')) then
      continue;

    sourceFile := origin + fileData.cFileName;
    newFile    := destination + fileData.cFileName;

    if(isPathDirectory(sourceFile + '\\')) then
      begin
        //First create the dir before doing the recursion
        CreateDirectory(PWideChar(newFile), nil);

        DeepCopyOfFiles(sourceFile + '\\', newFile + '\\');
      end
    else
      begin
        CopyFile(PWideChar(sourceFile), PWideChar(newFile), true);
      end;
  until FindNextFile(fileHandle, fileData) = False;
end;

procedure CopyPasteSelectedFileOrDirectory();
 var
  origin              : string;
  destination         : string;
begin
  if(selectedFileOrDirName_forCopying = INVALID_FILE) then
    exit;

  origin := selectedFileOrDirName_forCopying;

  //Extreme new way of renaming a copied file
  destination := selectedFileOrDirName_forCopying.Remove( selectedFileOrDirName_forCopying.LastIndexOf('.') );
  destination := destination + '_new' + IntToStr(Random(20));

  if(isPathDirectory(origin + '\\')) then
    begin
      CreateDirectory(PWideChar(destination), nil);
      DeepCopyOfFiles(origin + '\\', destination + '\\');
    end
  else
    begin
      destination := destination + selectedFileOrDirName_forCopying.Substring( selectedFileOrDirName_forCopying.LastIndexOf('.'));
      CopyFile(PWideChar(origin), PWideChar(destination), true);
    end;

  exit;
end;

procedure CutPasteSelectedFileOrDirectory();
var
  origin              : string;
  destination         : string;
  fileOperationStatus : Boolean;
  buffer              : array[0..1023] of char;
  buffer2             : array[0..1023] of char;
  i: Integer;
begin
  if(selectedFileOrDirName_forCopying = INVALID_FILE) then
    exit;

  //Initialize the buffers with null chars
  for i := 0 to 1023 do
    begin
      buffer[i]  := char(0);
      buffer2[i] := char(0);
    end;

  origin      := selectedFileOrDirName_forCopying;

  destination := selectedFileOrDirName_forCopying.Substring(selectedFileOrDirName_forCopying.LastIndexOf('\\')); //Get just the file name by cutting the rest of the path
  destination := currentPath + destination;

  //Stack Overflow: Copying string content to char array delphi
  StrLCopy(PChar(@buffer[0]), PChar(origin), High(buffer));
  origin := buffer;

  //Stack Overflow: Copying string content to char array delphi
  StrLCopy(PChar(@buffer2[0]), PChar(destination), High(buffer));
  destination := buffer2;

  fileOperationStatus := MoveFileEx(PwideChar(origin), PWideChar(destination), MOVEFILE_WRITE_THROUGH);

  PrintInfoMsg('File operation status code: ' + BoolToStr(fileOperationStatus) + ' Error message: ' + SysErrorMessage(GetLastError()));

  if(fileOperationStatus = true) then
    selectedFileOrDirName_forCopying := INVALID_FILE;

end;

procedure DeleteSelectedFileOrDirectory();
var
  filePath            : string;
  fileData            : TFileData;
  fileStruct          : TSearchRec;
begin

  //Get file's data from the global variable selectedFileOrDir
  fileData := GetFileFromHandle(rightClicked_selectedFileOrDir);

  //Construct the file's absolute path
  filePath := currentPath + string(fileData.findData.cFileName);

  if(isPathDirectory(filePath + '\\')) then
    begin
      DeepDeletionOfFiles(filePath);
    end
  else
    begin
      DeleteFileW(PWideChar(filePath));
    end;

end;

function WindowProc(hWnd, Msg:Longint; wParam : WPARAM; lParam: LPARAM):Longint; stdcall;
var
  fileData              : TFileData;
  str                   : string;
  editText              : PWideChar;
  buffer                : array[0..1023] of char;
  pathFromTheFuture     : string;
  command               : string;
  parameters            : string;
  hPopUpMenu            : HMENU;
  cursorPoint           : TPoint;
  fileHandleExist       : Boolean;
  Error                 : integer;
  OK                    : boolean;
  tvData                : PNMHDR;
  ptvkd                 : PNMKey;
  selectedTVNode        : TVNode;
  hTreeSelectedItem     : HTREEITEM;
  contextMenuPasteBtnFlags : Integer;
  data                     : TShellLinkInfo;
label endOfFunction, destroySmallWnd, repaintFiles;
begin

  case Msg of
      WM_CREATE: begin

        //Load all the icons with its normal size
        tBackIcon.hNormal         := HBITMAP(LoadImageW(0, PWideChar(BackFileIconPath),       IMAGE_BITMAP, 80, 80, LR_LOADFROMFILE));
        tFolderIcon.hNormal       := HBITMAP(LoadImageW(0, PWideChar(FolderIconPath),         IMAGE_BITMAP, 80, 80, LR_LOADFROMFILE));
        tFileIcon.hNormal         := HBITMAP(LoadImageW(0, PWideChar(FileIconPath),           IMAGE_BITMAP, 80, 80, LR_LOADFROMFILE));
        tPngFileIcon.hNormal      := HBITMAP(LoadImageW(0, PWideChar(PngFileIconPath),        IMAGE_BITMAP, 80, 80, LR_LOADFROMFILE));
        tTxtFileIcon.hNormal      := HBITMAP(LoadImageW(0, PWideChar(TextFileIconPath),       IMAGE_BITMAP, 80, 80, LR_LOADFROMFILE));
        tExeFileIcon.hNormal      := HBITMAP(LoadImageW(0, PWideChar(ExecutableFileIconPath), IMAGE_BITMAP, 80, 80, LR_LOADFROMFILE));
        tShortCutIcon.hNormal     := HBITMAP(LoadImageW(0, PWideChar(ShortcutIconPath),       IMAGE_BITMAP, 80, 80, LR_LOADFROMFILE));
        tSymLinkIcon.hNormal      := HBITMAP(LoadImageW(0, PWideChar(SymLinkIconPath),        IMAGE_BITMAP, 80, 80, LR_LOADFROMFILE));

        //Load all the icons with its normal size
        tBackIcon.hSmall         := HBITMAP(LoadImageW(0, PWideChar(BackFileIconPath),       IMAGE_BITMAP, SMALL_SIZE, SMALL_SIZE, LR_LOADFROMFILE));
        tFolderIcon.hSmall       := HBITMAP(LoadImageW(0, PWideChar(FolderIconPath),         IMAGE_BITMAP, SMALL_SIZE, SMALL_SIZE, LR_LOADFROMFILE));
        tFileIcon.hSmall         := HBITMAP(LoadImageW(0, PWideChar(FileIconPath),           IMAGE_BITMAP, SMALL_SIZE, SMALL_SIZE, LR_LOADFROMFILE));
        tPngFileIcon.hSmall      := HBITMAP(LoadImageW(0, PWideChar(PngFileIconPath),        IMAGE_BITMAP, SMALL_SIZE, SMALL_SIZE, LR_LOADFROMFILE));
        tTxtFileIcon.hSmall      := HBITMAP(LoadImageW(0, PWideChar(TextFileIconPath),       IMAGE_BITMAP, SMALL_SIZE, SMALL_SIZE, LR_LOADFROMFILE));
        tExeFileIcon.hSmall      := HBITMAP(LoadImageW(0, PWideChar(ExecutableFileIconPath), IMAGE_BITMAP, SMALL_SIZE, SMALL_SIZE, LR_LOADFROMFILE));
        tShortCutIcon.hSmall     := HBITMAP(LoadImageW(0, PWideChar(ShortcutIconPath),       IMAGE_BITMAP, SMALL_SIZE, SMALL_SIZE, LR_LOADFROMFILE));
        tSymLinkIcon.hSmall      := HBITMAP(LoadImageW(0, PWideChar(SymLinkIconPath),        IMAGE_BITMAP, SMALL_SIZE, SMALL_SIZE, LR_LOADFROMFILE));


        //Load all the other icons that dont need its small size
        hSearchPathIcon   := HBITMAP(LoadImageW(0, PWideChar(SearchIconPath),         IMAGE_BITMAP,100, 80, LR_LOADFROMFILE));
        hCreateFileIcon   := HBITMAP(LoadImageW(0, PWideChar(CreateFileIconPath),     IMAGE_BITMAP, 80, 78, LR_LOADFROMFILE));
        hMenuIcon         := HBITMAP(LoadImageW(0, PWideChar(MenuIconPath),           IMAGE_BITMAP, 45, 45, LR_LOADFROMFILE));
        hCreateFolderIcon := HBITMAP(LoadImageW(0, PWideChar(CreateFolderIconPath),   IMAGE_BITMAP, 50, 50, LR_LOADFROMFILE));
        hSmallFolderIcon  := HBITMAP(LoadImageW(0, PWideChar(FolderIconPath),         IMAGE_BITMAP, 20, 20, LR_LOADFROMFILE));
      end;

      WM_NOTIFY: begin

        { LParam holds a pointer to the struct of the tree view item clicked,
          so make a cast to have the struct's data }
        tvData := PNMHDR(lParam);

        if(tvData.code = TVN_KEYDOWN) then
        begin
          { LParam holds a pointer to the struct that has the key press information,
            so make a cast to have the struct's data }
          ptvkd    := PNMKEY(lParam);

          { Check if the enter key was pressed }
          if(ptvkd.nVKey = VK_RETURN) then
          begin
            { If the key enter was pressed on a tree view item, update the path
              with the tree view item path and repaint to display that directory }

            selectedTVNode := GetTVNodeFromTreeViewSelectedItemHandle(tvData.hwndFrom);
            UpdatePath(selectedTVNode.fullPath + '\\');
            goto repaintFiles;
          end;

        end;


        if(tvData.code = NM_DBLCLK) then
        begin
          selectedTVNode := GetTVNodeFromTreeViewSelectedItemHandle(tvData.hwndFrom);

          { Load the directory into the node that was clicked }
          LoadDirectoryIntoTreeViewNodeList(selectedTVNode.fullPath, selectedTVNode.hItem);
        end;
      end;

      WM_MOUSEWHEEL: begin

        //Read if the mouse wheel was going down
        if(not (wParam = 4287102976)) then
        begin
          if(nLevel > 0) then
            begin
              nLevel := nLevel - 1;
            end
          else
            begin
              goto endOfFunction; //If equal to zero, then do not repaint in order to avoid flickering
            end;

          goto repaintFiles;
        end else
        begin
          nLevel := nLevel + 1;

          goto repaintFiles;
        end;

      end;

      WM_KEYDOWN: begin
        PrintInfoMsg('Keyboard key pressed: ' + IntToStr(wParam) + ' LParam: ' + IntToStr( lParam));
      end;

      WM_CONTEXTMENU: begin
        writeln('Button: ', lParam, ', W: ', wParam,' was right clicked');
        Writeln('File: ', string(GetFileFromHandle(wParam).findData.cFileName));

        fileHandleExist := DoesFileHandleExist(wParam);

        GetCursorPos(cursorPoint);
        hPopupMenu := CreatePopupMenu();

        { Check if the user right-clicked a file or folder, if not, exit }
        if(not fileHandleExist) then
          begin
            rightClicked_selectedFileOrDir := 0;
            contextMenuPasteBtnFlags := MF_BYPOSITION or MF_STRING;

            writeln(selectedFileOrDirName_forCopying);

            { If no file is selected for an operation, then disable the paste button }
            if(selectedFileOrDirName_forCopying = INVALID_FILE) then
              contextMenuPasteBtnFlags := contextMenuPasteBtnFlags or MF_DISABLED;

            InsertMenu(hPopupMenu, 0, contextMenuPasteBtnFlags, PASTE_FILE_CONTEXT_MENU_BTN_ID, PWideChar('Paste'));
          end
        else
          begin
            { Save the handle that the user right-clicked on, in order to use that handle to find and delete the file or for other file operations }
            rightClicked_selectedFileOrDir := wParam;

            InsertMenu(hPopupMenu, 0, MF_BYPOSITION or MF_STRING, DELETE_FILE_CONTEXT_MENU_BTN_ID, PWideChar('Delete'));
            InsertMenu(hPopUpMenu, 0, MF_BYPOSITION or MF_SEPARATOR, 0, nil);
            InsertMenu(hPopupMenu, 0, MF_BYPOSITION or MF_STRING, CREATE_SYM_LINK_CONTEXT_MENU_BTN_ID,  PWideChar('Create Sym Link'));
            InsertMenu(hPopupMenu, 0, MF_BYPOSITION or MF_STRING, CREATE_HARD_LINK_CONTEXT_MENU_BTN_ID, PWideChar('Create Hard Link'));
            InsertMenu(hPopupMenu, 0, MF_BYPOSITION or MF_STRING, CREATE_SHORTCUT_CONTEXT_MENU_BTN_ID,  PWideChar('Create Shortcut'));
            InsertMenu(hPopUpMenu, 0, MF_BYPOSITION or MF_SEPARATOR, 0, nil);
            InsertMenu(hPopupMenu, 0, MF_BYPOSITION or MF_STRING, CUT_FILE_CONTEXT_MENU_BTN_ID, PWideChar('Cut'));
            InsertMenu(hPopupMenu, 0, MF_BYPOSITION or MF_STRING, COPY_FILE_CONTEXT_MENU_BTN_ID, PWideChar('Copy'));

          end;

        SetForegroundWindow(hWnd);
        TrackPopupMenu(hPopupMenu, TPM_BOTTOMALIGN or TPM_LEFTALIGN, cursorPoint.X, cursorPoint.Y, 0, hWnd, 0);
      end;

      WM_COMMAND: begin

        { ------------------- "Scroll Bars" buttons events ------------------- }

        //Read the up button
        if(lParam = hUpBtn) then
        begin
          if(nLevel > 0) then
            begin
              nLevel := nLevel - 1;
            end
          else
            begin
              goto endOfFunction; //If equal to zero, then do not repaint in order to avoid flickering
            end;

          goto repaintFiles;
        end;

        //Read the down button
        if(lParam = hDownBtn) then
        begin
          nLevel := nLevel + 1;

          goto repaintFiles;
        end;

        { ------------------- Context Menu buttons events -------------------- }

        //Read the context menu's paste button click event
        if(wParam = PASTE_FILE_CONTEXT_MENU_BTN_ID) then
        begin

          PrintInfoMsg('Paste button was clicked, current path: ' + currentPath);

          if(selectedFile_Operation = OPERATION_COPYING) then
            begin
              CopyPasteSelectedFileOrDirectory();
            end
          else
            begin
              CutPasteSelectedFileOrDirectory();
            end;

          goto repaintFiles;
        end;

        if(wParam = COPY_FILE_CONTEXT_MENU_BTN_ID) then
        begin
          PrintInfoMsg('Copy button was clicked');

          selectedFileOrDirName_forCopying := IfThen(rightClicked_selectedFileOrDir = 0, INVALID_FILE, (currentPath + GetFileFromHandle(rightClicked_selectedFileOrDir).findData.cFileName));
          selectedFile_Operation := OPERATION_COPYING;

          PrintLogMsg('Selected file path: ' + selectedFileOrDirName_forCopying);

          goto repaintFiles;

        end;

        if(wParam = CUT_FILE_CONTEXT_MENU_BTN_ID) then
        begin
          PrintInfoMsg('Cut button was clicked');

          selectedFileOrDirName_forCopying := IfThen(rightClicked_selectedFileOrDir = 0, INVALID_FILE, (currentPath + GetFileFromHandle(rightClicked_selectedFileOrDir).findData.cFileName));
          selectedFile_Operation := OPERATION_CUTTING;

          PrintLogMsg('Selected file path: ' + selectedFileOrDirName_forCopying);

          goto repaintFiles;

        end;

        if(wParam = CREATE_SYM_LINK_CONTEXT_MENU_BTN_ID) then
        begin
          PrintInfoMsg('Create symlink button was clicked');
          selectedFileOrDirName_forCopying := IfThen(rightClicked_selectedFileOrDir = 0, INVALID_FILE, (currentPath + GetFileFromHandle(rightClicked_selectedFileOrDir).findData.cFileName));
          CreateSymLink(selectedFileOrDirName_forCopying);
          PrintLogMsg('Selected file path: ' + selectedFileOrDirName_forCopying);

          goto repaintFiles;
        end;

        if(wParam = CREATE_HARD_LINK_CONTEXT_MENU_BTN_ID) then
        begin
          PrintInfoMsg('Create hard link button was clicked');
          selectedFileOrDirName_forCopying := IfThen(rightClicked_selectedFileOrDir = 0, INVALID_FILE, (currentPath + GetFileFromHandle(rightClicked_selectedFileOrDir).findData.cFileName));
          CreateHardLinkss(selectedFileOrDirName_forCopying);
          PrintLogMsg('Selected file path: ' + selectedFileOrDirName_forCopying);

          goto repaintFiles;
        end;

        if(wParam = CREATE_SHORTCUT_CONTEXT_MENU_BTN_ID) then
        begin
          PrintInfoMsg('Create shortcut button was clicked');
          selectedFileOrDirName_forCopying := IfThen(rightClicked_selectedFileOrDir = 0, INVALID_FILE, (currentPath + GetFileFromHandle(rightClicked_selectedFileOrDir).findData.cFileName));
          CreateShortCut(selectedFileOrDirName_forCopying);
          PrintLogMsg('Selected file path: ' + selectedFileOrDirName_forCopying);

          goto repaintFiles;
        end;

        //Read the context menu's delete button click event
        if(wParam = DELETE_FILE_CONTEXT_MENU_BTN_ID) then
        begin
          DeleteSelectedFileOrDirectory();
          goto repaintFiles;
        end;

        { --------------------- "App bar" buttons events --------------------- }

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

        //Check for the menu icon button event
        if(lParam = hStyleBtn) then
        begin

          //If the message box window is open, dont proceed
          if(isSmallWndOpen) then
            goto endOfFunction;

          isLinear := not isLinear;

          goto repaintFiles;
        end;

        { --------------------- Text boxs edit events ------------------------ }

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

        { ------------------------ Other events ----------------------------- }

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

        { ----------------- Custom Message Box buttons events ---------------- }

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

        { ----------------- File's button events ---------------- }

        //If a file button was clicked, lParam will have the handle of the button that was pressed
        fileData := GetFileFromHandle(lParam);

        str := fileData.findData.cFileName;

        pathFromTheFuture := IfThen(hPathBtn = lParam, currentPath, (currentPath + str + '\\'));

        if(not isPathDirectory(pathFromTheFuture)) then
        begin
          command := 'Unknown file extension';

          pathFromTheFuture := pathFromTheFuture.Remove(pathFromTheFuture.LastIndexOf('\') - 1);  //Get rid of the '\\' from the string

          if(pathFromTheFuture.EndsWith('.exe')) then
          begin
            OK := ExecuteProcess(pathFromTheFuture, '', '', false, false, false, Error);
            PrintLogMsg('Creating of process status: ' + BoolToStr(OK));

            goto endOfFunction;
          end;

          if(pathFromTheFuture.EndsWith('.lnk')) then
          begin
            Winshell.GetShellLinkInfo(pathFromTheFuture, data);
            PrintInfoMsg('File path of the shortcut target: ' + data.PathName);

            goto endOfFunction;
          end;

          { Execute custom commands }
          if(pathFromTheFuture.EndsWith('.txt')) then
          begin
            command    := 'C:\Users\DELL\AppData\Local\Programs\Microsoft VS Code\Code.exe';
            parameters := pathFromTheFuture;
          end;

          if(pathFromTheFuture.EndsWith('.png')) then
          begin
            //command    := 'C:\\Windows\\System32\\rundll32.exe';
            //parameters := '"C:\\Program Files (x86)\\Windows Photo Viewer\\PhotoViewer.dll", ImageView_Fullscreen ' + pathFromTheFuture;
            command    := 'C:\Users\DELL\AppData\Local\Programs\Microsoft VS Code\Code.exe';
            parameters := pathFromTheFuture;
          end;

          if(not (command = 'Unknown file extension')) then
          begin
            OK := ExecuteProcess(command, parameters, '', false, false, false, Error);
            PrintLogMsg('Creating of process status: ' + BoolToStr(OK));
          end
          else
          begin
              PrintErrorMsg('unknown file extension ok? Cannot open this file');
          end;

          goto endOfFunction;
        end;


        if(str = '..') then
        begin
          //Since pathFromTheFuture will look like this: 'C:\\Users\\..\\', remove the '..' first
          pathFromTheFuture := pathFromTheFuture.Remove(pathFromTheFuture.IndexOf('..'));
          //Now, the string will look like this 'C:\\Users\\' but we want to get rid of the 'Users\\' because we want to go back a dir, in this case 'C:\\'
          //So, get rid of the '\\'
          pathFromTheFuture := pathFromTheFuture.Remove(pathFromTheFuture.LastIndexOf('\\'));
          //Now the string looks like this 'C:\\Users', now remove the last index of the '\\' plus 2
          //because we actually want to keep the '\\' in the path but at the same time we want to get rid of the rest of the chars that are after the '\\'
          pathFromTheFuture := pathFromTheFuture.Remove(pathFromTheFuture.LastIndexOf('\\') + 2);
          //Now the strings will look like this: 'C:\\'
        end;
          
        UpdatePath(pathFromTheFuture);

        nLevel := 0;

        repaintFiles:
          DestroyWindow(hEdit); //Destroy the label that shows the current path to display the new path (this will be repainted in DrawElements function)
          DestroyAllFiles();
          DrawElements(); //Draw all the files in the new path directory
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
  FileExtensionIconMap.Add('back'    ,  tBackIcon);
  FileExtensionIconMap.Add('folder'  ,  tFolderIcon);
  FileExtensionIconMap.Add('file'    ,  tFileIcon);
  FileExtensionIconMap.Add('txt'     ,  tTxtFileIcon);
  FileExtensionIconMap.Add('png'     ,  tPngFileIcon);
  FileExtensionIconMap.Add('shortcut',  tShortCutIcon);
  FileExtensionIconMap.Add('symlink' ,  tSymLinkIcon);
  FileExtensionIconMap.Add('exe'     ,  tExeFileIcon);
end;

begin
  LWndClass.hInstance := hInstance;

  hPrev := HTREEITEM(TVI_FIRST);
  hPrevRootItem                  := 0;
  hPrevLev2Item                  := 0;
  nLevel                         := 0;
  rightClicked_selectedFileOrDir := 0;
  isLinear                       := False;
  selectedFile_Operation             := OPERATION_COPYING;
  selectedFileOrDirName_forCopying   := INVALID_FILE;

  Randomize();
  InitCommonControls();


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
  nodeList     := TList<TVNode>.Create;
  pureFileList := TList<WIN32_FIND_DATA>.Create;
  hack         := TList<Integer>.Create;
  g_nUniqueID   := 0;
  FileExtensionIconMap := TDictionary<string,TIcon>.Create;
  InitFileExtensionMap();

  //Label
  hStatic         := CreateWindowEx(2,'Edit', 'Path: ', WS_VISIBLE or WS_CHILD or ES_LEFT, 20, 35, 73, 50,hMainHandle,0,hInstance,nil);
  SendMessage(hStatic, WM_SETFONT, hFontText, 0);

  //Search btn
  hPathBtn        := CreateWindowW('Button', 'Search', WS_VISIBLE or WS_CHILD or BS_BITMAP, SEARCH_BAR_X_POS + 1100 + 20, SEARCH_BAR_Y_POS, 38, 33, hMainHandle, 0, hInstance, nil);
  SendMessageW(hPathBtn, BM_SETIMAGE, IMAGE_BITMAP, LPARAM(hSearchPathIcon));

  //Create file btn
  hCreateFileBtn  := CreateWindowW('Button', 'Create File', WS_VISIBLE or WS_CHILD or BS_BITMAP, 180, 75, 50, 52, hMainHandle, 0, hInstance, nil);
  SendMessageW(hCreateFileBtn, BM_SETIMAGE, IMAGE_BITMAP, LPARAM(hCreateFileIcon));

  //Create directory btn
  hCreateDirBtn   := CreateWindowW('Button', 'Create Dir', WS_VISIBLE or WS_CHILD or BS_BITMAP, 290, 75, 50, 50, hMainHandle, 0, hInstance, nil);
  SendMessageW(hCreateDirBtn, BM_SETIMAGE, IMAGE_BITMAP, LPARAM(hCreateFolderIcon));

  //Change menu file btn
  hStyleBtn       := CreateWindowW('Button', 'Menu Icon', WS_VISIBLE or WS_CHILD or BS_BITMAP, 400, 75, 50, 50, hMainHandle, 0, hInstance, nil);
  SendMessageW(hStyleBtn, BM_SETIMAGE, IMAGE_BITMAP, LPARAM(hMenuIcon));

  //Up Button
  hUpBtn    := CreateWindow('Button', '^', WS_VISIBLE or WS_CHILD or BS_PUSHBUTTON or BS_TEXT, 1250, 300, 40, 40, hMainHandle, 0, hInstance, nil);

  //Down Button
  hDownBtn  := CreateWindow('Button', 'v', WS_VISIBLE or WS_CHILD or BS_PUSHBUTTON or BS_TEXT, 1250, 350, 40, 40, hMainHandle, 0, hInstance, nil);

  DrawElements();

  CreateTreeView();
  LoadDirectoryIntoTreeViewNodeList('C:', TVI_ROOT);

  while GetMessage(Msg,0,0,0) do
  begin
    TranslateMessage(Msg);
    DispatchMessage(Msg);
  end;

end.
