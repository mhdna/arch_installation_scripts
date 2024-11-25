#!/bin/sh

# After installing the requiered packages
sudo ln -s /etc/runit/sv/libvirtd /run/runit/service > /dev/null 2>&1
sudo sv start libvirtd
sudo usermod -aG libvirt "$USER"
sudo sv restart libvirtd
