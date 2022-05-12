NAME=kizapr-u102

all: clean $(NAME).bin diff

diff:
	echo "e49c20b237a78b54c2cb26b133d5903bb60bd8ef" > original.sha1
	openssl sha1 $(NAME).bin | cut -d ' ' -f 2 > $(NAME).sha1
	diff original.sha1 $(NAME).sha1

$(NAME).bin: $(NAME).o
	ld65 -C $(NAME).ld -o $(NAME).bin $(NAME).o

$(NAME).o: $(NAME).asm
	ca65 -l $(NAME).lst $(NAME).asm

clean:
	rm -f $(NAME).bin $(NAME).lst $(NAME).o original.sha1
