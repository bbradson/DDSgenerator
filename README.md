# DDSgenerator

A script to quickly and easily generate DDS files for textures, with the goal of improving texture quality, reducing load times, VRAM usage and potentially RAM usage.
Created for Rimworld, but this should work just fine for other games too.

Makes use of Microsoft texconv and texdiag as well as ImageMagick.
Supported formats are JPG and PNG, but other formats supported by ImageMagick can easily be edited in when necessary too.

General usage of this script is:
 - Place the script and its dependancies folder in a folder that contains pictures anywhere, including subfolders, and all their subfolders.
 - Right-click DDSgenerator.ps1
 - Run with powershell
 - ???



How it works:

PNG and JPG files normally have a small filesize, but the formats themselves cannot be directly displayed by a GPU. Applications and games like Rimworld have to unpack, decompress and then convert the content of these files into a suitable texture format for GPUs, usually just plain RGBA. This RGBA data has a fixed size of 4 bytes per pixel. 4MB for a 1024x1024 texture, 16KB for a 64x64 texture, directly translating into a matching, rather large VRAM usage. To reduce this impact on VRAM special kinds of compression that can be read out and processed by GPUs exist. Rimworld compresses all textures into a format called BC3 during loading. It's rather old and not too good looking, but it works on all computers and is quicker to assemble than more complex formats. It's also the cause of artifacts that most textures appear to have in rimworld when zooming in on them.

This script here attempts to solve the issues BC3 has by compressing into better formats, using up more processing power and more time than one would normally want to allocate during loading. It compresses textures that have no transparency into a format that does not support any: BC1. This further reduces VRAM usage by 50% for affected textures, with no other differences over BC3. All other textures are compressed into the modern BC7 format. BC7 does not use up less VRAM than BC3, but it looks far better, having almost no artifacts at all. It does however require lots of processing power to create and isn't compatible with GPUs that do not support DirectX 10. The cutoff age for GPUs here is generally somewhere around 2010.

The container used to store textures on the hard drive is DDS. Unlike PNG it directly accepts compressed texture formats and only requires reading out by applications, greatly cutting down on loadup times.


Note regarding this script: Due to limitations of powershell this script has to create a small and very short-lived cache file. The default path I chose for that is C:\. If you don't have a C: drive, you will have to edit said path at the lines 19, 22 and 25 of the ps1 file.