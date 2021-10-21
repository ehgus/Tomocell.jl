
function TCFile(tcfname::AbstractString, imgDim::Integer, dtype::Type{<:AbstractFloat}=Float64)
    if imgDim ∉ (2, 3)
        throw(ArgumentError("image dimension must be two or three dimension"))
    end
    imgtype = ImgType(imgDim)

    h5open(tcfname) do h5io
        if !haskey(h5io, "Data")
            throw(ArgumentError("The file does not contain 'Data' group. Is it TCF file?"))
        elseif !haskey(h5io["Data"], String(imgtype))
            throw(ArgumentError("The TCFile does not support the suggested image type"))
        end

        dataio = h5io["Data"][String(imgtype)]
        len = _getAttr(dataio, "DataCount")
        size = SVector{imgDim}([_getAttr(dataio, "Size$(idx)") for idx in ("X","Y","Z")[1:imgDim]])
        resolution = SVector{imgDim}([_getAttr(dataio, "Resolution$(idx)") for idx in ("X","Y","Z")[1:imgDim]])
        dt = (len == 1) ? zero(Float64) : _getAttr(dataio, "TimeInterval")

        TCFile{dtype}{imgDim}(tcfname,imgtype,len,size,resolution,dt)
    end
end


function TCFcell(io::HDF5.File)
    if !haskey(attributes(io), "type")
        throw(ArgumentError("The file does not contain 'type' attribute. Is it TCFcell file?"))
    elseif _getAttr(io, "type") != "TCFcell"
        throw(ArgumentError("'type' attribute has value '$(_getAttr(io,"type"))'. Is it TCFcell file?"))
    end

    # attribute
    tcfname = _getAttr(io, "tcfname")
    index = _getAttr(io, "index")
    # data
    data = Dict{String,Any}(key => read(io[key]) for key in keys(io))
    VolumeOrArea = pop!(data, "VolumeOrArea")
    drymass = pop!(data, "drymass")
    CM = pop!(data,"CM")
    mask = haskey(data,"mask") ? pop!(data,"mask") : nothing
    optional = !isempty(data) ? data : nothing

    TCFcell{N}(tcfname,index, VolumeOrArea, drymass, CM, mask, optional)
end

function TCFcell(fname::AbstractString)
    h5open(fname) do io
        TCFcell(io)
    end
end

function Base.write(io::HDF5.File, tcfcell::TCFcell)
    h5open(fname,"w") do io
        _setAttr(io, "type", "TCFcell")
        # attribute
        _setAttr(io, "tcfname", tcfcell.tcfname)
        _setAttr(io, "index", tcfcell.index)
        # data:TODO
    end
end