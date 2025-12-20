// Configuration
// Try same-origin first (will hit the frontend proxy), then local addresses
const API_CANDIDATES = [
    'same-origin',
    'http://127.0.0.1:3000',
    'http://localhost:3000'
];

function buildUrl(path, base) {
    try { return new URL(path, base).toString(); } catch { return base.replace(/\/$/, '') + '/' + path.replace(/^\//, ''); }
}

async function fetchWithFallback(path, options) {
    let lastErr = null;

    // 1) Try same-origin relative path first (will hit frontend proxy)
    try {
        const msg = `📡 Trying same-origin ${path}`;
        console.log(msg);
        logDebug(msg, 'info');
        const resp = await fetch(path, options);
        if (resp.ok) {
            logDebug(`✓ Success same-origin ${path}`, 'success');
            return resp;
        }
        const warn = `⚠️ same-origin returned HTTP ${resp.status}`;
        console.warn(warn);
        logDebug(warn, 'warn');
        lastErr = new Error(warn);
    } catch (err) {
        const warn = `⚠️ same-origin failed: ${err.message || err}`;
        console.warn(warn);
        logDebug(warn, 'warn');
        lastErr = err;
    }

    // 2) Try explicit host candidates
    for (const base of API_CANDIDATES) {
        if (base === 'same-origin') continue;
        const url = buildUrl(path, base);
        try {
            const msg = `📡 Trying ${url}`;
            console.log(msg);
            logDebug(msg, 'info');
            const resp = await fetch(url, options);
            if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
            logDebug(`✓ Success ${url}`, 'success');
            return resp;
        } catch (err) {
            const warn = `⚠️ Request to ${base} failed: ${err.message || err}`;
            console.warn(warn);
            logDebug(warn, 'warn');
            lastErr = err;
            // try next
        }
    }
    const finalErr = lastErr || new Error('All fetch attempts failed');
    const errMsg = `❌ All fetch attempts failed: ${finalErr.message || finalErr}`;
    console.error(errMsg);
    logDebug(errMsg, 'error');
    throw finalErr;
}

// State
let posts = [];
let rankings = [];
let isLoading = false;
let refreshInterval = null;

// DOM Elements
const postsContainer = document.getElementById('posts-container');
const rankingsContainer = document.getElementById('rankings-container');
const totalPostsEl = document.getElementById('total-posts');
const rankedCountEl = document.getElementById('ranked-count');
const authorInput = document.getElementById('author-input');
const contentInput = document.getElementById('content-input');
const submitBtn = document.getElementById('submit-btn');
const toastEl = document.getElementById('toast');
const tabButtons = document.querySelectorAll('.tab-button');
const tabContents = document.querySelectorAll('.tab-content');
const topPostsSidebar = document.getElementById('top-posts-sidebar');

// Debug helper
function logDebug(message, level='info') {
    try {
        const panel = document.getElementById('debug-panel');
        if (!panel) return;
        const line = document.createElement('div');
        line.className = `debug-line debug-${level}`;
        const time = new Date().toISOString().slice(11,19);
        line.textContent = `[${time}] ${message}`;
        panel.insertBefore(line, panel.firstChild);
        // keep panel manageable
        while (panel.childNodes.length > 200) panel.removeChild(panel.lastChild);
    } catch (e) {
        // ignore
    }
}

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    console.log('🚀 SUITER Frontend Initializing...');
    logDebug('🚀 SUITER Frontend Initializing...', 'info');
    console.log('📡 API CANDIDATES:', API_CANDIDATES);
    logDebug('📡 API CANDIDATES: ' + JSON.stringify(API_CANDIDATES), 'info');
    setupEventListeners();
    loadData();
    // Auto-refresh every 5 seconds
    refreshInterval = setInterval(loadData, 5000);
});

// Setup Event Listeners
function setupEventListeners() {
    submitBtn.addEventListener('click', handleSubmitPost);
    contentInput.addEventListener('keydown', (e) => {
        if (e.key === 'Enter' && e.ctrlKey) {
            handleSubmitPost();
        }
    });

    tabButtons.forEach(button => {
        button.addEventListener('click', () => {
            const tabName = button.getAttribute('data-tab');
            switchTab(tabName);
        });
    });
}

