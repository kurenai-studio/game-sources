class_name PivoFace
# ---------- Лицо Пивозавра ----------
# Фото из концепта (по просьбе автора игры — «локальный мем»), уменьшено до
# пиксельной картинки 44×58 в оранжевой рамке, как на концепте. Хранится прямо
# в коде (PNG в base64), чтобы не зависеть от импорта картинок.

const PNG := (
	"iVBORw0KGgoAAAANSUhEUgAAACwAAAA6CAYAAADLC7uHAAAJ4klEQVR42tVaS47kthn+KJGiHlWq7nHXOIO0AyODAZKlr+B9LpBz" +
	"5BbOOXyMLHKBLB3AiDGJO2jHnldVqSRRpMQsKLJIPbp7AmQxBISSUCrp48fvf7IIAOg/32h8AoP86Q0hnwpYO6g9+eavNwAA0feX" +
	"b6XGQXQ4thLHSgAAyg0PHlCmDLsNB49jJDQCAKSMgrAIOWPBvSwil0cP2p5Aao1OKbRS4VR1OIhuBvSbP9QhYPsyfwj02CFxwI6t" +
	"dOfBkBoC/ew5suvBkji8ddD+BaTWkGQAAHTKfJaE4ailu23HEwATwPbmgGWpgwfMgI7fLQ0tB4BGDpQFziISgGaEoJPDZbIpBVIg" +
	"BYPo+2DlAsCi7x1A99JOBzMFMGP5qKVbhcvEFVJGIckAhhiMkEAODjQzE/JHQiN0agiluaRhSA3dhYB9sBboEvCD6LBDAgHDyGyw" +
	"aNWIpNbBZKfECfQBeAf4x8PZABmNKzopfN+H4n8VX5gctnT28h0SYBEvAePmt3I0KBYRSGGAtFLhJGRg5I96iWMl8I8P9YMu5fu+" +
	"w6s4MZ8nA/pYCec5dKchWB8a8ITdKfBOGbCHkai7N5W71+J5eZUDiELA/pdrwF9e5RgAvDrNvzu2EkiBHTg6NcC3T8YTcBquiBQd" +
	"pNZopcKhEoHrnL7fXG8mGgbw1e21M6Yl0JbJ4yiZFVE6WTB9YTfNc3fe1jUYTyBFh1PVfVTgiHywU2BTdn239n3frYOe6Neym+bF" +
	"eOTglELLwRm6ZffJgG+z3C1tmbJRN5dxe7MJHuwb4OKDFTHujCdI8xw3ZYENBbZFhpvSgCYr3mP6bv/aSeLz2y3I+8jpqdxwvPQY" +
	"9zXme4lywx3zNogkNMJANa6fbXF1s8dmfAvhmftMcyBnDKSIgGouvZeeLM2KyxAw0xH2mww8jlESGUQ253MXpBJkUwkBTymoIih2" +
	"HGmeY0MvQP2xLTK8+HyPt4czDp6n8UF/5ZExA2yTDwBISwbSksUkZG3sRneVIwbNYlxvC9yUhXF3olkEneYFPtsVY3SsA4/j28ti" +
	"LuE772nEu1IxPtDlUHmb5SCJCbtlzEGzGEXOA6+wBnpbZLjeFk5Gd2+rWXI1zVUc4Cw3DJ0gQcYgYJOeYROhxNxA/LSSKmLAMoY8" +
	"M8tbKTj9zozy2ZeGjHNjrscVsqDXEiv3uJwxsMyA6uIBghlGdzIJGCcJARjBljOkzEPDgIRSMB6DU4o0L54kpW2Roa1zADXSXz1D" +
	"yih+qZrHQzMAsCRGidTpuVMDEMOBt2ymjCLxIlenlAGbxM6N2WFZXtKwZTodWUZdY/9ZiSLneDvmNrYgAN5PvMSY8tlk2txkQK8B" +
	"vaSE1KWQNki09RlpXqxKYsqyG3UNvqXIM466EailXGfYWrmkETplctp0XOpgJQgJ0kJGCMCigN2pJLRoAl880/P5O/ebtq7BKTXA" +
	"lXKJUsgwTwDRQbIIbJTHPE8YS5oRLCPk0Xw38NMrsrAsn85z7XJKg8SJzlI/0aFnDKlfMIourMUWkvNoISP7f4xoOhPGkwDsrHD8" +
	"iDHVr5XFQ27uyYCt9vwlkKIz+pGDq72cDD4S7McMoRSEUg8D9kGLUehS9K6M8Y3Mr8dk1wNywOAZxlN9sD+Gd6+fBDwA3Na1p9t+" +
	"9eHd+JBOKXRK4Ty6nunDCc9mhvaQLHwP4ZdR/nNXzZvxeJHRplGIFIFqe/PZ9M6D+JP2gT7kHew4nRu09TlYYR/0zEu0de1mMr1J" +
	"ag3VXhjvxqyul0DM/jedDu9eLxpadZ6XZj6eyNeLNTI56EASS2Br9C5k+znEYhdoIoMlWZicon7UI9F5bNCLTY4ps2AAlzHATJC5" +
	"2d84Y/M9xBTcWgYXPfsS+Oe/THB6QJrLGvbaR92Ke+EydgzbZH1DL2C0aBzYSl0Oe7000jwPIumS8dMlnVh2O2UMzI5+0pARrUKe" +
	"xrNk3WfTGtK00tCimenYrpDNVZZ8fuRLQQ466Nf6YK0crJEdexHkyT6L9vDBtnXtPEhbnxdZ3n3x+2Blrbv0ZUrXpAAAA9WIFEEn" +
	"1Yxdlw2OfeEpuKUgYNPHywRy7L2w7AcPwiLTsp3gokudRKtbC9YOy27MgBIcB7QQrQoACqVQN8JEwIVQXo+GtClytHVtMrTzd7Ns" +
	"LUeMM4aZNKjfLZdkcLNaA5vYsogBQIpD0+L9u1PQ620ahaZWy7+zEoJpV/3np3twSscyKUxZE00fd2sALtFrZWQZhdQasVRAA7x7" +
	"2yLLqZOO1XdaMuP6ADQTG5Bagw0aEU/QdhLAJXA5VzYan+81Lgx77CqqQdXcQhNGkWU0uN5lhuXDuJrVSeDulyM2LwrcIodIlGsB" +
	"WE/TQbka8ocff8aWM+D5NQbRBX6X8RgYHcGqH27l3HxpZpojNI1noTrLDWgfrFv2k2Fad3qcVBu4x9f/fo/TTw1IQzBUrdtWYDxx" +
	"fWTTDI/nDGs5OLCdMhsqOWEYqJ7Vcn6otsu8gwF9i3LU1QX0ZntpQx2aFqSIIGQP3Wn8+vkO22d8JQFLHtewv5tkwaqmB83ixZzY" +
	"SqODwg4p0pJBtGrWPQr6b+M+yC5LsX3Gg/pxCeSjRmdLet8AI0XQIQwmS6BzxEAKCKyDtu/IGHVewd8HeVKJNAVre7c1enOMO0o0" +
	"jd0xTYx6OQ/ftu82zUPssx6quOtGzFKG1bu1HHBsOoh2vcs+BQ14XaKUzsDaa3uPA+EZmTP+MRzXrXLnDwJupXJgRd87bUsyuNJo" +
	"OmJmItR0c3LpnKqnFbO2E/UoYN/47EZfKxWaunPexPcWfiTjMnaGV50EqpNY1LwzbtE5FttBX9iV8nENp4w6QJaRg+jw86EOJ7Ei" +
	"iSU2g856zGerYFut/tJX1TmY0LymmwQMKwfbhb97U+HuTYVyw3Gb5ejKAQlVbmltfWeNzkZA3wfvshQxM+zS1OxBR17jph00BtHh" +
	"/u0JPx9q7DYcz6+Lh92aa7Mu7NFV92f87UONKj5j2FKUG44rFV9ArVTwNhLaiTVSAbUy4BuFE9XuvxI/Hs6o7s/YvCiw23CTLrBH" +
	"/PAY1kDG/WPdaZQZw90L4NU93F50dVKoAGxogSu1Lo8lDW+23E3Qfm/D+uZFgS92hckxPMlMNmWGB3eHAKDUDHhRoLoPy57q/owK" +
	"wO2+/KhSfzqR232JzZaj9EL1dC8v+L/E8l8HiPMUO56gJAzV/nKfn+z457f7Eh9oj2Ml8Jt0XvP9/YdfApCWlP11HlYbD4Xm6f99" +
	"nJuKY7d/LKCw2XLHjgU2Zd2CjwDcnY6LL//db/eBvnlpdqBMhJUPh+bDE/d6lyLYlYo/Sg63+xK3+zIAGzM4sIHWN0Xg4shf/ph/" +
	"Un8Di77+tiafCtivv63JfwEKVbrD9LardAAAAABJRU5ErkJggg=="
)

static var _tex: ImageTexture

static func image() -> Image:
	var im := Image.new()
	im.load_png_from_buffer(Marshalls.base64_to_raw(PNG))
	return im

static func texture() -> ImageTexture:
	if _tex == null:
		_tex = ImageTexture.create_from_image(image())
	return _tex
