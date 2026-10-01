.PHONY: manual clean-manual

manual:
	python3 -c "import reportlab" 2>/dev/null || python3 -m pip install reportlab
	python3 tools/build_manual.py
	@echo "Built: dist/MicroSky-Horizon-Complete-Project-Manual.pdf"

clean-manual:
	rm -f dist/MicroSky-Horizon-Complete-Project-Manual.pdf
