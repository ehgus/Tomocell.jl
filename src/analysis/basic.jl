

"""
create N dimensional diamond kernel with radius r
"""
function __diamond_kernel(r::Integer, N::Integer)
    size = ntuple(_ -> 2*r+1, N)
    kernel = BitArray{N}(undef, size)
    
    origin = CartesianIndex(ntuple(_->r+1, N))
    @inbounds for i in CartesianIndices(size) 
        kernel[i] = sum(abs.(Tuple(i - origin))) <= r
    end
    kernel
end

function __get_centerOfmass(img::AbstractArray{<:Real})
    ND = ndims(img)
    indices = ((1:ND) .- (0:(ND-2))')%ND .+ 1

    partialsum = [np.sum(data,dims = index) for index in eachslice(indices;dims = 1)]
    totalsum = np.sum(partialsum[1])
    centerOfmass = [sum(idxsum .* (1:idxsize)) for (idxsum, idxsize) in zip(partialsum,size(img))]./totalsum

    SVector{ndims(img)}(centerOfmass)
end

function _default_cellmask(img::AbstractArray{<:Real})
    kernel = __diamond_kernel(2,ndims(img))
    thresh = otsu_threshold(img)

    _binary_mask = img .> thresh
    _binary_mask = opening(_binary_mask, kernel)
    _binary_mask = imfill(_binary_mask)
    mask = label_components(_binary_mask)
    
    mask
end

function get_celldata(tcfile::TCFile, idx::integer, bgRI = 1.337,limits = Dict(), cellmask_func = _default_cellmask; rtn_mask = false)

    # get basic data
    rawdata = raw_getindex(tcfile, idx)
    netRIdata = rawdata/1e4 .- bgRI
    volpix = prod(tcfile.resol)
    mask = cellmask_func(rawdata)
    labels = length(Set(mask))

    # get separate mask
    maskpiece = BitArray(undef, labels, size(mask)...)
    maskidx = Vector(1:labels)
    for (i,slice) in enumerate(eachslice(maskpiece; dims = 1))
        slice = (mask == i)
    end
    
    # evaluation of physical quantities
    volumes = [sum(selectdim(maskpiece, 1, i))*volpix for i in maskidx] # μm^3

    if haskey(limits, "minvol")
        limit = volumes .> limits["minvol"]
        maskidx = maskidx[limit]
        volumes = volumes[limit]
    end
    if haskey(limits, "maxvol")
        limit = volumes .< limits["maxvol"]
        maskidx = maskidx[limit]
        volumes = volumes[limit]
    end

    drymasses = [sum(netRIdata[selectdim(maskpiece, 1, i)])*volpix/0.185 for i in maskidx] # pg
    
    if haskey(limits, "mindm")
        limit = drymasses .> limits["mindm"]
        maskidx = maskidx[limit]
        drymasses = drymasses[limit]
        volumes = volumes[limit]
    end
    if haskey(limits, "maxdm")
        limit = drymasses .< limits["maxdm"]
        maskidx = maskidx[limit]
        drymasses = drymasses[limit]
        volumes = volumes[limit]
    end

    centerOfmasses = [__get_centerOfmass(netRIdata[selectdim(maskpiece, 1, i)]) for i in maskidx]
    
    tcfcells = [TCFcell(tcfile, idx, centerOfmass, drymass, Dict("volume"=>volume)) for (centerOfmass, drymass, volume) in zip(centerOfmasses, drymasses, volumes)]

    if rtn_mask
        for (tcfcell, i) in zip(tcfcells, maskidx)
            tcfcell["mask"] = copy(selectdim(A,1,i))
        end
    end
    tcfcells
end


function _default_connectivity(bf_tcfcells::Vector{TCFcell},af_tcfcells::Vector{TCFcell})
    
end

function get_celldata_t(tcfcellsTimeseries::Vector{Vector{TCFcell}}, connectivity_function = _default_connectivity)

end