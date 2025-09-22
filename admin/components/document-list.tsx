"use client"

import { X } from "lucide-react"
import type { Document } from "@/app/train-ai/page"

interface DocumentListProps {
  documents: Document[]
  onRemove: (id: string) => void
}

export function DocumentList({ documents, onRemove }: DocumentListProps) {
  return (
    <div className="space-y-4">
      {documents.map((doc, index) => (
        <div
          key={doc.id}
          className="bg-white rounded-2xl p-4 flex items-center justify-between shadow-sm hover:shadow-md transition-all duration-300 hover:scale-[1.02] group"
        >
          <div className="flex items-center gap-4">
            <span className="text-lg font-semibold text-gray-700">{index + 1}.</span>
            <span className="text-lg font-medium text-gray-900 underline">{doc.name}</span>
          </div>

          <button
            onClick={() => onRemove(doc.id)}
            className="w-8 h-8 bg-red-500 rounded-full flex items-center justify-center hover:bg-red-600 transition-colors group-hover:scale-110 transform duration-200"
          >
            <X className="w-4 h-4 text-white" />
          </button>
        </div>
      ))}

      {documents.length === 0 && (
        <div className="text-center py-12 text-gray-500">
          <p className="text-lg">No documents uploaded yet</p>
          <p className="text-sm">Upload PDF or DOCX files to get started</p>
        </div>
      )}
    </div>
  )
}
