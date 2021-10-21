"""
interface of TCF file
"""
struct TCFile{T <: AbstractFloat,N} <: AbstractVector{Array{T, N}}
    tcfname::AbstractString
    imgtype::ImgType
    # paramters
    len::Int64
    size::SVector{N,Int64}
    resolution::SVector{N,Float64}
    dt::Float64
end

Base.size(tcfile::TCFile) = (tcfile.len,)
dataSize(tcfile::TCFile) = tcfile.shape
dataNdims(tcfile::TCFile) = length(dataSize(tcfile))
dataLength(tcfile::TCFile) = prod(dataSize(tcfile))

function Base.getindex(tcfile::TCFile, key::Integer)
    if length(tcfile) < key || key <= 0
        throw(BoundsError())
    else
        h5open(tcfile.tcfname) do io
            # h5 file use zero index
            rawData = read(io["Data/$(Int(tcfile.imgtype))D/$(cfmt("%06d",key-1))"])
            data = convert(eltype(tcfile), raw_getindex(tcfile,key))
            data ./= 1e4
            return data
        end
    end
end


"""
TCFcell
"""
struct TCFcell{N}
    # attribute
    tcfname::AbstractString
    index::UInt16
    # data
    VolumeOrArea::Float64   # μm³ or μm²
    drymass::Float64        # pg
    CM::SVector{N,Float64}  # μm
    CompactMask::Union{Nothing,@NamedTuple{mask::Array{Bool, N},offset::SVector{N, Int64}}}
    optional::Union{Nothing, Dict{AbstractString,Any}}
end

dataNdims(tcfcell::TCFcell) = length(tcfcell.CM)

function TCFcell(tcfile::TCFile,index::Integer,VolumeOrArea, drymass, CM, mask=nothing, optional=nothing)
    tcfname = tcfile.tcfname
    N = dataSize(tcfile)
    @assert index > 0

    TCFcell{N}(tcfname, UInt(index), VolumeOrArea, drymass, CM, mask, optional)
end

"""
TCFcellGroup
"""
mutable struct TCFcellGroup{N} <: AbstractVector{Vector{TCFcell{N}}}
    # attribute
    tcfile::TCFile
    cellGroup::Vector{Vector{TCFcell{N}}}
end

function TCFcellGroup(tcfcell::TCFcell, tcfcells...)
    tcfname = tcfcell.tcfname
    N = dataDims(tcfcell)
    # variable variation
    for _tcfcell in tcfcells
        @assert isa(_tcfcell, TCFcell)
        @assert _tcfcell.name == tcfname
        @assert dataDims(_tcfcell) == N
    end
    # sort cell as groups
    tcfile = TCFile(tcfname, N)
    len = length(tcfile)
    cellGroup = Vector{}(Vector{TCFcell{N}}(undef, 0), len)
    for _tcfcell in tcfcells
        push!(cellGroup[_tcfcell.index], _tcfcell)
    end

    TCFcellGroup{N}(tcfile, cellGroup)
end