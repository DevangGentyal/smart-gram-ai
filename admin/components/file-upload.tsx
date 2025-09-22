"use client"

import type React from "react"

import { useCallback, useState } from "react"
import { Upload } from "lucide-react"

interface FileUploadProps {
  onUpload: (files: File[]) => void
}

export function FileUpload({ onUpload }: FileUploadProps) {
  const [isDragOver, setIsDragOver] = useState(false)

  const handleDragOver = useCallback((e: React.DragEvent) => {
    e.preventDefault()
    setIsDragOver(true)
  }, [])

  const handleDragLeave = useCallback((e: React.DragEvent) => {
    e.preventDefault()
    setIsDragOver(false)
  }, [])

  const handleDrop = useCallback(
    (e: React.DragEvent) => {
      e.preventDefault()
      setIsDragOver(false)

      const files = Array.from(e.dataTransfer.files).filter(
        (file) =>
          file.type === "application/pdf" ||
          file.type === "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
      )

      if (files.length > 0) {
        onUpload(files)
      }
    },
    [onUpload],
  )

  const handleFileSelect = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      const files = Array.from(e.target.files || []).filter(
        (file) =>
          file.type === "application/pdf" ||
          file.type === "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
      )

      if (files.length > 0) {
        onUpload(files)
      }

      // Reset input
      e.target.value = ""
    },
    [onUpload],
  )

  return (
    <div className="flex justify-center">
      <div
        className={`file-upload-area relative ${isDragOver ? "drag-over" : ""}`}
        onDragOver={handleDragOver}
        onDragLeave={handleDragLeave}
        onDrop={handleDrop}
      >
        <input
          type="file"
          multiple
          accept=".pdf,.docx"
          onChange={handleFileSelect}
          className="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
          id="file-upload"
        />
        <label
          htmlFor="file-upload"
          className="bg-black text-white px-8 py-3 rounded-full text-lg font-semibold hover:bg-gray-800 transition-all duration-300 hover:scale-105 shadow-lg hover:shadow-xl cursor-pointer flex items-center gap-2"
        >
          <Upload className="w-5 h-5" />
          Upload
        </label>
      </div>
    </div>
  )
}
