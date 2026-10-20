/*
 * Next Token — Windows screensaver (.scr)
 *
 * Plays next-token.html (in the same folder as this .scr) full screen in
 * Microsoft Edge's kiosk mode, and closes it on any key press, mouse click,
 * touch, or real mouse movement — like a normal Windows screensaver.
 *
 * Arguments (standard screensaver protocol):
 *   /s        run the screensaver
 *   /p <hwnd> preview inside Control Panel's small monitor (not supported: exits)
 *   /c        settings (shows a short info box)
 *   (none)    run the screensaver (handy for double-click testing)
 *
 * Build (MinGW-w64):  see build-windows.sh
 */
#ifndef UNICODE
#define UNICODE
#endif
#ifndef _UNICODE
#define _UNICODE
#endif
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <shellapi.h>
#include <shlobj.h>
#include <wchar.h>
#include <stdlib.h>
#include <stdio.h>

#define GRACE_MS        1500      /* ignore input right after start */
#define MOVE_THRESHOLD  12        /* pixels the pointer must move to count as "real" */
#define APP_TITLE       L"Next Token"

static HANDLE g_job = NULL;
static HANDLE g_edge = NULL;
static DWORD  g_startTick = 0;
static POINT  g_origin = { -1, -1 };
static HHOOK  g_kbHook = NULL, g_msHook = NULL;

static void quit(void) { PostQuitMessage(0); }
static BOOL armed(void) { return GetTickCount() - g_startTick > GRACE_MS; }

static LRESULT CALLBACK kbProc(int code, WPARAM wp, LPARAM lp) {
    if (code == HC_ACTION && armed() && (wp == WM_KEYDOWN || wp == WM_SYSKEYDOWN)) quit();
    return CallNextHookEx(g_kbHook, code, wp, lp);
}

static LRESULT CALLBACK msProc(int code, WPARAM wp, LPARAM lp) {
    if (code == HC_ACTION && armed()) {
        MSLLHOOKSTRUCT *m = (MSLLHOOKSTRUCT *)lp;
        if (wp == WM_MOUSEMOVE) {
            if (g_origin.x == -1) g_origin = m->pt;
            else if (abs(m->pt.x - g_origin.x) > MOVE_THRESHOLD || abs(m->pt.y - g_origin.y) > MOVE_THRESHOLD) quit();
        } else {
            quit();   /* any button, wheel, or touch (touch is delivered as mouse input) */
        }
    }
    return CallNextHookEx(g_msHook, code, wp, lp);
}

/* Find msedge.exe: App Paths registration first, then the standard install folders. */
static BOOL findEdge(wchar_t *out, DWORD cch) {
    const wchar_t *key = L"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\App Paths\\msedge.exe";
    HKEY roots[2] = { HKEY_CURRENT_USER, HKEY_LOCAL_MACHINE };
    for (int i = 0; i < 2; i++) {
        DWORD sz = cch * sizeof(wchar_t);
        if (RegGetValueW(roots[i], key, NULL, RRF_RT_REG_SZ, NULL, out, &sz) == ERROR_SUCCESS &&
            GetFileAttributesW(out) != INVALID_FILE_ATTRIBUTES) return TRUE;
    }
    const wchar_t *envs[2] = { L"ProgramFiles(x86)", L"ProgramFiles" };
    for (int i = 0; i < 2; i++) {
        wchar_t base[MAX_PATH];
        if (GetEnvironmentVariableW(envs[i], base, MAX_PATH)) {
            _snwprintf(out, cch, L"%s\\Microsoft\\Edge\\Application\\msedge.exe", base);
            out[cch - 1] = 0;
            if (GetFileAttributesW(out) != INVALID_FILE_ATTRIBUTES) return TRUE;
        }
    }
    return FALSE;
}

/* Build a file:/// URL from a Windows path (UTF-8, percent-encoded). */
static void pathToUrl(const wchar_t *path, wchar_t *out, size_t cch) {
    char utf8[4 * MAX_PATH];
    WideCharToMultiByte(CP_UTF8, 0, path, -1, utf8, sizeof utf8, NULL, NULL);
    char url[12 * MAX_PATH] = "file:///";
    size_t n = strlen(url);
    for (unsigned char *p = (unsigned char *)utf8; *p && n < sizeof url - 4; p++) {
        unsigned char c = *p;
        if (c == '\\') url[n++] = '/';
        else if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') ||
                 strchr("-._~/:", c)) url[n++] = (char)c;
        else n += sprintf(url + n, "%%%02X", c);
    }
    url[n] = 0;
    strcat(url, "?kiosk=1");
    MultiByteToWideChar(CP_UTF8, 0, url, -1, out, (int)cch);
}

/* Delete a folder tree (used to give Edge a clean profile every run). */
static void deleteTree(const wchar_t *dir) {
    wchar_t from[MAX_PATH + 2] = { 0 };
    wcsncpy(from, dir, MAX_PATH);                       /* double-NUL terminated */
    SHFILEOPSTRUCTW op = { 0 };
    op.wFunc = FO_DELETE; op.pFrom = from;
    op.fFlags = FOF_NO_UI;
    SHFileOperationW(&op);
}

