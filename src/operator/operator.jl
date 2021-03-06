# operator.jl


"""
AbstractOperator represents any linear operator that maps coefficients of
a source set to coefficients of a destination set. Typically, source and
destination are of type FunctionSet.
The action of the operator is defined by providing a method for apply!.

The dimension of an operator are like a matrix: (length(dest),length(src)).

Source and destination should at least implement the following:
- length
- size
- eltype

The element type (eltype) should be equal for src and dest.
"""
abstract AbstractOperator{ELT}

eltype{ELT}(::AbstractOperator{ELT}) = ELT
eltype{ELT}(::Type{AbstractOperator{ELT}}) = ELT
eltype{OP <: AbstractOperator}(::Type{OP}) = eltype(supertype(OP))

isreal(op::AbstractOperator) = isreal(src(op)) && isreal(dest(op))

op_eltype(src::FunctionSet, dest::FunctionSet) = promote_type(eltype(src),eltype(dest))


"Promote the element type of the given operator."
promote_eltype{ELT,S}(op::AbstractOperator{ELT}, ::Type{S}) =
	_promote_eltype(op, promote_type(ELT,S))

# For eltype promotion, subtypes should implement op_promote_eltype. They can
# assume that S differs from ELT and that S is wider than ELT. The definition
# should be like:
# promote_eltype{ELT,S}(op::SomeOperator{ELT}, ::Type{S}) = ...
# The eltypes of the source and destination sets should also be promoted.
_promote_eltype{ELT}(op::AbstractOperator{ELT}, ::Type{ELT}) = op
_promote_eltype{ELT,S}(op::AbstractOperator{ELT}, ::Type{S}) =
	op_promote_eltype(op, S)

# Default implementation of src and dest: assume they are fields
src(op::AbstractOperator) = op.src
dest(op::AbstractOperator) = op.dest

# The size of the operator as a linear map from source to destination.
# It is equal to the size of its matrix representation.
size(op::AbstractOperator) = (length(dest(op)), length(src(op)))

size(op::AbstractOperator, j::Int) = j==1 ? length(dest(op)) : length(src(op))

#+(op1::AbstractOperator, op2::AbstractOperator) = +(promote(op1,op2)...)

"Is the action of the operator in-place?"
is_inplace(op::AbstractOperator) = false

"Is the operator diagonal?"
is_diagonal(op::AbstractOperator) = false

function apply(op::AbstractOperator, coef_src)
	coef_dest = zeros(eltype(op), dest(op))
	apply!(op, coef_dest, coef_src)
	coef_dest
end

# Catch applications of an operator, and do:
# - call inline implementation of operator if available
# - call apply!(op, dest(op), src(op), coef_dest, coef_src), which can be
#   implemented by operators whose action depends on src and/or dest.
function apply!(op::AbstractOperator, coef_dest, coef_src)
	if is_inplace(op)
		copy!(coef_dest, coef_src)
		apply_inplace!(op, coef_dest)
	else
		apply!(op, dest(op), src(op), coef_dest, coef_src)
	end
	# We expect each operator to return coef_dest, but we repeat here to make
	# sure our method is type-stable.
	coef_dest
end

# Provide a general dispatchable definition for in-place operators also
function apply!(op::AbstractOperator, coef_srcdest)
		apply_inplace!(op, coef_srcdest)
		coef_srcdest
end

function apply_inplace!(op::AbstractOperator, coef_srcdest)
		apply_inplace!(op, dest(op), src(op), coef_srcdest)
		coef_srcdest
end


# Catch-all for missing implementations
function apply!(op::AbstractOperator, dest, src, coef_dest, coef_src)
	println("Operation of ", typeof(op), " on ", typeof(dest), " and ", typeof(src), " not implemented.")
	throw(InexactError())
end

# Catch-all for missing implementations
function apply_inplace!(op::AbstractOperator, dest, src, coef_srcdest)
	println("In-place operation of ", typeof(op), " not implemented.")
	throw(InexactError())
end

(*)(op::AbstractOperator, coef_src) = apply(op, coef_src)

"""
Apply an operator multiple times, to each column of the given argument.
"""
function apply_multiple(op::AbstractOperator, matrix_src)
	ELT = eltype(op)
	matrix_dest = zeros(ELT, size(op,1), size(matrix_src)[2:end]...)
	coef_src = zeros(ELT, size(src(op)))
	coef_dest = zeros(ELT, size(dest(op)))
	apply_multiple!(op, matrix_dest, matrix_src, coef_dest, coef_src)
end

function apply_multiple!(op::AbstractOperator, matrix_dest, matrix_src,
	coef_dest = zeros(eltype(matrix_dest), size(dest(op))),
	coef_src  = zeros(eltype(matrix_src), size(src(op))))

	# Make sure the first dimensions of the matrices agree with the dimensions
	# of the operator
	@assert size(matrix_dest, 1) == size(op,1)
	@assert size(matrix_src, 1) == size(op,2)
	# and that the remaining dimensions agree with each other
	for i in 2:ndims(matrix_dest)
		@assert size(matrix_src,i) == size(matrix_dest,i)
	end
	for i in 1:size(matrix_src,2)
		for j in eachindex(coef_src)
			coef_src[j] = matrix_src[j,i]
		end
		apply!(op, coef_dest, coef_src)
		for j in eachindex(coef_dest)
			matrix_dest[j,i] = coef_dest[j]
		end
	end
	matrix_dest
end


collect(op::AbstractOperator) = matrix(op)

function matrix(op::AbstractOperator)
    a = Array(eltype(op), size(op))
    matrix!(op, a)
