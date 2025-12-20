# SUITER Frontend - Lightweight HTML/CSS/JS Version

This is a lightweight, memory-efficient HTML/CSS/JavaScript frontend for SUITER that replaces the Next.js version.

## Features

- **No Node.js required** - Pure static HTML/CSS/JavaScript
- **Minimal memory footprint** - ~5MB vs Next.js's 100MB+
- **Fast load times** - Instant page loads
- **Full functionality** - All features of the original frontend
- **Responsive design** - Works on mobile and desktop
- **Dark theme** - Matches the original design

## Files

- `index.html` - Main HTML structure
- `styles.css` - All styling (Tailwind-free alternative)
- `app.js` - Client-side JavaScript for interactivity
- `server.sh` - Simple Python HTTP server

## How to Run

### Option 1: Using the provided script
```bash
cd frontend
chmod +x server.sh
./server.sh 8080
```

### Option 2: Using Python directly
```bash
cd frontend
python3 -m http.server 8080
```

### Option 3: Using Node.js http-server (if installed)
```bash
cd frontend
npx http-server -p 8080
```

### Option 4: Using any other static server
Any HTTP server can serve the files. Point it to the `frontend` directory.

Then visit: `http://localhost:8080`

### Live demo on GitHub Pages ✅
We also deploy the static frontend to GitHub Pages using embedded mock data. Visit:

  https://Mozzicstar.github.io/SUITER

This site uses the files in `frontend/` and the bundled `frontend/mock/*.json` data so it works without a running API server.

## Configuration

The frontend expects the API server to be available at:
- Development: `http://localhost:3000`
- Production: Uses the same origin

To change the API URL, edit `app.js` and modify the `API_URL` constant.

## API Endpoints Required

The frontend communicates with the following endpoints:

- `GET /api/posts` - Fetch all posts
- `POST /api/posts` - Create a new post
- `GET /api/rankings` - Fetch rankings

## Memory Usage

- **HTML/CSS/JS**: ~500KB
- **Browser footprint**: ~20-30MB
- **Compared to Next.js**: ~15x less memory

## Features

- 📰 **Feed Tab** - Browse all posts
- 🏆 **Rankings Tab** - View top-ranked users
- ✨ **Create Posts** - Submit new posts with author name
- 📊 **Network Stats** - Real-time statistics
- 🔥 **Top Trending** - See top 5 posts by attention
- 🔄 **Auto-refresh** - Updates every 5 seconds
- 📱 **Responsive** - Works on all screen sizes
- 🌙 **Dark Theme** - Easy on the eyes

## Development

To modify the frontend:

1. Edit `index.html` for structure
2. Edit `styles.css` for styling
3. Edit `app.js` for functionality

No build process required. Changes are instant.

## Browser Compatibility

- Chrome/Chromium 90+
- Firefox 88+
- Safari 14+
- Edge 90+

## Performance

- Initial load: < 100ms
- Network requests: Only to API endpoints
- No runtime overhead from frameworks
- Instant tab switching
- Smooth animations with CSS

## Notes

- This version removes all Next.js, React, and Tailwind dependencies
- No build step required
- No development server overhead
- Pure vanilla JavaScript with no external dependencies (except for HTTP calls)
- Fully compatible with the original API

## Troubleshooting

**API calls failing?**
- Make sure the API server is running on port 3000 (or update API_URL in app.js)
- Check browser console (F12) for errors
- Ensure CORS is enabled on the API server

**Port already in use?**
- Run on a different port: `./server.sh 8081`

**Page not loading styles?**
- Clear browser cache (Ctrl+Shift+Delete)
- Make sure `styles.css` and `app.js` are in the same directory as `index.html`
