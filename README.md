# Hello, Mojo

We're excited to introduce you to Mojo with this interactive notebook!

Mojo is designed as a superset of Python, so a lot of language features you are familiar with and the concepts that you know in Python translate directly to Mojo. For instance, a "Hello World" program in Mojo looks exactly as it does in Python:

```python
print("Hello Mojo!")
```

And as we'll show later, you can also import existing Python packages and use them like you're used to.

But Mojo provides a ton of powerful features on top of Python, so that's what we'll focus on in this notebook.

To be clear, this guide is not your traditional introduction to a programming language. This notebook assumes you're already familiar with Python and some systems programming concepts so we can focus on what's special about Mojo.

This runnable notebook is actually based on the Mojo programming manual, but we've simplified a bunch of the explanation so you can focus on playing with the code. If you want to learn more about a topic, refer to the complete manual.

Let's get started!

# Basic systems programming extensions

Python is not designed nor does it excel for systems programming, but Mojo is. This section describes how to perform basic systems programming in Mojo.

## let and var declarations

Exactly like Python you can assign values to a name and it implicitly creates a function-scope variable within a function. This provides a very dynamic and easy way to write code, but it also creates a challenge for two reasons:

Systems programmers often want to declare that a value that is immutable.
Systems programmers want to get an error if they mistype a variable name in an assignment.
To support this, Mojo supports let and var declarations, which introduce a new scoped runtime value: let is immutable and var is mutable. These values use lexical scoping and support name shadowing:

```python
def your_function(a, b):
    let c = a
    # Uncomment to see an error:
    # c = b  # error: c is immutable

    if c != b:
        let d = b
        print(d)

your_function(2, 3)
```

`let` and `var` declarations also support type specifiers, patterns, and late initialization:

```python
def your_function():
    let x: Int = 42
    let y: Float64 = 17.0

    let z: Float32
    if x != 0:
        z = 1.0
    else:
        z = foo()
    print(z)

def foo() -> Float32:
    return 3.14

your_function()
```

## `struct` types
Modern systems programming have the ability to build high-level and safe abstractions on top of low-level data layout controls, indirection-free field access, and other niche tricks. Mojo provides that with the struct type.

struct types are similar in many ways to classes. However, where classes are extremely dynamic with dynamic dispatch, monkey-patching (or dynamic method “swizzling”), and dynamically bound instance properties, structs are static, bound at compile time, and are inlined into their container instead of being implicitly indirect and reference counted.

Here’s a simple definition of a struct:
```python
struct MyPair:
    var first: Int
    var second: Int

    # We use 'fn' instead of 'def' here - we'll explain that soon
    fn __init__(inout self, first: Int, second: Int):
        self.first = first
        self.second = second

    fn __lt__(self, rhs: MyPair) -> Bool:
        return self.first < rhs.first or
              (self.first == rhs.first and
               self.second < rhs.second)
```

The biggest difference compared to a class is that all instance properties in a struct must be explicitly declared with a var or let declaration. This allows the Mojo compiler to layout and access property values precisely in memory without indirection or other overhead.

Struct fields are bound statically: they aren’t looked up with a dictionary indirection. As such, you cannot del a method or reassign it at runtime. This enables the Mojo compiler to perform guaranteed static dispatch, use guaranteed static access to fields, and inline a struct into the stack frame or enclosing type that uses it without indirection or other overheads.

## Strong type checking

Although you can still use dynamic types just like in Python, Mojo also allows you to use strong type checking in your program.

One of the primary ways to employ strong type checking is with Mojo’s struct type. A struct definition in Mojo defines a compile-time-bound name, and references to that name in a type context are treated as a strong specification for the value being defined. For example, consider the following code that uses the MyPair struct shown above:

```python
def pair_test() -> Bool:
    let p = MyPair(1, 2)
    # Uncomment to see an error:
    # return p < 4 # gives a compile time error
    return True
```

If you uncomment the first return statement and run it, you’ll get a compile-time error telling you that `4` cannot be converted to `MyPair`, which is what the RHS of `__lt__` requires (in the `MyPair` definition).

