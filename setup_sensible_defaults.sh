#!/bin/sh

case "$(readlink -f /sbin/init)" in
*systemd*)
	logind_conf="/etc/systemd/logind.conf"
	;;
*)
	logind_conf="/etc/elogind/logind.conf"
	;;
esac

append() {
	if ! sudo grep -q "$1" "$2"; then
		echo "$1" | sudo tee --append "$2"
	fi
}

artix_only_settings() {
	# dbus UUID must be generated for Artix runit.
	sudo mkdir -p /var/lib/dbus
	dbus-uuidgen | sudo tee /var/lib/dbus/machine-id

	# # Use system notifications for chromium based browsers on Artix
	sudo mkdir -p /etc/profile.d
	echo "export \$(dbus-launch)" | sudo tee /etc/profile.d/dbus.sh
}

sudo sed -Ei "s/^#(ParallelDownloads).*/\1 = 10/;/^#Color$/s/#//" /etc/pacman.conf

# less shutdown times.
[ -f "/etc/systemd/system.conf" ] && sudo sed -i 's/#DefaultTimeoutStopSec=90s/DefaultTimeoutStopSec=10s/' /etc/systemd/system.conf

# disable shutdown using power key.
sudo sed -i "s/#HandlePowerKey=poweroff/HandlePowerKey=ignore/" $logind_conf

# don't bootup when hibernated on lid open
sudo sed -Ei "s/^#HibernateMode.*/HibernateMode=shutdown/" /etc/systemd/sleep.conf

# disable BIOS beeps
sudo rmmod pcspkr
sudo mkdir -p /etc/modprobe.d
echo "blacklist pcspkr" | sudo tee /etc/modprobe.d/nobeep.conf

# disable headset popup
echo 'options snd_hda_intel power_save=0' | sudo tee /etc/modprobe.d/modprobe.conf

# enable sysrq
sudo mkdir -p /etc/sysctl.d
echo "kernel.sysrq = 1" | sudo tee /etc/sysctl.d/99-sysctl.conf

gsettings set org.gtk.Settings.FileChooser window-size '(800, 600)'

# Sudo permissions
sudo mkdir -p /etc/sudoers.d
append "@includedir /etc/sudoers.d" /etc/sudoers
echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/00-mhd-wheel-can-sudo
echo "%wheel ALL=(ALL:ALL) NOPASSWD:/usr/bin/shutdown,/usr/bin/reboot,/usr/bin/updatedb,/usr/bin/mount,/usr/bin/umount,/usr/bin/pacman -Syu,/usr/bin/pacman -Syyu,/usr/bin/pacman -Syyu --noconfirm,/usr/bin/loadkeys,/usr/bin/pacman -Syyuw --noconfirm,/usr/bin/pacman -S -u -y --config /etc/pacman.conf --,/usr/bin/pacman -S -y -u --config /etc/pacman.conf --" | sudo tee /etc/sudoers.d/01-mhd-cmds-without-password
echo "Defaults editor=/usr/bin/nvim" | sudo tee /etc/sudoers.d/02-mhd-visudo-editor

if [ "$(readlink -f /sbin/init)" != "*systemd*" ]; then
	artix_only_settings
fi
