# functionset.jl


######################
# Type hierarchy
######################

"""
A FunctionSet is any set of functions with a finite size. It is typically the
truncation of an infinite set, but that need not be the case.

A FunctionSet has a dimension N and a numeric type T. The dimension N corresponds
to the number of variables of the basis functions. The numeric type T is the
type of expansion coefficients corresponding to this set.

Each function set is ordered. There is a one-to-one map between the integers
from 1 to length(s) and the elements of the set. This map defines the order of
coefficients in a vector that represents a function expansion in the set.

A FunctionSet has two types of indexing: native indexing and linear indexing.
Linear indexing is used to order elements of the set into a vector, as explained
above. Native indices are closer to the mathematical definitions of the basis
functions. For example, a tensor product set consisting of M functions in the
first dimension times N functions in the second dimension may have a native index
(i,j), with 1 <= i <= M and 1 <= j <= N. The native representation of an expansion
in this set is a matrix of size M x N. In contrast, the linear representation is
a large vector of length MN.
Another example is given by orthogonal polynomials: they are typically indexed
by their degree. Hence, their native index ranges from 0 to N-1, but their linear
index ranges from 1 to N.

Computations in this package are typically performed using native indexing where
possible. Linear indexing is used to convert representations into a form suitable
for linear algebra: expansions turn into vectors, and linear operators turn into
matrices.
"""
abstract FunctionSet{N,T}


# Useful abstraction for special cases
typealias FunctionSet1d{T} FunctionSet{1,T}
typealias FunctionSet2d{T} FunctionSet{2,T}
typealias FunctionSet3d{T} FunctionSet{3,T}

"The dimension of the set."
ndims{N,T}(::FunctionSet{N,T}) = N
ndims{N,T}(::Type{FunctionSet{N,T}}) = N
ndims{S <: FunctionSet}(::Type{S}) = ndims(supertype(S))

"The numeric type of the set is like the eltype of the set, but it is always real."
numtype(s::FunctionSet) = real(eltype(s))

"Property to indicate whether the functions in the set are real-valued (for real arguments)."
isreal(s::FunctionSet) = isreal(one(eltype(s)))

"""
The eltype of a set is the typical numeric type of expansion coefficients. It is
either NumT or Complex{NumT}, where NumT is the numeric type of the set.
"""
eltype{N,T}(::Type{FunctionSet{N,T}}) = T
eltype{B <: FunctionSet}(::Type{B}) = eltype(supertype(B))

# Convenience methods
eltype(x, y) = promote_type(eltype(x), eltype(y))
eltype(x, y, z) = promote_type(eltype(x), eltype(y), eltype(z))
eltype(x, y, z, t) = promote_type(eltype(x), eltype(y), eltype(z), eltype(t))
eltype(x...) = promote_eltype(map(eltype, x)...)




# Is a given set a basis? In general, it is not. But it could be.
# Hence, we need a property for it:
is_basis(s::FunctionSet) = false

# Any basis is a frame
is_frame(s::FunctionSet) = is_basis(s)


"Property to indicate whether a basis is orthogonal."
is_orthogonal(s::FunctionSet) = false

"Property to indicate whether a basis is biorthogonal (or a Riesz basis)."
is_biorthogonal(s::FunctionSet) = is_orthogonal(s)

"Return the size of the set."
size(s::FunctionSet) = (length(s),)

"Return the size of the j-th dimension of the set (if applicable)."
size(s::FunctionSet, j) = j==1 ? length(s) : throw(BoundsError())

endof(s::FunctionSet) = length(s)

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

promote{N,T}(set1::FunctionSet{N,T}, set2::FunctionSet{N,T}) = (set1,set2)

function promote{N,T1,T2}(set1::FunctionSet{N,T1}, set2::FunctionSet{N,T2})
    T = promote_type(T1,T2)
    (promote_eltype(set1,T), promote_eltype(set2,T))
end

# similar returns a similar basis of a given size and numeric type
# It can be implemented in terms of resize and promote_eltype.
similar(b::FunctionSet, T::Type, n) = resize(promote_eltype(b, T), n)

"""
Return a set of zero coefficients in the native format of the set.
"""
zeros(set::FunctionSet) = zeros(eltype(set), set)

# By default we assume that the native format corresponds to an array of the
# same size as the set. This is not true, e.g., for multisets.
zeros(T::Type, set::FunctionSet) = zeros(T, size(set))


