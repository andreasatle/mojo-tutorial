from memory.unsafe import DTypePointer
from random import rand, seed
from memory import memset_zero
from benchmark import Benchmark
from algorithm import vectorize, parallelize
alias nelts = simdwidthof[DType.float32]()

@value
struct Matrix:
    var data: DTypePointer[DType.float32]
    var rows: Int
    var cols: Int

    fn __init__(inout self, rows: Int, cols: Int):
        self.rows = rows
        self.cols = cols
        self.data = DTypePointer[DType.float32].alloc(rows * cols)
        seed(4711) # Reset the seed everytime, so results are the same.
        rand(self.data, rows*cols)

    @always_inline
    fn zero(inout self):
        memset_zero(self.data, self.rows * self.cols)

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
fn matmul_parallelized(inout C: Matrix, A: Matrix, B: Matrix):
    C.zero()

    @parameter
    fn outer(m: Int):
        for k in range(A.cols):
            @parameter
            fn inner[nelts: Int](n: Int):
                C.store[nelts](m, n, C.load[nelts](m, n) + A[m,k] * B.load[nelts](k, n))
            vectorize[nelts,inner](C.cols)
    parallelize[outer](C.rows)

fn test[n: Int, m: Int, k: Int]():

    fn naive_test() -> None:
        let A = Matrix(m,k)
        let B = Matrix(k,n)
        var C = Matrix(m,n)
        _ = matmul_naive(C, A, B)

    fn vectorized_test() -> None:
        let A = Matrix(m,k)
        let B = Matrix(k,n)
        var C = Matrix(m,n)
        _ = matmul_vectorized(C, A, B)

    fn parallelized_test() -> None:
        let A = Matrix(m,k)
        let B = Matrix(k,n)
        var C = Matrix(m,n)
        _ = matmul_parallelized(C, A, B)

    print("Naive matmul     :", Benchmark().run[naive_test]())
    print("Vectorized matmul:", Benchmark().run[vectorized_test]())
    print("Parallelized matmul:", Benchmark().run[parallelized_test]())

fn main():
    alias n: Int = 199
    alias m: Int = 12031
    alias k: Int = 111
    print("nelts:", nelts)
    test[n,m,k]()
    

    