// API Functions
async function fetchPosts() {
    try {
        const resp = await fetchWithFallback('/api/posts');
        const data = await resp.json();
        console.log('✓ Posts fetched:', Array.isArray(data) ? data.length : typeof data);
        return data;
    } catch (error) {
        console.error('❌ Error fetching posts:', error);
        // Fallback to local mock file (useful when hosted on GitHub Pages)
        try {
            const mockResp = await fetch('/mock/posts.json');
            if (mockResp.ok) {
                const mockData = await mockResp.json();
                console.log('✓ Loaded posts from local mock');
                return mockData;
            }
        } catch (e) {
            // ignore
        }
        return [];
    }
}

async function fetchRankings() {
    try {
        const resp = await fetchWithFallback('/api/rankings');
        const data = await resp.json();
        console.log('✓ Rankings fetched:', Array.isArray(data) ? data.length : typeof data);
        return data;
    } catch (error) {
        console.error('❌ Error fetching rankings:', error);
        // Fallback to local mock file (useful when hosted on GitHub Pages)
        try {
            const mockResp = await fetch('/mock/rankings.json');
            if (mockResp.ok) {
                const mockData = await mockResp.json();
                console.log('✓ Loaded rankings from local mock');
                return mockData;
            }
        } catch (e) {
            // ignore
        }
        return [];
    }
}

async function createPost(author, content) {
    try {
        const options = {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ author, content })
        };
        const resp = await fetchWithFallback('/api/posts', options);
        if (!resp.ok) throw new Error(`HTTP ${resp.status}: Failed to create post`);
        return await resp.json();
    } catch (error) {
        console.error('Error creating post:', error);
        throw error;
    }
}

// Load Data
async function loadData() {
    if (isLoading) return;
    isLoading = true;

    try {
        console.log('📥 Loading data from API...');
        const [postsData, rankingsData] = await Promise.all([
            fetchPosts(),
            fetchRankings(),
        ]);

        posts = Array.isArray(postsData) ? postsData : [];
        rankings = Array.isArray(rankingsData) ? rankingsData : [];

        console.log(`✓ Loaded ${posts.length} posts and ${rankings.length} rankings`);
        updateUI();
    } catch (error) {
        console.error('❌ Error loading data:', error);
    } finally {
        isLoading = false;
    }
}

// Update UI
function updateUI() {
    // Update stats
    totalPostsEl.textContent = posts.length;
    rankedCountEl.textContent = rankings.length;

    // Update posts
    renderPosts();

    // Update rankings
    renderRankings();

    // Update top posts sidebar
    renderTopPostsSidebar();
}

// Render Posts
function renderPosts() {
    if (posts.length === 0) {
        postsContainer.innerHTML = '<div class="loading">No posts yet. Be the first to share!</div>';
        return;
    }

    postsContainer.innerHTML = posts.map(post => `
        <article class="post-card" id="post-${post.id}" data-post-id="${post.id}">
            <div class="post-header">
                <div class="post-avatar">${getInitial(post.author)}</div>
                <div class="post-meta">
                    <div class="post-author" title="${escapeHtml(post.author || 'anonymous')}">${escapeHtml(post.author || 'anonymous')}</div>
                    <div class="post-date">${formatDate(post.created_at)}</div>
                </div>
            </div>
            <p class="post-content">${escapeHtml(post.content || '')}</p>
            <div class="post-engagement">
                <span>❤️ ${post.likes || 0}</span>
                <span>💬 ${post.comments || 0}</span>
                <span>🔁 ${post.reposts || 0}</span>
                <span>👁️ ${post.attention_accumulated || 0}</span>
            </div>
            <div class="post-footer">
                <span class="post-badge post-badge-level">⭐ Level ${post.level || 1}</span>
            </div>
        </article>
    `).join('');
}

