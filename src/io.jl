
function TCFile(tcfname::AbstractString, imgDim::Integer, dtype::Type{<:AbstractFloat}=Float64)
    if imgDim ∉ (2, 3)
        throw(ArgumentError("image dimension must be two or three dimension"))
    end

    h5open(tcfname) do io
        if "Data" ∉ keys(io)
            throw(ArgumentError("The file does not contain 'Data' group. Is it TCF file?"))
        elseif imgtype ∉ keys(io["Data"])
            throw(ArgumentError("The TCFile does not support the suggested image type"))
        else
            h5io = io["Data"][imgtype]
            len = _getAttr("DataCount", h5io)
            size = SVector{imgDim}([[_getAttr("Size$(idx)", h5io) for idx in ("X","Y","Z")[1:imgDim]] len])
            resolution = SVector{imgDim}([_getAttr("Resolution$(idx)", h5io) for idx in ("X","Y","Z")[1:imgDim]])
            dt = (len == 1) ? 0.0 : _getAttr("TimeInterval", h5io)
            TCFile{dtype}{imgDim}(tcfname,ImgType(_imgtype),len,size,resolution,dt)
        end
    end
end


function TCFcell(io::HDF5.File)
    if haskey(io, "type")
        throw(ArgumentError("The file does not contain 'type' attribute. Is it TCFcell file?"))
    end

    if _getAttr("type",io) == "TCFcell"
        # attribute
        tcfname = _getAttr("tcfname", io)
        idx = _getAttr("idx", io)
        # data
        data = Dict{String,Any}(key => read(io[key]) for key in keys(io))
        VolumeOrArea = pop!(data, "VolumeOrArea")
        drymass = pop!(data, "drymass")
        CM = pop!(data,"CM")
        mask = haskey(data,"mask") ? pop!(data,"mask") : nothing
        optional = !isempty(data) ? data : nothing

        TCFcell{N}(tcfname, VolumeOrArea, drymass, CM, mask, optional)
    else
        throw(ArgumentError("'type' attribute has value '$(_getAttr("type",io))'. Is it TCFcell file?"))
    end
end

function TCFcell(fname::AbstractString)
    h5open(fname) do io
        TCFcell(io)
    end
end