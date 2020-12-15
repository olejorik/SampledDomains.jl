module SampledDomains

import Base.:*

export CartesianDomain2D, make_centered_domain2D, dualRange, dualDomain

# TODO rewrite as parametric type
struct CartesianDomain2D
    xrange::AbstractRange
    yrange::AbstractRange
end

*(dom::CartesianDomain2D, s::Real) = CartesianDomain2D(dom.xrange * s, dom.yrange*s)
*( s::Real, dom::CartesianDomain2D) = CartesianDomain2D(dom.xrange * s, dom.yrange*s)

function make_centered_domain2D(xlength, ylength, pixelsize)
    xrange = ((1:xlength) .- (1 + xlength) / 2) .* pixelsize
    yrange = ((1:ylength) .- (1 + ylength) / 2) .* pixelsize
    CartesianDomain2D(xrange, yrange)
end


"""
    dualRange(xrange::AbstractRange, q::Int =1)

Construct range in Fourier-transform-dual domain with upsampling factor `q`. If sampling in `x` has step size Δx, the dual
domain is sampled in interval (-q/2Δx, q/2Δx).
"""
function dualRange(xrange::AbstractRange, q::Int =1)
    len = length(xrange) *q
    st = step(xrange) /q
    return UnitRange(-floor(Int, len / 2), ceil(Int, len / 2) - 1) / (st * len)
    
end

function dualDomain(dom::CartesianDomain2D, q::Int = 1)
    kxrange = dualRange(dom.xrange, q)
    kyrange = dualRange(dom.yrange, q)
    return CartesianDomain2D(kxrange,kyrange)
end

end
