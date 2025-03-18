import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart' as win;

class Util{
  //windows.
  void getActiveWinName(){
    String name = '';
    int hwnd = win.GetForegroundWindow();
    ffi.Pointer<Utf16>? namePtr = name.toNativeUtf16();
    int? y = win.GetWindowTextLength(hwnd);
    win.GetWindowText(hwnd, namePtr, y+1);
    name = namePtr.toDartString(length: y);
    print(name);
    win.free(namePtr);
  }
}

