HOOKDEF(LONG, WINAPI, RegOpenKeyExA, __in HKEY hKey,
                       __in_opt LPCTSTR lpSubKey, __reserved DWORD ulOptions,
                       __in REGSAM samDesired, __out PHKEY phkResult) {
  LONG ret;
  if (strstr(lpSubKey, "VirtualBox") != NULL) {
    ret = 1;
    LOQ("s", "Hardening", "Faked RegOpenKeyExA return");
  } else if (strstr(lpSubKey, "ControlSet") != NULL) {
    ret = 1;
    LOQ("s", "Hardening", "Faked RegOpenKeyExA return");
  } else {
    ret = Old_RegOpenKeyExA(hKey, lpSubKey, ulOptions, samDesired, phkResult);
  }
  LOQ("psP", "Registry", hKey, "SubKey", lpSubKey, "Handle", phkResult);
  return ret;
}
HOOKDEF(DWORD, WINAPI, GetFileAttributesA,
                           __in LPCTSTR lpFileName) {
  BOOL ret;
  if (strstr(lpFileName, "VBox") != NULL) {
    ret = INVALID_FILE_ATTRIBUTES;
    LOQ("s", "Hardening", "Faked GetFileAttributesA return");
  } else {
    ret = Old_GetFileAttributesA(lpFileName);
  }
  LOQ("s", "GetFileAttributesA", lpFileName);
  return ret;
}
HOOKDEF(LONG, WINAPI, RegQueryValueExA, __in HKEY hKey,
                       __in_opt LPCTSTR lpValueName,
                       __reserved LPDWORD lpReserved, __out_opt LPDWORD lpType,
                       __out_opt LPBYTE lpData, __inout_opt LPDWORD lpcbData) {
  LONG ret;
  if (strstr(lpValueName, "SystemBiosVersion") != NULL) {
    ret = ERROR_SUCCESS;
    LOQ("s", "Hardening", "Faked RegQueryValueExA return");
  } else if (strstr(lpValueName, "Identifier") != NULL) {
    ret = ERROR_SUCCESS;
    LOQ("s", "Hardening", "Faked RegQueryValueExA return");
  } else if (strstr(lpValueName, "ProductId") != NULL) {
    ret = ERROR_SUCCESS;
    LOQ("s", "Hardening", "Faked RegQueryValueExA return");
  } else {
    ret = Old_RegQueryValueExA(hKey, lpValueName, lpReserved, lpType, lpData,
                               lpcbData);
  }
  LOQ("psLB", "Handle", hKey, "ValueName", lpValueName, "Type", lpType,
      "Buffer", lpcbData, lpData);
  return ret;
}
