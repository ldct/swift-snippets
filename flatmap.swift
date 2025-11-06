import Combine

public extension Publisher where Failure == Never, Output: Sendable {
    func next(_: isolated (any Actor)? = #isolation) async -> Output {
        var scopedCancellables = Set<AnyCancellable>()
        return await withUnsafeContinuation { continuation in
            self.first().sink { value in
                continuation.resume(returning: value)
                scopedCancellables.removeAll()
            }.store(in: &scopedCancellables)
        }
    }
}

@MainActor class MyClass {
    let a = CurrentValueSubject<Int, Never>(0)
    let b = CurrentValueSubject<Int, Never>(0)
    let c = PassthroughSubject<String, Never>() // publisher that never emits
    
    func myFunc() async -> String {
        let aVal = await a.next()
        let bVal = await b.next()
        if aVal + bVal > 5 {
            return await c.next()
        } else {
            return "Hello World"
        }
    }
    
    /// Correct translation of `myFunc` into a publisher
    func myPublisher() -> AnyPublisher<String, Never> {
        Publishers.CombineLatest(a, b)
            .map { $0 + $1 > 5 }
            .first()
            .flatMap { [c] over in
                over
                ? c.eraseToAnyPublisher()
                : Just("Hello World").eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    /// Bad translation
    func myPublisherWrong() -> AnyPublisher<String, Never> {
        Publishers.CombineLatest3(a, b, c)
            .map { a, b, c in
                if a + b > 5 {
                    c
                } else {
                    "Hello World"
                }
            }
            .eraseToAnyPublisher()
    }

        
    var cancellables: Set<AnyCancellable> = []
    
    init() {
        Task {
            print("async: \(await myFunc())")
        }
        
        myPublisher().first().sink { print("correct publisher: \($0)") }.store(in: &cancellables)
        
        myPublisherWrong().first().sink { print("correct publisher: \($0)") }.store(in: &cancellables)
    }
}

let myClass = MyClass()
