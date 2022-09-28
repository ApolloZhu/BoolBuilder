# BoolBuilder

`@resultBuilder` for building a `Bool`.

## Example

```swift
import BoolBuilder

let condition: Bool = all {
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
}
```

## Acknowledgements

Thanks to [@Vince14Genius](https://github.com/vince14genius) for the idea and API feedback.
