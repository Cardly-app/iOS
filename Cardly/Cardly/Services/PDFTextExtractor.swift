//
//  PDFTextExtractor.swift
//  Cardly
//
//  PDF → text. Uses PDFKit for text-based pages and falls back to Vision OCR
//  (Korean + English) for scanned / image-only pages. Heavy work runs off the
//  main thread; the extracted text feeds the normal AI generation pipeline.
//

import Foundation
import PDFKit
import Vision

enum PDFTextExtractor {
    static let maxPages = 30          // guard against runaway time/cost
    static let maxChars = 20_000      // the server caps too, but cap client-side

    /// Extract text from a PDF. Text pages via PDFKit; scanned pages via OCR.
    static func extract(from url: URL) async -> String {
        await Task.detached(priority: .userInitiated) {
            guard url.startAccessingSecurityScopedResource() else { return "" }
            defer { url.stopAccessingSecurityScopedResource() }
            guard let doc = PDFDocument(url: url) else { return "" }

            var out = ""
            let pages = min(doc.pageCount, maxPages)
            for i in 0..<pages {
                guard let page = doc.page(at: i) else { continue }
                let text = (page.string ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                if text.count >= 20 {
                    out += text + "\n\n"
                } else {
                    out += (await ocr(page)) + "\n\n"   // scanned / image page fallback
                }
                if out.count >= maxChars { break }
            }
            return String(out.prefix(maxChars))
        }.value
    }

    /// Render one page to an image and run Vision text recognition (ko + en).
    private static func ocr(_ page: PDFPage) async -> String {
        let bounds = page.bounds(for: .mediaBox)
        let scale: CGFloat = 2.0
        let size = CGSize(width: bounds.width * scale, height: bounds.height * scale)
        guard let cg = page.thumbnail(of: size, for: .mediaBox).cgImage else { return "" }

        var request = RecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = [Locale.Language(identifier: "ko-KR"),
                                        Locale.Language(identifier: "en-US")]
        request.usesLanguageCorrection = true

        guard let results = try? await request.perform(on: cg) else { return "" }
        return results
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")
    }
}
