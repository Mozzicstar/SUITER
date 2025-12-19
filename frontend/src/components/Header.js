export default function Header(){
  return (
    <header className="sticky top-0 z-50 backdrop-blur-md bg-black/30 border-b border-blue-500/10">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 flex justify-between items-center">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-gradient-to-br from-blue-400 to-purple-500 rounded-lg flex items-center justify-center font-bold text-white">Σ</div>
          <div>
            <h1 className="text-lg font-bold text-white">SUITER</h1>
            <p className="text-xs text-gray-400">Truth Network</p>
          </div>
        </div>
        <nav className="flex items-center gap-4">
          <a href="#" className="text-sm text-gray-300 hover:text-white">Feed</a>
          <a href="#" className="text-sm text-gray-300 hover:text-white">Leaderboard</a>
        </nav>
      </div>
    </header>
  )
}