end

function matrix!(op::AbstractOperator, a)
    n = length(src(op))
    m = length(dest(op))

    @assert (m,n) == size(a)

    coef_src  = zeros(eltype(a), src(op))
    coef_dest = zeros(eltype(a), dest(op))
    matrix_fill!(op, a, coef_src, coef_dest)
end

function matrix_fill!(op::AbstractOperator, a, coef_src, coef_dest)
    for (i,si) in enumerate(eachindex(coef_src))
		coef_src[si] = 1
        apply!(op, coef_dest, coef_src)
		coef_src[si] = 0
        for (j,dj) in enumerate(eachindex(coef_dest))
            a[j,i] = coef_dest[dj]
        end
    end
    a
end

function checkbounds(op::AbstractOperator, i::Int, j::Int)
	1 <= i <= size(op,1) || throw(BoundsError())
	1 <= j <= size(op,2) || throw(BoundsError())
end

function getindex(op::AbstractOperator, i, j)
	checkbounds(op, i, j)
	unsafe_getindex(op, i, j)
end

function unsafe_getindex(op::AbstractOperator, i, j)
	s = zeros(eltype(op), src(op))
	d = zeros(eltype(op), dest(op))
	s[j] = 1
	apply!(op, d, s)
	d[i]
end

function diagonal(op::AbstractOperator)
    if is_diagonal(op)
        # Make data of all ones in the native representation of the operator
        all_ones = ones(src(op))
        # Apply the operator: this extracts the diagonal because the operator is diagonal
        diagonal_native = apply(op, all_ones)
        # Convert to vector
        linearize_coefficients(src(op), diagonal_native)
    else
        # This could be more efficient
        eltype(op)[op[i,i] for i in 1:length(src(op))]
    end
end

function inv_diagonal(op::AbstractOperator)
    @assert is_diagonal(op)
    d = diagonal(op)
    # Avoid getting Inf values, we prefer a pseudo-inverse in this case
    d[find(d.==0)] = Inf
    DiagonalOperator(dest(op), src(op), d.^(-1))
end



"An OperatorTranspose represents the transpose of an operator."
immutable OperatorTranspose{OP,ELT} <: AbstractOperator{ELT}
	op	::	OP

	OperatorTranspose(op::AbstractOperator{ELT}) = new(op)
end

OperatorTranspose(op::AbstractOperator) =
	OperatorTranspose{typeof(op),eltype(op)}(op)

promote_eltype{OP,ELT,S}(op::OperatorTranspose{OP,ELT}, ::Type{S}) =
	OperatorTranspose(promote_eltype(op.op, S))

ctranspose(op::AbstractOperator) = OperatorTranspose(op)

operator(opt::OperatorTranspose) = opt.op

# By simply switching src and dest, we implicitly identify the dual of these linear vector spaces
# with the spaces themselves.
src(opt::OperatorTranspose) = dest(operator(opt))

dest(opt::OperatorTranspose) = src(operator(opt))

for property in [:is_inplace, :is_diagonal]
	@eval $property(opt::OperatorTranspose) = $property(operator(opt))
end

# Types may implement this general transpose call to implement their transpose without creating a new operator type for it.
apply!(opt::OperatorTranspose, dest, src, coef_dest, coef_src) =
	apply_transpose!(operator(opt), src, dest, coef_dest, coef_src)

apply_inplace!(opt::OperatorTranspose, dest, src, coef_srcdest) =
	apply_transpose_inplace!(operator(opt), src, dest, coef_srcdest)

function apply_transpose!(op::AbstractOperator, dest, src, coef_dest, coef_src)
	println("Operation of ", typeof(op), " has no lazy transpose implemented.")
	throw(InexactError())
end

function apply_transpose_inplace!(op::AbstractOperator, dest, src, coef_srcdest)
	println("Operation of ", typeof(op), " has no in-place lazy transpose implemented.")
	throw(InexactError())
end


"An OperatorInverse represents the inverse of an operator."
immutable OperatorInverse{OP,ELT} <: AbstractOperator{ELT}
	op	::	OP

	OperatorInverse(op::AbstractOperator{ELT}) = new(op)
end

OperatorInverse(op::AbstractOperator) =
	OperatorInverse{typeof(op),eltype(op)}(op)

promote_eltype{OP,ELT,S}(op::OperatorInverse{OP,ELT}, ::Type{S}) =
	OperatorInverse(promote_eltype(op.op, S))

inv(op::AbstractOperator) = OperatorInverse(op)

operator(op::OperatorInverse) = op.op

src(op::OperatorInverse) = dest(operator(op))

dest(op::OperatorInverse) = src(operator(op))

for property in [:is_inplace, :is_diagonal]
	@eval $property(op::OperatorInverse) = $property(operator(op))
end

# Types may implement this general transpose call to implement their transpose without creating a new operator type for it.
apply!(op::OperatorInverse, dest, src, coef_dest, coef_src) =
	apply_inv!(operator(op), src, dest, coef_dest, coef_src)

apply!(op::OperatorInverse, dest, src, coef_srcdest) =
	apply_inv_inplace!(operator(op), src, dest, coef_srcdest)

function apply_inv!(op::AbstractOperator, dest, src, coef_dest, coef_src)
	println("Operation of ", typeof(op), " has no lazy inverse implemented.")
	throw(InexactError())
end

function apply_inv_inplace!(op::AbstractOperator, dest, src, coef_srcdest)
	println("Operation of ", typeof(op), " has no in-place lazy inverse implemented.")
	throw(InexactError())
end
