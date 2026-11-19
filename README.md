# PC-Hardware-Inspector

A small Windows program that shows what is inside your PC in one click. Open it, and you get a clean hardware report you can paste straight into a chat, forum post, or support ticket.

Built for the moment someone says "my game keeps crashing" and you need to know what they are running.

## What it shows

- Computer model, motherboard, and BIOS
- Windows version and build
- CPU: name, cores, threads, clock speed, cache
- RAM: total, available, and every installed module (size, type, speed, brand)
- GPU: name, VRAM, driver version, driver date, current resolution
- Drives: model, type (SSD or HDD), size, health, free space
- Monitors, network adapters, and audio devices
- Battery, if there is one

No personal data is collected. IP addresses, MAC addresses, and serial numbers are not included.

## How to use it

1. Go to the Releases page and download 'PC-Hardware-Inspector.exe' and the source code.
2. Export it
3. Double click the .exe file.
4. Wait a few seconds. The report appears in the window.
5. The report is already copied to your clipboard. Paste it wherever you need it with Ctrl+V.

That is the whole program. It is a single file and nothing needs to be installed.

## Where reports are saved

Every run saves a text file to an `Exports` folder next to the program, named with the date and time:

```
Exports/PC-Hardware-Report_Year-Month-Day_Hour-Minute-Second.txt
```

## Requirements

Windows 10 or Windows 11.
