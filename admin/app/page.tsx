import { Navigation } from "@/components/navigation"
import Link from "next/link"

export default function HomePage() {
  return (
    <div className="min-h-screen bg-gray-50">
      <Navigation />

      <main className="container mx-auto px-4 py-8 md:py-16">
        <div className="text-center space-y-8">
          {/* Decorative sparkles */}
          <div className="relative">
            <div className="absolute -top-8 left-1/4 w-8 h-8 text-red-400 animate-sparkle text-2xl md:text-3xl">✦</div>
            <div className="absolute -top-4 right-1/3 w-6 h-6 text-pink-400 animate-sparkle delay-300 text-xl md:text-2xl">
              ✧
            </div>
          </div>

          <div className="space-y-4 animate-slide-in-up">
            <h1 className="text-4xl md:text-6xl font-bold text-black">Hello Admin!</h1>
            <p className="text-lg md:text-xl text-gray-600 max-w-md mx-auto px-4">
              Smart Gram is running Great, and people are loving it ❤️
            </p>
          </div>

          <div className="py-8 animate-slide-in-up stagger-2">
            <Link
              href="/train-ai"
              className="inline-block bg-red-600 text-white px-6 md:px-8 py-2 md:py-3 rounded-full text-base font-semibold hover:bg-red-700 transition-all duration-300 hover-scale-small shadow-md"
            >
              Train AI
            </Link>
          </div>

          {/* AI Bot Illustration */}
          <div className="relative mt-8 md:mt-16 animate-slide-in-up stagger-3">
            <div className="absolute top-8 right-1/4 w-8 md:w-12 h-8 md:h-12 text-red-400 animate-sparkle delay-500 text-2xl md:text-3xl">
              ✦
            </div>
            <div className="absolute top-4 left-1/3 w-6 md:w-8 h-6 md:h-8 text-pink-400 animate-sparkle delay-700 text-xl md:text-2xl">
              ✧
            </div>

            <div className="w-64 md:w-80 h-64 md:h-80 mx-auto bg-white rounded-3xl border-2 border-gray-200 flex items-center justify-center shadow-lg hover-lift">
              <div className="w-32 md:w-48 h-32 md:h-48 relative animate-float">
                {/* AI Bot SVG */}
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
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  )
}
