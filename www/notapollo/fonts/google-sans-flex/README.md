# Google Sans Flex Fonts

This directory contains the Google Sans Flex font files for local serving.

## Installation

The fonts are automatically downloaded when you run the asset download script:

```bash
# From the www/notapollo directory
./scripts/smart-retry-assets.sh
# or
./scripts/download-assets.sh
```

## Expected Files

After running the download script, this directory should contain:

- `GoogleSansFlex-*.woff2` - Individual font weight files
- `fonts.css` - Local font definitions CSS file

## Manual Installation

If automatic download fails, you can manually download Google Sans Flex fonts:

1. Visit [Google Fonts](https://fonts.google.com/specimen/Google+Sans)
2. Download the font family
3. Extract the .woff2 files to this directory
4. Run the download script to generate the CSS file

## Usage

The fonts are referenced in the main CSS files and will be loaded automatically when the page loads.

## Fallbacks

If fonts are not available, the system will fall back to:
- system-ui
- -apple-system  
- BlinkMacSystemFont
- Segoe UI
- Roboto
- sans-serif