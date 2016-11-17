# intervalgrids.jl


"An AbstractIntervalGrid is a grid that is defined on an interval, i.e. it is connected."
abstract AbstractIntervalGrid{T} <: AbstractGrid1d{T}

# Some default implementations for interval grids follow
left(g::AbstractIntervalGrid) = g.a
right(g::AbstractIntervalGrid) = g.b
length(g::AbstractIntervalGrid) = g.n

# Perhaps we should add a stepsize field, for better efficiency?
# Now the stepsize is recomputed with every call to getindex.

"An equispaced grid has equispaced points, and therefore it has a stepsize."
abstract AbstractEquispacedGrid{T} <: AbstractIntervalGrid{T}

range(g::AbstractEquispacedGrid) = range(left(g), stepsize(g), length(g))

unsafe_getindex(g::AbstractEquispacedGrid, i) = g.a + (i-1)*stepsize(g)

similar_grid(g::AbstractEquispacedGrid, a, b) =
    similar_grid(g, a, b, promote_type(eltype(g), typeof((b-a)/length(g))))

# Equispaced grids already support rescaling - avoid the construction of a LinearMappedGrid,
# but make sure to retain the type of the original grid.
rescale(g::AbstractEquispacedGrid, a, b) = similar_grid(g, a, b)

mapped_grid(g::AbstractEquispacedGrid, map::AffineMap) =
    similar_grid(g, forward_map(map, left(g)), forward_map(map, right(g)))

"""
An equispaced grid with n points on an interval [a,b], including the endpoints.
It has stepsize (b-a)/(n-1).
"""
immutable EquispacedGrid{T} <: AbstractEquispacedGrid{T}
    n   ::  Int
    a   ::  T
    b   ::  T

    EquispacedGrid(n, a = -one(T), b = one(T)) = (@assert a < b; new(n, a, b))
end

EquispacedGrid{T}(n, ::Type{T} = Float64) = EquispacedGrid{T}(n)

EquispacedGrid{T}(n, a, b, ::Type{T} = typeof((b-a)/n)) = EquispacedGrid{T}(n, a, b)

similar_grid(g::EquispacedGrid, a, b, T) = EquispacedGrid{T}(length(g), a, b)

stepsize(g::EquispacedGrid) = (g.b-g.a)/(g.n-1)


"""
A periodic equispaced grid is an equispaced grid that omits the right endpoint.
It has stepsize (b-a)/n.
"""
immutable PeriodicEquispacedGrid{T} <: AbstractEquispacedGrid{T}
    n   ::  Int
    a   ::  T
    b   ::  T

    PeriodicEquispacedGrid(n, a = -one(T), b = one(T)) = (@assert a < b; new(n, a, b))
end

PeriodicEquispacedGrid{T}(n, ::Type{T} = Float64) = PeriodicEquispacedGrid{T}(n)

PeriodicEquispacedGrid{T}(n, a, b, ::Type{T} = typeof((b-a)/n)) = PeriodicEquispacedGrid{T}(n, a, b)

similar_grid(g::PeriodicEquispacedGrid, a, b, T) = PeriodicEquispacedGrid{T}(length(g), a, b)

stepsize(g::PeriodicEquispacedGrid) = (g.b-g.a)/g.n



"""
A MidpointEquispaced grid is an equispaced grid with grid points in the centers of the equispaced
subintervals. In other words, this is a DCT-II grid.
It has stepsize (b-a)/n.
"""
immutable MidpointEquispacedGrid{T} <: AbstractEquispacedGrid{T}
    n   ::  Int
    a   ::  T
    b   ::  T

    MidpointEquispacedGrid(n, a = -one(T), b = one(T)) = (@assert a < b; new(n, a, b))
end

MidpointEquispacedGrid{T}(n, ::Type{T} = Float64) = MidpointEquispacedGrid{T}(n)

MidpointEquispacedGrid{T}(n, a, b, ::Type{T} = typeof((b-a)/n)) = MidpointEquispacedGrid{T}(n, a, b)

similar_grid(g::MidpointEquispacedGrid, a, b, T) = MidpointEquispacedGrid{T}(length(g), a, b)

unsafe_getindex{T}(g::MidpointEquispacedGrid{T}, i) = g.a + (i-one(T)/2)*stepsize(g)

stepsize(g::MidpointEquispacedGrid) = (g.b-g.a)/g.n




immutable ChebyshevIIGrid{T} <: AbstractIntervalGrid{T}
    n   ::  Int
end

typealias ChebyshevGrid ChebyshevIIGrid

ChebyshevIIGrid{T}(n::Int, ::Type{T} = Float64) = ChebyshevIIGrid{T}(n)


left{T}(g::ChebyshevIIGrid{T}) = -one(T)
right{T}(g::ChebyshevIIGrid{T}) = one(T)

# The minus sign is added to avoid having to flip the inputs to the dct. More elegant fix required.
unsafe_getindex{T}(g::ChebyshevIIGrid{T}, i) = T(-1)*cos((i-1/2) * T(pi) / (g.n) )
