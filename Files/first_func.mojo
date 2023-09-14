fn your_function1(a: Int, b: Int):
    let c = a
    if c != b:
        let d = b
        print(d)

fn your_function2():
    let x: Int = 42
    let y: Float64 = 17.0
    let z: Float32

    if x != 0:
        z = 1.0
    else:
        z = foo()
    print(z)

fn foo() -> Float32:
    return 3.14

fn main():
    your_function1(2,3)
    your_function2()


