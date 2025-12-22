/**
 * Vercel API Route: Proxy requests to the backend API
 * This file is optional - use only if deploying with a backend server
 * 
 * Usage: /api/posts?action=fetch or /api/posts (POST)
 * Forwards requests to: process.env.BACKEND_API_URL
 */

export default async function handler(req, res) {
  // Get the backend API URL from environment variables
  const backendUrl = process.env.BACKEND_API_URL || 'http://localhost:3000';
  
  // Extract the path after /api/
  const path = req.query.slug ? `/${req.query.slug.join('/')}` : '/';
  
  try {
    // Build the full URL to forward
    const targetUrl = new URL(path, backendUrl);
    
    // Copy query parameters
    Object.entries(req.query).forEach(([key, value]) => {
      if (key !== 'slug') {
        targetUrl.searchParams.append(key, value);
      }
    });
    
    // Forward the request to the backend
    const response = await fetch(targetUrl.toString(), {
      method: req.method,
      headers: {
        'Content-Type': 'application/json',
        ...req.headers, // Forward original headers
      },
      body: req.method !== 'GET' ? JSON.stringify(req.body) : undefined,
    });
    
    // Get response data
    const data = await response.json();
    
    // Return with same status code
    res.status(response.status).json(data);
  } catch (error) {
    console.error('Proxy error:', error);
    res.status(500).json({
      error: 'Failed to reach backend API',
      message: error.message,
    });
  }
}