## Overloaded functions & methods

Also just like Python, you can define functions in Mojo without specifying argument types and let Mojo infer the data types. But when you want to ensure type safety, Mojo also offers full support for overloaded functions and methods.

Essentially, this allows you to define multiple functions with the same name but with different arguments. This is a common feature seen in many languages such as C++, Java, and Swift.

Let’s look at an example:

```python
struct Complex:
    var re: Float32
    var im: Float32

    fn __init__(inout self, x: Float32):
        """Construct a complex number given a real number."""
        self.re = x
        self.im = 0.0

    fn __init__(inout self, r: Float32, i: Float32):
        """Construct a complex number given its real and imaginary components."""
        self.re = r
        self.im = i
```

You can implement overloads anywhere you want: for module functions and for methods in a class or a struct.

Mojo doesn’t support overloading solely on result type, and doesn’t use result type or contextual type information for type inference, keeping things simple, fast, and predictable. Mojo will never produce an “expression too complex” error, because its type-checker is simple and fast by definition.

## `fn` definitions

The extensions above are the cornerstone that provides low-level programming and provide abstraction capabilities, but many systems programmers prefer more control and predictability than what def in Mojo provides. To recap, `def` is defined by necessity to be very dynamic, flexible and generally compatible with Python: arguments are mutable, local variables are implicitly declared on first use, and scoping isn’t enforced. This is great for high level programming and scripting, but is not always great for systems programming. To complement this, Mojo provides an `fn` declaration which is like a “strict mode” for `def`.

`fn` and `def` are always interchangeable from an interface level: there is nothing a `def` can provide that a `fn` cannot (or vice versa). The difference is that a `fn` is more limited and controlled on the inside of its body (alternatively: pedantic and strict). Specifically, `fn`s have a number of limitations compared to `def`s:

1. Argument values default to being immutable in the body of the function (like a `let`), instead of mutable (like a `var`). This catches accidental mutations, and permits the use of non-copyable types as arguments.

2. Argument values require a type specification (except for `self` in a method), catching accidental omission of type specifications. Similarly, a missing return type specifier is interpreted as returning None instead of an unknown return type. Note that both can be explicitly declared to return object, which allows one to opt-in to the behavior of a def if desired.

3. Implicit declaration of local variables is disabled, so all locals must be declared. This catches name typos and dovetails with the scoping provided by `let` and `var`.

4. Both support raising exceptions, but this must be explicitly declared on a fn with the raises function effect, placed after the function argument list.

## The `__copyinit__` and `__moveinit__` special methods

Mojo supports full “value semantics” as seen in languages like C++ and Swift, and it makes defining simple aggregates of fields very easy with its `@value` decorator (described in more detail in the Programming Manual).

For advanced use cases, Mojo allows you to define custom constructors (using Python’s existing `__init__` special method), custom destructors (using the existing `__del__` special method) and custom copy and move constructors using the new `__copyinit__` and `__moveinit__` special methods.

These low-level customization hooks can be useful when doing low level systems programming, e.g. with manual memory management. For example, consider a heap array type that needs to allocate memory for the data when constructed and destroy it when the value is destroyed:

```python
from Pointer import Pointer
from IO import print_no_newline

struct HeapArray:
    var data: Pointer[Int]
    var size: Int
    var cap: Int

    fn __init__(inout self):
        self.cap = 16
        self.size = 0
        self.data = Pointer[Int].alloc(self.cap)

    fn __init__(inout self, size: Int, val: Int):
        self.cap = size * 2
        self.size = size
        self.data = Pointer[Int].alloc(self.cap)
        for i in range(self.size):
            self.data.store(i, val)
     
    fn __del__(owned self):
        self.data.free()

    fn dump(self):
        print_no_newline("[")
        for i in range(self.size):
            if i > 0:
                print_no_newline(", ")
            print_no_newline(self.data.load(i))
        print("]")
```

This array type is implemented using low level functions to show a simple example of how this works. However, if you go ahead and try this out, you might be surprised:

