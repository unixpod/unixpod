#!/bin/bash
# Script para instalacao de programas padrao no desktops do Onda Digital
# Onda Digital 28 08 2018 (marcelo, arthur, ricardo)
programas=(inkscape gimp firefox-esr libreoffice sublime-text geany audacity bluefish gcc scribus brasero scratch codeblocks openshot texlive-full texmaker)
for i in ${programas[*]}
do
	apt-get -y  install ${i};
done
#Brackets
function brackets{
	apt update
	apt install libpango1.0-0 libpangox-1.0-0 libcurl3
	wget github.com/adobe/brackets/releases/download/release-1.13/Brackets.Release.1.13.64-bit.deb && dpkg -i Brackets.Release.1.13.64-bit.deb
}
brackets