// Render Rankings
function renderRankings() {
    if (rankings.length === 0) {
        rankingsContainer.innerHTML = '<div class="loading">No rankings yet.</div>';
        return;
    }

    const medals = ['🥇', '🥈', '🥉'];
    rankingsContainer.innerHTML = rankings.map((rank, index) => `
        <div class="ranking-item">
            <div class="ranking-medal">${medals[index] || '⭐'}</div>
            <div class="ranking-info">
                <div class="ranking-name">${escapeHtml(rank.profile_name || rank.author || 'Anonymous')}</div>
                <div class="ranking-score">Score: ${rank.score || rank.attention || 0}</div>
            </div>
            <div style="text-align: right;">
                <div style="color: #60a5fa; font-weight: bold;">#${index + 1}</div>
            </div>
        </div>
    `).join('');
}

// Render Top Posts Sidebar
function renderTopPostsSidebar() {
    const topPosts = [...posts]
        .sort((a, b) => (b.attention_accumulated || 0) - (a.attention_accumulated || 0))
        .slice(0, 5);

    if (topPosts.length === 0) {
        topPostsSidebar.innerHTML = '<div class="loading" style="font-size: 0.875rem; padding: 1rem 0;">No posts yet</div>';
        return;
    }

    topPostsSidebar.innerHTML = topPosts.map(post => `
        <div class="top-post-item" data-post-id="${post.id}" title="${escapeHtml(post.content || '')}">
            <div class="tp-author" style="font-weight:600; color:#fff;">${escapeHtml(post.author || 'anonymous')}</div>
            <div class="tp-snippet" style="font-size:0.85rem; color:#cbd5e1; margin-top:0.25rem;">${escapeHtml((post.content || '').slice(0, 80))}${(post.content || '').length > 80 ? '…' : ''}</div>
        </div>
    `).join('');

    // Attach click handlers to jump to post in feed
    topPostsSidebar.querySelectorAll('.top-post-item').forEach(el => {
        el.addEventListener('click', () => {
            const pid = el.getAttribute('data-post-id');
            const target = document.getElementById('post-' + pid);
            if (target) {
                target.scrollIntoView({ behavior: 'smooth', block: 'center' });
                target.classList.add('highlight');
                setTimeout(() => target.classList.remove('highlight'), 2000);
            } else {
                showToast('Post not found in feed. It may have been removed.', 'info');
            }
        });
    });
}

// Handle Submit Post
async function handleSubmitPost() {
    const author = authorInput.value.trim() || 'anonymous';
    const content = contentInput.value.trim();

    if (!content) {
        showToast('Please enter some content', 'error');
        return;
    }

    submitBtn.disabled = true;
    submitBtn.textContent = 'Posting...';

    try {
        await createPost(author, content);
        showToast('Post created successfully!', 'success');
        contentInput.value = '';
        await loadData();
    } catch (error) {
        showToast('Failed to create post. Please try again.', 'error');
    } finally {
        submitBtn.disabled = false;
        submitBtn.textContent = 'Post';
    }
}

// Switch Tab
function switchTab(tabName) {
    // Update buttons
    tabButtons.forEach(btn => {
        btn.classList.toggle('active', btn.getAttribute('data-tab') === tabName);
    });

    // Update content
    tabContents.forEach(content => {
        content.classList.toggle('active', content.id === `${tabName}-tab`);
    });
}

// Show Toast
function showToast(message, type = 'info') {
    toastEl.textContent = message;
    toastEl.className = `toast show ${type}`;

    setTimeout(() => {
        toastEl.classList.remove('show');
    }, 3000);
}

// Utility Functions
function getInitial(author) {
    return (author && author[0]) ? author[0].toUpperCase() : 'U';
}

function formatDate(dateString) {
    if (!dateString) return 'now';
    try {
        const date = new Date(dateString);
        const now = new Date();
        const diff = now - date;
        const seconds = Math.floor(diff / 1000);
        const minutes = Math.floor(seconds / 60);
        const hours = Math.floor(minutes / 60);
        const days = Math.floor(hours / 24);

        if (seconds < 60) return 'just now';
        if (minutes < 60) return `${minutes}m ago`;
        if (hours < 24) return `${hours}h ago`;
        if (days < 7) return `${days}d ago`;

        return date.toLocaleDateString();
    } catch {
        return 'recently';
    }
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// Cleanup on page unload
window.addEventListener('beforeunload', () => {
    if (refreshInterval) clearInterval(refreshInterval);
});
