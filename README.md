# DDSgenerator

A script to quickly and easily generate DDS files for textures, with the goal of improving texture quality, reducing load times, RAM usage and VRAM usage.
Created for Rimworld, but this should work just fine for other games too.

Makes use of Microsoft texconv and texdiag as well as ImageMagick.
Supported formats are JPG and PNG, but other formats supported by ImageMagick can easily be edited in when necessary too.

General usage of this script is:
 - Place the script and its dependancies folder in a folder that contains pictures anywhere, including subfolders, and all their subfolders.
 - Right-click DDSgenerator.ps1
 - Run with powershell
 - ???


Note: Due to limitations of powershell this script has to create a small and very short-lived cache file. The default path I chose for that is C:\. If you don't have a C: drive, you will have to edit said path at the lines 19, 22 and 25 of this script.