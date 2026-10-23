.PHONY: all build run clean
NAME = Lovetris

all: build

build:
	@rm -f $(NAME).love
	cd src && 7z a -tzip ../$(NAME).love ./* > /dev/null
	7z a -tzip $(NAME).love LICENSE > /dev/null
	7z l $(NAME).love
run: build
	love $(NAME).love
clean:
	@rm -f $(NAME).love
