VIVADO        := /home/nano/opt/2023.2/Vivado/2023.2/bin/vivado
VIVADO_SCRIPT := scripts/create-vivado-project.tcl
BUILD_DIR     := build

.PHONY: all vivado clean help

all: help

help:
	@echo "Available make targets:"
	@echo "  make vivado   - create Vivado project for Arty Z7-10 board"
	@echo "  make clean    - delete build folder"

vivado:
	mkdir -p $(BUILD_DIR)
	$(VIVADO) -source $(VIVADO_SCRIPT) -log ${BUILD_DIR}/vivado.log -journal ${BUILD_DIR}/vivado.jou -tempDir ${BUILD_DIR}

clean:
	rm -rf ${BUILD_DIR}
