import Foundation

public func measure <T> (_ f: @autoclosure () -> T) -> (result: T, duration: String) {
    let startTime = CFAbsoluteTimeGetCurrent()
    let result = f()
    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
    let formattedTimeString = String(format: "%.00004f", timeElapsed)
    return (result, "elapsed time is \(formattedTimeString) sec.")
}
