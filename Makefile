NAME=index
README=README.md

.PHONY: all
all: $(README)

$(README): $(NAME).1
	pandoc $< -tman -tmarkdown \
	> $@