static int runSaver(void) {
    HANDLE mutex = CreateMutexW(NULL, TRUE, L"Local\\NextTokenScreensaver");
    if (GetLastError() == ERROR_ALREADY_EXISTS) return 0;   /* already running */

    wchar_t self[MAX_PATH], dir[MAX_PATH], html[MAX_PATH], edge[MAX_PATH], url[4 * MAX_PATH];
    GetModuleFileNameW(NULL, self, MAX_PATH);
    wcscpy(dir, self);
    wchar_t *slash = wcsrchr(dir, L'\\'); if (slash) *slash = 0;
    _snwprintf(html, MAX_PATH, L"%s\\next-token.html", dir); html[MAX_PATH - 1] = 0;
    if (GetFileAttributesW(html) == INVALID_FILE_ATTRIBUTES) {
        MessageBoxW(NULL, L"next-token.html was not found next to the screensaver file.\n"
                          L"Reinstall Next Token with Install.bat.", APP_TITLE, MB_ICONERROR);
        return 1;
    }
    if (!findEdge(edge, MAX_PATH)) {
        MessageBoxW(NULL, L"Microsoft Edge was not found. Next Token needs Edge to play.", APP_TITLE, MB_ICONERROR);
        return 1;
    }
    pathToUrl(html, url, 4 * MAX_PATH);

    wchar_t profile[MAX_PATH], local[MAX_PATH];
    if (!GetEnvironmentVariableW(L"LOCALAPPDATA", local, MAX_PATH)) wcscpy(local, dir);
    _snwprintf(profile, MAX_PATH, L"%s\\NextToken\\EdgeProfile", local); profile[MAX_PATH - 1] = 0;
    deleteTree(profile);

    wchar_t cmd[8 * MAX_PATH];
    _snwprintf(cmd, 8 * MAX_PATH,
        L"\"%s\" --kiosk \"%s\" --edge-kiosk-type=fullscreen --user-data-dir=\"%s\" "
        L"--no-first-run --no-default-browser-check --disable-features=Translate",
        edge, url, profile);
    cmd[8 * MAX_PATH - 1] = 0;

    /* Put Edge (and every process it starts) in a job, so closing the job closes Edge completely. */
    g_job = CreateJobObjectW(NULL, NULL);
    JOBOBJECT_EXTENDED_LIMIT_INFORMATION li = { 0 };
    li.BasicLimitInformation.LimitFlags = JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;
    SetInformationJobObject(g_job, JobObjectExtendedLimitInformation, &li, sizeof li);

    STARTUPINFOW si;
    ZeroMemory(&si, sizeof si);
    si.cb = sizeof si;
    PROCESS_INFORMATION pi;
    if (!CreateProcessW(NULL, cmd, NULL, NULL, FALSE, CREATE_SUSPENDED, NULL, dir, &si, &pi)) {
        MessageBoxW(NULL, L"Could not start Microsoft Edge.", APP_TITLE, MB_ICONERROR);
        return 1;
    }
    AssignProcessToJobObject(g_job, pi.hProcess);
    ResumeThread(pi.hThread);
    CloseHandle(pi.hThread);
    g_edge = pi.hProcess;
    g_startTick = GetTickCount();

    g_kbHook = SetWindowsHookExW(WH_KEYBOARD_LL, kbProc, GetModuleHandleW(NULL), 0);
    g_msHook = SetWindowsHookExW(WH_MOUSE_LL, msProc, GetModuleHandleW(NULL), 0);
    SetTimer(NULL, 1, 250, NULL);

    MSG msg;
    while (GetMessageW(&msg, NULL, 0, 0) > 0) {
        if (msg.message == WM_TIMER && WaitForSingleObject(g_edge, 0) == WAIT_OBJECT_0) break; /* Edge closed (Alt+F4) */
        DispatchMessageW(&msg);
    }

    if (g_kbHook) UnhookWindowsHookEx(g_kbHook);
    if (g_msHook) UnhookWindowsHookEx(g_msHook);
    TerminateJobObject(g_job, 0);
    CloseHandle(g_job);
    CloseHandle(g_edge);
    ReleaseMutex(mutex);
    return 0;
}

int WINAPI wWinMain(HINSTANCE hi, HINSTANCE hp, PWSTR args, int show) {
    (void)hi; (void)hp; (void)show;
    wchar_t a[8] = { 0 };
    const wchar_t *p = args;
    while (*p == L' ') p++;
    if (*p == L'/' || *p == L'-') p++;
    a[0] = (wchar_t)towlower(*p);

    if (a[0] == L'p') return 0;                       /* no mini preview */
    if (a[0] == L'c') {
        MessageBoxW(NULL, L"Next Token has no settings.\n\n"
                          L"Set the wait time in Windows' Screen Saver Settings.\n"
                          L"How a language model writes, one token at a time.", APP_TITLE, MB_ICONINFORMATION);
        return 0;
    }
    return runSaver();                                /* /s or no argument */
}
