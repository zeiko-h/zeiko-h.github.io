MD_DIR := src
OUTPUT_DIR := docs
MD_FILES := $(shell find $(MD_DIR) -type f -name "*.md")
#MD_FILES := $(wildcard $(MD_DIR)/*.md)
HTML_FILES := $(shell find $(OUTPUT_DIR) -type f -name "*.html")
#HTML_FILES := $(wildcard $(OUTPUT_DIR)/*.html)

markdown: $(MD_FILES)
	@for f in $^; do\
		BASENAME="$${f#*/}";\
		FILENAME=$${BASENAME%.md};\
		OUTPUTNAME=$(OUTPUT_DIR)/$${FILENAME}.html;\
		mkdir -p $${OUTPUTNAME%/*};\
		pandoc $$f -f markdown -t html -c /styles.css --highlight-style breezedark -s --template=templates/custom.html -o $${OUTPUTNAME};\
		echo pandoc $$f -f markdown -t html -s --template=templates/custom.html -o $${OUTPUTNAME};\
	done
	@cp templates/styles.css $(OUTPUT_DIR)/styles.css

echo: $(MD_FILES)
	echo $(MD_FILES)

clean: 
	@rm $(HTML_FILES)
	@rm $(OUTPUT_DIR)/styles.css
