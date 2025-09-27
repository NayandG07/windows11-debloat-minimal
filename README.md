# 🪟 Windows Minimalist Debloat

A lightweight, reversible debloat tool for Windows 10/11 that removes unnecessary bloat like Edge UI, Bing integration, and telemetry — while keeping apps like Spotify, Netflix, and Microsoft Store working.  

---

## ✨ Features

- 🗑️ Remove Edge browser UI (but keep WebView2 runtime so apps still work).  
- 🔍 Disable Bing integration in Start Menu search.  
- 📉 Disable telemetry services (DiagTrack, WerSvc) for privacy.  
- 🔁 Reversible: run Revert.ps1 to restore defaults (Edge, Bing, telemetry).  
- 🛡️ Smart watchdog (DebloatWatchdog.bat) that checks on startup:
  - If no bloat → exits silently.  
  - If Edge/Bing reappear → gives a choice:  
    - Yes → fix + reboot now.  
    - No → schedule fix automatically on next reboot.  
- 📜 Logging: everything is tracked in C:\Debloat\watchdog.log.

---

## 📂 Files Included

- Debloat.ps1 — main debloat script.  
- Revert.ps1 — undo all changes (restore Edge, Bing, telemetry).  
- DebloatWatchdog.bat — auto-monitor and fix if Windows updates restore bloat.  
- README.md — this guide.  
- LICENSE — MIT License.  

---

## 🚀 How to Use

### 1. Download
- Go to the GitHub repo.  
- Click Code → Download ZIP, extract to C:\Debloat.  

---

### 2. Run the Debloat Script
- Right-click Debloat.ps1 → Run with PowerShell.  
- This will:  
  - Remove Edge browser UI.  
  - Disable Bing search integration.  
  - Disable telemetry services.  
- All actions logged to C:\Debloat\watchdog.log.

---

### 3. Enable the Watchdog
To auto-fix if updates bring bloat back:  
1. Press Win + R, type shell:startup, press Enter.  
2. Copy DebloatWatchdog.bat into the Startup folder.  

Now, every login:  
- If everything is fine → watchdog exits silently.  
- If Edge/Bing return → it will prompt you:  
  - Yes → fix + reboot now.  
  - No → silently schedule fix for next reboot.  

---

### 4. Revert to Defaults
If you want Edge, Bing, and telemetry back:  
- Right-click Revert.ps1 → Run with PowerShell.  
- Restores defaults and logs it.

---

### 5. Logs
- Check: C:\Debloat\watchdog.log

---

## ❓ Why This Tool?

Most debloat scripts are either too aggressive or one-and-done.  
This project is:  
- 🎯 Targeted — only Edge UI, Bing search, telemetry.  
- 🛠️ Safe — keeps WebView2 runtime so apps don’t break.  
- 🔄 Persistent — watchdog re-applies fixes if updates undo them.  
- 🔓 Reversible — Revert.ps1 brings everything back.  

---

## ⚠️ Disclaimer

- Use at your own risk.  
- Tested on Windows 10/11 Pro.  
- Major Windows updates may restore bloat (watchdog helps mitigate).  

---

## 📜 License

This project is licensed under the [MIT License](./LICENSE).