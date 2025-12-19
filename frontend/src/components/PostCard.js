export default function PostCard({post}){
  return (
    <article className="bg-white/6 border border-white/6 rounded-lg p-4">
      <header className="flex items-center gap-3 mb-2">
        <div className="w-10 h-10 rounded-full bg-gradient-to-br from-blue-500 to-purple-500 flex items-center justify-center text-white font-semibold">
          {post.author?.slice(0,1).toUpperCase()||'U'}
        </div>
        <div>
          <div className="text-sm font-semibold text-white truncate">{post.author}</div>
          <div className="text-xs text-gray-400">{post.created_at || 'now'}</div>
        </div>
      </header>
      <p className="text-sm text-gray-200 break-words">{post.content_hash}</p>
      <footer className="flex items-center gap-3 mt-3 text-xs text-gray-400">
        <span className="px-2 py-1 bg-blue-500/10 rounded">⭐ Level {post.level||1}</span>
        <span className="px-2 py-1 bg-purple-500/10 rounded">👁️ {post.attention_accumulated||0}</span>
      </footer>
    </article>
  )
}
