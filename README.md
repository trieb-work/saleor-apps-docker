# Saleor Apps Docker Images

This repository automatically builds and publishes Docker images for [Saleor Apps](https://github.com/saleor/apps). Each app is containerized individually and published to the GitHub Container Registry.

## Available Images

Images are available for all apps in the Saleor Apps repository. Each app has its own image with both version-specific and latest tags.

Example apps:
- `app-avatax`
- `app-invoices`
- `app-slack`
- And more...

## Using the Docker Images

To pull an image, use:

```bash
# Pull a specific version
docker pull ghcr.io/trieb-work/app-avatax:1.12.3

# Pull the latest version
docker pull ghcr.io/trieb-work/app-avatax:latest
```

## Image Updates

Images are updated in three ways:

1. **Automatically on Release**: When a new release is published in the Saleor Apps repository
2. **Daily Updates**: Automated builds run daily at midnight UTC
3. **Manual Triggers**: Through GitHub Actions workflow dispatch

## Manual Building

You can manually trigger builds in the GitHub Actions interface:

1. Go to the "Actions" tab
2. Select the "Build and Push Docker Images" workflow
3. Click "Run workflow"
4. Choose one of the following options:
   - Build all apps with their current versions
   - Build a specific app by providing its name
   - Process recent releases (default behavior)

## Image Specifications

- Base Image: `node:18-alpine`
- Platforms: `linux/amd64`, `linux/arm64`
- Exposed Port: `3000`
- Non-root user: `nextjs`

## Environment Variables

The following environment variables are available:

- `PORT`: Default is 3000
- `HOSTNAME`: Default is "0.0.0.0"
- `NODE_ENV`: Set to "production"

## Contributing

Feel free to open issues or submit pull requests if you find any problems or have suggestions for improvements.

## License

This project is licensed under the same terms as Saleor Apps. See the [LICENSE](https://github.com/saleor/apps/blob/main/LICENSE) file for details.
