"use client"

export function AIStatus() {
  return (
    <div className="bg-white rounded-3xl p-6 shadow-lg hover:shadow-xl transition-shadow duration-300">
      {/* AI Bot Illustration */}
      <div className="flex justify-center mb-6">
        <div className="w-32 h-32 relative animate-float">
          <svg viewBox="0 0 200 200" className="w-full h-full">
            {/* Bot body */}
            <ellipse cx="100" cy="140" rx="60" ry="40" fill="#e5f3ff" stroke="#2563eb" strokeWidth="3" />

            {/* Bot head */}
            <circle cx="100" cy="80" r="45" fill="#f0f9ff" stroke="#2563eb" strokeWidth="3" />

            {/* Antenna */}
            <line x1="100" y1="35" x2="100" y2="20" stroke="#2563eb" strokeWidth="3" />
            <circle cx="100" cy="18" r="4" fill="#2563eb" />

            {/* Eyes */}
            <circle cx="85" cy="75" r="6" fill="#2563eb" />
            <circle cx="115" cy="75" r="6" fill="#2563eb" />

            {/* Smile */}
            <path d="M 80 95 Q 100 110 120 95" stroke="#2563eb" strokeWidth="3" fill="none" />

            {/* Headphones */}
            <path d="M 60 60 Q 50 80 60 100" stroke="#2563eb" strokeWidth="4" fill="none" />
            <path d="M 140 60 Q 150 80 140 100" stroke="#2563eb" strokeWidth="4" fill="none" />
            <circle cx="60" cy="80" r="8" fill="#2563eb" />
            <circle cx="140" cy="80" r="8" fill="#2563eb" />
          </svg>

          {/* Status indicator */}
          <div className="absolute -top-2 -right-2 w-6 h-6 bg-green-500 rounded-full border-2 border-white animate-pulse"></div>
        </div>
      </div>

      {/* Status Information */}
      <div className="bg-black text-white rounded-2xl p-4 space-y-2">
        <div className="flex justify-between items-center">
          <span className="text-sm font-medium">Status</span>
          <span className="text-sm font-semibold">Active</span>
        </div>
        <div className="flex justify-between items-center">
          <span className="text-sm font-medium">Last Updated</span>
          <span className="text-sm font-semibold">12/08/2005</span>
        </div>
      </div>
    </div>
  )
}
