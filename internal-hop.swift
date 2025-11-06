import Combine
import Foundation

func printThread() {
    print(Thread.current)
}

final class MyUnsafeClass {
    var arr = [Int]()
    
    func twiddle(_ n : Int) async {
        printThread()
        if n == 0 {
            arr.insert(0, at: 0)
            arr.popLast()
        } else {
            await twiddle(n-1)
        }
    }
}

Task { @MainActor in
    var c = MyUnsafeClass()
    printThread()
    await c.twiddle(10)
    printThread()
}
