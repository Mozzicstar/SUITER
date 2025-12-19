import { useState, useEffect } from 'react';
import { fetchPosts, fetchRankings } from '../lib/api';

export default function Home() {
  const [posts, setPosts] = useState([]);
  const [rankings, setRankings] = useState([]);
  const [loading, setLoading] = useState(true);

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
  }, []);

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
      <header className="bg-white shadow">
        <div className="max-w-7xl mx-auto px-4 py-6">
          <h1 className="text-3xl font-bold text-gray-900">🚀 SUITER</h1>
          <p className="text-gray-600">Social Truth Network on Sui Blockchain</p>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 py-12">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {/* Feed */}
          <div className="md:col-span-2">
            <div className="bg-white rounded-lg shadow p-6">
              <h2 className="text-2xl font-bold mb-6">Feed</h2>
              {loading ? (
                <p className="text-gray-500">Loading posts...</p>
              ) : posts.length === 0 ? (
                <p className="text-gray-500">No posts yet. Be the first to create one!</p>
              ) : (
                <div className="space-y-4">
                  {posts.slice(0, 10).map((post) => (
                    <div key={post.id} className="border rounded p-4 hover:bg-gray-50">
                      <p className="font-semibold text-gray-900">{post.author}</p>
                      <p className="text-gray-700 mt-2">{post.content_hash?.substring(0, 50)}...</p>
                      <div className="flex gap-4 mt-3 text-sm text-gray-600">
                        <span>⭐ Level {post.level}</span>
                        <span>👁️ {post.attention_accumulated} attention</span>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>

          {/* Rankings */}
          <div>
            <div className="bg-white rounded-lg shadow p-6">
              <h2 className="text-xl font-bold mb-6">🏆 Rankings</h2>
              {rankings.length === 0 ? (
                <p className="text-gray-500">No rankings yet</p>
              ) : (
                <div className="space-y-3">
                  {rankings.slice(0, 10).map((item, idx) => (
                    <div key={item.post_id} className="flex justify-between items-center p-2 hover:bg-gray-50 rounded">
                      <span className="text-gray-700">
                        #{idx + 1} <span className="font-semibold">{item.score?.toFixed(2)}</span>
                      </span>
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* Stats */}
            <div className="bg-white rounded-lg shadow p-6 mt-6">
              <h3 className="font-bold mb-4">📊 Stats</h3>
              <div className="space-y-2 text-sm">
                <p className="text-gray-600">Posts: <span className="font-semibold">{posts.length}</span></p>
                <p className="text-gray-600">Rankings: <span className="font-semibold">{rankings.length}</span></p>
              </div>
            </div>
          </div>
        </div>

        {/* Info Banner */}
        <div className="mt-12 bg-blue-50 border border-blue-200 rounded-lg p-6">
          <h3 className="font-bold text-lg mb-2">🎯 Getting Started</h3>
          <ul className="text-sm text-gray-700 space-y-1">
            <li>✓ Contracts deployed to Sui testnet</li>
            <li>✓ Indexer listening to events</li>
            <li>✓ API server running (localhost:3000)</li>
            <li>✓ Database initialized</li>
            <li>→ Create posts, earn attention, build reputation!</li>
          </ul>
        </div>
      </main>
    </div>
  );
}