```python
var a = HeapArray(3, 1)
a.dump()   # Should print [1, 1, 1]
# Uncomment to see an error:
# var b = a  # ERROR: Vector doesn't implement __copyinit__

var b = HeapArray(4, 2)
b.dump()   # Should print [2, 2, 2, 2]
a.dump()   # Should print [1, 1, 1]
```

The compiler isn’t allowing us to make a copy of our array: `HeapArray` contains an instance of `Pointer` (which is equivalent to a low-level C pointer), and Mojo can’t know “what the pointer means” or “how to copy it” - this is one reason why application level programmers should use higher level types like arrays and slices! More generally, some types (like atomic numbers) cannot be copied or moved around at all, because their address provides an identity just like a class instance does.

In this case, we do want our array to be copyable around, and to enable this, we implement the `__copyinit__` special method, which conventionally looks like this:

```python
struct HeapArray:
    var data: Pointer[Int]
    var size: Int
    var cap: Int

    fn __init__(inout self):
        self.cap = 16
        self.size = 0
        self.data = Pointer[Int].alloc(self.cap)

    fn __init__(inout self, size: Int, val: Int):
        self.cap = size * 2
        self.size = size
        self.data = Pointer[Int].alloc(self.cap)
        for i in range(self.size):
            self.data.store(i, val)

    fn __copyinit__(inout self, other: Self):
        self.cap = other.cap
        self.size = other.size
        self.data = Pointer[Int].alloc(self.cap)
        for i in range(self.size):
            self.data.store(i, other.data.load(i))
            
    fn __del__(owned self):
        self.data.free()

    fn dump(self):
        print_no_newline("[")
        for i in range(self.size):
            if i > 0:
                print_no_newline(", ")
            print_no_newline(self.data.load(i))
        print("]")
```

With this implementation, our code above works correctly and the b = a copy produces a logically distinct instance of the array with its own lifetime and data. Mojo also supports the `__moveinit__` method which allows both Rust-style moves (which take a value when a lifetime ends) and C++-style moves (where the contents of a value is removed but the destructor still runs), and allows defining custom move logic. Please see the Value Lifecycle section in the Programming Manual for more information.

```python
var a = HeapArray(3, 1)
a.dump()   # Should print [1, 1, 1]
# This is no longer an error:
var b = a

b.dump()   # Should print [1, 1, 1]
a.dump()   # Should print [1, 1, 1]
```

Mojo provides full control over the lifetime of a value, including the ability to make types copyable, move-only, and not-movable. This is more control than languages like Swift and Rust, which require values to at least be movable. If you are curious how existing can be passed into the `__copyinit__` method without itself creating a copy, check out the section on Borrowed argument convention below.

# Python integration

It's easy to use Python modules you know and love in Mojo. You can import any Python module into your Mojo program and create Python types from Mojo types.

## Importing Python modules

To import a Python module in Mojo, just call Python.import_module() with the module name:

```python
from PythonInterface import Python

# This is equivalent to Python's `import numpy as np`
let np = Python.import_module("numpy")

# Now use numpy as if writing in Python
array = np.array([1, 2, 3])
print(array)
```

Yes, this imports Python NumPy, and you can import any other Python module.

Currently, you cannot import individual members (such as a single Python class or function)—you must import the whole Python module and then access members through the module name.

There's no need to worry about memory management when using Python in Mojo. Everything just works because Mojo was designed for Python from the beginning.

## Mojo types in Python

Mojo primitive types implicitly convert into Python objects. Today we support lists, tuples, integers, floats, booleans, and strings.

For example, given this Python function that prints Python types:

```python
%%python
def type_printer(my_list, my_tuple, my_int, my_string, my_float):
    print(type(my_list))
    print(type(my_tuple))
    print(type(my_int))
    print(type(my_string))
    print(type(my_float))
```

You can pass the Python function Mojo types, no problem:

```python
type_printer([0, 3], (False, True), 4, "orange", 3.4)
```

Notice that in a Jupyter notebook, the Python function declared above is automatically available to any Mojo code in following code cells. (In other situations, you will need to import the Python module.)

Mojo doesn't have a standard Dictionary yet, so **it is not yet possible to create a Python dictionary from a Mojo dictionary**. You can work with Python dictionaries in Mojo though!

