from memory.unsafe import DTypePointer
from random import rand, seed
from memory import memset_zero
from benchmark import Benchmark
from algorithm import vectorize, parallelize
alias nelts = simdwidthof[DType.float32]()


@value
struct Vector:
    var data: DTypePointer[DType.float32]
    var n: Int

    fn __init__(inout self, n: Int):
        self.n = n
        self.data = DTypePointer[DType.float32].alloc(n)
        seed(4711) # Reset the seed everytime, so results are the same.
        rand(self.data, n)

    @always_inline
    fn zero(inout self):
        memset_zero(self.data, self.n)

    @always_inline
    fn __getitem__(self, i: Int) -> Float32:
        return self.load[1](i)

    @always_inline
    fn load[nelts: Int](self, i: Int) -> SIMD[DType.float32, nelts]:
        return self.data.simd_load[nelts](i)

    @always_inline
    fn __setitem__(self, i: Int, val: Float32):
        return self.store[1](i, val)

    @always_inline
    fn store[nelts:Int](self, i: Int, val: SIMD[DType.float32, nelts]):
        self.data.simd_store[nelts](i, val)

    fn print(self):
        for i in range(self.n):
                print(i+1,self[i])

fn main():
    let v = Vector(100)
    var w = v.load[nelts](99)
    #v.store[nelts](99, w+v.load[nelts](0))
    var w2 = v.load[nelts](99)
    print(w,w2)