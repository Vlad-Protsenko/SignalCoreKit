//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

import Foundation

public extension Guarantee where Value == Void {

    /// Uses `mach_absolute_time` (pauses while suspended)
    static func after(seconds: TimeInterval) -> Guarantee<Void> {
        let (guarantee, future) = Guarantee<Void>.pending()

        let isMainApp = (ProcessInfo.processInfo.processName == "Signal")
        if !isMainApp && seconds > 2.0 {
            // App extensions have shorter lifecycles and are under more restrictive memory limits
            // For short-lived extensions (e.g. the NSE), the future make not resolve for a long time effectively
            // leaking any objects captured by the promise resolve block.
            //
            // If these show up repeatedly in the logs, it might be a good idea to move to the walltime variant.
            Logger.info("Building a time-elapsed guarantee with process-clock interval of: \(seconds)")
        }

        DispatchQueue.global().asyncAfter(deadline: .now() + seconds) {
            future.resolve()
        }
        return guarantee
    }

    /// Uses `gettimeofday` (ticks while suspended)
    static func after(wallInterval: TimeInterval) -> Guarantee<Void> {
        let (guarantee, future) = Guarantee<Void>.pending()
        DispatchQueue.global().asyncAfter(wallDeadline: .now() + wallInterval) {
            future.resolve()
        }
        return guarantee
    }
}
