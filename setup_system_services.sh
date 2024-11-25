#!/bin/sh

case "$(readlink -f /sbin/init)" in
*systemd*)
	systemctl --enable --user pipewire-pulse.service
	systemctl --enable --user pipewire-pulse.socket
	sudo systemctl enable --now --user NetworkManager
	sudo systemctl enable --now --user cronie
	sudo systemctl enable --now keyd
	sudo systemctl enable --now tlp
	;;
*runit*)
    sudo rm -rf /etc/runit/sv/keyd/
    sudo cp -r ./runit_services/keyd/ /etc/runit/sv/
	for service in NetworkManager backlight cronie keyd; do #tlp vnstat modemmanager
		sudo ln -s "/etc/runit/sv/$service" /run/runit/service/
	done
	if [ ! -e '/run/runit/service/logind' ]; then
		sudo ln -s "/etc/runit/sv/elogind" /run/runit/service/
	fi
	;;
esac
