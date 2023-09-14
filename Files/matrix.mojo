from memory.unsafe import DTypePointer
from random import rand, seed
from memory import memset_zero
from benchmark import Benchmark
from algorithm import vectorize, parallelize
from runtime.llcl import Runtime
alias nelts: Int = simdwidthof[DType.float32]()

@value
struct Matrix:
    var data: DTypePointer[DType.float32]
    var rows: Int
    var cols: Int

    fn __init__(inout self, rows: Int, cols: Int):
        # Pad to a multiple of the SIMD width
        self.rows = ((rows+nelts-1)//nelts)*nelts
        self.cols = ((cols+nelts-1)//nelts)*nelts
        self.data = DTypePointer[DType.float32].alloc(self.rows * self.cols)
        self.zero()

    @always_inline
    fn zero(inout self):
        memset_zero(self.data, self.rows * self.cols)

    @always_inline
    fn randomize(inout self):
        rand(self.data, self.rows*self.cols)

    @always_inline
    fn randomize(inout self, s: Int):
        seed(s) # Reset the seed everytime, so results are the same.
        self.randomize()

    @always_inline
    fn __getitem__(self, i: Int, j: Int) -> Float32:
        return self.load[1](i,j)

    @always_inline
    fn load[nelts: Int](self, i: Int, j: Int) -> SIMD[DType.float32, nelts]:
        return self.data.simd_load[nelts](i * self.cols + j)

    @always_inline
    fn __setitem__(self, i: Int, j: Int, val: Float32):
        return self.store[1](i, j, val)

    @always_inline
    fn store[nelts:Int](self, i: Int, j: Int, val: SIMD[DType.float32, nelts]):
        self.data.simd_store[nelts](i * self.cols + j, val)

    fn print(self):
        for i in range(self.rows):
            for j in range(self.cols):
                print(i+1,j+1,self[i,j])

fn matmul_naive(inout C: Matrix, A: Matrix, B: Matrix):
    C.zero()

    for i in range(C.rows):
        for j in range(C.cols):
            for k in range(A.cols):
                C[i,j] += A[i,k] * B[k,j]


# Vectorize over the columns of C and B
fn matmul_vectorized(inout C: Matrix, A: Matrix, B: Matrix):
    C.zero()

    for m in range(C.rows):
        for k in range(A.cols):
            @parameter
            fn inner[nelts: Int](n: Int):
                C.store[nelts](m, n, C.load[nelts](m, n) + A[m,k] * B.load[nelts](k, n))
            vectorize[nelts,inner](C.cols)

# Parallelize over the rows
fn matmul_parallelized(inout C: Matrix, A: Matrix, B: Matrix, rt: Runtime):
    C.zero()

    @parameter
    fn outer(m: Int):
        for k in range(A.cols):
            @parameter
            fn inner[nelts: Int](n: Int):
                C.store[nelts](m, n, C.load[nelts](m, n) + A[m,k] * B.load[nelts](k, n))
            vectorize[nelts,inner](C.cols)
    parallelize[outer](rt, C.rows)

fn test[n: Int, m: Int, k: Int]():
    with Runtime() as rt:
        var A = Matrix(m,k)
        var B = Matrix(k,n)
        var C = Matrix(m,n)
        A.randomize(4711)
        B.randomize(4711)

        @always_inline
        @parameter
        fn naive_test():
            _ = matmul_naive(C, A, B)

        @always_inline
        @parameter
        fn vectorized_test():
            _ = matmul_vectorized(C, A, B)

        @always_inline
        @parameter
        fn parallelized_test():
            _ = matmul_parallelized(C, A, B, rt)

        let naive_time = Benchmark().run[naive_test]()
        let vectorized_time = Benchmark().run[vectorized_test]()
        let parallelized_time = Benchmark().run[parallelized_test]()
        #print("Naive matmul       :", naive_time)
        print("Speedup Vectorized matmul  :", naive_time/vectorized_time)
        print("Speedup Parallelized matmul:", naive_time/parallelized_time)

fn main():
    alias n: Int = 199
    alias m: Int = 12031
    alias k: Int = 111
    print("nelts:", nelts)
    let q = 8
    print("q:", (q+nelts-1)//nelts*nelts)
    test[n,m,k]()

    

    
