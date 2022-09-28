import XCTest
import BoolBuilder

final class BoolBuilderTests: XCTestCase {
    enum MyError: Error {
        case yes
        case no
    }
    
    func testWarnEmptyBoolBuilder() {
        XCTAssertTrue(all { })
        XCTAssertFalse(any { })
        XCTAssertTrue(try all { })
        XCTAssertFalse(try any { })
    }
    
    func testExample() {
        let conditions: [(Bool, Bool, Bool, Bool, Bool)] = (0..<(1 << 5)).map {
            (($0 >> 4).isMultiple(of: 2),
             ($0 >> 3).isMultiple(of: 2),
             ($0 >> 2).isMultiple(of: 2),
             ($0 >> 1).isMultiple(of: 2),
             $0.isMultiple(of: 2))
        }
        for (
            conditionA, conditionB, conditionC, conditionD, conditionE
        ) in conditions {
            XCTAssertEqual(
                all {
                    any {
                        conditionA
                        conditionB
                            .inverted
                        
                        either {
                            conditionC
                        } or: {
                            conditionD
                        }
                    }
                    conditionE
                },
                (
                    (
                        conditionA
                        ||
                        !conditionB
                        ||
                        (
                            conditionC
                            !=
                            conditionD
                        )
                    )
                    &&
                    conditionE
                )
            )
        }
    }
    
    func testAll() {
        XCTAssertTrue(all { true })
        XCTAssertFalse(all { false })
        XCTAssertTrue(all {
            true
            true
        })
        XCTAssertFalse(all {
            true
            false
        })
        XCTAssertFalse(all {
            false
            true
        })
        XCTAssertFalse(all {
            false
            false
        })
    }
    
    func testOr() {
        XCTAssertTrue(any { true })
        XCTAssertFalse(any { false })
        XCTAssertTrue(any {
            true
            true
        })
        XCTAssertTrue(any {
            true
            false
        })
        XCTAssertTrue(any {
            false
            true
        })
        XCTAssertFalse(any {
            false
            false
        })
    }
    
    func testNot() {
        XCTAssertTrue(false.inverted)
        XCTAssertFalse(true.inverted)
    }
    
    func testExclusiveOr() {
        XCTAssertFalse(either {
            true
        } or: {
            true
        })
        XCTAssertTrue(either {
            true
        } or: {
            false
        })
        XCTAssertTrue(either {
            false
        } or: {
            true
        })
        XCTAssertFalse(either {
            false
        } or: {
            false
        })
        XCTAssertTrue(either {
            either {
                true
            } or: {
                false
            }
        } or: {
            all {
                true
                false
            }
        })
    }
    
    func testShortCircuit() {
        var counter = 0
        var incrementCounter: Bool {
            counter += 1
            return true
        }
        XCTAssertTrue(any {
            true
            incrementCounter
        })
        XCTAssertEqual(counter, 0)
        XCTAssertTrue(any {
            false
            true
            incrementCounter
        })
        XCTAssertEqual(counter, 0)
        XCTAssertFalse(all {
            false
            incrementCounter
        })
        XCTAssertEqual(counter, 0)
        XCTAssertFalse(all {
            true
            false
            incrementCounter
        })
        XCTAssertEqual(counter, 0)
        XCTAssertTrue(all { incrementCounter })
        XCTAssertEqual(counter, 1)
        XCTAssertTrue(any { incrementCounter })
        XCTAssertEqual(counter, 2)
    }
    
    func testThrowing() {
        func alwaysThrows() throws -> Bool {
            throw MyError.yes
        }
        func shouldNotHappen() throws -> Bool {
            throw MyError.no
        }
        func alwaysTrue() throws -> Bool {
            true
        }
        func alwaysFalse() throws -> Bool {
            false
        }
        
        XCTAssertTrue(try all {
            try alwaysTrue()
        })
        XCTAssertTrue(try any {
            try alwaysTrue()
        })
        XCTAssertFalse(try all {
            try alwaysFalse()
        })
        XCTAssertFalse(try any {
            try alwaysFalse()
        })
        XCTAssertThrowsError(try all {
            try alwaysThrows()
        })
        XCTAssertThrowsError(try any {
            try alwaysThrows()
        })
        XCTAssertThrowsError(try all {
            true
            try alwaysThrows()
        })
        XCTAssertNoThrow(try all {
            false
            try alwaysThrows()
        })
        XCTAssertThrowsError(try any {
            false
            try alwaysThrows()
        })
        XCTAssertNoThrow(try any {
            true
            try alwaysThrows()
        })
        XCTAssertThrowsError(try either {
            true
        } or: {
            try alwaysThrows()
        })
        XCTAssertThrowsError(try either {
            try alwaysThrows()
        } or: {
            false
        })
        
        XCTAssertThrowsError(try all {
            all {
                true
            }
            try either {
                try any {
                    true
                    try alwaysThrows()
                }
            } or: {
                try alwaysThrows()
            }
        })
        
        XCTAssertThrowsError(try all {
            true
            try alwaysThrows()
            try shouldNotHappen()
        }) {
            XCTAssertEqual($0 as? MyError, MyError.yes)
        }
        XCTAssertThrowsError(try any {
            false
            try alwaysThrows()
            try shouldNotHappen()
        }) {
            XCTAssertEqual($0 as? MyError, MyError.yes)
        }
        
        XCTAssertThrowsError(try all {
            let result = try alwaysThrows()
            result
        })
        XCTAssertThrowsError(try any {
            let result = try alwaysThrows()
            result
        })
    }
    
    func testMixAndMatch() {
        func alwaysThrows() throws -> Bool {
            throw MyError.yes
        }
        func shouldNotHappen() throws -> Bool {
            throw MyError.no
        }
        
        XCTAssertTrue(all {
            true || false
            true != false
        })
        XCTAssertFalse(any {
            true && false
            true == false
        })
        XCTAssertFalse(try all {
            try false && alwaysThrows()
            try shouldNotHappen()
        })
        XCTAssertTrue(try any {
            try true || alwaysThrows()
            try shouldNotHappen()
        })
    }
    
    func testManyConditions() {
        XCTAssertTrue(all {
            true
            true
            true
            true
            true
            
            true
            true
            true
            true
            true
            
            true
            true
            true
            true
            true
            
            true
            true
            true
            true
            true
        })
        XCTAssertFalse(any {
            false
            false
            false
            false
            false
            
            false
            false
            false
            false
            false
            
            false
            false
            false
            false
            false
            
            false
            false
            false
            false
            false
        })
        
        func alwaysThrows() throws -> Bool {
            throw MyError.yes
        }
        XCTAssertThrowsError(try all {
            true
            true
            true
            true
            true
            
            true
            true
            true
            true
            true
            
            true
            true
            true
            true
            true
            
            true
            true
            true
            true
            try alwaysThrows()
        })
        XCTAssertThrowsError(try any {
            false
            false
            false
            false
            false
            
            false
            false
            false
            false
            false
            
            false
            false
            false
            false
            false
            
            false
            false
            false
            false
            try alwaysThrows()
        })
    }
}
