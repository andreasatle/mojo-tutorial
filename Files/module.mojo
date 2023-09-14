# Use back-tick due to struct is a keyword.
from `struct` import Pair
import `struct` as st
import `struct`
fn main():
    let pair = Pair(2,4)
    pair.dump()

    let pair2 = st.Pair(3,5)
    pair2.dump()

    let pair3 = `struct`.Pair(4,6)
    pair3.dump()