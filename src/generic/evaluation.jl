# evaluation.jl

#####################
# Generic evaluation
#####################

# Compute the evaluation matrix of the given basis on the given set of points
# (a grid or any iterable set of points)
function evaluation_matrix(set::FunctionSet, pts)
    T = promote_type(eltype(set), numtype(pts))
    a = Array(T, length(pts), length(set))
    evaluation_matrix!(a, set, pts)
end

function evaluation_matrix!(a::AbstractMatrix, set::FunctionSet, pts)
    @assert size(a,1) == length(pts)
    @assert size(a,2) == length(set)

    for (j,ϕ) in enumerate(set), (i,x) in enumerate(pts)
        a[i,j] = ϕ(x)
    end
    a
end

# By default we evaluate on the associated grid (if any, otherwise this gives an error)
evaluation_operator(set::FunctionSet; options...) =
    evaluation_operator(set, grid(set); options...)

# Convert a grid to a DiscreteGridSpace
evaluation_operator(set::FunctionSet, grid::AbstractGrid; options...) =
    evaluation_operator(set, gridspace(set, grid); options...)

# For easier dispatch, if the destination is a DiscreteGridSpace we add the grid as parameter
evaluation_operator(set::FunctionSet, dgs::DiscreteGridSpace; options...) =
    grid_evaluation_operator(set, dgs, grid(dgs); options...)

default_evaluation_operator(set::FunctionSet, dgs::DiscreteGridSpace; options...) =
    MultiplicationOperator(set, dgs, evaluation_matrix(set, grid(dgs)))

# Evaluate s in the grid of dgs
# We try to see if any fast transform is available
function grid_evaluation_operator(set::FunctionSet, dgs::DiscreteGridSpace, grid::AbstractGrid; options...)
    if has_transform(set)
        if has_transform(set, dgs)
            full_transform_operator(set, dgs; options...)
        elseif length(set) < length(dgs)
            if ndims(set) == 1
                larger_set = resize(set, length(dgs))
            # The basis should at least be resizeable to the dimensions of the grid
            elseif ndims(set) == length(size(dgs))
                larger_set = resize(set, size(dgs))
            end
            if has_transform(larger_set, dgs)
                full_transform_operator(larger_set, dgs; options...) * extension_operator(set, larger_set; options...)
            else
                default_evaluation_operator(set, dgs; options...)
            end
        else
            # This might be faster implemented by:
            #   - finding an integer n so that nlength(dgs)>length(s)
            #   - resorting to the above evaluation + extension
            #   - subsampling by factor n
            default_evaluation_operator(set, dgs; options...)
        end
    else
        default_evaluation_operator(set, dgs; options...)
    end
end

# Try to do efficient evaluation also for subgrids
function grid_evaluation_operator(set::FunctionSet, dgs::DiscreteGridSpace, subgrid::AbstractSubGrid; options...)
    # We make no attempt if the set has no associated grid
    if has_grid(set)
        # Is the associated grid of the same type as the supergrid at hand?
        if typeof(grid(set)) == typeof(supergrid(subgrid))
            # It is: we can use the evaluation operator of the supergrid
            super_dgs = gridspace(set, supergrid(subgrid))
            E = evaluation_operator(set, super_dgs; options...)
            R = restriction_operator(super_dgs, dgs; options...)
            R*E
        else
            default_evaluation_operator(set, dgs; options...)
        end
    else
        default_evaluation_operator(set, dgs; options...)
    end
end
