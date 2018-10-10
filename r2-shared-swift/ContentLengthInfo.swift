//
//  ContentLengthInfo.swift
//  r2-shared-swift
//
//  Created by Ullström Jonas (BookBeat) on 2018-09-26.
//  Copyright © 2018 Readium. All rights reserved.
//

import Foundation

public class ContentLengthInfo {
    
    public struct Progress: Equatable {
        public let startProgress: Double
        public let endProgress: Double
    }
    
    enum ProgressError: Error {
        case invalidPages
    }
    
    public init(spineContentLengthTuples: [(spineLink: Link, contentLength: Int)]) {
        let totalLength = spineContentLengthTuples.reduce(0, {$0 + $1.contentLength})
        self.totalLength = totalLength
        
        self.spineContentLengths = spineContentLengthTuples.map({ (tuple) -> SpineContentLength in
            let percent = Double(tuple.contentLength) / Double(totalLength)
            return SpineContentLength(spineItem: tuple.spineLink, contentLength: tuple.contentLength, percentOfTotal: percent)
        })
        
        assert(
            spineContentLengthTuples.count == 0 ||
            self.spineContentLengths.reduce(0, {$0 + $1.percentOfTotal}) >= 0.99999999999
        )
    }
    
    public let spineContentLengths: [SpineContentLength]
    
    public var totalLength: Int
}

public extension ContentLengthInfo {
    
    /**
     This uses the content lengths of all the spine items to calculate progress.
     */
    func totalProgressFor(currentDocumentIndex: Int, currentPageInDocument: Int, documentTotalPages: Int) throws -> Progress {
        assert(spineContentLengths.count > currentDocumentIndex)
        guard currentPageInDocument >= 1 && currentPageInDocument <= documentTotalPages else { throw ProgressError.invalidPages }
        
        let progressionPreviousPage = Double(currentPageInDocument-1) / Double(documentTotalPages)
        let progressionCurrentPage = Double(currentPageInDocument) / Double(documentTotalPages)
        return totalProgressFor(currentDocumentIndex: currentDocumentIndex,
                                startOfPageProgressInDocument: progressionPreviousPage,
                                endOfPageProgressInDocument: progressionCurrentPage)
    }
    
    /**
     This uses the content lengths of all the spine items to calculate progress.
     This func will always return the endProgress for the startProgress since there's no way of knowing the page sizes in this context.
     */
    func totalProgressFor(currentDocumentIndex: Int, progressInDocument: Double) -> Progress {
        return totalProgressFor(currentDocumentIndex: currentDocumentIndex,
                                startOfPageProgressInDocument: progressInDocument,
                                endOfPageProgressInDocument: progressInDocument)
    }
    
    private func totalProgressFor(currentDocumentIndex: Int, startOfPageProgressInDocument: Double, endOfPageProgressInDocument: Double) -> Progress {
        assert(spineContentLengths.count > currentDocumentIndex)
        
        var progressionUntilChapter: Double = 0
        for (index, element) in spineContentLengths.enumerated() {
            if index >= currentDocumentIndex { break }
            progressionUntilChapter += element.percentOfTotal
        }
        
        let progressionInDocumentForFullPublicationUpUntilPage = spineContentLengths[currentDocumentIndex].percentOfTotal * startOfPageProgressInDocument
        let pageStartProgression = progressionUntilChapter + progressionInDocumentForFullPublicationUpUntilPage
        
        let progressionInDocumentForFullPublication = spineContentLengths[currentDocumentIndex].percentOfTotal * endOfPageProgressInDocument
        let pageEndProgression = min(progressionUntilChapter + progressionInDocumentForFullPublication, 1) //Float-addition and multiplication will sometimes yield progression greater than 1 i.e. 1.0000000000000007 or such.
        
        assert(pageEndProgression >= 0 && pageEndProgression <= 1.0)
        assert(pageStartProgression >= 0 && pageStartProgression <= pageEndProgression)
        
        return Progress(startProgress: pageStartProgression, endProgress: pageEndProgression)
    }
}
