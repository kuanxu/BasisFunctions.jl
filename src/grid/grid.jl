# grid.jl

"AbstractGrid is the supertype of all grids."
abstract AbstractGrid{N,T}

typealias AbstractGrid1d{T} AbstractGrid{1,T}
typealias AbstractGrid2d{T} AbstractGrid{2,T}
typealias AbstractGrid3d{T} AbstractGrid{3,T}
typealias AbstractGrid4d{T} AbstractGrid{4,T}

dim{N,T}(::Type{AbstractGrid{N,T}}) = N
dim{G <: AbstractGrid}(::Type{G}) = dim(super(G))
dim{N,T}(g::AbstractGrid{N,T}) = N

numtype{N,T}(::Type{AbstractGrid{N,T}}) = T
numtype{G <: AbstractGrid}(::Type{G}) = numtype(super(G))
numtype{N,T}(g::AbstractGrid{N,T}) = T

# The element type of a grid is the type returned by getindex.
eltype{T}(::Type{AbstractGrid{1,T}}) = T
eltype{N,T}(::Type{AbstractGrid{N,T}}) = Vec{N,T}
eltype{G <: AbstractGrid}(::Type{G}) = eltype(super(G))

# Default dimension of the index is 1
index_dim{N,T}(::Type{AbstractGrid{N,T}}) = 1
index_dim{G <: AbstractGrid}(::Type{G}) = 1
index_dim(g::AbstractGrid) = index_dim(typeof(g))

size(g::AbstractGrid1d) = (length(g),)

support(g::AbstractGrid) = (left(g),right(g))



checkbounds(g::AbstractGrid, idx::Int) = (1 <= idx <= length(g) || throw(BoundsError()))

# Default implementation of index iterator: construct a range
eachindex(g::AbstractGrid) = 1:length(g)


# Grid iteration:
#	for x in grid
#		do stuff...
#	end
# Implemented by start, next and done.
function start(g::AbstractGrid)
	iter = eachindex(g)
	(iter, start(iter))
end

function next(g::AbstractGrid, state)
	iter = state[1]
	iter_state = state[2]
	idx,iter_newstate = next(iter,iter_state)
	(g[idx], (iter,iter_newstate))
end

done(g::AbstractGrid, state) = done(state[1], state[2])

"Sample the function f on the given grid."
sample(g::AbstractGrid, f::Function, ELT) = sample!(zeros(ELT, size(g)), g, f)

@generated function sample!(result, g::AbstractGrid, f::Function)
	xargs = [:(x[$d]) for d = 1:dim(g)]
	quote
		for i in eachindex(g)
			x = g[i]
			result[i] = f($(xargs...))
		end
		result
	end
end



"""
A TensorProductGrid represents the tensor product of other grids.

immutable TensorProductGrid{TG,GN,LEN,N,T} <: AbstractGrid{N,T}

Parameters:
- Parameter TG is a tuple of (grid) types.
- Parameter GN is a tuple of the dimensions of each of the grids.
- Parameter LEN is the length of TG and GN (the index dimension).
- Parametes N and T are the total dimension and numeric type of this grid.
"""
immutable TensorProductGrid{TG,GN,LEN,N,T} <: AbstractGrid{N,T}
	grids	::	TG

	TensorProductGrid(grids::Tuple) = new(grids)
end

TensorProductGrid(grids...) = TensorProductGrid{typeof(grids),map(dim,grids),length(grids),sum(map(dim, grids)),numtype(grids[1])}(grids)

TensorProductGrid(grid1::TensorProductGrid, grid2::TensorProductGrid) = TensorProductGrid(grid1.grids..., grid2.grids...)

TensorProductGrid(grid1::AbstractGrid, grid2::TensorProductGrid) = TensorProductGrid(grid1, grid2.grids...)
TensorProductGrid(grid1::TensorProductGrid, grid2::AbstractGrid) = TensorProductGrid(grid1.grids..., grid2)

tensorproduct(g::AbstractGrid, n) = TensorProductGrid([g for i=1:n]...)

# Use the Latex \otimes operator for constructing a tensor product grid
⊗(g1::AbstractGrid, g2::AbstractGrid) = TensorProductGrid(g1, g2)
⊗(g1::AbstractGrid, g::AbstractGrid...) = TensorProductGrid(g1, g...)


index_dim{TG,GN,LEN,N,T}(::Type{TensorProductGrid{TG,GN,LEN,N,T}}) = LEN

tp_length{TG,GN,LEN,N,T}(g::TensorProductGrid{TG,GN,LEN,N,T}) = LEN

size(g::TensorProductGrid) = map(length, g.grids)
size(g::TensorProductGrid, j::Int) = length(g.grids[j])

