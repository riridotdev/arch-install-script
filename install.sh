#!/usr/bin/env bash

set -e

if [ $(id -u) != 0 ]; then
    echo "Must run as root" >&2
    exit 1
fi

if ! systemctl is-enabled systemd-networkd; then
    systemctl enable systemd-networkd
fi
if ! systemctl is-active systemd-networkd; then
    systemctl start systemd-networkd
    while ! systemctl is-active systemd-networkd; do
        sleep 1
    done
fi

network_file=20-wired.network
network_file_path=/etc/systemd/network/$network_file 

if [ ! -f $network_file_path ]; then
    cat <<-EOF > $network_file_path
	[Match]
	Name=ens3
	
	[Network]
	DHCP=yes
	EOF

    systemctl restart systemd-networkd
fi

resolv_conf=/etc/resolv.conf

if ! grep "nameserver 8.8.8.8" $resolv_conf; then
    echo "nameserver 8.8.8.8" >> $resolv_conf
fi

install_list=(
    # Language Compilers and Runtimes
    "clang"
    "gcc"
    "go"
    "lua"
    "nodejs"
    "python"

    # Language Servers and Tools
    "gopls"
    "lua-language-server"
    "shellcheck"
    "typescript-language-server"

    # Debuggers and Analysis
    "delve"
    "gdb"
    "valgrind"

    # Build Tools
    "make"
    "pkgconf"
    
    # Shell and Terminal
    "dash"
    "fish"
    "kitty"
    "starship"

    # Editors
    "neovim"

    # CLI Tools
    "bat"
    "bc"
    "cifs-utils"
    "cloc"
    "coreutils"
    "expect"
    "eza"
    "fd"
    "file"
    "fzf"
    "git"
    "git-delta"
    "gnupg"
    "htop"
    "httpie"
    "jq"
    "lsof"
    "postgresql"
    "pwgen"
    "ripgrep"
    "sudo"
    "tree"
    "unzip"
    "which"
    "zoxide"

    # Virtualisation
    "docker"
    "libvirt"
    "qemu-base"
    "remmina"

    # Third Party
    "aws-cli"
    "discord"
    "firefox"
    "github-cli"
    #"steam"

    # Graphical
    "gammastep"
    "nautilus"
    "sway"
    "wev"
    "wl-clipboard"
    "zathura"

    # Networking
    "bind"
    "dnsmasq"
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

su ryan <<'EOF'
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
EOF
