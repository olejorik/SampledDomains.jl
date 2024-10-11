"""
The goal of the module is to attach physical coordinates to array elements, so `a[i,j]` could be interpreted as ``f(x_i, y_j)`` for some function ``f``.
"""
module SampledDomains

abstract type AbstractDomain end

import Base.:*
import Base: size, length, axes, getindex, ndims
import Base.iterate, Base.IteratorSize, Base.IndexStyle

export CartesianDomain2D, make_centered_domain2D, dualRange, dualDomain

getranges(dom::AbstractDomain) = [getfield(dom, n) for n in fieldnames(typeof(dom))]

length(dom::AbstractDomain) = prod(length.(getranges(dom)))
size(dom::AbstractDomain) = tuple(length.(reverse(getranges(dom)))...) # we need reverse to follow column major rule
# size(dom::AbstractDomain, d) = length(getfield(dom,d))
size(dom::AbstractDomain, d) = size(dom)[d]
ndims(dom::AbstractDomain) = length(fieldnames(typeof(dom)))

# TODO rewrite as parametric type
struct CartesianDomain2D <: AbstractDomain
    xrange::AbstractRange
    yrange::AbstractRange
end

*(dom::CartesianDomain2D, s::Real) = CartesianDomain2D(dom.xrange .* s, dom.yrange .* s)
*(s::Real, dom::CartesianDomain2D) = dom * s

function getindex(dom::CartesianDomain2D, I::Vararg{Int,2})
    return collect(x[i] for (x, i) in zip(reverse(getranges(dom)), I))
end

function Base.getindex(dom::CartesianDomain2D, i::Int)
    1 <= i <= length(dom) || throw(BoundsError(dom, i))
    xc, yc = divrem(i, size(dom, 2))
    return [dom.yrange[yc], dom.xrange[xc + 1]]
end

Base.IndexStyle(::Type{<:CartesianDomain2D}) = IndexCartesian()

function iterate(dom::CartesianDomain2D, state)
    return iterate(Iterators.product(reverse(getranges(dom))...), state)
end
iterate(dom::CartesianDomain2D) = iterate(Iterators.product(reverse(getranges(dom))...))
# axes(dom::CartesianDomain2D) = axes(Iterators.product(getranges(dom)...))
# ndims(dom::CartesianDomain2D) = ndims(Iterators.product(getranges(dom)...))
IteratorSize(dom::CartesianDomain2D) = IteratorSize(Iterators.product(getranges(dom)...))

function make_centered_domain2D(xlength, ylength, pixelsizex, pixelsizey)
    xrange = ((1:xlength) .- (1 + xlength) / 2) .* pixelsizex
    yrange = ((1:ylength) .- (1 + ylength) / 2) .* pixelsizey
    return CartesianDomain2D(xrange, yrange)
end

make_centered_domain2D(xlength, ylength, pixelsize) =
    make_centered_domain2D(xlength, ylength, pixelsize, pixelsize)

"""
    dualRange(xrange::AbstractRange, q::Int =1)

Construct range in Fourier-transform-dual domain with upsampling factor `q`. If sampling in `x` has step size Δx, the dual
domain is sampled in interval (-q/2Δx, q/2Δx).
"""
function dualRange(xrange::AbstractRange, q::Int=1)
    len = length(xrange) * q
    st = step(xrange) / q
    return UnitRange(-floor(Int, len / 2), ceil(Int, len / 2) - 1) / (st * len)
end

function dualDomain(dom::CartesianDomain2D, q::Tuple{Int,Int}=(1, 1))
    kxrange = dualRange(dom.xrange, q[1])
    kyrange = dualRange(dom.yrange, q[2])
    return CartesianDomain2D(kxrange, kyrange)
end

"""
    SampledDomain(vals::Array, dom::AbstractDomain)
    SampledDomain(f::Function, dom::AbstractDomain)

Contains two fileds: `vals` and `dom` representing sampled values of function `f` on `dom`ain.
"""
struct SampledDomain
    vals::Array
    dom::AbstractDomain
    function SampledDomain(vals::Array, dom::AbstractDomain)
        return if size(vals) != size(dom)
            ErrorException("Different size of the domain and values array")
        else
            new(vals, dom)
        end
    end
end

function SampledDomain(f::Function, dom::AbstractDomain)
    return SampledDomain(
        map(x -> f(x...), Iterators.product(reverse(getranges(dom))...)), dom
    )
end

end
