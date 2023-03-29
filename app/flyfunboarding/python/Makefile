
BASENAME := combined-shapefile
EXTENSIONS := shp shx dbf prj
DOWNLOAD_DIR := timezones
DOWNLOAD_URL := https://ro-z.net/public/timezones
DOWNLOAD_FILES := $(foreach ext,$(EXTENSIONS),$(DOWNLOAD_DIR)/$(BASENAME).$(ext))

all: airports.db $(DOWNLOAD_FILES)

$(DOWNLOAD_DIR):
	@mkdir -p $@

$(DOWNLOAD_FILES): | $(DOWNLOAD_DIR)
	@echo "Downloading $@..."
	curl -s -o $@ $(DOWNLOAD_URL)/$(notdir $@)

airports.db: 
	@echo "Creating $@..."
	@./airports.py

