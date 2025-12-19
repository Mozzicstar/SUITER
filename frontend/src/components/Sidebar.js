export default function Sidebar({postsCount,rankingsCount}){
  return (
    <aside className="space-y-4">
      <div className="bg-gradient-to-br from-blue-500/8 to-purple-500/8 border border-blue-500/10 rounded-xl p-4">
        <p className="text-xs text-gray-400">Total Posts</p>
        <p className="text-2xl font-bold text-white">{postsCount}</p>
      </div>
      <div className="bg-gradient-to-br from-yellow-400/6 to-orange-400/6 border border-yellow-400/10 rounded-xl p-4">
        <p className="text-xs text-gray-400">Ranked</p>
        <p className="text-2xl font-bold text-yellow-300">{rankingsCount}</p>
      </div>
    </aside>
  )
}
