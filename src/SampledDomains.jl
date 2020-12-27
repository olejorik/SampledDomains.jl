"""
The goal of the module is to attach physical coordinaes to array elements, so `a[i,j]` could be interpreted as ``f(x_i, y_j)`` for some function ``f``.
"""
module SampledDomains

abstract type AbstractDomain end

import Base.:*
import Base.size

export CartesianDomain2D, make_centered_domain2D, dualRange, dualDomain

# TODO rewrite as parametric type
struct CartesianDomain2D<:AbstractDomain
    xrange::AbstractRange
    yrange::AbstractRange
end

getranges(dom::AbstractDomain) = [getfield(dom,n) for n in fieldnames(typeof(dom))]

size(dom::AbstractDomain) = tuple(length.(reverse(getranges(dom)))...) # we need reverse to follow column major rule
# size(dom::AbstractDomain, d) = length(getfield(dom,d))
size(dom::AbstractDomain, d) = size(dom)[d]

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

"""
    SampledDomain(vals::Array, dom::AbstractDomain) 
    SampledDomain(f::Function, dom::AbstractDomain)

Contains two fileds: `vals` and `dom` representing sampled values of function `f` on `dom`ain.
"""
struct SampledDomain
    vals::Array
    dom::AbstractDomain
    SampledDomain(vals::Array, dom::AbstractDomain) = size(vals) != size(dom) ? ErrorException("Different size of the domain and values array") : new(vals, dom)
end

SampledDomain(f::Function, dom::AbstractDomain) = SampledDomain(map(x->f(x...), collect(Iterators.product(reverse(getranges(dom))...))), dom)

end
