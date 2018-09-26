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
    
    public final var spineContentLengths: [SpineContentLength]
    
    public var totalLength: Int
}

public struct SpineContentLength {
    init(spineItem: Link, contentLength: Int, percentOfTotal: Double) {
        self.spineItem = spineItem
        self.contentLength = contentLength
        self.percentOfTotal = percentOfTotal
    }
    public let spineItem: Link
    public let contentLength: Int
    public let percentOfTotal: Double
}


#if DEBUG
private var lastProgress: Double = 0
private var jumps = [Double]()
#endif

public extension ContentLengthInfo {
    
    /**
     This method is a "medelsvenssons" total progression. It uses the content lengths of all the chapters
     */
    func totalProgressFor(currentDocumentIndex: Int, currentPageInDocument: Int, documentTotalPages: Int) -> Double {
        assert(spineContentLengths.count > currentDocumentIndex)
        
        var progressionUntilChapter: Double = 0
        for (index, element) in spineContentLengths.enumerated() {
            if index >= currentDocumentIndex { break }
            progressionUntilChapter += element.percentOfTotal
        }
        
        let percentProgressionInChapter = Double(currentPageInDocument) / Double(documentTotalPages)
        
        let progressionInChapterForFullPublication = spineContentLengths[currentDocumentIndex].percentOfTotal * percentProgressionInChapter
        
        let totalProgression = progressionUntilChapter + progressionInChapterForFullPublication
        #if DEBUG
        let jump = totalProgression - lastProgress
        if jump > 0 {
            jumps.append(jump)
        }
        print("Jump: \(jump)")
        lastProgress = totalProgression
        #endif
        return totalProgression
    }
}