"Compute the native index corresponding to the given linear index."
native_index(b::FunctionSet, idx) = idx

"Compute the linear index corresponding to the given native index."
linear_index(b::FunctionSet, idxn) = idxn

"""
Convert the set of coefficients in the native format of the set to a linear list.
The order of the coefficients in this list is determined by the order of the
elements in the set.
"""
# We do nothing if the list of coefficiens is already linear and has the right
# element type
linearize_coefficients{N,T}(set::FunctionSet{N,T}, coef_native::AbstractArray{T,1}) = coef_native

# Otherwise: allocate memory for the linear set and call linearize_coefficients! to do the work
function linearize_coefficients(set::FunctionSet, coef_native)
    coef_linear = zeros(eltype(set), length(set))
    linearize_coefficients!(coef_linear, set, coef_native)
end

# Default implementation
function linearize_coefficients!(coef_linear, set::FunctionSet, coef_native)
    for (i,j) in enumerate(eachindex(coef_native))
        coef_linear[i] = coef_native[j]
    end
    coef_linear
end

"""
Convert a linear set of coefficients back to the native representation of the set.
"""
function delinearize_coefficients{N,T}(set::FunctionSet{N,T}, coef_linear::AbstractArray{T,1})
    coef_native = zeros(set)
    delinearize_coefficients!(coef_native, set, coef_linear)
end

function delinearize_coefficients!(coef_native, set::FunctionSet, coef_linear)
    for (i,j) in enumerate(eachindex(coef_native))
        coef_native[j] = coef_linear[i]
    end
    coef_native
end

# Sets have a native size and a linear size. However, there is not necessarily a
# bijection between the two. You can always convert a native size to a linear size,
# but the other direction can be done in general only approximately.
# For example, a 2D tensor product set can only support sizes of the form n1 * n2. Its native size may be
# (n1,n2) and its linear size n1*n2, but not any integer n maps to a native size tuple.
# By convention, we denote a native size variable by size_n.
"Compute the native size best corresponding to the given linear size."
approximate_native_size(b::FunctionSet, size_l) = size_l

"Compute the linear size corresponding to the given native size."
linear_size(b::FunctionSet, size_n) = size_n

"Suggest a suitable size, close to n, to resize the given function set."
approx_length(set::FunctionSet, n) = n


###############################
## Properties of function sets

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


#######################
## Iterating over sets

# Default set of linear indices: from 1 to length(s)
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

function checkbounds(s::FunctionSet, i1, i2, i3, i4)
    checkbounds(size(s,1),i1)
    checkbounds(size(s,2),i2)
    checkbounds(size(s,3),i3)
    checkbounds(size(s,4),i4)
end

function checkbounds(s::FunctionSet, i...)
    for n = 1:length(i)
        checkbounds(size(s,n), i[n])
    end
end

"Return the support of the idx-th basis function."
support(b::FunctionSet1d, idx) = (left(b,idx), right(b,idx))

"""
Compute the moment of the given basisfunction, i.e. the integral on its
support.
"""
# Default to numerical integration
moment(b::FunctionSet, idx) = quadgk(b[idx], left(b), right(b))[1]

# This is a candidate for generated functions to avoid the splatting
call_set{N}(b::FunctionSet{N}, i, x::AbstractVector) = call_set(b, i, x...)

# This too is a candidate for generated functions to avoid the splatting
call_set{N}(b::FunctionSet{N}, i, x::Vec{N}) = call_set(b, i, x...)

# Here is another candidate for generated functions to avoid the splatting
function call_set(s::FunctionSet, i, x...)
    checkbounds(s, i)
    call_element(s, i, x...)
end

# The specific set can choose to override call_element or call_element_native. The
# latter is called with a native index.
call_element(s::FunctionSet, i, x...) =
    call_element_native(s, native_index(s, i), x...)

# Evaluate on a grid
function call_set(b::FunctionSet, i::Int, grid::AbstractGrid)
    result = zeros(promote_type(eltype(b),numtype(grid)), size(grid))
    call_set!(result, b, i, grid)
end

function call_set!(result, b::FunctionSet, i::Int, grid::AbstractGrid)
    @assert size(result) == size(grid)

    for k in eachindex(grid)
        result[k] = call_set(b, i, grid[k]...)
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
            z = z + coef[i]*call_set(b, i, $(xargs...))
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
    apply!(E, result, coef)
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
