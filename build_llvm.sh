#!/usr/bin/env bash

sudo pip3 install cmake

cd
git clone http://llvm.org/git/llvm.git
cd llvm/tools
git clone --depth 1 http://llvm.org/git/clang.git
cd ..; mkdir build; cd build
cmake .. -DLLVM_TARGETS_TO_BUILD="BPF;X86"
make -j $(getconf _NPROCESSORS_ONLN)
