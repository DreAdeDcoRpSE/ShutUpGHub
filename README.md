# G Hub Discord Integration Disable Script

## Overview
This is a simple Windows batch script designed to **automatically disable Logitech G Hub’s integration with Discord**.  

Logitech G Hub often ignores its own “disable Discord integration” settings and can prompt users repeatedly to connect to Discord. This script modifies the internal G Hub configuration file and prevents it from asking to connect to Discord, while safely restarting G Hub afterward.

---

## How It Works

1. **Shuts down G Hub completely**  
   The script kills `lghub.exe`, `lghub_agent.exe`, and `lghub_updater.exe` to ensure no processes are running before making changes.

2. **Locates the Discord integration config**  
   The relevant configuration file is located at:  
   `%LocalAppData%\LGHUB\integrations\applet_discord\config.json`
   
4. **Removes the read-only attribute if set**  
Ensures the script can modify the JSON configuration file.

5. **Checks and updates the “enabled” setting**  
- If `"enabled": false` is already set, it reports it.  
- Otherwise, it replaces `"enabled": true` with `"enabled": false` in the JSON file.

5. **Restores the read-only attribute**  
Prevents G Hub from automatically re-enabling the integration until manually changed.

6. **Waits safely and provides a countdown**  
Pauses are included to allow G Hub’s backend services to fully shut down and catch up, preventing errors during restart. A 10-second countdown is displayed for visual feedback.

7. **Restarts G Hub**  
Launches the G Hub application after making the changes.

---

## Usage

1. Close any G Hub windows (optional, as the script will force close them).  
2. Double-click the batch file or run it from a terminal.  
3. Wait for the countdown and confirmation messages.  
4. G Hub will restart automatically with Discord integration disabled.  

> **Note:** Each time G Hub updates, it may reset this configuration. You will need to re-run this script after updates.

---

## Requirements

- Windows OS  
- Logitech G Hub installed  
- No additional software required; uses built-in CMD and PowerShell  

---

## Safety Notes

- The script only modifies the `applet_discord/config.json` file.  
- All changes are local to your user account.  
- The read-only attribute ensures changes persist even if G Hub tries to reset them.

---

## License

This project is licensed under the **GNU General Public License v3.0 (GPL-3.0)**. See the [LICENSE](LICENSE) file for details.

