MD_DIR := src
OUTPUT_DIR := docs
#MD_FILES := $(wildcard $(MD_DIR)/*.md)
MD_FILES := $(shell find . -type f -name "*.md")
HTML_FILES := $(wildcard $(OUTPUT_DIR)/*.html)

markdown: $(MD_FILES)
	@for f in $^; do\
		BASENAME="$${f#*/}";\
		FILENAME=$${BASENAME%.md};\
		OUTPUTNAME=$(OUTPUT_DIR)/$${FILENAME}.html;\
		mkdir -p $${OUTPUTNAME%/*};\
		pandoc $$f -f markdown -t html -s --template=templates/custom.html -o $${OUTPUTNAME};\
		echo pandoc $$f -f markdown -t html -s --template=templates/custom.html -o $${OUTPUTNAME};\
	done

echo: $(MD_FILES)
	echo $(MD_FILES)

clean: 
	@rm $(HTML_FILES)
