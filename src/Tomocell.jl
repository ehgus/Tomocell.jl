module Tomocell

using HDF5
using StaticArrays: SVector
using Format: cfmt
using Images: otsu_threshold, opening, imfill, label_components


export TCFile, TCFcell, TCFcellGroup, dataSize, dataNdims, dataLength

#utils containing useful internal functions
include("utils.jl")

#structs and functions to be exposed
include("FileHandler.jl")
include("io.jl")

end # module
