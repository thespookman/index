NAME=index
README=README.md
DESTDIR?=/usr
BIN=$(DESTDIR)/bin
MAN=$(DESTDIR)/share/man/man1
INSTALLED_NAME=$(BIN)/$(NAME)
INSTALLED_MAN=$(MAN)/$(NAME).1

.PHONY: all
all: $(README)

.PHONY: install
install: $(INSTALLED_NAME) $(INSTALLED_MAN)

.PHONY: uninstall
uninstall:
	rm -f $(INSTALLED_NAME) $(INSTALLED_MAN)

$(BIN):
	mkdir -p $@

$(MAN):
	mkdir -p $@

$(INSTALLED_NAME): $(NAME) | $(BIN)
	cp $< $@

$(INSTALLED_MAN): $(NAME).1 | $(MAN)
	cp $< $@

$(README): $(NAME).1
	pandoc $< -fman -tmarkdown \
	| sed -e 's/NAME/index/' \
	| awk ' \
	$$0=="# OPTIONS" { \
		synopsis=!synopsis; \
		print "      " catted; \
		print "```"; \
	} \
	synopsis && !length() {next} \
	synopsis { \
		out=0;gsub(/[*\\]/,""); \
		out=out+gsub(/^\|/,"      |"); \
		out=out+match($$0,/^\) \.{3}/); \
		} \
	synopsis && out {print catted; catted=""} \
	synopsis {catted=catted " " $$0} \
	! synopsis {print} \
	$$0=="# SYNOPSIS" {synopsis=!synopsis;print "```"}' \
	> $@

.PHONY: clean
clean:
	rm -f $(README)
