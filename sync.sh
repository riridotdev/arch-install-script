#!/usr/bin/env bash

set -e

if [ $(id -u) != 0 ]; then
    echo "Must run as root" >&2
    exit 1
fi

services=(
    "systemd-networkd"
    "systemd-resolved"
    "systemd-timesyncd"
)

for service in ${services[@]}; do
    if ! systemctl is-enabled "${service}"; then
        systemctl enable "${service}"
    fi
    if ! systemctl is-active "${service}"; then
        systemctl start "${service}"
        while ! systemctl is-active "${serivce}"; do
            sleep 1
        done
    fi
done

network_file_dir=/etc/systemd/network/

wired_network_file_path="${network_file_dir}20-wired.network"
if [ ! -f $wired_network_file_path ]; then
    cat <<-EOF > "$wired_network_file_path"
	[Match]
	Name=enp5s0
	
	[Network]
	DHCP=yes
	EOF

    systemctl restart systemd-networkd
fi

wireless_network_file_path="${network_file_dir}30-wireless.network"
if [ ! -f $wireless_network_file_path ]; then
    cat <<-EOF > "$wireless_network_file_path"
	[Match]
	Name=wlan0
	
	[Network]
	DHCP=yes
	EOF

    systemctl restart systemd-networkd
fi

install_list=(
    # Language Compilers and Runtimes
    "clang"
    "gcc"
    "go"
    "lua"
    "nodejs"
    "python"
    "terraform"

    # Language Servers and Tools
    "gopls"
    "lua-language-server"
    "shellcheck"
    "shfmt"
    "typescript-language-server"

    # Debuggers and Analysis
    "delve"
    "gdb"
    "valgrind"

    # Build Tools
    "cmake"
    "make"
    "pkgconf"
    
    # Shell and Terminal
    "dash"
    "fish"
    "fisher"
    "kitty"
    "starship"

    # Editors
    "neovim"

    # CLI Tools
    "alsa-utils"
    "bat"
    "bc"
    "cifs-utils"
    "cloc"
    "coreutils"
    "dmidecode"
    "expect"
    "eza"
    "fd"
    "file"
    "freerdp"
    "fzf"
    "git"
    "git-delta"
    "gnupg"
    "htop"
    "httpie"
    "jq"
    "libva-utils"
    "lsof"
    "man-db"
    "man-pages"
    "perf"
    "postgresql"
    "pwgen"
    "ripgrep"
    "rsync"
    "sudo"
    "sysstat"
    "tree"
    "unzip"
    "which"
    "zip"
    "zoxide"

    # Virtualisation
    "docker"
    "libvirt"
    "qemu-base"
    "remmina"
    "virt-install"

    # Third Party
    "aws-cli"
    "discord"
    "firefox"
    "firefox-developer-edition"
    "github-cli"

    # Graphical
    "gammastep"
    "nautilus"
    "sway"
    "wev"
    "wl-clipboard"
    "zathura"
    "zathura-pdf-poppler"

    # Networking
    "bind"
    "iwd"
    "mtr"
    "nmap"
    "openbsd-netcat"
    "openssh"
    "openvpn"
    "traceroute"
    "whois"
    "wireshark-qt"

    # Fonts
    "ttf-hack-nerd"
)

for i in ${install_list[@]}; do
    if ! pacman -Q $i &>/dev/null; then
        pacman -S --noconfirm $i
    fi
done

if lcpci | grep "Radeon RX"; then
    pacman -S --noconfirm libva-mesa-driver
fi

if lscpu | grep "GenuineIntel"; then
    pacman -S --noconfirm intel-ucode
fi

if ! systemctl is-enabled libvirtd; then
    systemctl enable libvirtd
fi

if [ $(realpath /usr/bin/sh) != $(which dash) ]; then
    ln -snf $(which dash) /usr/bin/sh
fi

sudoers_line="%wheel ALL=(ALL:ALL) ALL"
sed -i "s/#\s*$sudoers_line/$sudoers_line/" /etc/sudoers
if ! grep -x $sudoers_line /etc/sudoers; then
    echo $sudoers_line >> /etc/sudoers
fi

if ! id ryan; then
    useradd -m -G wheel -s $(which bash) ryan
fi

groups=(
    "docker"
    "libvirt"
    "wireshark"
)
for group in ${groups[@]}; do
    if ! groups ryan | grep -w ${group}; then
        echo "Adding user 'ryan' to group '${group}'"
        usermod ryan -aG ${group}
    fi
done

su ryan <<'EOF'
default_dirs=(
    "~/dev/temp"
    "~/dev/riridotdev"

    "~/mount"
)

for dir in ${default_dirs[@]}; do
    if [ ! -d "${dir}" ]; then
        mkdir -p "${dir}"
    fi
done

github_dir=~/dev/riridotdev
github_url=https://github.com/riridotdev

if [ ! -d $github_dir ]; then
    mkdir -p $github_dir
fi

if [ ! -d $github_dir/dotfiles ]; then
    git clone $github_url/dotfiles.git $github_dir/dotfiles
fi

if [ ! -d $github_dir/sto ]; then
    git clone $github_url/sto.git $github_dir/sto

    if [ ! -d ~/.local/bin ]; then
        mkdir -p ~/.local/bin
    fi

    ln -sn $github_dir/sto/sto.sh ~/.local/bin/sto

    ~/.local/bin/sto apply $github_dir/dotfiles
fi

if ! fish -c "fisher list | grep -w jorgebucaran/autopair.fish"; then
    fish -c "fisher install jorgebucaran/autopair.fish"
fi
EOF
