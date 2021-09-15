
function sliceviewer(data::Array{<:Number,3}, axis::Integer = 3)
    fig = Figure()

    ax = Axis(fig[1,1])
    slider = Slider(fig[2,1], range = 1:size(data,axis), startvalue = div(size(data,axis), 2))
    
    slicedata = @lift selectdim(data, axis, $(slider.value))
    heatmap!(ax, slicedata, colorrange = extrema(data))
end