# Parameterization: compile time meta-programming
Mojo supports a full compile-time metaprogramming functionality built into the compiler as a separate stage of compilation - after parsing, semantic analysis, and IR generation, but before lowering to target-specific code. It uses the same host language for runtime programs as it does for metaprograms, and leverages MLIR to represent and evaluate these programs in a predictable way.

Let’s take a look at some simple examples.

## Defining parameterized types and functions
Mojo structs and functions may each be parameterized, but an example can help motivate why we care. Let’s look at a “SIMD” type, which represents a low-level vector register in hardware that holds multiple instances of a scalar data-type. Hardware accelerators these days are getting exotic datatypes, and it isn’t uncommon to work with CPUs that have 512-bit or longer SIMD vectors. There is a lot of diversity in hardware (including many brands like SSE, AVX-512, NEON, SVE, RVV, etc) but many operations are common and used by numerics and ML kernel developers - this type exposes them to Mojo programmers.

Here is very simplified and cut down version of the SIMD API from the Mojo standard library. We use `HeapArray` to store the SIMD data for this example and implement basic operations on our type using loops - we do that simply to mimic the desired SIMD type behavior for the sake of demonstration. The real Stdlib implementation is backed by real SIMD instructions which are accessed through Mojo's ability to use MLIR directly (see more on that topic in the Advanced Mojo Features section).

```python
from List import VariadicList

struct MySIMD[size: Int]:
    var value: HeapArray

    # Create a new SIMD from a number of scalars
    fn __init__(inout self, *elems: Int):
        self.value = HeapArray(size, 0)
        let elems_list = VariadicList(elems)
        for i in range(elems_list.__len__()):
            self[i] = elems_list[i]

    fn __copyinit__(inout self, other: MySIMD[size]):
        self.value = other.value

    fn __getitem__(self, i: Int) -> Int:
        return self.value.data.load(i)
    
    fn __setitem__(self, i: Int, val: Int):
        return self.value.data.store(i, val)

    # Fill a SIMD with a duplicated scalar value.
    fn splat(self, x: Int) -> Self:
        for i in range(size):
            self[i] = x
        return self

    # Many standard operators are supported.
    fn __add__(self, rhs: MySIMD[size]) -> MySIMD[size]:
        let result = MySIMD[size]()
        for i in range(size):
            result[i] = self[i] + rhs[i]
        return result
    
    fn __sub__(self, rhs: Self) -> Self:
        let result = MySIMD[size]()
        for i in range(size):
            result[i] = self[i] - rhs[i]
        return result

    fn concat[rhs_size: Int](self, rhs: MySIMD[rhs_size]) -> MySIMD[size + rhs_size]:
        let result = MySIMD[size + rhs_size]()
        for i in range(size):
            result[i] = self[i]
        for j in range(rhs_size):
            result[size + j] = rhs[j]
        return result

    fn dump(self):
        self.value.dump()
```

Parameters in Mojo are declared in square brackets using an extended version of the `PEP695` syntax. They are named and have types like normal values in a Mojo program, but they are evaluated at compile time instead of runtime by the target program. The runtime program may use the value of parameters - because the parameters are resolved at compile time before they are needed by the runtime program - but the compile time parameter expressions may not use runtime values.

In the example above, there are two declared parameters: the `MySIMD` struct is parameterized by a `size` parameter, and `concat` method is further parametrized with an `rhs_size` parameter. Because `MySIMD` is a parameterized type, the type of a self argument carries the parameters - the full type name is `MySIMD[size]`. While it is always valid to write this out (as shown in the return type of `__add__`), this can be verbose: we recommend using the `Self` type (from `PEP673`) like the `__sub__` example does.

The actual SIMD type provided by Mojo Stdlib is also parametrized on a data type of the elements.

## Using parameterized types and functions

The size specifies the number of elements in a SIMD vector, the example below shows how our type can be used:

