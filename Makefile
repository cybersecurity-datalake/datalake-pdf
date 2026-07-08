MAIN_TEX := src/main.tex
OUTPUT_DIR := output
OUTPUT_PDF := $(OUTPUT_DIR)/main.pdf
LATEXMK := latexmk
LATEXMK_FLAGS := -pdf -interaction=nonstopmode -file-line-error -halt-on-error

.PHONY: pdf lint clean watch

pdf: $(OUTPUT_PDF)

$(OUTPUT_PDF): $(MAIN_TEX)
	mkdir -p $(OUTPUT_DIR)
	$(LATEXMK) $(LATEXMK_FLAGS) $(MAIN_TEX)

lint:
	@status=0; \
	chktex -q -n1 -n8 $(MAIN_TEX) || status=$$?; \
	test $$status -eq 0 -o $$status -eq 2

clean:
	rm -rf $(OUTPUT_DIR)
	mkdir -p $(OUTPUT_DIR)
	printf '\n' > $(OUTPUT_DIR)/.gitkeep
	rm -rf src/output
	rm -f src/indent.log
	rm -f src/main.aux src/main.bbl src/main.blg src/main.fdb_latexmk src/main.fls src/main.log src/main.pdf
	rm -f main.aux main.bbl main.blg main.fdb_latexmk main.fls main.log main.pdf

watch:
	mkdir -p $(OUTPUT_DIR)
	$(LATEXMK) $(LATEXMK_FLAGS) -pvc -view=none $(MAIN_TEX)
