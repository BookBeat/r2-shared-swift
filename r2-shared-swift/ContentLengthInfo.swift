//
//  ContentLengthInfo.swift
//  r2-shared-swift
//
//  Created by Ullström Jonas (BookBeat) on 2018-09-26.
//  Copyright © 2018 Readium. All rights reserved.
//

import Foundation

public class ContentLengthInfo {
    
    public struct PageProgress: Equatable {
        public let documentStartProgress: Double
        public let documentEndProgress: Double
        public let totalStartProgress: Double
        public let totalEndProgress: Double
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
    func pageProgressFor(currentDocumentIndex: Int, currentPageInDocument: Int, documentTotalPages: Int) throws -> PageProgress {
        assert(spineContentLengths.count > currentDocumentIndex)
        guard currentPageInDocument >= 1 && currentPageInDocument <= documentTotalPages else { throw ProgressError.invalidPages }
        
        let documentStartProgress = Double(currentPageInDocument-1) / Double(documentTotalPages)
        let documentEndProgress = Double(currentPageInDocument) / Double(documentTotalPages)
        return pageProgressFor(currentDocumentIndex: currentDocumentIndex,
                               documentStartProgress: documentStartProgress,
                               documentEndProgress: documentEndProgress)
    }
    
    /**
     This uses the content lengths of all the spine items to calculate progress.
     This func will always return the endProgress for the startProgress since there's no way of knowing the page sizes in this context.
     */
    func pageProgressFor(currentDocumentIndex: Int, progressInDocument: Double) -> PageProgress {
        return pageProgressFor(currentDocumentIndex: currentDocumentIndex,
                               documentStartProgress: progressInDocument,
                               documentEndProgress: progressInDocument)
    }
    
    private func pageProgressFor(currentDocumentIndex: Int, documentStartProgress: Double, documentEndProgress: Double) -> PageProgress {
        assert(spineContentLengths.count > currentDocumentIndex)
        
        var startOfDocumentTotalProgress: Double = 0
        for (index, element) in spineContentLengths.enumerated() {
            if index >= currentDocumentIndex { break }
            startOfDocumentTotalProgress += element.percentOfTotal
        }
        
        let documentLengthPercentOfTotal = spineContentLengths[currentDocumentIndex].percentOfTotal
        
        let pageStartPercentOfTotal = documentLengthPercentOfTotal * documentStartProgress
        let pageStartTotalProgress = startOfDocumentTotalProgress + pageStartPercentOfTotal
        
        let pageEndPercentOfTotal = documentLengthPercentOfTotal * documentEndProgress
        let pageEndTotalProgress = min(startOfDocumentTotalProgress + pageEndPercentOfTotal, 1) //Float-addition and multiplication will sometimes yield progression greater than 1 i.e. 1.0000000000000007 or such.
        
        assert(pageEndTotalProgress >= 0 && pageEndTotalProgress <= 1.0)
        assert(pageStartTotalProgress >= 0 && pageStartTotalProgress <= pageEndTotalProgress)
        
        return PageProgress.init(documentStartProgress: documentStartProgress,
                                 documentEndProgress: documentEndProgress,
                                 totalStartProgress: pageStartTotalProgress,
                                 totalEndProgress: pageEndTotalProgress)
    }
}