dim{TG,GN}(g::TensorProductGrid{TG,GN}, j::Int) = GN[j]

length(g::TensorProductGrid) = prod(size(g))

grids(g::TensorProductGrid) = g.grids
grid(g::TensorProductGrid, j::Int) = g.grids[j]

left(g::TensorProductGrid) = Vec(map(left, g.grids)...)
left(g::TensorProductGrid, j) = left(g.grids[j])

right(g::TensorProductGrid) = Vec(map(right, g.grids)...)
right(g::TensorProductGrid, j) = right(g.grids[j])


@generated function eachindex{TG,GN,LEN}(g::TensorProductGrid{TG,GN,LEN})
    startargs = fill(1, LEN)
    stopargs = [:(size(g,$i)) for i=1:LEN]
    :(CartesianRange(CartesianIndex{$LEN}($(startargs...)), CartesianIndex{$LEN}($(stopargs...))))
end

@generated function getindex{TG,GN,LEN}(g::TensorProductGrid{TG,GN,LEN}, index::CartesianIndex{LEN})
    :(@nref $LEN g d->index[d])
end

# This first set of routines applies when LEN ≠ N
# TODO: optimize with generated functions to remove all splatting.
getindex{TG,GN,N,T}(g::TensorProductGrid{TG,GN,1,N,T}, i1::Int) = Vec{N,T}(g.grids[1][i1]...)
getindex{TG,GN,N,T}(g::TensorProductGrid{TG,GN,2,N,T}, i1::Int, i2) =
	Vec{N,T}(g.grids[1][i1]..., g.grids[2][i2]...)
getindex{TG,GN,N,T}(g::TensorProductGrid{TG,GN,3,N,T}, i1::Int, i2, i3) =
	Vec{N,T}(g.grids[1][i1]..., g.grids[2][i2]..., g.grids[3][i3]...)
getindex{TG,GN,N,T}(g::TensorProductGrid{TG,GN,4,N,T}, i1::Int, i2, i3, i4) =
	Vec{N,T}(g.grids[1][i1]..., g.grids[2][i2]..., g.grids[3][i3]..., g.grids[4][i4]...)

# These routines apply when LEN = N
getindex{TG,GN,T}(g::TensorProductGrid{TG,GN,2,2,T}, i1::Int, i2) =
	Vec{2,T}(g.grids[1][i1], g.grids[2][i2])
getindex{TG,GN,T}(g::TensorProductGrid{TG,GN,3,3,T}, i1::Int, i2, i3) =
	Vec{3,T}(g.grids[1][i1], g.grids[2][i2], g.grids[3][i3])
getindex{TG,GN,T}(g::TensorProductGrid{TG,GN,4,4,T}, i1::Int, i2, i3, i4) =
	Vec{4,T}(g.grids[1][i1], g.grids[2][i2], g.grids[3][i3], g.grids[4][i4])

ind2sub(g::TensorProductGrid, idx::Int) = ind2sub(size(g), idx)
sub2ind(G::TensorProductGrid, idx...) = sub2ind(size(g), idx...)





# Map a grid 'g' defined on [left(g),right(g)] to the interval [a,b].
immutable LinearMappedGrid{G,T} <: AbstractGrid1d{T}
	grid	::	G
	a		::	T
	b		::	T

	LinearMappedGrid(grid::AbstractGrid1d{T}, a, b) = new(grid, a, b)
end

LinearMappedGrid{T}(g::AbstractGrid1d{T}, a, b) = LinearMappedGrid{typeof(g),T}(g, a, b)

left(g::LinearMappedGrid) = g.a
right(g::LinearMappedGrid) = g.b

grid(g::LinearMappedGrid) = g.grid

length(g::LinearMappedGrid) = length(g.grid)

for op in (:size,:eachindex)
	@eval $op(g::LinearMappedGrid) = $op(grid(g))
end

getindex(g::LinearMappedGrid, idx::Int) = map_linear(getindex(grid(g),idx), left(g), right(g), left(grid(g)), right(grid(g)))


rescale(g::AbstractGrid1d, a, b) = LinearMappedGrid(g, a, b)

# Avoid multiple linear mappings
rescale(g::LinearMappedGrid, a, b) = LinearMappedGrid(grid(g), a, b)


# Preserve tensor product structure
function rescale{TG,GN,N}(g::TensorProductGrid{TG,GN,N,N}, a::Vec{N}, b::Vec{N})
	scaled_grids = [ rescale(grid(g,i), a[i], b[i]) for i in 1:N]
	TensorProductGrid(scaled_grids...)
end


include("intervalgrids.jl")

