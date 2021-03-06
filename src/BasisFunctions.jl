# BasisFunctions

#__precompile__()

module BasisFunctions

using FastTransforms

using ArrayViews
using StaticArrays
using RecipesBase

import Base: +, *, /, ==, |, &, -, \, ^, .+, .*, .-, .\, ./, .^
import Base: ≈

import Base: promote, promote_rule, convert, promote_eltype, widen

import Base: length, size, start, next, done, ind2sub, sub2ind, eachindex,
        range, collect, endof, checkbounds, first, last

import Base: cos, sin, exp, log

import Base: zeros, ones, fill!

import Base: getindex, setindex!, unsafe_getindex, eltype

import Base: isreal, iseven, isodd

import Base: ctranspose, transpose, inv, hcat, vcat, ndims

import Base: show, showcompact, call, convert, similar

import Base: dct, idct

import Base: indices, normalize

import Base: broadcast

# import PyPlot: plot


## Exports

# from maps/maps.jl
export AbstractMap, AffineMap, DiagonalMap, IdentityMap
export forward_map, inverse_map, jacobian, linearize
export translation, linear_map, interval_map, scaling_map
export is_linear

# from maps/partition.jl
export PiecewiseInterval, Partition

# from grid/grid.jl
export AbstractGrid, AbstractGrid1d, AbstractGrid2d, AbstractGrid3d,
        AbstractEquispacedGrid, EquispacedGrid, PeriodicEquispacedGrid, MidpointEquispacedGrid,
        TensorProductGrid, AbstractIntervalGrid, eachelement, stepsize, ChebyshevGrid, ScatteredGrid, ChebyshevNodeGrid, ChebyshevExtremaGrid
export dim, left, right, range, sample

# from grid/subgrid.jl
export AbstractSubGrid, IndexSubGrid, subindices, supergrid, is_subindex,
    similar_subgrid

# from grid/mappedgrid.jl
export MappedGrid, mapped_grid, apply_map

# from operator/dimop.jl
export DimensionOperator, dimension_operator

# from sets/functionset.jl
export FunctionSet, FunctionSet1d, FunctionSet2d, FunctionSet3d
export numtype, grid, left, right, support, eval_expansion, eval_set_element, eval_element
export name
export complexify
export instantiate, promote_eltype, resize
export native_index, linear_index, multilinear_index, native_size, linear_size
export is_basis, is_frame, is_orthogonal, is_biorthogonal
export in_support
export True, False
export approx_length, extension_size
export has_transform, has_extension, has_derivative, has_antiderivative, has_grid
export linearize_coefficients, delinearize_coefficients
export moment

# from sets/subsets.jl
export FunctionSubSet, indices

# from sets/tensorproductset.jl
export TensorProductSet, tensorproduct, ⊗, element, elements, composite_length

# from sets/mappedsets.jl
export map, imap, map_linear, imap_linear, rescale

# from sets/mapped_set.jl
export MappedSet, mapped_set, mapping

#from expansions.jl
export SetExpansion, TensorProductExpansion, coefficients, set, roots,
        random_expansion, differentiate, antidifferentiate, call_set_expansion,
        ∂x, ∂y, ∂z, ∫∂x, ∫∂y, ∫∂z, ∫, is_compatible

# from operator/operators.jl
export AbstractOperator, operator, src, dest, apply!,
        apply, apply_multiple, apply_inplace!
export OperatorInverse, OperatorTranspose
export matrix, diagonal, is_diagonal, is_inplace

# from operator/composite_operator.jl
export CompositeOperator, compose

# from operator/special_operators.jl
export IdentityOperator, ScalingOperator, DiagonalOperator, inv_diagonal,
        CoefficientScalingOperator, MatrixOperator, FunctionOperator,
        MultiplicationOperator, WrappedOperator, UnevenSignFlipOperator, ZeroOperator,
        IndexRestrictionOperator, IndexExtensionOperator

# from generic/transform.jl
export transform_operator, transform_set, full_transform_operator,
    transform_operator_pre, transform_operator_post,
    transform_to_grid, transform_to_grid_pre, transform_to_grid_post,
    transform_from_grid, transform_from_grid_pre, transform_from_grid_post

# from generic/extension
export extension_operator, default_extension_operator, extension_size, extend,
    restriction_operator, default_restriction_operator, restriction_size, restrict,
    Extension, Restriction

