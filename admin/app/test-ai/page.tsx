"use client"

import { Navigation } from "@/components/navigation"
import { AIPlayground } from "@/components/ai-playground"

export default function TestAIPage() {
  return (
    <div className="min-h-screen bg-gray-50">
      <Navigation />

      <main className="container mx-auto px-4 py-8">
        <div className="max-w-4xl mx-auto">
          <div className="text-center mb-8">
            <h1 className="text-4xl font-bold text-black mb-4">Test AI Playground</h1>
            <p className="text-lg text-gray-600">Test your trained AI model with queries and see how it responds</p>
          </div>

          <AIPlayground />
        </div>
      </main>
    </div>
  )
}
