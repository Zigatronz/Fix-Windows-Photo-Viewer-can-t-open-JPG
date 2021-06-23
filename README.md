# Fix Windows Photo Viewer can't open JPG
Here is how to fix the Windows Photo Viewer problem.
 ## Where/How this problem occur?
  - This problem occur when you take **picture from your phone's screenshot**
  - When open the file **using Windows Photo Viewer** this **error appeared** on Windows Photo display:
    > "Windows Photo Viewer can't display this picture because there might not be enough memory available in your computer. Close some program that you aren't using or free some hard disk space (if it's almost full), and then try again."
 ## How to fix
  - Somehow this can be fix by converting all your picture with **image converter** but it may resulting **quality drop**
  - To overcome the issue, only **1 byte** in the JPG file that need to be change, which is:
    > from: "ICC_PROFILE"\
    > to: "ICC_PROFILX"

    Hex view:
    > address: 0x22\
    > from: 0x45\
    > to: 0x58
  - It's hard to convert all of it one-by-one. So, I made a software that can change all of that **easily, simply at instant speed**
  - Refer download below

# Download
  [Download Fix JPG](https://github.com/Zigatronz/Fix-Windows-Photo-Viewer-can-t-open-JPG/releases/tag/v1.0)

# How to use
 - Simply **run `FixJPG.exe`**
 - Later `FixJPG.exe` will create you a folder called `ToFix`
 - Drop all **JPG files** you want to fix **into `ToFix` folder**
 - **Run `FixJPG.exe`** again
 - You're done

 # How it's work
 - Read byte at `0x22`, if it's `0x45`, then change it to `0x58`
 - only `.jpg` files in ToFix folder are processed