# from generic/evaluation.jl
export evaluation_operator, grid_evaluation_operator, default_evaluation_operator,
    evaluation_matrix

# from generic/interpolation.jl
export interpolation_operator, default_interpolation_operator, interpolation_matrix

# from generic/leastsquares.jl
export leastsquares_operator, default_leastsquares_operator, leastsquares_matrix

# from generic/approximation.jl
export approximation_operator, default_approximation_operator, approximate

# from generic/differentiation.jl
export differentiation_operator, antidifferentiation_operator, derivative_set,
    antiderivative_set, Differentiation, Antidifferentiation

# from tensorproducts.jl
export is_homogeneous, basetype, tensorproduct

# from operator/tensorproductoperator.jl
export TensorProductOperator

# from operator/block_operator.jl
export BlockOperator, block_row_operator, block_column_operator, composite_size

# from functional/functional.jl
export AbstractFunctional, EvaluationFunctional, row

# from grid/discretegridspace.jl
export DiscreteGridSpace, DiscreteGridSpace1d, DiscreteGridSpaceNd, left, right,
    gridspace

# from util/functors.jl
export Cos, Sin, Exp, Log, PowerFunction, IdentityFunction

# from sets/augmented_set.jl
export ⊕, set, fun, derivative, AugmentedSet

# from sets/multiple_set.jl
export MultiSet, multiset

# from sets/piecewise_set.jl
export PiecewiseSet

# from sets/operated_set.jl
export OperatedSet

# from sets/euclidean.jl
export Cn, Rn

# from fourier/fourier.jl
export FourierBasis, FourierBasisEven, FourierBasisOdd, FourierBasisNd,
    FastFourierTransform, InverseFastFourierTransform,
    FastFourierTransformFFTW, InverseFastFourierTransformFFTW,
    frequency2idx, idx2frequency,
    fourier_basis_even, fourier_basis_odd

# from fourier/(co)sineseries.jl
export CosineSeries, SineSeries


# from poly/chebyshev.jl
export ChebyshevBasis, ChebyshevBasisSecondKind,
    FastChebyshevTransform, InverseFastChebyshevTransform,
    FastChebyshevTransformFFTW, InverseFastChebyshevTransformFFTW

# from util/plots.jl
# export plot, plot_expansion, plot_samples, plot_error
# from util/recipes.jl
export plotgrid, postprocess

#from util/MultiArray.jl
export MultiArray

# from poly/polynomials.jl and friends
export LegendreBasis, JacobiBasis, LaguerreBasis, HermiteBasis, MonomialBasis

# from bf_splines.jl
export SplineBasis, FullSplineBasis, PeriodicSplineBasis, NaturalSplineBasis, SplineDegree
export degree, interval


using Base.Cartesian


include("util/common.jl")
include("util/multiarray.jl")
include("util/slices.jl")
include("util/functors.jl")

include("maps/maps.jl")
include("maps/partition.jl")

include("grid/grid.jl")
include("grid/tensorproductgrid.jl")

include("sets/functionset.jl")

include("operator/operator.jl")
include("operator/composite_operator.jl")

include("grid/discretegridspace.jl")
include("grid/mappedgrid.jl")
include("grid/intervalgrids.jl")
include("grid/scattered_grid.jl")
include("grid/subgrid.jl")

include("sets/derived_set.jl")
include("sets/tensorproductset.jl")
include("sets/mapped_set.jl")

include("sets/euclidean.jl")

include("operator/dimop.jl")

include("operator/basic_operators.jl")
include("operator/special_operators.jl")
include("operator/tensorproductoperator.jl")
include("operator/block_operator.jl")



include("expansions.jl")

include("functional/functional.jl")


include("tensorproducts.jl")

include("generic/generic_operators.jl")

include("sets/subsets.jl")
include("sets/composite_set.jl")
include("sets/multiple_set.jl")
include("sets/piecewise_set.jl")
include("sets/operated_set.jl")
include("sets/augmented_set.jl")


include("fourier/fouriertransforms.jl")
include("fourier/fourier.jl")
include("fourier/cosineseries.jl")
include("fourier/sineseries.jl")

include("bf_splines.jl")

include("bf_wavelets.jl")

include("poly/polynomials.jl")

include("poly/chebyshev.jl")
include("poly/legendre.jl")
include("poly/jacobi.jl")
include("poly/laguerre.jl")
include("poly/hermite.jl")

include("util/recipes.jl")

end # module
