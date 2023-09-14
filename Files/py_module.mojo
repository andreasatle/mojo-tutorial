from python import Python

fn main():
    try:
        let np = Python.import_module("numpy")
        let a = np.array([1, 2, 3])
        print(a)
    except:
        print("Python modules failed to load")
        pass
