fn main():
    let vec1 = SIMD[DType.float32, 4](1.0,2.0,3.0,4.0)
    let vec2 = SIMD[DType.float32, 4](2.0,3.0,4.0,5.0)
    let vec3 = vec1 + vec2
    print(vec3)