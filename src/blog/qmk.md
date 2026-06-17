---
title: "Flashing a Corne keyboard with QMK on linux"
date: 2026-06-17
---
I have a corne keyboard and I bounce on and off using it (mostly off).
It was a fun project to put together and typing on it is different and probably worth the novelty
to someone like me who uses computers a lot.
Usually I only pick it up once or twice a year,
which is very annoying because I need to relearn how to flash it every time I want to use it again.

So for future me, this is really only a 5 minute job.

## Step 0: Obtain a keymap
Get a keymap from qmk configurator or edit a keymap.c, or anywhere else.

## Step 1: Compile the firmware
Using qmk compile firmware for your keyboard.
The command will probably look something like:
``` sh
qmk compile -kb <keyboard> -km <keymap>
```

Note: my command looks like this:
``` sh
qmk compile -e CONVERT_TO=promicro_rp2040
```

Generally just follow the steps here: 
docs.qmk.fm/newbs_building_firmware

## Step 2: Putting it on the keyboard
This is where I usually get caught up.
I'm on linux and I do not usually have luck with this command:

``` sh
qmk flash -kb <my_keyboard> -km <my_keymap>
```

Instead I have found that mounting the keyboard and copying over the compiled firmware works great.
``` sh
mount /dev/sdXYZi /mnt
cp firmware-name.uf2 /mnt/
umount /mnt
```

## Summary
``` bash
cp keymap.json keyboards/crkbd/keymaps/zeikoh/keymap.json 

qmk compile -e CONVERT_TO=promicro_rp2040

# Plug in one half of the keyboard, set it to flash mode by clicking button twice
lsblk # confirm it shows as partition
sudo mount /dev/sdXYZi /mnt
sudo cp firmware.uf2 /mnt/
sudo umount /mnt

# Do the other half as above...

# Success...?
```
