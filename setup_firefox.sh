#!/usr/bin/env bash

main() {
	read -rp "Enter your username: " name
	bin_dir="/home/$name/bin"
	overrides_conf="/home/$name/.config/firefox/overrides.js"
    addonlist="$(awk '!/^#.*/{print $1}' "./firefox_addons.txt")"

	pacman -S --needed curl

	browserdir="/home/$name/.mozilla/firefox"
	profilesini="$browserdir/profiles.ini"

	# Start firefox headless so it generates a profile. Then get that profile in a variable.
	sudo -u "$name" firefox --headless >/dev/null 2>&1 &
	sleep 1

	profile="$(sed -n "/Default=.*.default-release/ s/.*=//p" "$profilesini")"
	pdir="$browserdir/$profile"

	if [ -d "$pdir" ]; then
		# Get the Arkenfox user.js and prepare it.
		arkenfox="$pdir/arkenfox.js"
		overrides="$pdir/user-overrides.js"
		userjs="$pdir/user.js"
		ln -fs "$overrides_conf" "$overrides"
		[ ! -f "$arkenfox" ] && curl -L "https://raw.githubusercontent.com/arkenfox/user.js/master/user.js" >"$arkenfox"
		cat "$arkenfox" "$overrides" >"$userjs"
        # change ownership to the user, otherwise arkenfox-auto-update can't run
        # -h for the symbolic link's ownership to be changed, not the target
		chown -h "$name:$name" "$arkenfox" "$userjs" "$overrides"
		# Install the updating script.
		mkdir -p /usr/local/lib /etc/pacman.d/hooks
		cp "$bin_dir/arkenfox-auto-update" /usr/local/lib/
		chown root:root /usr/local/lib/arkenfox-auto-update
		chmod 755 /usr/local/lib/arkenfox-auto-update

		# Trigger the update when needed via a pacman hook.
		echo "[Trigger]
        Operation = Upgrade
        Type = Package
        Target = firefox
        Target = librewolf
        Target = librewolf-bin
        [Action]
        Description=Update Arkenfox user.js
        When=PostTransaction
        Depends=arkenfox-user.js
        Exec=/usr/local/lib/arkenfox-auto-update" >/etc/pacman.d/hooks/arkenfox.hook
		# Install extensions
		# IFS=' '
		sudo -u "$name" mkdir -p "$pdir/extensions/"
		for addon in $addonlist; do
			addonurl="$(curl "https://addons.mozilla.org/en-US/firefox/addon/${addon}/" | grep -o 'https://addons.mozilla.org/firefox/downloads/file/[^"]*')"
			file="${addonurl##*/}"
			addontmp="$(mktemp -d)"
			curl -LO "$addonurl" >"$addontmp/$file"
			id="$(unzip -p "$file" manifest.json | grep "\"id\"")"
			id="${id%\"*}"
			id="${id##*\"}"
            dst="$pdir/extensions/$id.xpi"
			mv "$file" "$dst"
            chown "$name:$name" "$dst"
		done
	fi

	# Kill the now unnecessary firefox instance.
	# pkill firefox
}

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
	echo "Running as root..."
	sudo -E bash -c "$(declare -f main); main"
	exit $?
fi

# Call the main function without sudo if already running as root
main
