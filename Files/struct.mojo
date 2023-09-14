struct Pair:
    var first: Int
    var second: Int

    fn __init__(inout self, first: Int, second: Int):
        self.first = first
        self.second = second

    fn dump(self):
        print(self.first, self.second)

    fn set_first(inout self, first: Int):
        self.first = first

    fn set_second(inout self, second: Int):
        self.second = second

fn main():
    # When set_first is called, the struct must be declared with a var, not a let.
    # This is different to e.g. javascript, where the struct is mutable even if declared with const.
    var pair = Pair(2,5)
    pair.dump()
    pair.set_first(10)
    pair.set_second(4711)
    pair.dump()
