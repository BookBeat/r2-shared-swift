//
//  ContentLengthInfo.swift
//  r2-shared-swift
//
//  Created by Ullström Jonas (BookBeat) on 2018-09-26.
//  Copyright © 2018 Readium. All rights reserved.
//

import Foundation

public class ContentLengthInfo {
    
    public init(spineContentLengthTuples: [(spineLink: Link, contentLength: Int)]) {
        let totalLength = spineContentLengthTuples.reduce(0, {$0 + $1.contentLength})
        self.totalLength = totalLength
        
        self.spineContentLengths = spineContentLengthTuples.map({ (tuple) -> SpineContentLength in
            let percent = Double(tuple.contentLength) / Double(totalLength)
            return SpineContentLength(spineItem: tuple.spineLink, contentLength: tuple.contentLength, percentOfTotal: percent)
        })
        
        assert(self.spineContentLengths.reduce(0, {$0 + $1.percentOfTotal}) >= 0.99999999999)
    }
    
    public let spineContentLengths: [SpineContentLength]
    
    public var totalLength: Int
}

public extension ContentLengthInfo {
    
    /**
     This method is a "medelsvenssons" total progression. It uses the content lengths of all the chapters
     */
    func totalProgressFor(currentDocumentIndex: Int, currentPageInDocument: Int, documentTotalPages: Int) -> Double {
        assert(spineContentLengths.count > currentDocumentIndex)
        let percentProgressionInChapter = Double(currentPageInDocument) / Double(documentTotalPages)
        let progressionInChapterForFullPublication = spineContentLengths[currentDocumentIndex].percentOfTotal * percentProgressionInChapter
        return totalProgressFor(currentDocumentIndex: currentDocumentIndex, progressInDocument: progressionInChapterForFullPublication)
    }
    
    func totalProgressFor(currentDocumentIndex: Int, progressInDocument: Double) -> Double {
        assert(spineContentLengths.count > currentDocumentIndex)
        
        var progressionUntilChapter: Double = 0
        for (index, element) in spineContentLengths.enumerated() {
            if index >= currentDocumentIndex { break }
            progressionUntilChapter += element.percentOfTotal
        }
        
        let totalProgression = progressionUntilChapter + progressInDocument
        return totalProgression
    }
}
