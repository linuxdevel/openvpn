# How to Enable GitHub Pages

To publish this documentation site, follow these steps:

## 1. Enable GitHub Pages

1. Go to your repository settings: `https://github.com/linuxdevel/openvpn/settings`
2. Scroll down to the "Pages" section in the left sidebar
3. Under "Source", select "GitHub Actions"
4. The site will automatically deploy when you push changes to the main branch

## 2. Access Your Site

Once enabled, your documentation will be available at:
**https://linuxdevel.github.io/openvpn/**

## 3. Automatic Deployment

The GitHub Actions workflow (`.github/workflows/jekyll-gh-pages.yml`) will:
- Automatically build the Jekyll site
- Deploy it to GitHub Pages
- Run on every push to the main branch

## 4. Custom Domain (Optional)

If you want to use a custom domain:
1. Add a CNAME file to the `docs/` directory with your domain
2. Configure your DNS provider to point to GitHub Pages
3. Update the `url` and `baseurl` in `docs/_config.yml`

That's it! Your professional OpenVPN documentation site will be live.