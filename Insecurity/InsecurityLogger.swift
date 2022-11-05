import Foundation

public enum InsecurityLoggerMode {
    case none
    case full
}

func insecPrint(_ message: @autoclosure () -> String,
                file: StaticString = #file,
                line: UInt = #line) {
#if DEBUG
    switch Insecurity.loggerMode {
    case .full:
        let fileString: String
        let nonStaticString = file.string
        if let url = URL(string: nonStaticString) {
            fileString = url.lastPathComponent
        } else {
            fileString = (nonStaticString as NSString).lastPathComponent
        }
        
        print("Insecurity: \(fileString):\(line) \(message())")
    case .none:
        break
    }
#endif
}

func insecAssertFail(_ message: @autoclosure () -> String,
                 file: StaticString = #file,
                 line: UInt = #line) {
    #if DEBUG
    assertionFailure(message(), file: file, line: line)
    #endif
}

#if DEBUG
private extension StaticString {
    var string: String {
        self.withUTF8Buffer { buffer in
            String(decoding: buffer, as: UTF8.self)
        }
    }
}
#endif
