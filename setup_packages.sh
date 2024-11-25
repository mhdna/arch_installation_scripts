#!/usr/bin/env bash

# Usage:
# -c cleans up only
# Otherwise, it does all the good stuff

repodir="$HOME/.local/src"
aurhelper="yay"
if [ -f "pkgs.txt" ]; then
	pkgs="pkgs.txt"
else
	pkgs="$HOME/Github/arch_setup_scripts/pkgs.txt"
fi

[ ! -f "$pkgs" ] && echo "$pkgs doesn't exist in this directory." && exit 1

affirmative() {
	GREEN='\033[0;32m'
	RESET='\033[0m'

	echo -e "${GREEN}${@}${RESET}"
}

cleanup() {
	# shellcheck disable=SC2046
	sudo pacman -D --asdeps $(pacman -Qqe)
	# shellcheck disable=SC2046
	# $(pacman -Qqs xfce4) \
	# include Artix stuff because it doesn't matter even on Arch
	sudo pacman -D --asexplicit base base-devel $(pacman -Qqg base-devel) linux-lts linux-firmware grub $aurhelper networkmanager wpa_supplicant cronie \
		$(pacman -Qqs runit) archlinux-mirrorlist artix-archlinux-support elogind \
		$(pacman -Qqg texlive-most) $(awk '!/^(#|--).*/{print $1}' "$pkgs") #my pacakges
	if [ -n "$(pacman -Qtdq)" ]; then
		while [ ! "$ans" = "n" ]; do
			clear
			echo "Packages to Remove:"
			sudo pacman -Qtdq
			read -rp "Any more thing to not remove from these? [package name/n/q] " ans
			[ "$ans" = "q" ] && exit 0
			# shellcheck disable=SC2086
			[ ! "$ans" = "n" ] && sudo pacman -D --asexplicit $ans
		done
		sudo pacman -Qtdq | sudo pacman -Rns -
	fi

	affirmative "All clean."
}

install_missing() {
	echo "Refreshing Arch Keyring..."
	sudo pacman --noconfirm -Sy archlinux-keyring

	# Install an AUR helper if not installed already
	if ! which "$aurhelper" >/dev/null 2>&1 && ! pacman -Qq "$aurhelper" >/dev/null 2>&1; then
		sudo chown -R "$USER:wheel" "$(dirname "$repodir")"
		git clone --depth 1 --single-branch --no-tags "https://aur.archlinux.org/$aurhelper.git" "$repodir/$aurhelper" ||
			{
				cd "$repodir/$aurhelper" || return 1
				git pull --force origin master
			}
		cd "$repodir/$aurhelper" || exit 1
		makepkg --noconfirm -si || return 1
	fi

	# Install main repos packages
	# shellcheck disable=SC2046
	sudo pacman -Sy --needed --noconfirm $(awk '!/^\s*#.*/{print $1}' "$pkgs" | sed '/^--AUR--/Q')

	# Install AUR packages
	# shellcheck disable=SC2046
	$aurhelper -S --noconfirm --needed $(awk '!/^\s*#.*/{print $1}' "$pkgs" | sed '1,/^--AUR--/d')

	# affirmative "All installed."
}

main() {
	cleanup
	[ "$1" == "-c" ] && exit 0

	install_missing
}

run() {
	trap 'sudo rm -f /etc/sudoers.d/mhd-temp' HUP INT QUIT TERM PWR EXIT
	echo "%wheel ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/mhd-temp >/dev/null 2>&1
	# read -rp "Are you sure to continue the installation? [y/n] " ans
	# shellcheck disable=SC2068
	# [ "$ans" == "y" ] && $@
	$@
}

run main "$@"
