all: makerworld.scad

makerworld.scad: makerworld.in.scad geneva-drive.scad
	sed -e '/include <geneva-drive.scad>/{r geneva-drive.scad' -e 'd}' makerworld.in.scad > makerworld.scad
	sed -i -e '/Test Code: not included in makerworld.scad/,$$d' makerworld.scad
