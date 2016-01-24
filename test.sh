#!/bin/sh
try() {
	luaenv local $1
	cd cc
	git checkout $2
	cd ..
	echo lua = $1
	echo cc = $2
	lua -v
	unset key
	read -rsp $'Press any key to continue...\n' -n1 key
	lua cli.lua .
}
for lv in luajit-2.0.4 luajit-2.1.0-beta1; do
	for cv in master 1.77 1.74 1.74pr17 1.74pr16 1.74pr14 1.74pr13 1.73 1.64 1.6 1.58 1.5 1.41; do
		try $lv $cv
	done
done
for lv in 5.2.1 5.2.3 5.3.2; do
	for cv in master 1.77 1.74; do
		try $lv $cv
	done
done
