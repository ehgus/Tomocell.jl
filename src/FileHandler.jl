
@enum ImgType TwoD=2 ThreeD=3

struct TCFile{N}
    tcfname::String
    imgtype::ImgType
    dtype::Type{<:AbstractFloat}
    # paramters
    len::Int64
    shape::SVector{N,Int64}
    resol::SVector{N,Float64}
    dt::Float64
end

function TCFile(tcfname::String, imgtype::String, dtype::Type{<:AbstractFloat}=Float64)
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
            getAttr(key) = read(attributes(io["Data"][imgtype])[key])[1]
            len = getAttr("DataCount")
            shape = SVector{_imgtype}([getAttr("Size$(idx)") for idx in ("X","Y","Z")[1:_imgtype]])
            resol = SVector{_imgtype}([getAttr("Resolution$(idx)") for idx in ("X","Y","Z")[1:_imgtype]])
            dt = (len == 1) ? 0.0 : getAttr("TimeInterval")
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