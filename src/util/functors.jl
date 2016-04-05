# functors.jl

"AbstractFunction is the supertype of all functors."
abstract AbstractFunction

isreal{F <: AbstractFunction}(::Type{F}) = True
isreal(f::AbstractFunction) = isreal(typeof(f))

"The function x^α"
immutable PowerFunction <: AbstractFunction
    α   ::  Int
end

name(f::PowerFunction, arg = "x") = "$arg^$(f.α)"

call(f::PowerFunction, x) = x^(f.α)


"Functor for the logarithmic function."
immutable Log <: AbstractFunction
end

name(f::Log, arg = "x") = "log($(arg))"

call(f::Log, x) = log(x)

derivative(f::Log) = PowerFunction(-1)


"Functor for the exponential function."
immutable Exp <: AbstractFunction
end

name(f::Exp, arg = "x") = "exp($(arg))"

call(f::Exp, x) = exp(x)

derivative(f::Exp) = f


"Functor for the cosine function."
immutable Cos <: AbstractFunction
end

name(f::Cos, arg = "x") = "cos($(arg))"

call(f::Cos, x) = cos(x)


"Functor for the sine function."
immutable Sin <: AbstractFunction
end

name(f::Sin, arg = "x") = "sin($(arg))"

call(f::Sin, x) = sin(x)

derivative(f::Cos) = -1 * Sin()

derivative(f::Sin) = Cos()



"A ScaledFunction represents a scalar times a function."
immutable ScaledFunction{F <: AbstractFunction,T} <: AbstractFunction
    f   ::  F
    a   ::  T
end

scalar(f::ScaledFunction) = f.a

*(a::Number, f::AbstractFunction) = ScaledFunction(f, a)
*(a::Number, f::ScaledFunction) = ScaledFunction(f.f, a*f.a)

call(f::ScaledFunction, x) = f.a * f.f(x)

name(f::ScaledFunction, arg = "x") = "$(f.a) * " * name(f.f, arg)

derivative(f::ScaledFunction) = f.a * derivative(f.f)

isreal{F,T}(::Type{ScaledFunction{F,T}}) = isreal(F) & isreal(T)



"A DilatedFunction represents f(a*x) where a is a scalar."
immutable DilatedFunction{F,T} <: AbstractFunction
    f   ::  F
    a   ::  T
end

scalar(f::DilatedFunction) = f.a

call(f::DilatedFunction, x) = f.f(f.a*x)

name(f::DilatedFunction, arg = "x") = name(f.f, "$(f.a) * " * arg)

derivative(f::DilatedFunction) = f.a * DilatedFunction(derivative(f.f), f.a)

isreal{F,T}(::Type{DilatedFunction{F,T}}) = isreal(F) & isreal(T)


"A CombinedFunction represents f op g, where op can be any binary operator."
immutable CombinedFunction{F,G,OP} <: AbstractFunction
    f   ::  F
    g   ::  G
    # op is supposed to be a type that can be called with two arguments
    # Such as: AddFun, MulFun, etc. -> see base/functors.jl
    op  ::  OP
end

+(f::AbstractFunction, g::AbstractFunction) = CombinedFunction(f, g, Base.AddFun())
-(f::AbstractFunction, g::AbstractFunction) = CombinedFunction(f, g, Base.SubFun())
*(f::AbstractFunction, g::AbstractFunction) = CombinedFunction(f, g, Base.MulFun())

fun1(f::CombinedFunction) = f.f
fun2(f::CombinedFunction) = f.g
operator(f::CombinedFunction) = f.op

call(f::CombinedFunction, x) = f.op(f.f(x), f.g(x))

name(f::CombinedFunction, arg = "x") = _name(f, f.op, arg)
_name(f::CombinedFunction, op::Base.AddFun, arg) = name(f.f, arg) * " + " * name(f.g, arg)
_name(f::CombinedFunction, op::Base.SubFun, arg) = name(f.f, arg) * " - " * name(f.g, arg)
_name(f::CombinedFunction, op::Base.MulFun, arg) = name(f.f, arg) * " * " * name(f.g, arg)

derivative(f::CombinedFunction) = derivative_op(f, fun1(f), fun2(f), operator(f))

derivative_op(::CombinedFunction, f, g, ::Base.AddFun) = derivative(f) + derivative(g)

derivative_op(::CombinedFunction, f, g, ::Base.SubFun) = derivative(f) - derivative(g)

# The chain rule
derivative_op(::CombinedFunction, f, g, ::Base.MulFun) = derivative(f) * g + f * derivative(g)


isreal{F,G,OP}(::Type{CombinedFunction{F,G,OP}}) = isreal(F) & isreal(G)


"A CompositeFunction represents f(g(x))."
immutable CompositeFunction{F,G} <: AbstractFunction
    f   ::  F
    g   ::  G
end

∘(f::AbstractFunction, g::AbstractFunction) = CompositeFunction(f, g)

call(f::CompositeFunction, x) = f.f(f.g(x))

name(f::CompositeFunction, arg = "x") = name(f.f, name(f.g, arg))

derivative(f::CompositeFunction) = (derivative(f.f) ∘ f.g) * derivative(f.g)

isreal{F,G}(::Type{CompositeFunction{F,G}}) = isreal(F) & isreal(G)


"The identity function"
immutable IdentityFunction <: AbstractFunction
end

call(f::IdentityFunction, x) = x

name(f::IdentityFunction, arg = "x") = arg

derivative(f::IdentityFunction) = ConstantFunction()

^(f::IdentityFunction, α::Int) = PowerFunction(α)

"The constant function 1"
immutable ConstantFunction <: AbstractFunction
end

call(f::ConstantFunction, x) = one(x)

name(f::ConstantFunction, arg = "x") = "1"

x = IdentityFunction()

*(f::ConstantFunction, g::ConstantFunction) = f
*(f::AbstractFunction, g::ConstantFunction) = f
*(f::ConstantFunction, g::AbstractFunction) = g

cos(f::AbstractFunction) = CompositeFunction(Cos(), f)
sin(f::AbstractFunction) = CompositeFunction(Sin(), f)
exp(f::AbstractFunction) = CompositeFunction(Exp(), f)
log(f::AbstractFunction) = CompositeFunction(Log(), f)
