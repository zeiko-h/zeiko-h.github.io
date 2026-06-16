MD_DIR := src
OUTPUT_DIR := docs
MD_FILES := $(wildcard $(MD_DIR)/*.md)
HTML_FILES := $(wildcard $(OUTPUT_DIR)/*.html)

markdown: $(MD_FILES)
	@for f in $^; do\
		BASENAME="$${f##*/}";\
		FILENAME=$${BASENAME%.md};\
		OUTPUTNAME=$(OUTPUT_DIR)/$${FILENAME}.html;\
		pandoc $$f -f markdown -t html -s -o $${OUTPUTNAME};\
	done

clean: 
	@rm $(HTML_FILES)
