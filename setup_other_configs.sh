#!/bin/sh

# user config
shell="zsh"
sudo usermod -a -G wheel,video,audio,docker -s /bin/$shell "$USER" && chown "$USER":wheel /home/"$USER"
# sudo groupadd no-internet
# sudo usermod -a -G no-internet "$USER"
# sudo iptables -I OUTPUT 1 -m owner --gid-owner no-internet -j DROP # drop network activity for group no-internet
# xorg configs

for c in "00-keyboard.conf" "20-intel.conf" "30-touchpad.conf"; do
	sudo cp ./xorg.conf.d/$c /etc/X11/xorg.conf.d/$c
done
# keyd config
sudo cp ./systemwide_configs/keyd.conf /etc/keyd/default.conf

# cronjobs
crontab - <"./systemwide_configs/cronjobs.txt"