```python
# Make a vector of 4 elements.
let a = MySIMD[4](1, 2, 3, 4)

# Make a vector of 4 elements and splat a scalar value into it.
let b = MySIMD[4]().splat(100)

# Add them together and print the result
let c = a + b
c.dump()

# Make a vector of 2 elements.
let d = MySIMD[2](10, 20)

# Make a vector of 2 elements.
let e = MySIMD[2](70, 50)

let f = d.concat[2](e)
f.dump()

# Uncomment to see the error:
# let x = a + e # ERROR: Operation MySIMD[4]+MySIMD[2] is not defined

let y = f + a
y.dump()
```

Note that the `concat` method needs an additional parameter to indicate the size of the second SIMD vector: that is handled by parameterizing the call to concat. Our toy SIMD type shows the use of a concrete type (`Int`), but the major power of parameters comes from the ability to define parametric algorithms and types, e.g. it is quite easy to define parametric algorithms, e.g. ones that are length- and DType-agnostic:

```python
from DType import DType
from Math import sqrt

fn rsqrt[width: Int, dt: DType](x: SIMD[dt, width]) -> SIMD[dt, width]:
    return 1 / sqrt(x)
```

The Mojo compiler is fairly smart about type inference with parameters. Note that this function is able to call the parametric `sqrt(x)` function without specifying the parameters, the compiler infers its parameters as if you wrote `sqrt[width,type](x)` explicitly. Also note that `rsqrt` chose to define its first parameter named `width` but the SIMD type names it size without challenge.

## Parameter expressions are just Mojo code

All parameters and parameter expressions are typed using the same type system as the runtime program: `Int` and `DType` are implemented in the Mojo standard library as structs. Parameters are quite powerful, supporting the use of expressions with operators, function calls etc at compile time, just like a runtime program. This enables the use of many ‘dependent type’ features, for example, you might want to define a helper function to concatenate two SIMD vectors, like we did in the example above:

```python
fn concat[len1: Int, len2: Int](lhs: MySIMD[len1], rhs: MySIMD[len2]) -> MySIMD[len1+len2]:
    let result = MySIMD[len1 + len2]()
    for i in range(len1):
        result[i] = lhs[i]
    for j in range(len2):
        result[len1 + j] = rhs[j]
    return result


let a = MySIMD[2](1, 2)
let x = concat[2,2](a, a)
x.dump()
```

Note how the result length is the sum of the input vector lengths, and you can express that with a simple + operation. For a more complex example, take a look at the `SIMD.shuffle` method in the standard library: it takes two input SIMD values, a vector shuffle mask as a list, and returns a SIMD that matches the length of the shuffle mask.

## Powerful compile-time programming

While simple expressions are useful, sometimes you want to write imperative compile-time logic with control flow. For example, the isclose function in the Math module uses exact equality for integers but close comparison for floating point. You can even do compile time recursion, e.g. here is an example “tree reduction” algorithm that sums all elements of a vector recursively into a scalar:

```python
fn slice[new_size: Int, size: Int](x: MySIMD[size], offset: Int) -> MySIMD[new_size]:
    let result = MySIMD[new_size]()
    for i in range(new_size):
        result[i] = x[i + offset]
    return result

fn reduce_add[size: Int](x: MySIMD[size]) -> Int:
    @parameter
    if size == 1:
        return x[0]
    elif size == 2:
        return x[0] + x[1]

    # Extract the top/bottom halves, add them, sum the elements.
    alias half_size = size // 2
    let lhs = slice[half_size, size](x, 0)
    let rhs = slice[half_size, size](x, half_size)
    return reduce_add[half_size](lhs + rhs)
    
let x = MySIMD[4](1, 2, 3, 4)
x.dump()
print("Elements sum:", reduce_add[4](x))
```

This makes use of the `@parameter if` feature, which is an if statement that runs at compile time. It requires that its condition be a valid parameter expression, and ensures that only the live branch of the if is compiled into the program.

## Mojo types are just parameter expressions

While we’ve shown how you can use parameter expressions within types, in both Python and Mojo, type annotations can themselves be arbitrary expressions. Types in Mojo have a special metatype type, allowing type-parametric algorithms and functions to be defined, for example we can extend our `HeapArray` struct to support arbitrary types of the elements: