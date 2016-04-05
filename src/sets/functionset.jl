# functionset.jl


######################
# Type hierarchy
######################

"""
A FunctionSet is any set of functions. It is a logical superset of sets
with more structure, such as bases and frames. Each FunctionSet has a finite size,
and hence typically represents the truncation of an infinite set.
A FunctionSet has a dimension N and a numeric type T.
"""
abstract FunctionSet{N,T}

"""
An AbstractFrame has more structure than a set of functions. It is the truncation
of an infinite frame. (Since an AbstractFrame has a finite size, strictly speaking
this is usually a basis, albeit a very ill-conditioned one.)
"""
abstract AbstractFrame{N,T} <: FunctionSet{N,T}

"""
A basis is a non-redundant frame.
"""
abstract AbstractBasis{N,T} <: AbstractFrame{N,T}


# Useful abstraction for special cases in 1D
typealias FunctionSet1d{T} FunctionSet{1,T}
typealias AbstractFrame1d{T} AbstractFrame{1,T}
typealias AbstractBasis1d{T} AbstractBasis{1,T}

"The dimension of the set."
dim{N,T}(::Type{FunctionSet{N,T}}) = N
dim{B <: FunctionSet}(::Type{B}) = dim(super(B))
dim(s::FunctionSet) = dim(typeof(s))

"The numeric type of the set."
numtype{N,T}(::Type{FunctionSet{N,T}}) = real(T)
numtype{B <: FunctionSet}(::Type{B}) = numtype(super(B))
numtype(s::FunctionSet) = numtype(typeof(s))

"Trait to indicate whether the functions in the set are real-valued (for real arguments)."
isreal{N,T}(::Type{FunctionSet{N,T}}) = True
isreal{B <: FunctionSet}(::Type{B}) = True
isreal(s::FunctionSet) = isreal(typeof(s))()

"""
The eltype of a set is the typical numeric type of expansion coefficients. It is 
either NumT or Complex{NumT}, where NumT is the numeric type of the set.
"""
eltype{N,T}(::Type{FunctionSet{N,T}}) = T
eltype{B <: FunctionSet}(::Type{B}) = eltype(super(B))

# The following line is in Base
# eltype(x) = eltype(typeof(x))
# But the following aren't:
eltype(x, y) = eltype(typeof(x), typeof(y))
eltype(x, y, z) = eltype(typeof(x), typeof(y), typeof(z))
eltype(x, y, z, t) = eltype(typeof(x), typeof(y), typeof(z), typeof(t))

eltype{F1<:Any, F2<:Any}(::Type{F1}, ::Type{F2}) = promote_type(eltype(F1), eltype(F2))
eltype{F1<:Any, F2<:Any, F3<:Any}(::Type{F1}, ::Type{F2}, ::Type{F3}) =
    promote_type(eltype(F1), eltype(F2), eltype(F3))
eltype{F1<:Any, F2<:Any, F3<:Any, F4<:Any}(::Type{F1}, ::Type{F2}, ::Type{F3}, ::Type{F4}) =
    promote_type(eltype(F1), eltype(F2), eltype(F3), eltype(F4))


"""
The dimension of the index of the set. This may in general be different from the dimension
of the set. For example, Fourier series on a lattice in 2D may be indexed with a single
index. Wavelets in 1D are usually indexed with two parameters, scale and position.
"""
index_dim{N,T}(::Type{FunctionSet{N,T}}) = 1
index_dim{B <: FunctionSet}(::Type{B}) = 1
index_dim(s::FunctionSet) = index_dim(typeof(s))




# Is a given set a basis? In general, no, but some sets could turn out to be a basis.
# Example: a TensorProductSet that consists of a basis in each dimension.
# This is a problem that can be solved in two ways: introduce a parallel hierarchy 
# TensorProdctFrame - TensorProductBasis, or make the Basis property a trait.
# This is the trait:
is_basis(::Type{FunctionSet}) = False
is_basis{S <: FunctionSet}(::Type{S}) = is_basis(super(S))
is_basis(s::FunctionSet) = is_basis(typeof(s))()

is_frame(F::Type{FunctionSet}) = False
is_frame{S <: FunctionSet}(::Type{S}) = is_basis(S)
is_frame(s::FunctionSet) = is_frame(typeof(s))()

# A basis is always a basis.
is_basis{B <: AbstractBasis}(::Type{B}) = True

# And a frame is always a frame.
is_frame{F <: AbstractFrame}(::Type{F}) = True


"Trait to indicate whether a basis is orthogonal."
is_orthogonal{N,T}(::Type{FunctionSet{N,T}}) = False
is_orthogonal{B <: FunctionSet}(::Type{B}) = False
is_orthogonal(s::FunctionSet) = is_orthogonal(typeof(s))()

is_biorthogonal{N,T}(::Type{FunctionSet{N,T}}) = False
is_biorthogonal{B <: FunctionSet}(::Type{B}) = is_orthogonal(B)
is_biorthogonal(s::FunctionSet) = is_biorthogonal(typeof(s))()

"Return the size of the set."
size(s::FunctionSet) = (length(s),)

"Return the size of the j-th dimension of the set (if applicable)."
size(s::FunctionSet, j) = j==1 ? length(s) : throw(BoundsError())


"""
The instantiate function takes a set type, size and numeric type as argument, and
returns an instance of the type with the given size and numeric type and using
default values for other parameters. This means the given type is usually abstract,
since it is given without parameters.

This function is mainly used to create instances for testing purposes.
"""
instantiate{B <: FunctionSet}(::Type{B}, n) = instantiate(B, n, Float64)

"Promote the element type of the function set."
# This definition catches cases where nothing needs to be done with diagonal dispatch
# All sets should implement their own promotion rules.
promote_eltype{N,T}(b::FunctionSet{N,T}, ::Type{T}) = b


# similar returns a similar basis of a given size and numeric type
# It can be implemented in terms of resize and promote_eltype.
similar{T}(b::FunctionSet, ::Type{T}, n) = resize(promote_eltype(b, T), n)


# The following properties are not implemented as traits with types, because they are
# not intended to be used in a time-critical path of the code.

"Does the set implement a derivative?"
has_derivative(b::FunctionSet) = false

"Does the set implement an antiderivative?"
has_antiderivative(b::FunctionSet) = false

"Does the set have an associated interpolation grid?"
has_grid(b::FunctionSet) = false

"Does the set have a transform associated with some grid (space)?"
has_transform(b::FunctionSet) = has_grid(b) && has_transform(b, DiscreteGridSpace(grid(b)))
has_transform(b::FunctionSet, d) = false

"Does the set support extension and restriction operators?"
has_extension(b::FunctionSet) = false

# A functionset has spaces associated with derivatives or antiderivatives of a certain order.
# The default is that the function set is closed under derivation/antiderivation
derivative_set(b::FunctionSet, order = 1) = b
antiderivative_set(b::FunctionSet, order = 1) = b

# A FunctionSet has logical indices and natural indices. The logical indices correspond to
# the ordering of the coefficients in an expansion. Each set must support integers from 1 to length(s)
# as logical index. However, it is free to support more.
# The natural index may be closer to the mathematical definition. For example, wavelets may
# have a natural index that corresponds to the combination of scale and position. Or some
# basis functions may commonly be defined from 0 to n-1, rather than from 1 to n.
# By convention, we denote a natural index variable by idxn.
"Compute the natural index corresponding to the given logical index."
natural_index(b::FunctionSet, idx) = idx

"Compute the logical index corresponding to the given natural index."
logical_index(b::FunctionSet, idxn) = idxn

# Similarly, sets have a natural size and a logical size. However, there is not necessarily a
# bijection between the two. You can always convert a natural size to a logical size, but the other
# direction can be done in general only approximately.
# For example, a 2D tensor product set can only support sizes of the form n1 * n2. Its natural size may be
# (n1,n2) and its logical size n1*n2, but not any integer n maps to a natural size tuple.
# By convention, we denote a natural size variable by size_n.
"Compute the natural size best corresponding to the given logical size."
approximate_natural_size(b::FunctionSet, size_l) = size_l

"Compute the logical size corresponding to the given natural size."
logical_size(b::FunctionSet, size_n) = size_n

# Default set of logical indices: from 1 to length(s)
# Default algorithms assume this indexing for the basis functions, and the same
# linear indexing for the set of coefficients.
# The indices may also have tensor-product structure, for tensor product sets.
eachindex(s::FunctionSet) = 1:length(s)

# Default iterator over sets of functions: based on underlying index iterator.
function start(s::FunctionSet)
    iter = eachindex(s)
    (iter, start(iter))
end

function next(s::FunctionSet, state)
    iter = state[1]
    iter_state = state[2]
    idx,iter_newstate = next(iter,iter_state)
    (s[idx], (iter,iter_newstate))
end

done(s::FunctionSet, state) = done(state[1], state[2])



# Provide this implementation which Base does not include anymore
# TODO: hook into the Julia checkbounds system, once such a thing is developed.
checkbounds(i::Int, j::Int) = (1 <= j <= i) ? nothing : throw(BoundsError())

