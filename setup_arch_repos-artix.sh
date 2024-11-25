#!/bin/sh

if [ "$(readlink -f /sbin/init)" != "*systemd*" ]; then
	echo "Enabling Arch Repositories for more a more extensive software collection..."
	if ! grep -q "^\[universe\]" /etc/pacman.conf; then
		echo "[universe]
Server = https://universe.artixlinux.org/\$arch
Server = https://mirror1.artixlinux.org/universe/\$arch
Server = https://mirror.pascalpuffke.de/artix-universe/\$arch
Server = https://artixlinux.qontinuum.space/artixlinux/universe/os/\$arch
Server = https://mirror1.cl.netactuate.com/artix/universe/\$arch
Server = https://ftp.crifo.org/artix-universe/" | sudo tee --append /etc/pacman.conf
		sudo pacman -Sy --noconfirm
	fi
	sudo pacman --noconfirm --needed -Sy \
		artix-keyring artix-archlinux-support
	for repo in extra community; do
		if ! grep -q "^\[$repo\]" /etc/pacman.conf; then
			echo "[$repo]
Include = /etc/pacman.d/mirrorlist-arch" | sudo tee --append /etc/pacman.conf
			sync=1
		else
			sync=0
		fi
	done
	[ "$sync" -eq 1 ] && {
		sudo pacman -Sy
		sudo pacman-key --populate archlinux
	}
fi
