# tensorproductgrid.jl

"""
A TensorProductGrid represents the tensor product of other grids.

immutable TensorProductGrid{TG,N,T} <: AbstractGrid{N,T}

Parameters:
- Parameter TG is a tuple of (grid) types.
- Parametes N and T are the total dimension and numeric type of this grid.
"""
immutable TensorProductGrid{TG,N,T} <: AbstractGrid{N,T}
	grids	::	TG
end

# Generic functions for composite types:
elements(grid::TensorProductGrid) = grid.grids
element(grid::TensorProductGrid, j::Int) = grid.grids[j]
element(grid::TensorProductGrid, range::Range) = tensorproduct(grid.grids[range]...)
composite_length(grid::TensorProductGrid) = length(elements(grid))

# Disallow tensor products of a single grid
function TensorProductGrid(grid::AbstractGrid)
	println("Use tensorproduct instead of TensorProductGrid.")
	grid
end

TensorProductGrid(grids...) = TensorProductGrid{typeof(grids),sum(map(dim, grids)),numtype(grids[1])}(grids)

size(g::TensorProductGrid) = map(length, g.grids)
size(g::TensorProductGrid, j::Int) = length(g.grids[j])

dim(g::TensorProductGrid, j::Int) = dim(element(g,j))

index_dim{TG,N,T}(::Type{TensorProductGrid{TG,N,T}}) = tuple_length(TG)

length(g::TensorProductGrid) = prod(size(g))

left(g::TensorProductGrid) = Vec(map(left, g.grids)...)
left(g::TensorProductGrid, j) = left(g.grids[j])

right(g::TensorProductGrid) = Vec(map(right, g.grids)...)
right(g::TensorProductGrid, j) = right(g.grids[j])


@generated function eachindex{TG}(g::TensorProductGrid{TG})
	LEN = tuple_length(TG)
	startargs = fill(1, LEN)
	stopargs = [:(size(g,$i)) for i=1:LEN]
	:(CartesianRange(CartesianIndex{$LEN}($(startargs...)), CartesianIndex{$LEN}($(stopargs...))))
end

@generated function getindex{TG}(g::TensorProductGrid{TG}, index::CartesianIndex)
	LEN = tuple_length(TG)
    :(@nref $LEN g d->index[d])
end

# For the recursive evaluation of grids, we want to flatten any Vec's
# This is achieved with FlatVec below:
FlatVec(x) = Vec(x)
FlatVec(x, y) = Vec(x, y)
FlatVec(x, y, z) = Vec(x, y, z)
FlatVec(x, y, z, t) = Vec(x, y, z, t)

FlatVec(x::Number, y::Vec{2}) = Vec(x, y[1], y[2])
FlatVec(x::Number, y::Vec{2}, z::Number) = Vec(x, y[1], y[2], z)
FlatVec(x::Number, y::Vec{3}) = Vec(x, y[1], y[2], y[3])
FlatVec(x::Vec{2}, y::Vec{2}) = Vec(x[1], x[2], y[1], y[2])
FlatVec(x::Vec{2}, y::Number) = Vec(x[1], x[2], y)
FlatVec(x::Vec{2}, y::Number, z::Number) = Vec(x[1], x[2], y, z)


getindex(g::TensorProductGrid, i1::Int, i2::Int) =
	FlatVec(g.grids[1][i1], g.grids[2][i2])

getindex(g::TensorProductGrid, i1::Int, i2::Int, i3::Int) =
	FlatVec(g.grids[1][i1], g.grids[2][i2], g.grids[3][i3])

getindex(g::TensorProductGrid, i1::Int, i2::Int, i3::Int, i4::Int) =
	FlatVec(g.grids[1][i1], g.grids[2][i2], g.grids[3][i3], g.grids[4][i4])