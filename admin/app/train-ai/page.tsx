"use client"

import { cn } from "@/lib/utils"
import { Navigation } from "@/components/navigation"
import { FileUpload } from "@/components/file-upload"
import { DocumentList } from "@/components/document-list"
import { AIStatus } from "@/components/ai-status"
import { useState, useEffect } from "react"
import Link from "next/link"
import ProtectedRoute from "../../context/ProtectedRoute"
import {
  addDoc,
  collection,
  doc,
  setDoc,
  deleteDoc,
  getDocs,
  Timestamp,
} from "firebase/firestore"
import { db } from "../../lib/firebase"

export interface Document {
  id: string
  name: string
  type: "pdf" | "docx"
  size: number
  uploadedAt: Date
  file?: File
  toDelete?: boolean
}

export default function TrainAIPage() {
  const [documents, setDocuments] = useState<Document[]>([])
  const [isTraining, setIsTraining] = useState(false)

  // 🧩 Load all existing documents from Firestore on mount
  useEffect(() => {
    const fetchDocuments = async () => {
      const snapshot = await getDocs(collection(db, "knowledgebase"))
      const docs: Document[] = snapshot.docs.map((d) => {
        const data = d.data()
        return {
          id: d.id,
          name: data.file_name,
          type: data.file_type,
          size: data.file_size,
          uploadedAt: data.upload_date?.toDate
            ? data.upload_date.toDate()
            : new Date(data.upload_date),
        }
      })
      setDocuments(docs)
    }
    fetchDocuments()
  }, [])

  // 📁 Handle file uploads (local only until TrainAI is clicked)
  const handleFileUpload = (files: File[]) => {
    const newDocuments: Document[] = files.map((file) => ({
      id: Date.now().toString() + Math.random().toString(36).substr(2, 9),
      name: file.name.replace(/\.(pdf|docx)$/, ""),
      type: file.name.endsWith(".pdf") ? "pdf" : "docx",
      size: file.size,
      uploadedAt: new Date(),
      file,
    }))
    setDocuments((prev) => [...prev, ...newDocuments])
  }

  // 🗑️ Mark document for deletion
  const handleRemoveDocument = (id: string) => {
    setDocuments((prev) =>
      prev.map((doc) =>
        doc.id === id ? { ...doc, toDelete: true } : doc
      )
    )
  }

  // 🚀 Upload & delete docs + sync with Firestore + backend
  const handleTrainAI = async () => {
    setIsTraining(true)
    try {
      // 1️⃣ Upload new PDFs
      const pdfToAdd = documents.filter(doc => !doc.toDelete && doc.file)
      for (const docData of pdfToAdd) {
        const newDocRef = doc(collection(db, "knowledgebase"))
        const firebaseId = newDocRef.id

        const formData = new FormData()
        formData.append("action", "add")
        formData.append("file_id", firebaseId)
        formData.append("pdf_file", docData.file as File)
        formData.append("file_name", docData.name)
        formData.append("file_type", docData.type)

        const res = await fetch("http://127.0.0.1:8000/update", {
          method: "POST",
          headers: { Authorization: "Bearer 12345678" },
          body: formData,
        })

        if (!res.ok) {
          console.error(`❌ Failed to upload ${docData.name}:`, await res.text())
          continue
        }

        console.log(`✅ Uploaded ${docData.name} successfully`)

        // Add to Firestore
        await setDoc(newDocRef, {
          file_name: docData.name,
          file_type: docData.type,
          file_size: docData.size,
          upload_date: Timestamp.fromDate(docData.uploadedAt),
        })

        // Update local state with Firebase ID
        setDocuments((prev) =>
          prev.map((d) =>
            d.name === docData.name ? { ...d, id: firebaseId } : d
          )
        )
      }

      // 2️⃣ Delete PDFs marked for removal
      const pdfToDelete = documents.filter(doc => doc.toDelete)
      for (const docData of pdfToDelete) {
        const formData = new FormData()
        formData.append("action", "delete")
        formData.append("file_id", docData.id)
        formData.append("file_name", docData.name)
        formData.append("file_type", docData.type)

        const res = await fetch("http://127.0.0.1:8000/update", {
          method: "POST",
          headers: { Authorization: "Bearer 12345678" },
          body: formData,
        })

        if (!res.ok) {
          console.error(`❌ Failed to delete ${docData.name}:`, await res.text())
          continue
        }

        console.log(`🗑️ Deleted ${docData.name} successfully`)

        // Remove from Firestore
        await deleteDoc(doc(db, "knowledgebase", docData.id))
      }

      // 3️⃣ Update local state
      setDocuments(prev => prev.filter(doc => !doc.toDelete))

    } catch (err) {
      console.error("🔥 Error during AI training:", err)
    } finally {
      setIsTraining(false)
    }
  }

  return (
    <ProtectedRoute>
      <div className="min-h-screen bg-gray-50">
        <Navigation />
        <main className="container mx-auto px-4 py-8">
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 lg:gap-8">

            {/* Left Column - Documents */}
            <div className="lg:col-span-2 animate-slide-in-left">
              <div className="bg-gray-200 rounded-3xl p-6 lg:p-8 h-full hover-lift">
                <h2 className="text-xl lg:text-2xl font-bold text-red-600 mb-6">
                  Your AI Knowledge base
                </h2>

                <DocumentList
                  documents={documents.filter(d => !d.toDelete)}
                  onRemove={handleRemoveDocument}
                />

                <div className="mt-8">
                  <FileUpload onUpload={handleFileUpload} />
                </div>
              </div>
            </div>

            {/* Right Column - AI Actions */}
            <div className="space-y-6 animate-slide-in-right">
              <AIStatus />

              <div className="space-y-4">
                <button
                  onClick={handleTrainAI}
                  disabled={isTraining || documents.length === 0}
                  className={cn(
                    "w-full bg-red-600 text-white py-2 md:py-3 rounded-full text-base font-semibold transition-all duration-300 shadow-md disabled:opacity-50 disabled:cursor-not-allowed",
                    isTraining ? "animate-pulse-glow" : "hover:bg-red-700 hover-scale-small"
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
    </ProtectedRoute>
  )
}
