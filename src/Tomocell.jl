module Tomocell

using HDF5
using StaticArrays: SVector
using Format: cfmt
using Images: otsu_threshold, opening, imfill, label_components


export TCFile, TCFcell, TCFcellGroup, dataSize, dataDims, dataLength

include("FileHandler.jl")
include("utils.jl")
include("io.jl")

end # module
