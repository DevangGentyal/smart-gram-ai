"use client"

import Link from "next/link"
import { usePathname } from "next/navigation"
import { User, Menu, X } from "lucide-react"
import { cn } from "@/lib/utils"
import { useState } from "react"

export function Navigation() {
  const pathname = usePathname()
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false)

  const navItems = [
    { name: "Home", href: "/" },
    { name: "Train AI", href: "/train-ai" },
    { name: "Test AI", href: "/test-ai" },
  ]

  return (
    <>
      {/* Desktop Navigation */}
      <nav className="w-full bg-white border border-gray-200 rounded-full px-6 py-4 mx-auto max-w-4xl mt-8 shadow-sm hover-lift animate-slide-in-up hidden md:block">
        <div className="flex items-center justify-between">
          <Link
            href="/"
            className="text-2xl font-bold text-red-600 hover:text-red-700 transition-all duration-300 hover:scale-105"
          >
            Smart Gram
          </Link>

          <div className="flex items-center gap-8">
            {navItems.map((item, index) => (
              <Link
                key={item.name}
                href={item.href}
                className={cn(
                  "text-lg font-medium transition-all duration-300 hover:text-red-600 hover:scale-105 animate-fade-in",
                  pathname === item.href ? "text-red-600 font-semibold" : "text-gray-700",
                  `stagger-${index + 1}`,
                )}
              >
                {item.name}
              </Link>
            ))}

            <div className="w-12 h-12 bg-red-600 rounded-full flex items-center justify-center hover:bg-red-700 transition-all duration-300 cursor-pointer hover-scale hover-glow animate-fade-in stagger-4">
              <User className="w-6 h-6 text-white" />
            </div>
          </div>
        </div>
      </nav>

      {/* Mobile Navigation */}
      <nav className="w-full bg-white border border-gray-200 rounded-2xl px-4 py-3 mx-auto max-w-sm mt-4 shadow-sm hover-lift animate-slide-in-up md:hidden">
        <div className="flex items-center justify-between">
          <Link href="/" className="text-xl font-bold text-red-600 hover:text-red-700 transition-colors">
            Smart Gram
          </Link>

          <button
            onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
            className="w-10 h-10 bg-red-600 rounded-full flex items-center justify-center hover:bg-red-700 transition-colors"
          >
            {isMobileMenuOpen ? <X className="w-5 h-5 text-white" /> : <Menu className="w-5 h-5 text-white" />}
          </button>
        </div>

        {/* Mobile Menu */}
        {isMobileMenuOpen && (
          <div className="mt-4 pt-4 border-t border-gray-200 animate-slide-in-up">
            <div className="flex flex-col gap-3">
              {navItems.map((item) => (
                <Link
                  key={item.name}
                  href={item.href}
                  onClick={() => setIsMobileMenuOpen(false)}
                  className={cn(
                    "text-lg font-medium transition-colors hover:text-red-600 py-2",
                    pathname === item.href ? "text-red-600 font-semibold" : "text-gray-700",
                  )}
                >
                  {item.name}
                </Link>
              ))}
            </div>
          </div>
        )}
      </nav>
    </>
  )
}
