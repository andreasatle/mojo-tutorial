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