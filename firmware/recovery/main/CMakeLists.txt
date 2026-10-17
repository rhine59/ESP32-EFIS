idf_component_register(SRCS "main.c" "diagnostics.c" INCLUDE_DIRS "." REQUIRES app_update esp_partition nvs_flash spi_flash)
