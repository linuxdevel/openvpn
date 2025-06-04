# GitHub Pages Documentation

This directory contains the Jekyll-based documentation site for the OpenVPN Bridge Mode project.

## Structure

- `index.md` - Main landing page
- `installation.md` - Complete installation guide
- `configuration.md` - Bridge mode configuration steps
- `troubleshooting.md` - Troubleshooting reference
- `_layouts/default.html` - Custom layout with navigation
- `assets/css/style.scss` - Custom styling
- `_config.yml` - Jekyll configuration

## Local Development

To run the site locally:

```bash
cd docs
bundle install
bundle exec jekyll serve
```

The site will be available at `http://localhost:4000/openvpn/`

## Deployment

The site is automatically deployed to GitHub Pages via GitHub Actions when changes are pushed to the main branch.

## Live Site

Once enabled, the documentation will be available at:
https://linuxdevel.github.io/openvpn/