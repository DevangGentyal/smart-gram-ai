"use client"

import { cn } from "@/lib/utils"

import { Navigation } from "@/components/navigation"
import { FileUpload } from "@/components/file-upload"
import { DocumentList } from "@/components/document-list"
import { AIStatus } from "@/components/ai-status"
import { useState } from "react"
import Link from "next/link"

export interface Document {
  id: string
  name: string
  type: "pdf" | "docx"
  size: number
  uploadedAt: Date
}

export default function TrainAIPage() {
  const [documents, setDocuments] = useState<Document[]>([
    {
      id: "1",
      name: "New September Rules 2025",
      type: "pdf",
      size: 2048000,
      uploadedAt: new Date("2025-09-01"),
    },
    {
      id: "2",
      name: "New October Rules 2025",
      type: "pdf",
      size: 1536000,
      uploadedAt: new Date("2025-10-01"),
    },
    {
      id: "3",
      name: "Testing Docs",
      type: "docx",
      size: 1024000,
      uploadedAt: new Date("2025-08-15"),
    },
    {
      id: "4",
      name: "Testing Docs",
      type: "docx",
      size: 1024000,
      uploadedAt: new Date("2025-08-15"),
    },
    {
      id: "5",
      name: "Testing Docs",
      type: "docx",
      size: 1024000,
      uploadedAt: new Date("2025-08-15"),
    },
  ])

  const [isTraining, setIsTraining] = useState(false)

  const handleFileUpload = (files: File[]) => {
    const newDocuments: Document[] = files.map((file) => ({
      id: Date.now().toString() + Math.random().toString(36).substr(2, 9),
      name: file.name.replace(/\.(pdf|docx)$/, ""),
      type: file.name.endsWith(".pdf") ? "pdf" : "docx",
      size: file.size,
      uploadedAt: new Date(),
    }))

    setDocuments((prev) => [...prev, ...newDocuments])

    // Simulate API call to upload files
    console.log("Uploading files to endpoint:", files)
  }

  const handleRemoveDocument = (id: string) => {
    setDocuments((prev) => prev.filter((doc) => doc.id !== id))
  }

  const handleTrainAI = async () => {
    setIsTraining(true)

    // Simulate API call to train AI
    console.log("Training AI with documents:", documents)

    // Simulate training delay
    setTimeout(() => {
      setIsTraining(false)
      alert("AI training completed successfully!")
    }, 3000)
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <Navigation />

      <main className="container mx-auto px-4 py-8">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 lg:gap-8">
          {/* Left Column - Document Management */}
          <div className="lg:col-span-2 animate-slide-in-left">
            <div className="bg-gray-200 rounded-3xl p-6 lg:p-8 h-full hover-lift">
              <h2 className="text-xl lg:text-2xl font-bold text-red-600 mb-6">Your AI Knowledge base</h2>

              <DocumentList documents={documents} onRemove={handleRemoveDocument} />

              <div className="mt-8">
                <FileUpload onUpload={handleFileUpload} />
              </div>
            </div>
          </div>

          {/* Right Column - AI Status & Actions */}
          <div className="space-y-6 animate-slide-in-right">
            <AIStatus />

            <div className="space-y-4">
              <button
                onClick={handleTrainAI}
                disabled={isTraining || documents.length === 0}
                className={cn(
                  "w-full bg-red-600 text-white py-2 md:py-3 rounded-full text-base font-semibold transition-all duration-300 shadow-md disabled:opacity-50 disabled:cursor-not-allowed",
                  isTraining ? "animate-pulse-glow" : "hover:bg-red-700 hover-scale-small",
                )}
              >
                {isTraining ? "Training AI..." : "Train AI"}
              </button>

              <Link
                href="/test-ai"
                className="block w-full bg-white text-red-600 py-2 md:py-3 rounded-full text-base font-semibold border-2 border-red-600 hover:bg-red-50 transition-all duration-300 hover-scale-small shadow-md text-center"
              >
                Test AI
              </Link>
            </div>
          </div>
        </div>
      </main>
    </div>
  )
}
