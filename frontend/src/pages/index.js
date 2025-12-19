import { useState, useEffect } from 'react';
import { fetchPosts, fetchRankings, createPost } from '../lib/api';

export default function Home() {
  const [posts, setPosts] = useState([]);
  const [rankings, setRankings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [tab, setTab] = useState('feed');
  const [content, setContent] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [toast, setToast] = useState(null);

  useEffect(() => {
    const loadData = async () => {
      setLoading(true);
      const [postsData, rankingsData] = await Promise.all([
        fetchPosts(),
        fetchRankings(),
      ]);
      setPosts(postsData || []);
      setRankings(rankingsData || []);
      setLoading(false);
    };
    loadData();
    const interval = setInterval(loadData, 5000);
    return () => clearInterval(interval);
  }, []);

  const topPosts = posts.sort((a, b) => (b.attention_accumulated || 0) - (a.attention_accumulated || 0));

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-950 via-blue-900 to-slate-900">
      {/* Header */}
      <header className="sticky top-0 z-50 backdrop-blur-md bg-black/30 border-b border-blue-500/20">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div className="flex justify-between items-center">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-gradient-to-br from-blue-400 to-purple-500 rounded-lg flex items-center justify-center font-bold text-white">
                Σ
              </div>
              <div>
                <h1 className="text-2xl font-black text-transparent bg-clip-text bg-gradient-to-r from-blue-400 to-purple-400">SUITER</h1>
                <p className="text-xs text-blue-300">Truth Network</p>
              </div>
            </div>
            <div className="flex items-center gap-2 bg-blue-500/10 px-3 py-2 rounded-lg border border-blue-500/20">
              <span className="w-2 h-2 bg-green-400 rounded-full animate-pulse"></span>
              <span className="text-sm text-green-400 font-semibold">LIVE</span>
            </div>
          </div>
        </div>
      </header>

      {/* Main */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
          {/* Sidebar */}
          <div className="lg:col-span-1 space-y-4">
            {/* Quick Stats */}
            <div className="bg-gradient-to-br from-blue-500/10 to-purple-500/10 border border-blue-500/20 rounded-xl p-6 backdrop-blur-sm hover:border-blue-500/40 transition">
              <h3 className="text-sm font-semibold text-blue-300 mb-4">📊 Network</h3>
              <div className="space-y-3">
                <div>
                  <p className="text-xs text-gray-400">Total Posts</p>
                  <p className="text-2xl font-bold text-white">{posts.length}</p>
                </div>
                <div>
                  <p className="text-xs text-gray-400">Ranked</p>
                  <p className="text-2xl font-bold text-blue-400">{rankings.length}</p>
                </div>
                <div className="pt-3 border-t border-blue-500/20">
                  <p className="text-xs text-gray-400">Status</p>
                  <p className="text-sm text-green-400 font-semibold">✓ Active</p>
                </div>
              </div>
            </div>

            {/* Create Post Card */}
            <div className="bg-gradient-to-br from-purple-500/20 to-blue-500/10 border border-purple-500/30 rounded-xl p-6 backdrop-blur-sm">
              <h3 className="text-sm font-semibold text-purple-300 mb-4">✨ Share Truth</h3>
              <label htmlFor="post-content" className="sr-only">Post content</label>
              <textarea
                id="post-content"
                value={content}
                onChange={(e) => setContent(e.target.value)}
                placeholder="What's on your mind?"
                className="w-full bg-white/5 border border-white/10 rounded-lg px-3 py-2 text-white placeholder-gray-500 text-sm focus:outline-none focus:border-purple-500/50 resize-none"
                rows="4"
                aria-label="Post content"
              />
              <button
                onClick={async () => {
                  if (!content || content.trim().length < 3) {
                    setToast({ type: 'error', text: 'Please enter at least 3 characters' });
                    setTimeout(() => setToast(null), 3000);
                    return;
                  }
                  setSubmitting(true);
                  try {
                    await createPost({ content_hash: content });
                    setToast({ type: 'success', text: 'Post created — refreshing feed' });
                    setContent('');
                    // refresh
                    const [postsData, rankingsData] = await Promise.all([fetchPosts(), fetchRankings()]);
                    setPosts(postsData || []);
                    setRankings(rankingsData || []);
                  } catch (err) {
                    console.error(err);
                    setToast({ type: 'error', text: 'Failed to create post' });
                  }
                  setTimeout(() => setToast(null), 3000);
                  setSubmitting(false);
                }}
                disabled={submitting}
                className={`w-full mt-3 ${submitting ? 'opacity-60 cursor-wait' : ''} bg-gradient-to-r from-purple-500 to-blue-500 hover:from-purple-600 hover:to-blue-600 text-white font-semibold py-2 rounded-lg transition transform hover:scale-105`}
              >
                {submitting ? 'Posting...' : 'Post'}
              </button>
              {toast && (
                <div className={`mt-3 text-sm ${toast.type === 'error' ? 'text-red-300' : 'text-green-300'}`}>{toast.text}</div>
              )}
            </div>
          </div>

          {/* Main Feed */}
          <div className="lg:col-span-2">
            <div className="bg-gradient-to-br from-slate-800/50 to-slate-900/50 border border-blue-500/20 rounded-xl backdrop-blur-sm overflow-hidden">
              {/* Tabs */}
              <div className="flex border-b border-blue-500/20">
                <button
                  onClick={() => setTab('feed')}
                  className={`flex-1 px-4 py-4 font-semibold transition ${
                    tab === 'feed'
                      ? 'text-blue-400 border-b-2 border-blue-400 bg-blue-500/5'
                      : 'text-gray-400 hover:text-gray-300'
                  }`}
                >
                  Hot Feed
                </button>
                <button
                  onClick={() => setTab('recent')}
                  className={`flex-1 px-4 py-4 font-semibold transition ${
                    tab === 'recent'
                      ? 'text-blue-400 border-b-2 border-blue-400 bg-blue-500/5'
                      : 'text-gray-400 hover:text-gray-300'
                  }`}
                >
                  Recent
                </button>
              </div>

              {/* Posts */}
              <div className="p-4 space-y-3 max-h-[600px] overflow-y-auto">
                {loading ? (
                  <div className="flex items-center justify-center py-12">
                    <div className="text-center">
                      <div className="w-8 h-8 border-3 border-blue-500/30 border-t-blue-400 rounded-full animate-spin mx-auto mb-2"></div>
                      <p className="text-gray-400">Loading posts...</p>
                    </div>
                  </div>
                ) : (tab === 'feed' ? topPosts : posts).length === 0 ? (
                  <div className="flex items-center justify-center py-12">
                    <p className="text-gray-500 text-center">No posts yet. Be the first! 🚀</p>
                  </div>
                ) : (
                  (tab === 'feed' ? topPosts : posts).slice(0, 20).map((post) => (
                    <div
                      key={post.id}
                      className="bg-white/5 border border-white/10 rounded-lg p-4 hover:bg-white/10 hover:border-blue-500/30 transition cursor-pointer group"
                    >
                      <div className="flex gap-3">
                        <div className="w-10 h-10 rounded-full bg-gradient-to-br from-blue-400 to-purple-500 flex-shrink-0 flex items-center justify-center text-white font-bold text-sm">
                          {post.author?.substring(0, 1).toUpperCase() || '?'}
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="font-semibold text-white group-hover:text-blue-300 transition">
                            {post.author?.substring(0, 8)}...
                          </p>
                          <p className="text-xs text-gray-400 mb-2">Just now</p>
                          <p className="text-gray-300 text-sm break-words">
                            {post.content_hash?.substring(0, 60)}...
                          </p>
                          <div className="flex gap-4 mt-3 text-xs text-gray-400">
                            <span className="inline-flex items-center gap-1 px-2 py-1 bg-blue-500/20 text-blue-300 rounded">
                              ⭐ Level {post.level || 1}
                            </span>
                            <span className="inline-flex items-center gap-1 px-2 py-1 bg-purple-500/20 text-purple-300 rounded">
                              👁️ {post.attention_accumulated || 0}
                            </span>
                          </div>
                        </div>
                      </div>
                    </div>
                  ))
                )}
              </div>
            </div>
          </div>

          {/* Leaderboard */}
          <div className="lg:col-span-1">
            <div className="bg-gradient-to-br from-slate-800/50 to-slate-900/50 border border-yellow-500/20 rounded-xl p-6 backdrop-blur-sm h-fit">
              <h3 className="text-lg font-bold text-transparent bg-clip-text bg-gradient-to-r from-yellow-400 to-orange-400 mb-4">
                🏆 Leaderboard
              </h3>
              <div className="space-y-2">
                {rankings.slice(0, 10).map((item, idx) => (
                  <div
                    key={item.post_id}
                    className="flex items-center gap-3 p-3 bg-white/5 border border-white/10 rounded-lg hover:bg-white/10 transition group"
                  >
                    <span className="text-xl font-bold text-yellow-400 w-6">
                      {idx === 0 ? '🥇' : idx === 1 ? '🥈' : idx === 2 ? '🥉' : `#${idx + 1}`}
                    </span>
                    <div className="flex-1 min-w-0">
                      <p className="text-white font-semibold text-sm truncate">Post</p>
                      <p className="text-blue-400 text-xs">{item.score?.toFixed(3) || '0'} pts</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="border-t border-blue-500/20 bg-black/30 backdrop-blur-md mt-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="text-center text-sm text-gray-400">
            <p>Powered by Sui Blockchain • Package: {process.env.NEXT_PUBLIC_API_URL}</p>
          </div>
        </div>
      </footer>
    </div>
  );
}
