import axios from 'axios';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

export const fetchPosts = async () => {
  try {
    const response = await api.get('/api/posts');
    return response.data;
  } catch (error) {
    console.error('Error fetching posts:', error);
    return [];
  }
};

export const fetchPost = async (id) => {
  try {
    const response = await api.get(`/api/posts/${id}`);
    return response.data;
  } catch (error) {
    console.error('Error fetching post:', error);
    return null;
  }
};

export const fetchProfiles = async () => {
  try {
    const response = await api.get('/api/profiles');
    return response.data;
  } catch (error) {
    console.error('Error fetching profiles:', error);
    return [];
  }
};

export const fetchFeed = async () => {
  try {
    const response = await api.get('/api/posts/feed');
    return response.data;
  } catch (error) {
    console.error('Error fetching feed:', error);
    return [];
  }
};

export const fetchRankings = async () => {
  try {
    const response = await api.get('/api/rankings');
    return response.data;
  } catch (error) {
    console.error('Error fetching rankings:', error);
    return [];
  }
};

export default api;