checkbounds(s::FunctionSet, i) = checkbounds(length(s), i)

function checkbounds(s::FunctionSet, i1, i2)
    checkbounds(size(s,1),i1)
    checkbounds(size(s,2),i2)
end

function checkbounds(s::FunctionSet, i1, i2, i3)
    checkbounds(size(s,1),i1)
    checkbounds(size(s,2),i2)
    checkbounds(size(s,3),i3)
end

function checkbounds(s::FunctionSet, i...)
    for n = 1:length(i)
        checkbounds(size(s,n), i[n])
    end
end

"Return the support of the idx-th basis function."
support(b::AbstractBasis1d, idx) = (left(b,idx), right(b,idx))

# This is a candidate for generated functions to avoid the splatting
call{N}(b::FunctionSet{N}, i, x::AbstractVector) = call(b, i, x...)

# This too is a candidate for generated functions to avoid the splatting
call{N}(b::FunctionSet{N}, i, x::Vec{N}) = call(b, i, x...)

# Here is another candidate for generated functions to avoid the splatting
function call(s::FunctionSet, i, x...)
    checkbounds(s, i)
    call_element(s, i, x...)
end

# Evaluate on a grid
function call(b::FunctionSet, i::Int, grid::AbstractGrid)
    result = zeros(promote_type(eltype(b),numtype(grid)), size(grid))
    call!(result, b, i, grid)
end

function call!(result, b::FunctionSet, i::Int, grid::AbstractGrid)
    @assert size(result) == size(grid)

    for k in eachindex(grid)
        result[k] = call(b, i, grid[k]...)
    end
    result
end

# This method to remove an ambiguity warning
call_expansion(b::FunctionSet, coef) = nothing

"""
Evaluate an expansion given by the set of coefficients `coef` in the point x.
"""
@generated function call_expansion{S <: Number}(b::FunctionSet, coef, xs::S...)
    xargs = [:(xs[$d]) for d = 1:length(xs)]
    quote
        T = promote_type(eltype(coef), S)
        z = zero(T)
        for i in eachindex(b)
            z = z + coef[i]*b(i, $(xargs...))
        end
        z
    end
end

@generated function call_expansion{N,T}(b::FunctionSet{N,T}, coef, x::Vec{N})
    xargs = [:(x[$d]) for d = 1:length(x)]
    quote
        call_expansion(b, coef, $(xargs...))
    end
end

function call_expansion{V <: Vec}(b::FunctionSet, coef, xs::AbstractArray{V})
    result = Array(eltype(coef), size(xs))
    call_expansion!(result, b, coef, xs)
end

# Vectorized method. Revisit once there is a standard way in Julia to treat
# vectorized function that is also fast.
# @generated to avoid splatting overhead (even though the function is vectorized,
# perhaps there is no need)
@generated function call_expansion{S <: Number}(b::FunctionSet, coef, xs::AbstractArray{S}...)
    xargs = [:(xs[$d]) for d = 1:length(xs)]
    quote
        T = promote_type(eltype(coef), S)
        result = similar(xs[1], T)
        call_expansion!(result, b, coef, $(xargs...))
    end
end

# It's probably best to include some checks
# - eltype(coef) is promotable to ELT
# - grid and b have the same numtype
function call_expansion{N}(b::FunctionSet{N}, coef, grid::AbstractGrid{N})
    ELT = promote_type(eltype(b), eltype(coef))
    result = Array(ELT, size(grid))
    call_expansion!(result, b, coef, grid)
end



function call_expansion!{N}(result, b::FunctionSet{N}, coef, grid::AbstractGrid{N})
    @assert size(result) == size(grid)
    ELT = promote_type(eltype(b), eltype(coef))
    E = evaluation_operator(b, DiscreteGridSpace(grid, ELT))
    result = E*coef
end

function call_expansion!{VEC <: Vec}(result, b::FunctionSet, coef, xs::AbstractArray{VEC})
    @assert size(result) == size(xs)

    for i in eachindex(xs)
        result[i] = call_expansion(b, coef, xs[i]...)
    end
    result
end


@generated function call_expansion!(result, b::FunctionSet, coef, xs::AbstractArray...)
    xargs = [:(xs[$d][i]) for d = 1:length(xs)]
    quote
        for i in 1:length(xs)
            @assert size(result) == size(xs[i])
        end

        for i in eachindex(xs[1])
            result[i] = call_expansion(b, coef, $(xargs...))
        end
        result
    end
end
