# legendre.jl

"""
A basis of Legendre polynomials on the interval [-1,1].
"""
immutable LegendreBasis{T} <: OPS{T}
    n           ::  Int
end

name(b::LegendreBasis) = "Legendre OPS"

# Constructor with a default numeric type
LegendreBasis{T}(n::Int, ::Type{T} = Float64) = LegendreBasis{T}(n)

instantiate{T}(::Type{LegendreBasis}, n, ::Type{T}) = LegendreBasis{T}(n)

promote_eltype{T,S}(b::LegendreBasis{T}, ::Type{S}) = LegendreBasis{promote_type(T,S)}(b.n)

resize(b::LegendreBasis, n) = LegendreBasis(n, eltype(b))


left(b::LegendreBasis) = -1
left(b::LegendreBasis, idx) = -1

right(b::LegendreBasis) = 1
right(b::LegendreBasis, idx) = 1

#grid(b::LegendreBasis) = LegendreGrid(b.n)


jacobi_α(b::LegendreBasis) = 0
jacobi_β(b::LegendreBasis) = 0

weight{T}(b::LegendreBasis{T}, x) = ones(T,x)


# See DLMF, Table 18.9.1
# http://dlmf.nist.gov/18.9#i
rec_An{T}(b::LegendreBasis{T}, n::Int) = T(2*n+1)/T(n+1)

rec_Bn{T}(b::LegendreBasis{T}, n::Int) = zero(T)

rec_Cn{T}(b::LegendreBasis{T}, n::Int) = T(n)/T(n+1)
