module Tomocell

using HDF5: h5open, attributes
using StaticArrays: SVector
using Format: cfmt
using Images: otsu_threshold, opening, imfill, label_components
using Unitful


export TCFile, TCFcell

include("FileHandler.jl")
include("utils.jl")

end # module
