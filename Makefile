NAME=index
README=README.md

.PHONY: all
all: $(README)

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
