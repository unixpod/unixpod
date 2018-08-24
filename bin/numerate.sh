#!/bin/bash
# script de numeração de faces 
# por Marcelo Silva <marceloss@ufba.br>
# data: 23 de agosto de 2018
# dependecias: python, numpy, opencv, opencv-samples, hdf5 
if [[ $((which pacman)) ]]
    then
    OS=arch
elif [[ $((which apt-get)) ]]
    then
    OS=Debian
fi
depsa=(python-numpy hdf5 opencv opencv-samples)
depsd=(python3-opencv opencv-data libopencv-dev)

archdeps() {
    sudo pacman -Syu ${depsa[@]}
}
debdeps() {
    sudo apt-get install ${depsd[@]}
}

function numerar() {

}


