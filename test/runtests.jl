using SampledDomains
using Test

@testset "SampledDomains.jl" begin
    a= SampledDomains.CartesianDomain2D(1:3, -5:.5:-3.5)
    f(x,y) = x*y
    b = SampledDomains.SampledDomain(f, a)
    @test b.vals ==[
        -5.0  -10.0  -15.0
        -4.5   -9.0  -13.5
        -4.0   -8.0  -12.0
        -3.5   -7.0  -10.5
    ] 
    @test b.dom === a 
end
