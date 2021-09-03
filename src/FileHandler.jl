
@enum ImgType TwoD=2 ThreeD=3

struct TCFile{N}
    tcfname::AbstractString
    imgtype::ImgType
    dtype::Type{<:AbstractFloat}
    # paramters
    len::Int64
    shape::SVector{N,Int64}
    resol::SVector{N,Float64}
    dt::Float64
end

function TCFile(tcfname::AbstractString, imgtype::AbstractString, dtype::Type{<:AbstractFloat}=Float64)
    _imgtype = if (imgtype =="2D") 
        2
    elseif (imgtype =="3D")
        3
    else
        throw(ArgumentError("imgtype must be '3D' or '2D'"))
    end
    h5open(tcfname) do io
        if "Data" ∉ keys(io)
            throw(ArgumentError("The file does not contain 'Data' group. Is it TCF file?"))
        elseif imgtype ∉ keys(io["Data"])
            throw(ArgumentError("The TCFile does not support the suggested image type"))
        else
            h5io = io["Data"][imgtype]
            len = _getAttr("DataCount", h5io)
            shape = SVector{_imgtype}([_getAttr("Size$(idx)", h5io) for idx in ("X","Y","Z")[1:_imgtype]])
            resol = SVector{_imgtype}([_getAttr("Resolution$(idx)", h5io) for idx in ("X","Y","Z")[1:_imgtype]])
            dt = (len == 1) ? 0.0 : _getAttr("TimeInterval", h5io)
            TCFile{_imgtype}(tcfname,ImgType(_imgtype),dtype,len,shape,resol,dt)
        end
    end
end

Base.length(tcfile::TCFile) = tcfile.len
Base.ndims(tcfile::TCFile) = length(tcfile.shape)

function Base.getindex(tcfile::TCFile, key::Int)
    data = convert(Array{tcfile.dtype,ndims(tcfile)}, raw_getindex(tcfile,key))
    data ./= 1e4
    return data
end

function raw_getindex(tcfile::TCFile,key::Int)
    if length(tcfile) > key > 0
        throw(BoundsError())
    else
        h5open(tcfile.tcfname) do io
            data = read(io["Data/$(Int(tcfile.imgtype))D/$(cfmt("%06d",key))"])
            return data
        end
    end
end

struct TCFcell{N}
    tcfname::AbstractString
    resol::SVector{N,Float64}
    # (idx)th image data
    idx::UInt32
    # medatory data
    CM::SVector{N,Float64}
    drymass::Float64
    # optional data
    Optprop::Dict{AbstractString,Any}
end

function TCFcell(tcfile::TCFile{N},idx::Integer, CM::SVector{N,<:AbstractFloat},drymass::AbstractFloat,Optprop::Dict{String,Any}=Dict{String,Any}()) where {N}
    tcfname = tcfile.tcfname
    resol = tcfile.resol
    @assert idx > 0
    TCFcell{N}(tcfname,resol,UInt(idx),CM,drymass,Optprop)
end

function TCFcell(fname::AbstractString)
    h5open(fname) do io
        if "type" ∉ keys(io)
            throw(ArgumentError("The file does not contain 'type' attribute. Is it TCFcell file?"))
        elseif _getAttr("type",io) == "TCFcell"
            # get attributes
            tcfname = _getAttr("tcfname", io)
            resol = read(attributes(io)["resol"])
            idx = _getAttr("idx", io)
            N = length(resol)
            # get data
            optprop = Dict{String,Any}(key => _getAttr(key, io) for key in keys(io))
            CM = pop!(optprop, "CM")
            drymass = pop!(optprop, "drymass")
            
            TCFcell{N}(tcfname,resol,idx,CM,drymass,Optprop)
        else
            throw(ArgumentError("'type' attribute has value '$(_getAttr("type",io))'. Is it TCFcell file?"))
        end
    end
end


"""
return data
"""
function Base.getindex(tcfcell::TCFcell, key::AbstractString)
    if key == "CM"
        tcfcell.CM
    elseif key == "drymass"
        tcfcell.drymass
    else
        tcfcell.Optprop[key]
    end
end

function Base.setindex(key::AbstractString, value)
    if key == "CM" || key == "drymass"
        throw(ArgumentError("Invalid key"))
    else
        tcfcell.Optprop[key] = value
    end
end


