# Material Symbols Icons

This directory contains the Material Symbols Outlined icon fonts for local serving.

## Installation

The icons are automatically downloaded when you run the asset download script:

```bash
# From the www/notapollo directory
./scripts/smart-retry-assets.sh
# or
./scripts/download-assets.sh
```

## Expected Files

After running the download script, this directory should contain:

- `material-symbols-outlined.woff2` - Primary icon font file
- `material-symbols-outlined-*.woff2` - Additional variant files (if any)
- `icons.css` - Local icon definitions CSS file

## Manual Installation

If automatic download fails, you can manually download Material Symbols:

1. Visit [Google Fonts Icons](https://fonts.google.com/icons)
2. Download the Material Symbols Outlined font
3. Extract the .woff2 files to this directory
4. Run the download script to generate the CSS file

## Usage

Icons are used throughout the interface with the `material-symbols-outlined` class:

```html
<span class="material-symbols-outlined">home</span>
<span class="material-symbols-outlined">settings</span>
<span class="material-symbols-outlined">wifi</span>
```

## Available Icons

The interface uses these Material Symbols icons:
- `home` - Home/dashboard
- `wifi` - WiFi status
- `router` - Router status  
- `dns` - DNS status
- `settings` - Settings/configuration
- `refresh` - Refresh/reload
- `info` - Information
- `warning` - Warning states
- `error` - Error states
- `check_circle` - Success states
- `restart_alt` - Restart/reboot

## Fallbacks

If icon fonts are not available, the system will fall back to Unicode symbols or text labels.