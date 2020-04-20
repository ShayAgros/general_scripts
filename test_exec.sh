#!/bin/sh

sudo kexec -l /boot/vmlinuz-5.5.0-rc2+ --initrd=/boot/initrd.img-5.5.0-rc2+ --reuse-cmdline

sudo systemctl kexec
