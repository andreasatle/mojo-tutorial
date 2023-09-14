# Args to fn are borrowed by default (immutable)
fn add(x: Int, y: Int) -> Int:
    return x + y

# Args can be borrowed explicitly (immutable)
fn add_with_borrowed(borrowed x: Int, borrowed y: Int) -> Int:
    return x + y

# Args can be forced to be inout (mutable)
fn add_with_inout(inout x: Int, inout y: Int) -> Int:
    x += 1
    y += 1
    return x + y

# Args can be forced to be owned (mutable copy)
fn add_with_owned(owned x: Int, owned y: Int) -> Int:
    x += 1
    y += 1
    return x + y

# Text example with owned variable.
# This is called with a mutable copy except when the argument has suffix `^`.
# Then the variable is moved, and destroys from the calling scope.
fn set_fire_with_owned(owned text: String) -> String:
    text += "🔥"
    return text

fn main():
    print("Hello, world!")
    print(add(1, 2))
    var x: Int = 1
    var y: Int = 2
    let text = "Hello"
    var out_text: String
    print(add_with_borrowed(x, y), x, y)
    print(add_with_inout(x, y), x, y)
    print(add_with_owned(x, y), x, y)
    out_text = set_fire_with_owned(text)
    print(out_text, text)
    out_text = set_fire_with_owned(text^)
    print(out_text)
