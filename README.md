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

This script here attempts to solve the issues associated with BC3 compression done during loading by using better, more complex formats and doing this in advance. Results are stored in DDS files placed next to the usual PNGs. These take up more storage space, but can be loaded up as is and near instantly, greatly cutting down on loadup times. To save VRAM, the script converts textures without transparency into the BC1 format, which has no alpha channel. This lowers the footprint of relevant textures by 50%. Other textures are compressed into the high quality BC7 format with an identical memory use to BC3, but far fewer artifacts and smoother gradients. The tradeoff for the higher quality and efficiency is a far higher initial processing power requirement and slightly narrower GPU support. DirectX 10 support is necessary for this to work. The cutoff age for GPUs with this is generally somewhere around 2010. Runtime GPU usage is identical.

Note regarding this script: Due to limitations of powershell this script has to create a small and very short-lived cache file. The default path I chose for that is C:\. If you don't have a C: drive, you will have to edit said path at the lines 19, 22 and 25 of the ps1 file.